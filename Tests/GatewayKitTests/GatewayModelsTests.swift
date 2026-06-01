import XCTest
@testable import GatewayKit

final class GatewayModelsTests: XCTestCase {
    func testGatewayProfilesIncludeChinaDotTwoAndProxyGateways() {
        XCTAssertEqual(GatewayProfile.allCases.map(\.gateway), [
            "192.168.31.1",
            "192.168.31.2",
            "192.168.31.3"
        ])
        XCTAssertEqual(GatewayProfile.allCases.map(\.dnsServers), [
            ["192.168.31.1"],
            ["192.168.31.2"],
            ["192.168.31.3"]
        ])
    }

    func testGatewayProfileMatchingRecognizesDotTwoGateway() {
        XCTAssertEqual(GatewayProfile.matching(gateway: "192.168.31.2"), .dotTwo)
    }
}
