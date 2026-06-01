import XCTest
@testable import GatewayKit
@testable import GatewaySwitcherApp

@MainActor
final class AppStateTests: XCTestCase {
    func testSwitchGatewayUsesFreshCurrentNetworkSnapshot() async throws {
        let staleSnapshot = NetworkSnapshot(
            gateway: "192.168.31.1",
            interfaceName: "en0",
            serviceName: "Wi-Fi",
            localIPv4: "192.168.31.42",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.1"]
        )
        let ethernetSnapshot = NetworkSnapshot(
            gateway: "192.168.31.1",
            interfaceName: "en7",
            serviceName: "USB 10/100/1000 LAN",
            localIPv4: "192.168.31.77",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.1"]
        )
        let snapshots = LockedSnapshots([staleSnapshot, ethernetSnapshot, ethernetSnapshot])
        let switchedSnapshot = LockedSnapshot()

        let appState = AppState(
            snapshotProvider: {
                snapshots.next()
            },
            passwordlessStatusProvider: {
                true
            },
            gatewaySwitchAction: { _, snapshot in
                switchedSnapshot.value = snapshot
            },
            helperInstallAction: { _ in }
        )

        try await Task.sleep(nanoseconds: 100_000_000)
        appState.switchGateway(to: .dotTwo)
        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(switchedSnapshot.value?.serviceName, "USB 10/100/1000 LAN")
        XCTAssertEqual(switchedSnapshot.value?.interfaceName, "en7")
        XCTAssertEqual(switchedSnapshot.value?.localIPv4, "192.168.31.77")
    }
}

private final class LockedSnapshots: @unchecked Sendable {
    private let lock = NSLock()
    private var snapshots: [NetworkSnapshot]

    init(_ snapshots: [NetworkSnapshot]) {
        self.snapshots = snapshots
    }

    func next() -> NetworkSnapshot {
        lock.lock()
        defer { lock.unlock() }
        return snapshots.removeFirst()
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
