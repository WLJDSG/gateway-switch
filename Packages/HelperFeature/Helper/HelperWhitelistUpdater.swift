import Foundation
import Core

public enum HelperWhitelistUpdater: Sendable {
    public static let whitelistPath = "/etc/gateway-switcher-allowed-ips.conf"

    public static func update(ips: [String], runner: CommandRunning = ProcessCommandRunner()) throws {
        let content = Array(Set(ips)).sorted().joined(separator: "\n") + "\n"
        let escapedContent = content
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "'", with: "'\\''")
        let command = "printf '\(escapedContent)' > \(whitelistPath.shellQuoted)"
        let appleScript = "do shell script \(command.appleScriptQuoted) with administrator privileges"
        let result = try runner.run("/usr/bin/osascript", arguments: ["-e", appleScript])

        guard result.terminationStatus == 0 else {
            throw GatewayError.commandFailed("更新白名单失败：\(result.standardError)")
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