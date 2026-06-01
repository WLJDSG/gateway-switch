// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GatewaySwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "InspectorFeature", targets: ["InspectorFeature"]),
        .library(name: "HelperFeature", targets: ["HelperFeature"]),
        .library(name: "SwitcherFeature", targets: ["SwitcherFeature"]),
        .executable(name: "GatewaySwitcher", targets: ["GatewaySwitcherApp"]),
        .executable(name: "GatewaySwitcherWidgetExtension", targets: ["GatewaySwitcherWidget"])
    ],
    targets: [
        .target(
            name: "Core",
            path: "Packages/Core"
        ),
        .target(
            name: "InspectorFeature",
            dependencies: ["Core"],
            path: "Packages/InspectorFeature"
        ),
        .target(
            name: "HelperFeature",
            dependencies: ["Core"],
            path: "Packages/HelperFeature"
        ),
        .target(
            name: "SwitcherFeature",
            dependencies: ["Core", "InspectorFeature", "HelperFeature"],
            path: "Packages/SwitcherFeature"
        ),
        .executableTarget(
            name: "GatewaySwitcherApp",
            dependencies: ["SwitcherFeature", "Core"],
            path: "GatewaySwitcherApp",
            sources: ["App", "View", "ViewModel"],
            resources: [.process("Resources")]
        ),
        .executableTarget(
            name: "GatewaySwitcherWidget",
            dependencies: ["Core"],
            path: "GatewaySwitcherWidget"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Tests/CoreTests"
        ),
        .testTarget(
            name: "InspectorFeatureTests",
            dependencies: ["InspectorFeature"],
            path: "Tests/InspectorFeatureTests"
        ),
        .testTarget(
            name: "SwitcherFeatureTests",
            dependencies: ["SwitcherFeature"],
            path: "Tests/SwitcherFeatureTests"
        ),
        .testTarget(
            name: "AppTests",
            dependencies: ["GatewaySwitcherApp", "SwitcherFeature", "Core"],
            path: "Tests/AppTests"
        )
    ]
)