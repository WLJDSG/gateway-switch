import Foundation

public enum GatewayProfile: String, CaseIterable, Identifiable, Equatable {
    case china
    case proxy

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .china:
            return "国内网关"
        case .proxy:
            return "代理网关"
        }
    }

    public var gateway: String {
        switch self {
        case .china:
            return "192.168.31.1"
        case .proxy:
            return "192.168.31.3"
        }
    }

    public var dnsServers: [String] {
        [gateway]
    }

    public var symbolName: String {
        switch self {
        case .china:
            return "house.and.flag"
        case .proxy:
            return "shield.lefthalf.filled"
        }
    }

    public static func matching(gateway: String?) -> GatewayProfile? {
        guard let gateway else { return nil }
        return allCases.first { $0.gateway == gateway }
    }
}

public struct NetworkSnapshot: Equatable {
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

public struct CommandResult: Equatable {
    public var standardOutput: String
    public var standardError: String
    public var terminationStatus: Int32

    public init(standardOutput: String, standardError: String, terminationStatus: Int32) {
        self.standardOutput = standardOutput
        self.standardError = standardError
        self.terminationStatus = terminationStatus
    }
}

public enum GatewayError: LocalizedError, Equatable {
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
