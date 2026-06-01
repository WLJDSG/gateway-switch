import XCTest
@testable import GatewayKit
@testable import GatewaySwitcherApp
import SharedKit

@MainActor
final class AppStateTests: XCTestCase {
    func testSwitchGatewayUsesFreshCurrentNetworkSnapshot() async throws {
        let ethernetSnapshot = NetworkSnapshot(
            gateway: "192.168.31.1",
            interfaceName: "en7",
            serviceName: "USB 10/100/1000 LAN",
            localIPv4: "192.168.31.77",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.1"]
        )
        let switchedSnapshot = LockedSnapshot()
        let dotTwoProfile = GatewayProfile.defaults[1]

        let appState = AppState(
            snapshotProvider: { ethernetSnapshot },
            passwordlessStatusProvider: { true },
            gatewaySwitchAction: { _, snapshot in
                switchedSnapshot.value = snapshot
            },
            helperInstallAction: { _ in },
            whitelistUpdateAction: { _ in },
            widgetReloadAction: {}
        )

        try await Task.sleep(nanoseconds: 200_000_000)
        appState.switchGateway(to: dotTwoProfile)
        try await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertEqual(switchedSnapshot.value?.serviceName, "USB 10/100/1000 LAN")
        XCTAssertEqual(switchedSnapshot.value?.interfaceName, "en7")
        XCTAssertEqual(switchedSnapshot.value?.localIPv4, "192.168.31.77")
    }

    func testHandleDeepLinkWithUUID() async throws {
        let chinaProfile = GatewayProfile.defaults[0]
        let snapshot = NetworkSnapshot(gateway: "192.168.31.1", interfaceName: "en0", serviceName: "Wi-Fi", localIPv4: "192.168.31.42", dnsServers: ["192.168.31.1"])

        let appState = AppState(
            snapshotProvider: { snapshot },
            passwordlessStatusProvider: { false },
            gatewaySwitchAction: { _, _ in },
            helperInstallAction: { _ in },
            whitelistUpdateAction: { _ in },
            widgetReloadAction: {},
            startsTimer: false
        )

        let url = URL(string: "gatewayswitcher://switch?id=\(chinaProfile.id.uuidString)")!
        appState.handleDeepLink(url)

        XCTAssertEqual(appState.switchingProfile?.id, chinaProfile.id)

        try await Task.sleep(nanoseconds: 100_000_000)
    }

    func testHandleDeepLinkLegacyFormat() async throws {
        let appState = AppState(
            snapshotProvider: { NetworkSnapshot(gateway: nil, interfaceName: nil, serviceName: nil, localIPv4: nil, dnsServers: []) },
            passwordlessStatusProvider: { false },
            gatewaySwitchAction: { _, _ in },
            helperInstallAction: { _ in },
            whitelistUpdateAction: { _ in },
            widgetReloadAction: {},
            startsTimer: false
        )

        let url = URL(string: "gatewayswitcher://switch?profile=china")!
        appState.handleDeepLink(url)

        let chinaProfile = GatewayProfile.defaults[0]
        XCTAssertEqual(appState.switchingProfile?.id, chinaProfile.id)

        // Wait for async tasks to settle before next test
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}

private final class LockedSnapshot: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValue: NetworkSnapshot?

    var value: NetworkSnapshot? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedValue
        }
        set {
            lock.lock()
            storedValue = newValue
            lock.unlock()
        }
    }
}