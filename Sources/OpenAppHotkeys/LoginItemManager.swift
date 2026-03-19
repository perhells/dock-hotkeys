import Foundation

struct LoginItemManager {
    private static let label = "com.perhellstrom.openapphotkeys"
    private static let plistName = "com.perhellstrom.openapphotkeys.plist"

    private static var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(plistName)")
    }

    private static var logDir: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/Logs")
    }

    /// Returns true if the LaunchAgent plist exists in ~/Library/LaunchAgents.
    static func isEnabled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    @discardableResult
    static func setEnabled(_ enabled: Bool) -> Bool {
        if enabled {
            return install()
        } else {
            return uninstall()
        }
    }

    @discardableResult
    private static func install() -> Bool {
        let dest = launchAgentURL

        // Ensure ~/Library/LaunchAgents exists
        let dir = dest.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        } catch {
            fputs("Error: Could not create LaunchAgents directory: \(error.localizedDescription)\n", stderr)
            return false
        }

        // Always generate the plist with correct paths for this executable
        do {
            try generatePlistContent().write(to: dest, atomically: true, encoding: .utf8)
        } catch {
            fputs("Error: Could not write LaunchAgent plist: \(error.localizedDescription)\n", stderr)
            return false
        }

        // Load the agent (runs asynchronously to avoid blocking the main thread)
        launchctl(["bootstrap", "gui/\(getuid())", dest.path])
        return true
    }

    @discardableResult
    private static func uninstall() -> Bool {
        let dest = launchAgentURL
        guard FileManager.default.fileExists(atPath: dest.path) else { return true }

        // Unload the agent
        launchctl(["bootout", "gui/\(getuid())/\(label)"])

        // Remove the plist so the agent won't start on next login
        do {
            try FileManager.default.removeItem(at: dest)
        } catch {
            fputs("Error: Could not remove LaunchAgent plist: \(error.localizedDescription)\n", stderr)
            return false
        }
        return true
    }

    /// Runs a launchctl command asynchronously to avoid blocking the main thread.
    private static func launchctl(_ arguments: [String]) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = arguments
        task.terminationHandler = { process in
            if process.terminationStatus != 0 {
                fputs("Warning: launchctl \(arguments.first ?? "") exited with status \(process.terminationStatus)\n", stderr)
            }
        }
        do {
            try task.run()
        } catch {
            fputs("Error: Failed to run launchctl: \(error.localizedDescription)\n", stderr)
        }
    }

    private static func escapeXML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func generatePlistContent() -> String {
        let execPath = escapeXML(
            URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
        )
        let logPath = escapeXML(logDir.appendingPathComponent("openapphotkeys.log").path)
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(escapeXML(label))</string>

            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>

            <key>RunAtLoad</key>
            <true/>

            <key>StandardOutPath</key>
            <string>\(logPath)</string>

            <key>StandardErrorPath</key>
            <string>\(logPath)</string>
        </dict>
        </plist>
        """
    }
}
