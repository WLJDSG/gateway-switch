import Foundation
import SharedKit

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

    public func activeProfile(from profiles: [GatewayProfile]) -> GatewayProfile? {
        guard let gateway else { return nil }
        return profiles.first { $0.gateway == gateway }
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