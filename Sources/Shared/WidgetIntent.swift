import AppIntents

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
}

struct SwitchGatewayIntent: AppIntent {
    static var title: LocalizedStringResource = "切换网关"
    static var description = IntentDescription("切换默认网关并同步 DNS。")
    static var openAppWhenRun = true

    @Parameter(title: "网关")
    var profile: WidgetGatewayProfile

    init() {
        profile = .china
    }

    init(profile: WidgetGatewayProfile) {
        self.profile = profile
    }

    func perform() async throws -> some IntentResult {
        #if canImport(GatewayKit)
        try GatewayKit.GatewaySwitcher().switchDefaultGateway(to: profile.gatewayKitProfile)
        return .result()
        #else
        return .result()
        #endif
    }
}

#if canImport(GatewayKit)
import GatewayKit

extension WidgetGatewayProfile {
    var gatewayKitProfile: GatewayProfile {
        switch self {
        case .china:
            return .china
        case .proxy:
            return .proxy
        }
    }
}
#endif