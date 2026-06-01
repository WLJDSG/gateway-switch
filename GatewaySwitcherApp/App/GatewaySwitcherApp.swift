import SwiftUI
import Core
#if canImport(SwitcherFeature)
import SwitcherFeature
#endif

@main
struct GatewaySwitcherApp: App {
    @StateObject private var viewModel = AppViewModel()

    var body: some Scene {
        WindowGroup("切换网关") {
            ContentView()
                .environmentObject(viewModel)
                .frame(minWidth: 820, minHeight: 660)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onReceive(Timer.publish(every: 8, on: .main, in: .common).autoconnect()) { _ in
                    viewModel.refresh()
                }
        }
        .defaultSize(width: 920, height: 720)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("刷新网络状态") {
                    viewModel.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(viewModel)
        } label: {
            Label(viewModel.menuTitle, systemImage: viewModel.menuSymbolName)
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "gatewayswitcher", url.host == "switch" else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let idString = components?.queryItems?.first(where: { $0.name == "id" })?.value,
           let uuid = UUID(uuidString: idString),
           let profile = viewModel.profiles.first(where: { $0.id == uuid }) {
            viewModel.switchGateway(to: profile)
            return
        }

        if let legacyValue = components?.queryItems?.first(where: { $0.name == "profile" })?.value {
            let legacyMapping: [String: UUID] = [
                "china":    UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
                "dotTwo":   UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")!,
                "proxy":    UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")!,
            ]
            if let uuid = legacyMapping[legacyValue],
               let profile = viewModel.profiles.first(where: { $0.id == uuid }) {
                viewModel.switchGateway(to: profile)
                return
            }
        }
    }
}