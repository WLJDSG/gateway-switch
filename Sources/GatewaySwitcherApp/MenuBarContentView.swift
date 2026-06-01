import SwiftUI
import SharedKit
#if canImport(GatewayKit)
import GatewayKit
#endif

struct MenuBarContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appState.snapshot.gateway ?? "未知网关")
                .font(.headline)

            if let localIP = appState.snapshot.localIPv4 {
                Text(localIP)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(appState.profiles) { profile in
                Button {
                    appState.switchGateway(to: profile)
                } label: {
                    Label(profile.title, systemImage: profile.symbolName)
                }
                .disabled(appState.activeProfile?.id == profile.id || appState.isSwitching)
            }

            Divider()

            Button {
                openManagementView()
            } label: {
                Label("管理网关...", systemImage: "gearshape")
            }

            if !appState.isPasswordlessEnabled {
                Button {
                    appState.installPasswordlessHelper()
                } label: {
                    Label("安装免密切换", systemImage: "key")
                }
                .disabled(appState.isInstallingHelper)
            }

            Button {
                appState.refresh()
            } label: {
                Label("刷新状态", systemImage: "arrow.clockwise")
            }
            .disabled(appState.isRefreshing)

            Button("退出") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 6)
    }

    private func openManagementView() {
        if let window = NSApp.windows.first(where: { $0.title == "网关配置" }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            let vc = NSHostingController(rootView: ProfileManagementView().environmentObject(appState))
            let window = NSWindow(contentViewController: vc)
            window.title = "网关配置"
            window.makeKeyAndOrderFront(nil)
        }
    }
}