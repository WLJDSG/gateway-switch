import Foundation
import Core
#if canImport(SwitcherFeature)
import SwitcherFeature
#endif
import WidgetKit

@MainActor
final class AppViewModel: ObservableObject {
    @Published private(set) var snapshot = NetworkSnapshot(
        gateway: nil,
        interfaceName: nil,
        serviceName: nil,
        localIPv4: nil,
        dnsServers: []
    )
    @Published private(set) var profiles: [GatewayProfile] = []
    @Published private(set) var isRefreshing = false
    @Published private(set) var isSwitching = false
    @Published private(set) var switchingProfile: GatewayProfile?
    @Published private(set) var isInstallingHelper = false
    @Published private(set) var isPasswordlessEnabled = false
    @Published var statusMessage: String?

    private let service: GatewayService
    private let profileStore: ProfileStore

    init(service: GatewayService = GatewayService(), profileStore: ProfileStore = .shared) {
        self.service = service
        self.profileStore = profileStore

        loadProfiles()
        refresh()
        refreshPasswordlessStatus()
    }

    var activeProfile: GatewayProfile? {
        snapshot.activeProfile(from: profiles)
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

    func loadProfiles() {
        profiles = profileStore.initializeDefaultsIfNeeded()
    }

    func addProfile(_ profile: GatewayProfile) {
        profileStore.add(profile)
        profiles = profileStore.profiles
        WidgetCenter.shared.reloadAllTimelines()
        syncWhitelistIfNeeded()
    }

    func deleteProfile(id: UUID) {
        profileStore.delete(id: id)
        profiles = profileStore.profiles
        WidgetCenter.shared.reloadAllTimelines()
        syncWhitelistIfNeeded()
    }

    func updateProfile(_ profile: GatewayProfile) {
        profileStore.update(profile)
        profiles = profileStore.profiles
        WidgetCenter.shared.reloadAllTimelines()
        syncWhitelistIfNeeded()
    }

    func refresh() {
        guard !isRefreshing, !isSwitching else { return }
        isRefreshing = true

        Task.detached(priority: .userInitiated) { [service] in
            let nextSnapshot = service.currentSnapshot()
            let helperInstalled = service.isHelperInstalled()
            await MainActor.run {
                self.snapshot = nextSnapshot
                self.isPasswordlessEnabled = helperInstalled
                self.isRefreshing = false
            }
        }
    }

    func refreshPasswordlessStatus() {
        Task.detached(priority: .utility) { [service] in
            let helperInstalled = service.isHelperInstalled()
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

        Task.detached(priority: .userInitiated) { [service, installerPath] in
            do {
                try service.installHelper(installerPath: installerPath)
                let helperInstalled = service.isHelperInstalled()
                await MainActor.run {
                    self.isPasswordlessEnabled = helperInstalled
                    self.isInstallingHelper = false
                    self.statusMessage = helperInstalled ? "免密切换已启用，后续切换不再需要输入密码。" : "helper 已安装，但免密状态验证失败。"
                    self.syncWhitelistIfNeeded()
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

        Task.detached(priority: .userInitiated) { [service, profile] in
            do {
                let currentSnapshot = service.currentSnapshot()
                try service.switchGateway(to: profile, snapshot: currentSnapshot)
                let nextSnapshot = service.currentSnapshot()
                let helperInstalled = service.isHelperInstalled()
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

    private func syncWhitelistIfNeeded() {
        guard isPasswordlessEnabled else { return }
        let ips = profiles.map { $0.gateway } + profiles.flatMap { $0.dnsServers }

        Task.detached(priority: .utility) { [service, ips] in
            do {
                try service.syncWhitelist(ips: ips)
            } catch {
                // Whitelist update failure is non-critical
            }
        }
    }
}