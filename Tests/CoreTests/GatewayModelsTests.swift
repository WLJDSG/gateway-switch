import XCTest
@testable import Core
import Core

final class GatewayModelsTests: XCTestCase {
    func testDefaultProfilesIncludeThreePresets() {
        XCTAssertEqual(GatewayProfile.defaults.count, 3)
        XCTAssertEqual(GatewayProfile.defaults.map(\.gateway), [
            "192.168.31.1",
            "192.168.31.2",
            "192.168.31.3"
        ])
    }

    func testActiveProfileMatchesGatewayIP() {
        let profiles = GatewayProfile.defaults
        let snapshot = NetworkSnapshot(
            gateway: "192.168.31.2",
            interfaceName: "en0",
            serviceName: "Wi-Fi",
            localIPv4: "192.168.31.42",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.2"]
        )

        let matched = snapshot.activeProfile(from: profiles)
        XCTAssertEqual(matched?.gateway, "192.168.31.2")
        XCTAssertEqual(matched?.id, profiles[1].id)
    }

    func testActiveProfileReturnsNilForUnknownGateway() {
        let profiles = GatewayProfile.defaults
        let snapshot = NetworkSnapshot(
            gateway: "10.0.0.1",
            interfaceName: nil,
            serviceName: nil,
            localIPv4: nil,
            dnsServers: []
        )

        XCTAssertNil(snapshot.activeProfile(from: profiles))
    }

    func testActiveProfileReturnsNilWhenGatewayIsNil() {
        let snapshot = NetworkSnapshot(
            gateway: nil,
            interfaceName: nil,
            serviceName: nil,
            localIPv4: nil,
            dnsServers: []
        )

        XCTAssertNil(snapshot.activeProfile(from: GatewayProfile.defaults))
    }
}