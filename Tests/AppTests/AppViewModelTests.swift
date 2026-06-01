import XCTest
@testable import SwitcherFeature
@testable import GatewaySwitcherApp
import Core

@MainActor
final class AppViewModelTests: XCTestCase {
    private func makeStore() -> ProfileStore {
        let suiteName = "Test.AppVM.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return ProfileStore(defaults: defaults)
    }

    private func makeViewModel(
        runner: CommandRunning = MockCommandRunner(),
        store: ProfileStore? = nil
    ) -> AppViewModel {
        let service = GatewayService(runner: runner)
        let profileStore = store ?? makeStore()
        return AppViewModel(service: service, profileStore: profileStore)
    }

    func testInitialProfilesAreSeeded() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.profiles.count, 3)
        XCTAssertEqual(vm.profiles.map(\.gateway), ["192.168.31.1", "192.168.31.2", "192.168.31.3"])
    }

    func testAddProfile() {
        let vm = makeViewModel()
        let newProfile = GatewayProfile(title: "自定义", gateway: "10.0.0.1", description: "测试")

        vm.addProfile(newProfile)

        XCTAssertEqual(vm.profiles.count, 4)
        XCTAssertEqual(vm.profiles.last?.gateway, "10.0.0.1")
    }

    func testDeleteProfile() {
        let vm = makeViewModel()
        let profileToDelete = vm.profiles[1]

        vm.deleteProfile(id: profileToDelete.id)

        XCTAssertEqual(vm.profiles.count, 2)
        XCTAssertNil(vm.profiles.first(where: { $0.id == profileToDelete.id }))
    }

    func testUpdateProfile() {
        let vm = makeViewModel()
        var updated = vm.profiles[0]
        updated.title = "国内网关（已修改）"
        updated.gateway = "10.0.0.1"

        vm.updateProfile(updated)

        let fetched = vm.profiles.first(where: { $0.id == updated.id })
        XCTAssertEqual(fetched?.title, "国内网关（已修改）")
        XCTAssertEqual(fetched?.gateway, "10.0.0.1")
    }

    func testActiveProfileMatchesGatewayIP() async throws {
        let runner = MockCommandRunner { executable, arguments in
            if executable == "/sbin/route" && arguments == ["-n", "get", "default"] {
                return CommandResult(standardOutput: RouteOutput.gateway192_168_31_2, standardError: "", terminationStatus: 0)
            }
            return CommandResult(standardOutput: "", standardError: "", terminationStatus: 0)
        }
        let store = makeStore()
        let vm = makeViewModel(runner: runner, store: store)

        // Wait for the initial refresh from init to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        let matched = vm.activeProfile
        XCTAssertEqual(matched?.gateway, "192.168.31.2")
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

private let RouteOutput = (
    gateway192_168_31_2: """
   route to: default
destination: default
       mask: default
    gateway: 192.168.31.2
  interface: en0
      flags: <UP,GATEWAY,DONE,STATIC,PRCLONED>
 recvpipe  sendpipe  ssthresh  rttnet    rtt       rttvar    hopcount  mtu       expire
       0         0         0         0         0         0        0        1500         0
""",
    empty: ""
)