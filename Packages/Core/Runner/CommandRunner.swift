import Foundation

public protocol CommandRunning: Sendable {
    func run(_ executable: String, arguments: [String]) throws -> CommandResult
}

@available(macOSApplicationExtension, unavailable)
public struct ProcessCommandRunner: CommandRunning, Sendable {
    public init() {}

    public func run(_ executable: String, arguments: [String]) throws -> CommandResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()
        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        return CommandResult(
            standardOutput: output,
            standardError: error,
            terminationStatus: process.terminationStatus
        )
    }
}
