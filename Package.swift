// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GatewaySwitcher",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "GatewayKit", targets: ["GatewayKit"]),
        .executable(name: "GatewaySwitcher", targets: ["GatewaySwitcherApp"]),
        .executable(name: "GatewaySwitcherWidgetExtension", targets: ["GatewaySwitcherWidget"])
    ],
    targets: [
        .target(name: "GatewayKit", dependencies: ["SharedKit"]),
        .target(name: "SharedKit"),
        .executableTarget(
            name: "GatewaySwitcherApp",
            dependencies: ["GatewayKit", "SharedKit"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "GatewaySwitcherWidget",
            dependencies: ["SharedKit"]
        ),
        .testTarget(
            name: "GatewayKitTests",
            dependencies: ["GatewayKit", "GatewaySwitcherApp", "SharedKit"]
        )
    ]
)