import SwiftUI
import SharedKit

struct ProfileEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let isNew: Bool
    @State var profile: GatewayProfile

    @State private var dnsSameAsGateway = true
    @State private var customDNS = ""
    @State private var gatewayError: String?
    @State private var selectedSymbolIndex = 0

    private static let symbolOptions: [(name: String, label: String)] = [
        ("router", "路由器"),
        ("network", "网络"),
        ("wifi", "Wi-Fi"),
        ("globe", "全球"),
        ("shield", "盾牌"),
        ("lock.shield", "安全盾"),
        ("point.3.connected.trianglepath.dotted", "连接点"),
        ("network.badge.shield.half.filled", "代理"),
        ("server.rack", "服务器"),
        ("ethernet", "以太网"),
        ("antenna.radiowaves.left.and.right", "信号"),
        ("desktopcomputer", "台式机"),
        ("laptopcomputer", "笔记本"),
        ("link", "链接"),
        ("signals", "信号流"),
        ("telecom", "通信"),
        ("externaldrive", "外置存储"),
        ("flowchart", "流程"),
        ("arrow.triangle.branch", "分支"),
        ("lock", "锁定"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(isNew ? "新增网关" : "编辑网关")
                .font(.title2.weight(.bold))

            Form {
                TextField("标题", text: $profile.title)

                TextField("网关 IP", text: $profile.gateway)
                    .onChange(of: profile.gateway) { _, newValue in
                        validateGateway(newValue)
                    }

                if let gatewayError {
                    Text(gatewayError)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                Toggle("DNS 与网关相同", isOn: $dnsSameAsGateway)

                if !dnsSameAsGateway {
                    TextField("DNS 服务器（逗号分隔）", text: $customDNS)
                    Text("示例：8.8.8.8, 8.8.4.4")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("描述", text: $profile.description)

                SFSymbolPicker(selectedIndex: $selectedSymbolIndex, options: Self.symbolOptions)
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("取消") { dismiss() }
                Button("保存") {
                    saveProfile()
                    dismiss()
                }
                .disabled(profile.title.isEmpty || profile.gateway.isEmpty || gatewayError != nil)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 500)
        .onAppear {
            dnsSameAsGateway = profile.dnsServers == [profile.gateway]
            if !dnsSameAsGateway {
                customDNS = profile.dnsServers.joined(separator: ", ")
            }
            selectedSymbolIndex = Self.symbolOptions.firstIndex(where: { $0.name == profile.symbolName }) ?? 0
        }
    }

    private func validateGateway(_ value: String) {
        let parts = value.split(separator: ".")
        if parts.count != 4 {
            gatewayError = value.isEmpty ? nil : "需要 4 段 IP 地址"
            return
        }
        let valid = parts.allSatisfy { part in
            guard let n = Int(part), String(n) == part else { return false }
            return (0...255).contains(n)
        }
        gatewayError = valid ? nil : "IP 地址格式不正确"
    }

    private func saveProfile() {
        profile.symbolName = Self.symbolOptions[selectedSymbolIndex].name
        if dnsSameAsGateway {
            profile.dnsServers = [profile.gateway]
        } else {
            profile.dnsServers = customDNS
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if profile.dnsServers.isEmpty {
                profile.dnsServers = [profile.gateway]
            }
        }

        if isNew {
            appState.addProfile(profile)
        } else {
            appState.updateProfile(profile)
        }
    }
}

private struct SFSymbolPicker: View {
    @Binding var selectedIndex: Int
    let options: [(name: String, label: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("图标")
                .font(.headline)

            LazyVGrid(columns: Array(repeating: GridItem(.fixed(48), spacing: 8), count: 5), spacing: 8) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Button {
                        selectedIndex = index
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: option.name)
                                .font(.title3)
                                .frame(width: 40, height: 40)
                            Text(option.label)
                                .font(.system(size: 9))
                                .lineLimit(1)
                        }
                        .frame(width: 48, height: 56)
                        .background(selectedIndex == index ? Color.accentColor.opacity(0.2) : Color.clear, in: RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(selectedIndex == index ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: selectedIndex == index ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}