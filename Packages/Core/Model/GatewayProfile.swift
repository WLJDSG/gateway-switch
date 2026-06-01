import Foundation

public struct GatewayProfile: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var gateway: String
    public var dnsServers: [String]
    public var description: String
    public var symbolName: String

    public init(
        id: UUID = UUID(),
        title: String,
        gateway: String,
        dnsServers: [String]? = nil,
        description: String,
        symbolName: String = "router"
    ) {
        self.id = id
        self.title = title
        self.gateway = gateway
        self.dnsServers = dnsServers ?? [gateway]
        self.description = description
        self.symbolName = symbolName
    }

    public var deepLinkURL: URL {
        URL(string: "gatewayswitcher://switch?id=\(id.uuidString)")!
    }

    public static let defaults: [GatewayProfile] = [
        GatewayProfile(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567890")!,
            title: "国内网关",
            gateway: "192.168.31.1",
            description: "适合直连国内网络、低延迟访问本地服务。",
            symbolName: "router"
        ),
        GatewayProfile(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567891")!,
            title: ".2 网关",
            gateway: "192.168.31.2",
            description: "适合切换到 .2 网关，作为备用出口或中间路由。",
            symbolName: "point.3.connected.trianglepath.dotted"
        ),
        GatewayProfile(
            id: UUID(uuidString: "A1B2C3D4-E5F6-7890-ABCD-EF1234567892")!,
            title: "代理网关",
            gateway: "192.168.31.3",
            description: "适合将默认出口交给旁路由代理。",
            symbolName: "network.badge.shield.half.filled"
        )
    ]
}