import AppIntents
import Foundation

public enum WidgetGatewayProfile: String, AppEnum, CaseIterable {
    case china
    case dotTwo
    case proxy

    public static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "网关")

    public static let caseDisplayRepresentations: [WidgetGatewayProfile: DisplayRepresentation] = [
        .china: DisplayRepresentation(title: "国内网关", subtitle: "192.168.31.1"),
        .dotTwo: DisplayRepresentation(title: ".2 网关", subtitle: "192.168.31.2"),
        .proxy: DisplayRepresentation(title: "代理网关", subtitle: "192.168.31.3")
    ]

    public var title: String {
        switch self {
        case .china:
            return "国内"
        case .dotTwo:
            return ".2"
        case .proxy:
            return "代理"
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

    public var deepLinkURL: URL {
        URL(string: "gatewayswitcher://switch?profile=\(rawValue)")!
    }
}