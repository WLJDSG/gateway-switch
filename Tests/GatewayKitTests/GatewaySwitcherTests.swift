import XCTest
@testable import GatewayKit
import SharedKit

final class GatewaySwitcherTests: XCTestCase {
    func testSwitchFallsBackToAdminAuthorizationWhenInstalledHelperRejectsCurrentServiceName() throws {
        let runner = RecordingRunner(results: [
            CommandResult(standardOutput: "", standardError: "Service name is not allowed.", terminationStatus: 2),
            CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        ])
        let switcher = GatewaySwitcher(runner: runner)
        let snapshot = NetworkSnapshot(
            gateway: "192.168.31.2",
            interfaceName: "en7",
            serviceName: "USB 10/100/1000 LAN",
            localIPv4: "192.168.31.77",
            subnetMask: "255.255.255.0",
            dnsServers: ["192.168.31.2"]
        )

        let chinaProfile = GatewayProfile.defaults[0]
        try switcher.switchDefaultGateway(to: chinaProfile, snapshot: snapshot)

        XCTAssertEqual(runner.commands.map(\.executable), ["/usr/bin/sudo", "/usr/bin/osascript"])
        XCTAssertTrue(runner.commands[1].arguments.joined(separator: " ").contains("USB 10/100/1000 LAN"))
        XCTAssertTrue(runner.commands[1].arguments.joined(separator: " ").contains("192.168.31.1"))
    }
}

private final class RecordingRunner: CommandRunning, @unchecked Sendable {
    private let lock = NSLock()
    private var results: [CommandResult]
    private(set) var commands: [(executable: String, arguments: [String])] = []

    init(results: [CommandResult]) {
        self.results = results
    }

    func run(_ executable: String, arguments: [String]) throws -> CommandResult {
        lock.lock()
        defer { lock.unlock() }
        commands.append((executable, arguments))
        return results.removeFirst()
    }
}