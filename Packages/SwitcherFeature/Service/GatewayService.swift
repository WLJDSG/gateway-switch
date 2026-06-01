import Foundation
import Core
import InspectorFeature
import HelperFeature

public final class GatewayService: @unchecked Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func switchGateway(to profile: GatewayProfile, snapshot: NetworkSnapshot) throws {
        try GatewaySwitcher(runner: runner).switchDefaultGateway(to: profile, snapshot: snapshot)
    }

    public func currentSnapshot() -> NetworkSnapshot {
        NetworkInspector(runner: runner).snapshot()
    }

    public func isHelperInstalled() -> Bool {
        PasswordlessHelper.isInstalled(runner: runner)
    }

    public func installHelper(installerPath: String) throws {
        try PasswordlessHelper.install(runner: runner, installerPath: installerPath)
    }

    public func syncWhitelist(ips: [String]) throws {
        try HelperWhitelistUpdater.update(ips: ips, runner: runner)
    }
}