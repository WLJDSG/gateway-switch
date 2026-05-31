#if canImport(GatewayKit)
import GatewayKit
#endif
import SwiftUI

@main
struct GatewaySwitcherApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup("切换网关") {
            ContentView()
                .environmentObject(appState)
                .frame(minWidth: 820, minHeight: 660)
        }
        .defaultSize(width: 920, height: 720)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("刷新网络状态") {
                    appState.refresh()
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        MenuBarExtra {
            MenuBarContentView()
                .environmentObject(appState)
        } label: {
            Label(appState.menuTitle, systemImage: appState.menuSymbolName)
        }
    }
}
