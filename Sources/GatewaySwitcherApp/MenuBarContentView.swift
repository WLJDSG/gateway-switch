#if canImport(GatewayKit)
import GatewayKit
#endif
import SwiftUI

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

            ForEach(GatewayProfile.allCases) { profile in
                Button {
                    appState.switchGateway(to: profile)
                } label: {
                    Label(profile.title, systemImage: profile.symbolName)
                }
                .disabled(appState.activeProfile == profile || appState.isSwitching)
            }

            Divider()

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
}
