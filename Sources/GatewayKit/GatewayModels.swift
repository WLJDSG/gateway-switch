import Foundation

public enum GatewayProfile: String, CaseIterable, Identifiable, Equatable, Sendable {
    case china
    case dotTwo
    case proxy

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .china:
            return "国内网关"
        case .dotTwo:
            return ".2 网关"
        case .proxy:
            return "代理网关"
        }
    }

    public var gateway: String {
        switch self {
        case .china:
            return "192.168.31.1"
        case .dotTwo:
            return "192.168.31.2"
        case .proxy:
            return "192.168.31.3"
        }
    }

    public var dnsServers: [String] {
        [gateway]
    }

    public var description: String {
        switch self {
        case .china:
            return "适合直连国内网络、低延迟访问本地服务。"
        case .dotTwo:
            return "适合切换到 .2 网关，作为备用出口或中间路由。"
        case .proxy:
            return "适合将默认出口交给旁路由代理。"
        }
    }

    public var symbolName: String {
        switch self {
        case .china:
            return "router"
        case .dotTwo:
            return "point.3.connected.trianglepath.dotted"
        case .proxy:
            return "network.badge.shield.half.filled"
        }
    }

    public static func matching(gateway: String?) -> GatewayProfile? {
        guard let gateway else { return nil }
        return allCases.first { $0.gateway == gateway }
    }
}

public struct NetworkSnapshot: Equatable, Sendable {
    public var gateway: String?
    public var interfaceName: String?
    public var serviceName: String?
    public var localIPv4: String?
    public var subnetMask: String?
    public var dnsServers: [String]
    public var capturedAt: Date

    public init(
        gateway: String?,
        interfaceName: String?,
        serviceName: String?,
        localIPv4: String?,
        subnetMask: String? = nil,
        dnsServers: [String],
        capturedAt: Date = Date()
    ) {
        self.gateway = gateway
        self.interfaceName = interfaceName
        self.serviceName = serviceName
        self.localIPv4 = localIPv4
        self.subnetMask = subnetMask
        self.dnsServers = dnsServers
        self.capturedAt = capturedAt
    }

    public var activeProfile: GatewayProfile? {
        GatewayProfile.matching(gateway: gateway)
    }
}

public struct CommandResult: Equatable, Sendable {
    public var standardOutput: String
    public var standardError: String
    public var terminationStatus: Int32

    public init(standardOutput: String, standardError: String, terminationStatus: Int32) {
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.terminationStatus = terminationStatus
    }
}

public enum GatewayError: LocalizedError, Equatable, Sendable {
    case commandFailed(String)
    case invalidGateway(String)
    case missingNetworkConfiguration

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let message):
            return message
        case .invalidGateway(let gateway):
            return "网关地址不合法：\(gateway)"
        case .missingNetworkConfiguration:
            return "没有检测到可写入的网络服务、IP 或子网掩码，请先确认当前 Wi-Fi 已连接。"
        }
    }
}
