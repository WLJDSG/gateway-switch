import SwiftUI
import SharedKit
#if canImport(GatewayKit)
import GatewayKit
#endif

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HeaderView()

                    GatewayProfilePicker()

                    PasswordlessHelperBanner()

                    NetworkInfoGrid()

                    FooterView()
                }
                .padding(28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }

            if appState.isSwitching {
                SwitchingOverlay()
                    .transition(.opacity)
            }
        }
        .background(.background)
        .animation(.easeInOut(duration: 0.18), value: appState.isSwitching)
    }
}

private struct HeaderView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: appState.activeProfile?.symbolName ?? "network")
                .font(.system(size: 38, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(appState.activeProfile?.accentColor ?? .green)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text("网关切换器")
                    .font(.system(size: 28, weight: .bold))
                Text("当前使用 \(appState.displayGateway ?? "检测中")，可在已配置的网关之间快速切换。")
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Button {
                appState.refresh()
            } label: {
                Label("刷新", systemImage: appState.isRefreshing ? "arrow.triangle.2.circlepath.circle" : "arrow.clockwise")
            }
            .disabled(appState.isRefreshing)

            Button {
                openManagementView()
            } label: {
                Label("管理", systemImage: "gearshape")
            }
        }
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

private struct GatewayProfilePicker: View {
    @EnvironmentObject private var appState: AppState
    private let columns = [
        GridItem(.adaptive(minimum: 230), spacing: 14)
    ]

    var body: some View {
        if appState.profiles.isEmpty {
            Text("暂无网关配置，请点击「管理」添加。")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 80)
        } else {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                ForEach(appState.profiles) { profile in
                    GatewayProfileCard(profile: profile)
                }
            }
        }
    }
}

private struct GatewayProfileCard: View {
    @EnvironmentObject private var appState: AppState
    let profile: GatewayProfile

    private var isActive: Bool {
        appState.activeProfile?.id == profile.id
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label(profile.title, systemImage: profile.symbolName)
                    .font(.headline)
                Spacer()
                if isActive {
                    Label("使用中", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
            }

            Text(profile.gateway)
                .font(.system(.title2, design: .monospaced, weight: .semibold))

            Text(profile.description)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("DNS \(profile.dnsServers.joined(separator: ", "))")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button {
                appState.switchGateway(to: profile)
            } label: {
                if appState.switchingProfile?.id == profile.id {
                    Label("正在切换", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                } else {
                    Label(isActive ? "当前已启用" : "切换到此网关", systemImage: isActive ? "checkmark" : "arrow.right.circle")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isActive || appState.isSwitching)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isActive ? Color.green.opacity(0.65) : Color.secondary.opacity(0.14), lineWidth: isActive ? 2 : 1)
        }
    }
}

private struct SwitchingOverlay: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("正在切换网关")
                .font(.headline)
            Text("目标 \(appState.switchingProfile?.gateway ?? "网关")，正在同步 IPv4 路由器和 DNS。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(width: 320)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(radius: 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.08))
    }
}

private struct PasswordlessHelperBanner: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: appState.isPasswordlessEnabled ? "checkmark.shield.fill" : "lock.shield")
                .foregroundStyle(appState.isPasswordlessEnabled ? .green : .orange)
                .font(.title3)

            VStack(alignment: .leading, spacing: 3) {
                Text(appState.isPasswordlessEnabled ? "免密切换已启用" : "可安装免密切换")
                    .font(.headline)
                Text(appState.isPasswordlessEnabled ? "后续切换会走受限 helper，不再反复要求管理员密码。" : "首次安装需要管理员密码；之后只允许免密切换已配置的网关 IP。")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if !appState.isPasswordlessEnabled {
                Button {
                    appState.installPasswordlessHelper()
                } label: {
                    Label(appState.isInstallingHelper ? "安装中" : "安装", systemImage: "key")
                }
                .disabled(appState.isInstallingHelper)
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct NetworkInfoGrid: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
            GridRow {
                InfoTile(title: "本机 IP", value: appState.snapshot.localIPv4 ?? "未检测到", symbol: "laptopcomputer")
                InfoTile(title: "默认网关", value: appState.snapshot.gateway ?? "未检测到", symbol: "router")
            }
            GridRow {
                InfoTile(title: "子网掩码", value: appState.snapshot.subnetMask ?? "未知", symbol: "rectangle.3.group")
                InfoTile(title: "网络服务", value: appState.snapshot.serviceName ?? "未知", symbol: "wifi")
            }
            GridRow {
                InfoTile(title: "接口", value: appState.snapshot.interfaceName ?? "未知", symbol: "point.3.connected.trianglepath.dotted")
                InfoTile(title: "DNS", value: appState.snapshot.dnsServers.isEmpty ? "系统默认 / 未设置" : appState.snapshot.dnsServers.joined(separator: ", "), symbol: "server.rack")
            }
            GridRow {
                InfoTile(title: "更新时间", value: appState.snapshot.capturedAt.formatted(date: .omitted, time: .standard), symbol: "clock")
                InfoTile(title: "授权", value: appState.isPasswordlessEnabled ? "免密 helper" : "管理员授权", symbol: "key")
            }
        }
    }
}

private struct InfoTile: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(.body, design: value.contains(".") ? .monospaced : .default))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct FooterView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack {
            if appState.isSwitching {
                ProgressView()
                    .controlSize(.small)
                Text("正在写入 IPv4 路由器和 DNS...")
                    .foregroundStyle(.secondary)
            } else if appState.isInstallingHelper {
                ProgressView()
                    .controlSize(.small)
                Text("正在安装免密 helper...")
                    .foregroundStyle(.secondary)
            } else if let message = appState.statusMessage {
                Image(systemName: message.contains("失败") ? "exclamationmark.triangle" : "info.circle")
                    .foregroundStyle(message.contains("失败") ? .orange : .secondary)
                Text(message)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            } else {
                Image(systemName: "lock.shield")
                    .foregroundStyle(.secondary)
                Text("未安装免密 helper 时，切换会弹出管理员授权；安装后只需授权一次。")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .font(.callout)
    }
}

extension GatewayProfile {
    var accentColor: Color {
        let palette: [Color] = [.green, .orange, .blue, .purple, .red, .teal, .indigo, .yellow]
        let index = abs(id.hashValue) % palette.count
        return palette[index]
    }
}