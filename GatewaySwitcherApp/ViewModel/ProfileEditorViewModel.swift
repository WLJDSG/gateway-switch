import SwiftUI
import Core

@MainActor
final class ProfileEditorViewModel: ObservableObject {
    @Published var title: String
    @Published var gateway: String
    @Published var dnsSameAsGateway = true
    @Published var customDNS = ""
    @Published var description: String
    @Published var selectedSymbolIndex = 0
    @Published var gatewayError: String?

    let isNew: Bool
    private let originalProfile: GatewayProfile

    static let symbolOptions: [(name: String, label: String)] = [
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

    init(isNew: Bool, profile: GatewayProfile) {
        self.isNew = isNew
        self.originalProfile = profile
        self.title = profile.title
        self.gateway = profile.gateway
        self.description = profile.description
        self.dnsSameAsGateway = profile.dnsServers == [profile.gateway]
        if !dnsSameAsGateway {
            customDNS = profile.dnsServers.joined(separator: ", ")
        }
        selectedSymbolIndex = Self.symbolOptions.firstIndex(where: { $0.name == profile.symbolName }) ?? 0
    }

    var canSave: Bool {
        !title.isEmpty && !gateway.isEmpty && gatewayError == nil
    }

    func validateGateway() {
        let parts = gateway.split(separator: ".")
        if parts.count != 4 {
            gatewayError = gateway.isEmpty ? nil : "需要 4 段 IP 地址"
            return
        }
        let valid = parts.allSatisfy { part in
            guard let n = Int(part), String(n) == part else { return false }
            return (0...255).contains(n)
        }
        gatewayError = valid ? nil : "IP 地址格式不正确"
    }

    func buildProfile() -> GatewayProfile {
        var dns: [String]
        if dnsSameAsGateway {
            dns = [gateway]
        } else {
            dns = customDNS
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
            if dns.isEmpty { dns = [gateway] }
        }

        return GatewayProfile(
            id: originalProfile.id,
            title: title,
            gateway: gateway,
            dnsServers: dns,
            description: description,
            symbolName: Self.symbolOptions[selectedSymbolIndex].name
        )
    }
}