import XCTest
@testable import SwitcherFeature
import Core

final class GatewayServiceTests: XCTestCase {
    func testCurrentSnapshotReturnsGatewayFromRoute() {
        let runner = MockCommandRunner { executable, arguments in
            if executable == "/sbin/route" && arguments == ["-n", "get", "default"] {
                return CommandResult(standardOutput: """
   route to: default
destination: default
       mask: default
    gateway: 192.168.31.1
  interface: en0
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONED>
""", standardError: "", terminationStatus: 0)
            }
            return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }

        let service = GatewayService(runner: runner)
        let snapshot = service.currentSnapshot()

        XCTAssertEqual(snapshot.gateway, "192.168.31.1")
        XCTAssertEqual(snapshot.interfaceName, "en0")
    }

    func testIsHelperInstalledReturnsFalseWhenCommandFails() {
        let runner = MockCommandRunner { executable, arguments in
            if executable == "/usr/bin/sudo" && arguments.contains("--check") {
                return CommandResult(standardOutput: "", standardError: "a password is required", terminationStatus: 1)
            }
            return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }

        let service = GatewayService(runner: runner)
        XCTAssertFalse(service.isHelperInstalled())
    }

    func testIsHelperInstalledReturnsTrueWhenCommandSucceeds() {
        let runner = MockCommandRunner { executable, arguments in
            if executable == "/usr/bin/sudo" && arguments.contains("--check") {
                return CommandResult(standardOutput: "OK", standardError: "", terminationStatus: 0)
            }
            return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }

        let service = GatewayService(runner: runner)
        XCTAssertTrue(service.isHelperInstalled())
    }

    func testSwitchGatewayThrowsInvalidGatewayForBadIP() {
        let runner = MockCommandRunner { _, _ in
            CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }
        let service = GatewayService(runner: runner)

        let badProfile = GatewayProfile(title: "Bad", gateway: "not-an-ip", description: "")
        let snapshot = NetworkSnapshot(
            gateway: "192.168.31.1",
            interfaceName: "en0",
            serviceName: "Wi-Fi",
            localIPv4: "192.168.31.42",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.1"]
        )

        XCTAssertThrowsError(try service.switchGateway(to: badProfile, snapshot: snapshot)) { error in
            guard let gatewayError = error as? GatewayError else {
                XCTFail("Expected GatewayError")
                return
            }
            XCTAssertEqual(gatewayError, .invalidGateway("not-an-ip"))
        }
    }

    func testSyncWhitelistWritesAllowedIPs() {
        let runner = MockCommandRunner { executable, arguments in
            if executable == "/usr/bin/osascript" {
                return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
            }
            return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }
        let service = GatewayService(runner: runner)

        let ips = ["192.168.31.1", "192.168.31.2"]
        XCTAssertNoThrow(try service.syncWhitelist(ips: ips))
    }
}

private final class MockCommandRunner: CommandRunning, Sendable {
    private let handler: @Sendable (String, [String]) -> CommandResult

    init(handler: @escaping @Sendable (String, [String]) -> CommandResult = { _, _ in
        CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
    }) {
        self.handler = handler
    }

    func run(_ executable: String, arguments: [String]) throws -> CommandResult {
        handler(executable, arguments)
    }
}