import Foundation
import Core

public enum PasswordlessHelper {
    public static let helperPath = "/usr/local/bin/gateway-switcher-helper"

    public static func isInstalled(runner: CommandRunning = ProcessCommandRunner()) -> Bool {
        guard let result = try? runner.run("/usr/bin/sudo", arguments: ["-n", helperPath, "--check"]) else {
            return false
        }
        return result.terminationStatus == 0
    }

    public static func install(runner: CommandRunning = ProcessCommandRunner(), installerPath: String) throws {
        let command = "/bin/sh \(installerPath.shellQuoted)"
        let appleScript = "do shell script \(command.appleScriptQuoted) with administrator privileges"
        let result = try runner.run("/usr/bin/osascript", arguments: ["-e", appleScript])
        guard result.terminationStatus == 0 else {
            let message = [result.standardError, result.standardOutput]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first { !$0.isEmpty } ?? "安装免密 helper 失败"
            throw GatewayError.commandFailed(message)
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
