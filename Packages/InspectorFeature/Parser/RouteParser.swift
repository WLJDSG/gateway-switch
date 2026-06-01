import Foundation

public enum RouteParser {
    public static func parseDefaultRoute(_ output: String) -> (gateway: String?, interfaceName: String?) {
        var gateway: String?
        var interfaceName: String?

        for line in output.components(separatedBy: .newlines) {
            let parts = line
                .split(separator: ":", maxSplits: 1)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            guard parts.count == 2 else { continue }

            switch parts[0] {
            case "gateway":
                gateway = parts[1]
            case "interface":
                interfaceName = parts[1]
            default:
                continue
            }
        }

        return (gateway, interfaceName)
    }

    public static func parseHardwarePorts(_ output: String) -> [String: String] {
        var result: [String: String] = [:]
        var pendingServiceName: String?

        for line in output.components(separatedBy: .newlines) {
            if line.hasPrefix("Hardware Port:") {
                pendingServiceName = value(afterColonIn: line)
            } else if line.hasPrefix("Device:"), let serviceName = pendingServiceName {
                let device = value(afterColonIn: line)
                if !device.isEmpty {
                    result[device] = serviceName
                }
                pendingServiceName = nil
            }
        }

        return result
    }

    public static func parseDNSServers(_ output: String) -> [String] {
        output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !$0.hasPrefix("There aren't any DNS Servers set on") }
    }

    public static func parseNetworkInfo(_ output: String) -> (ipAddress: String?, subnetMask: String?, router: String?) {
        var ipAddress: String?
        var subnetMask: String?
        var router: String?

        for line in output.components(separatedBy: .newlines) {
            if line.hasPrefix("IP address:") {
                ipAddress = value(afterColonIn: line)
            } else if line.hasPrefix("Subnet mask:") {
                subnetMask = value(afterColonIn: line)
            } else if line.hasPrefix("Router:") {
                router = value(afterColonIn: line)
            }
        }

        return (ipAddress, subnetMask, router)
    }

    private static func value(afterColonIn line: String) -> String {
        line
            .split(separator: ":", maxSplits: 1)
            .dropFirst()
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) } ?? ""
    }
}
