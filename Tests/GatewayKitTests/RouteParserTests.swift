import XCTest
@testable import GatewayKit

final class RouteParserTests: XCTestCase {
    func testParseDefaultRouteFindsGatewayAndInterface() {
        let output = """
           route to: default
        destination: default
               mask: default
            gateway: 192.168.31.3
          interface: en0
              flags: <UP,GATEWAY,DONE,STATIC,PRCLONING,GLOBAL>
        """

        let route = RouteParser.parseDefaultRoute(output)

        XCTAssertEqual(route.gateway, "192.168.31.3")
        XCTAssertEqual(route.interfaceName, "en0")
    }

    func testParseHardwarePortsMapsDeviceToFriendlyServiceName() {
        let output = """
        Hardware Port: Wi-Fi
        Device: en0
        Ethernet Address: aa:bb:cc:dd:ee:ff

        Hardware Port: Thunderbolt Bridge
        Device: bridge0
        Ethernet Address: 11:22:33:44:55:66
        """

        let services = RouteParser.parseHardwarePorts(output)

        XCTAssertEqual(services["en0"], "Wi-Fi")
        XCTAssertEqual(services["bridge0"], "Thunderbolt Bridge")
    }

    func testParseDNSServersRemovesEmptyLinesAndNoServerMessage() {
        let output = """

        There aren't any DNS Servers set on Wi-Fi.
        223.5.5.5
        119.29.29.29

        """

        XCTAssertEqual(RouteParser.parseDNSServers(output), ["223.5.5.5", "119.29.29.29"])
    }

    func testParseNetworkInfoFindsManualIPv4Settings() {
        let output = """
        Manual Configuration
        IP address: 192.168.31.42
        Subnet mask: 255.255.255.0
        Router: 192.168.31.3
        IPv6: Off
        """

        let info = RouteParser.parseNetworkInfo(output)

        XCTAssertEqual(info.ipAddress, "192.168.31.42")
        XCTAssertEqual(info.subnetMask, "255.255.255.0")
        XCTAssertEqual(info.router, "192.168.31.3")
    }
}
