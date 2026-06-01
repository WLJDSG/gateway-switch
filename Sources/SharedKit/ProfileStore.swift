import Foundation

public final class ProfileStore: @unchecked Sendable {
    public static let appGroupIdentifier = "com.wenlanjun.GatewaySwitcher.shared"

    private let defaults: UserDefaults
    private let key = "gatewayProfiles"
    private let lock = NSLock()

    public static let shared = ProfileStore()

    public init(defaults: UserDefaults? = nil) {
        if let defaults {
            self.defaults = defaults
        } else {
            self.defaults = UserDefaults(suiteName: ProfileStore.appGroupIdentifier) ?? .standard
        }
    }

    public var profiles: [GatewayProfile] {
        get { lock.withLock { load() } }
        set { lock.withLock { save(newValue) } }
    }

    public func initializeDefaultsIfNeeded() -> [GatewayProfile] {
        lock.lock()
        defer { lock.unlock() }
        if defaults.object(forKey: key) == nil {
            save(GatewayProfile.defaults)
        }
        return load()
    }

    public func add(_ profile: GatewayProfile) {
        lock.lock()
        defer { lock.unlock() }
        var current = load()
        current.append(profile)
        save(current)
    }

    public func delete(id: UUID) {
        lock.lock()
        defer { lock.unlock() }
        var current = load()
        current.removeAll { $0.id == id }
        save(current)
    }

    public func update(_ profile: GatewayProfile) {
        lock.lock()
        defer { lock.unlock() }
        var current = load()
        if let index = current.firstIndex(where: { $0.id == profile.id }) {
            current[index] = profile
        }
        save(current)
    }

    public func profile(for id: UUID) -> GatewayProfile? {
        lock.lock()
        defer { lock.unlock() }
        return load().first { $0.id == id }
    }

    private func load() -> [GatewayProfile] {
        guard let data = defaults.data(forKey: key) else { return [] }
        do {
            return try JSONDecoder().decode([GatewayProfile].self, from: data)
        } catch {
            return []
        }
    }

    private func save(_ profiles: [GatewayProfile]) {
        do {
            let data = try JSONEncoder().encode(profiles)
            defaults.set(data, forKey: key)
        } catch {
            // silently fail — next read will return last successful save
        }
    }
}