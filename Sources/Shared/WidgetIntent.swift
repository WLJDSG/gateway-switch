import AppIntents
import Foundation

enum WidgetGatewayProfile: String, AppEnum {
    case china
    case proxy

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "网关")

    static var caseDisplayRepresentations: [WidgetGatewayProfile: DisplayRepresentation] = [
        .china: DisplayRepresentation(title: "国内网关", subtitle: "192.168.31.1"),
        .proxy: DisplayRepresentation(title: "代理网关", subtitle: "192.168.31.3")
    ]

    var title: String {
        switch self {
        case .china:
            return "国内"
        case .proxy:
            return "代理"
        }
    }

    var gateway: String {
        switch self {
        case .china:
            return "192.168.31.1"
        case .proxy:
            return "192.168.31.3"
        }
    }

    var symbolName: String {
        switch self {
        case .china:
            return "house.and.flag"
        case .proxy:
            return "shield.lefthalf.filled"
        }
    }

    var deepLinkURL: URL {
        URL(string: "gatewayswitcher://switch?profile=\(rawValue)")!
    }
}
