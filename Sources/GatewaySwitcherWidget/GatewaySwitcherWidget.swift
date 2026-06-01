import SwiftUI
import WidgetKit
import SharedKit

struct GatewaySwitcherWidgetEntry: TimelineEntry {
    let date: Date
    let profiles: [GatewayProfile]
}

struct GatewaySwitcherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> GatewaySwitcherWidgetEntry {
        GatewaySwitcherWidgetEntry(date: Date(), profiles: GatewayProfile.defaults)
    }

    func getSnapshot(in context: Context, completion: @escaping (GatewaySwitcherWidgetEntry) -> Void) {
        let profiles = ProfileStore().profiles
        completion(GatewaySwitcherWidgetEntry(date: Date(), profiles: profiles.isEmpty ? GatewayProfile.defaults : profiles))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GatewaySwitcherWidgetEntry>) -> Void) {
        let profiles = ProfileStore().profiles
        let entry = GatewaySwitcherWidgetEntry(date: Date(), profiles: profiles.isEmpty ? GatewayProfile.defaults : profiles)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(300))))
    }
}

struct GatewaySwitcherWidgetView: View {
    var entry: GatewaySwitcherTimelineProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("切换网关", systemImage: "network")
                .font(.headline)

            HStack(spacing: 8) {
                ForEach(entry.profiles.prefix(3)) { profile in
                    gatewayButton(profile)
                }
            }

            Text("需先在主 App 安装免密 helper")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .containerBackground(.regularMaterial, for: .widget)
    }

    private func gatewayButton(_ profile: GatewayProfile) -> some View {
        Link(destination: profile.deepLinkURL) {
            VStack(spacing: 6) {
                Image(systemName: profile.symbolName)
                    .font(.title3)
                Text(profile.title)
                    .font(.caption.weight(.semibold))
                Text(profile.gateway)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 74)
        }
        .buttonStyle(.bordered)
    }
}

struct GatewaySwitcherWidget: Widget {
    let kind = "GatewaySwitcherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GatewaySwitcherTimelineProvider()) { entry in
            GatewaySwitcherWidgetView(entry: entry)
        }
        .configurationDisplayName("切换网关")
        .description("从桌面小组件快速切换已配置的网关。")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct GatewaySwitcherWidgetBundle: WidgetBundle {
    var body: some Widget {
        GatewaySwitcherWidget()
    }
}