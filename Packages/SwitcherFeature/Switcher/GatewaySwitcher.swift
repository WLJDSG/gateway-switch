import Foundation
import Core
import InspectorFeature
import HelperFeature

public struct GatewaySwitcher: Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func switchDefaultGateway(to profile: GatewayProfile) throws {
        try switchDefaultGateway(to: profile, snapshot: NetworkInspector(runner: runner).snapshot())
    }

    public func switchDefaultGateway(to profile: GatewayProfile, snapshot: NetworkSnapshot) throws {
        let gateway = profile.gateway
        guard Self.isValidIPv4(gateway) else {
            throw GatewayError.invalidGateway(gateway)
        }
        guard
            let serviceName = snapshot.serviceName,
            let ipAddress = snapshot.localIPv4,
            let subnetMask = snapshot.subnetMask
        else {
            throw GatewayError.missingNetworkConfiguration
        }

        if try runPasswordlessHelper(profile: profile, serviceName: serviceName, ipAddress: ipAddress, subnetMask: subnetMask) {
            return
        }

        let shellCommand = Self.shellCommand(
            serviceName: serviceName,
            ipAddress: ipAddress,
            subnetMask: subnetMask,
            profile: profile
        )
        let appleScript = "do shell script \(shellCommand.appleScriptQuoted) with administrator privileges"
        let result = try runner.run("/usr/bin/osascript", arguments: ["-e", appleScript])

        guard result.terminationStatus == 0 else {
            let message = [result.standardError, result.standardOutput]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "切换网关失败"
            throw GatewayError.commandFailed(message)
        }
    }

    private func runPasswordlessHelper(
        profile: GatewayProfile,
        serviceName: String,
        ipAddress: String,
        subnetMask: String
    ) throws -> Bool {
        let result = try runner.run(
            "/usr/bin/sudo",
            arguments: [
                "-n",
                PasswordlessHelper.helperPath,
                "--service", serviceName,
                "--ip", ipAddress,
                "--subnet", subnetMask,
                "--router", profile.gateway,
                "--dns", profile.dnsServers.joined(separator: ",")
            ]
        )

        if result.terminationStatus == 0 {
            return true
        }

        let combinedOutput = "\(result.standardError)\n\(result.standardOutput)"
        if combinedOutput.contains("a password is required")
            || combinedOutput.contains("no tty present")
            || combinedOutput.contains("command not found")
            || combinedOutput.contains("No such file")
            || combinedOutput.contains("Router is not allowed")
            || combinedOutput.contains("DNS is not allowed")
            || combinedOutput.contains("Service name is not allowed") {
            return false
        }

        let message = combinedOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        throw GatewayError.commandFailed(message.isEmpty ? "免密 helper 执行失败" : message)
    }

    private static func shellCommand(
        serviceName: String,
        ipAddress: String,
        subnetMask: String,
        profile: GatewayProfile
    ) -> String {
        let service = serviceName.shellQuoted
        let gateway = profile.gateway
        let dns = profile.dnsServers.map(\.shellQuoted).joined(separator: " ")
        return [
            "/usr/sbin/networksetup -setmanual \(service) \(ipAddress.shellQuoted) \(subnetMask.shellQuoted) \(gateway.shellQuoted)",
            "/usr/sbin/networksetup -setdnsservers \(service) \(dns)",
            "/sbin/route -n change default \(gateway.shellQuoted) || /sbin/route -n add default \(gateway.shellQuoted)",
            "/usr/bin/dscacheutil -flushcache",
            "/usr/bin/killall -HUP mDNSResponder || true"
        ].joined(separator: "; ")
    }

    private static func isValidIPv4(_ value: String) -> Bool {
        let parts = value.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let number = Int(part), String(number) == part else { return false }
            return (0...255).contains(number)
        }
    }
}

private extension String {
    var appleScriptQuoted: String {
        "\"\(replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\""))\""
    }

    var shellQuoted: String {
        "'\(replacingOccurrences(of: "'", with: "'\\''"))'"
    }
}
