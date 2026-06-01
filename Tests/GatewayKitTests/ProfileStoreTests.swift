import XCTest
import SharedKit

final class ProfileStoreTests: XCTestCase {
    private func makeStore() -> ProfileStore {
        let suiteName = "Test.GatewaySwitcher.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return ProfileStore(defaults: defaults)
    }

    func testInitializeDefaultsIfNeededSeedsDefaults() {
        let store = makeStore()
        let profiles = store.initializeDefaultsIfNeeded()

        XCTAssertEqual(profiles.count, 3)
        XCTAssertEqual(profiles.map(\.gateway), ["192.168.31.1", "192.168.31.2", "192.168.31.3"])
    }

    func testInitializeDefaultsIfNeededDoesNotOverwriteExistingData() {
        let store = makeStore()
        _ = store.initializeDefaultsIfNeeded()

        let custom = GatewayProfile(title: "自定义", gateway: "10.0.0.1", description: "测试")
        store.add(custom)

        let profiles = store.initializeDefaultsIfNeeded()
        XCTAssertEqual(profiles.count, 4)
        XCTAssertEqual(profiles.last?.gateway, "10.0.0.1")
    }

    func testAddProfile() {
        let store = makeStore()
        _ = store.initializeDefaultsIfNeeded()

        let newProfile = GatewayProfile(title: "测试网关", gateway: "10.0.0.1", description: "测试用")
        store.add(newProfile)

        XCTAssertEqual(store.profiles.count, 4)
        XCTAssertEqual(store.profile(for: newProfile.id)?.gateway, "10.0.0.1")
    }

    func testDeleteProfile() {
        let store = makeStore()
        let profiles = store.initializeDefaultsIfNeeded()

        store.delete(id: profiles[1].id)

        XCTAssertEqual(store.profiles.count, 2)
        XCTAssertNil(store.profile(for: profiles[1].id))
    }

    func testUpdateProfile() {
        let store = makeStore()
        let profiles = store.initializeDefaultsIfNeeded()

        var updated = profiles[0]
        updated.title = "国内网关（已修改）"
        updated.gateway = "10.0.0.1"
        store.update(updated)

        let fetched = store.profile(for: updated.id)
        XCTAssertEqual(fetched?.title, "国内网关（已修改）")
        XCTAssertEqual(fetched?.gateway, "10.0.0.1")
    }

    func testProfileForNonexistentIDReturnsNil() {
        let store = makeStore()
        _ = store.initializeDefaultsIfNeeded()

        XCTAssertNil(store.profile(for: UUID()))
    }

    func testJSONRoundTrip() {
        let store = makeStore()
        let profiles = [
            GatewayProfile(title: "A", gateway: "1.1.1.1", dnsServers: ["1.1.1.1", "8.8.8.8"], description: "Desc A", symbolName: "router"),
            GatewayProfile(title: "B", gateway: "2.2.2.2", description: "Desc B", symbolName: "network")
        ]
        store.profiles = profiles

        let loaded = store.profiles
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].title, "A")
        XCTAssertEqual(loaded[0].dnsServers, ["1.1.1.1", "8.8.8.8"])
        XCTAssertEqual(loaded[1].gateway, "2.2.2.2")
    }
}