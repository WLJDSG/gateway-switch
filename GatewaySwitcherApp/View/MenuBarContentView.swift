import SwiftUI
import Core
#if canImport(SwitcherFeature)
import SwitcherFeature
#endif

struct MenuBarContentView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(viewModel.snapshot.gateway ?? "未知网关")
                .font(.headline)

            if let localIP = viewModel.snapshot.localIPv4 {
                Text(localIP)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            ForEach(viewModel.profiles) { profile in
                Button {
                    viewModel.switchGateway(to: profile)
                } label: {
                    Label(profile.title, systemImage: profile.symbolName)
                }
                .disabled(viewModel.activeProfile?.id == profile.id || viewModel.isSwitching)
            }

            Divider()

            Button {
                openManagementView()
            } label: {
                Label("管理网关...", systemImage: "gearshape")
            }

            if !viewModel.isPasswordlessEnabled {
                Button {
                    viewModel.installPasswordlessHelper()
                } label: {
                    Label("安装免密切换", systemImage: "key")
                }
                .disabled(viewModel.isInstallingHelper)
            }

            Button {
                viewModel.refresh()
            } label: {
                Label("刷新状态", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isRefreshing)

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
            let vc = NSHostingController(rootView: ProfileManagementView().environmentObject(viewModel))
            let window = NSWindow(contentViewController: vc)
            window.title = "网关配置"
            window.makeKeyAndOrderFront(nil)
        }
    }
}