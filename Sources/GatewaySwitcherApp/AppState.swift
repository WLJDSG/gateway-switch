import Foundation
#if canImport(GatewayKit)
import GatewayKit
#endif

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var snapshot = NetworkSnapshot(
        gateway: nil,
        interfaceName: nil,
        serviceName: nil,
        localIPv4: nil,
        dnsServers: []
    )
    @Published private(set) var isRefreshing = false
    @Published private(set) var isSwitching = false
    @Published private(set) var switchingProfile: GatewayProfile?
    @Published private(set) var isInstallingHelper = false
    @Published private(set) var isPasswordlessEnabled = false
    @Published var statusMessage: String?

    private let inspector = NetworkInspector()
    private let switcher = GatewaySwitcher()
    private var timer: Timer?

    init() {
        refresh()
        refreshPasswordlessStatus()
        timer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
    }

    var activeProfile: GatewayProfile? {
        snapshot.activeProfile
    }

    var displayGateway: String? {
        switchingProfile?.gateway ?? snapshot.gateway
    }

    var menuTitle: String {
        activeProfile?.title ?? "网关"
    }

    var menuSymbolName: String {
        activeProfile?.symbolName ?? "network"
    }

    func refresh() {
        guard !isRefreshing, !isSwitching else { return }
        isRefreshing = true

        Task.detached(priority: .userInitiated) { [inspector] in
            let nextSnapshot = inspector.snapshot()
            let helperInstalled = PasswordlessHelper.isInstalled()
            await MainActor.run {
                self.snapshot = nextSnapshot
                self.isPasswordlessEnabled = helperInstalled
                self.isRefreshing = false
            }
        }
    }

    func refreshPasswordlessStatus() {
        Task.detached(priority: .utility) {
            let helperInstalled = PasswordlessHelper.isInstalled()
            await MainActor.run {
                self.isPasswordlessEnabled = helperInstalled
            }
        }
    }

    func installPasswordlessHelper() {
        guard !isInstallingHelper else { return }
        guard let installerPath = Bundle.main.path(forResource: "install_passwordless_helper", ofType: "sh") else {
            statusMessage = "没有找到免密 helper 安装脚本，请通过运行脚本重新启动应用。"
            return
        }

        isInstallingHelper = true
        statusMessage = "正在安装免密切换 helper..."

        Task.detached(priority: .userInitiated) {
            do {
                try PasswordlessHelper.install(installerPath: installerPath)
                let helperInstalled = PasswordlessHelper.isInstalled()
                await MainActor.run {
                    self.isPasswordlessEnabled = helperInstalled
                    self.isInstallingHelper = false
                    self.statusMessage = helperInstalled ? "免密切换已启用，后续切换不再需要输入密码。" : "helper 已安装，但免密状态验证失败。"
                }
            } catch {
                await MainActor.run {
                    self.isInstallingHelper = false
                    self.statusMessage = error.localizedDescription
                    self.refreshPasswordlessStatus()
                }
            }
        }
    }

    func switchGateway(to profile: GatewayProfile) {
        guard !isSwitching else { return }
        isSwitching = true
        switchingProfile = profile
        statusMessage = "正在切换到 \(profile.gateway)，并同步 DNS..."

        let currentSnapshot = snapshot
        Task.detached(priority: .userInitiated) { [switcher, currentSnapshot] in
            do {
                try switcher.switchDefaultGateway(to: profile, snapshot: currentSnapshot)
                let nextSnapshot = NetworkInspector().snapshot()
                let helperInstalled = PasswordlessHelper.isInstalled()
                await MainActor.run {
                    self.snapshot = nextSnapshot
                    self.isPasswordlessEnabled = helperInstalled
                    self.statusMessage = "已切换到 \(profile.title) \(profile.gateway)，DNS：\(profile.dnsServers.joined(separator: ", "))"
                    self.isSwitching = false
                    self.switchingProfile = nil
                }
            } catch {
                await MainActor.run {
                    self.statusMessage = error.localizedDescription
                    self.isSwitching = false
                    self.switchingProfile = nil
                    self.refresh()
                }
            }
        }
    }

    func handleDeepLink(_ url: URL) {
        guard
            url.scheme == "gatewayswitcher",
            url.host == "switch",
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let profileValue = components.queryItems?.first(where: { $0.name == "profile" })?.value,
            let profile = GatewayProfile(rawValue: profileValue)
        else {
            return
        }

        switchGateway(to: profile)
    }
}
