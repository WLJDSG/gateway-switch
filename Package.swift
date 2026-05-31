// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GatewaySwitcher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "GatewayKit", targets: ["GatewayKit"]),
        .executable(name: "GatewaySwitcher", targets: ["GatewaySwitcherApp"])
    ],
    targets: [
        .target(name: "GatewayKit"),
        .executableTarget(
            name: "GatewaySwitcherApp",
            dependencies: ["GatewayKit"]
        ),
        .testTarget(
            name: "GatewayKitTests",
            dependencies: ["GatewayKit"]
        )
    ]
)
