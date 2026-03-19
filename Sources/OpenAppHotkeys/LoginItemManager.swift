import Foundation

struct LoginItemManager {
    private static let label = "com.perhellstrom.openapphotkeys"
    private static let plistName = "com.perhellstrom.openapphotkeys.plist"

    private static var launchAgentURL: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Library/LaunchAgents/\(plistName)")
    }

    /// Returns true if the LaunchAgent plist exists in ~/Library/LaunchAgents.
    static func isEnabled() -> Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    static func setEnabled(_ enabled: Bool) {
        if enabled {
            install()
        } else {
            uninstall()
        }
    }

    private static func install() {
        // Find the plist bundled alongside the executable
        let bundledPlist = bundledPlistURL()
        guard let source = bundledPlist else {
            fputs("Warning: Could not find LaunchAgent plist to install.\n", stderr)
            return
        }

        let dest = launchAgentURL

        // Ensure ~/Library/LaunchAgents exists
        let dir = dest.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        // Copy plist
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: source, to: dest)
        } catch {
            fputs("Warning: Could not copy LaunchAgent plist: \(error.localizedDescription)\n", stderr)
            return
        }

        // Load the agent
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["load", dest.path]
        try? task.run()
        task.waitUntilExit()
    }

    private static func uninstall() {
        let dest = launchAgentURL
        guard FileManager.default.fileExists(atPath: dest.path) else { return }

        // Unload the agent and remove the plist so the agent won't start on next login.
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        task.arguments = ["unload", dest.path]
        try? task.run()
        task.waitUntilExit()

        try? FileManager.default.removeItem(at: dest)
    }

    private static func bundledPlistURL() -> URL? {
        let execURL = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()

        // Candidates relative to the executable location:
        // 1. App bundle: .app/Contents/MacOS/Exe -> .app/Contents/Resources/LaunchAgents/
        // 2. SPM .build/debug or .build/release -> repo root/LaunchAgents/
        // 3. Sibling directory
        let candidates = [
            // Inside an app bundle (Contents/MacOS -> Contents/Resources)
            execURL.deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("Resources/LaunchAgents/\(plistName)"),
            // SPM build: .build/release/Exe -> repo/LaunchAgents/
            execURL.deletingLastPathComponent()
                .deletingLastPathComponent()
                .deletingLastPathComponent()
                .appendingPathComponent("LaunchAgents/\(plistName)"),
            // Sibling directory
            execURL.deletingLastPathComponent()
                .appendingPathComponent("LaunchAgents/\(plistName)"),
        ]

        for url in candidates {
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        // Fallback: generate a plist in-memory and write to temp
        return generatePlist()
    }

    private static func generatePlist() -> URL? {
        let execPath = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath().path
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
          "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>\(label)</string>

            <key>ProgramArguments</key>
            <array>
                <string>\(execPath)</string>
            </array>

            <key>RunAtLoad</key>
            <true/>

            <key>StandardOutPath</key>
            <string>/tmp/openapphotkeys.stdout.log</string>

            <key>StandardErrorPath</key>
            <string>/tmp/openapphotkeys.stderr.log</string>
        </dict>
        </plist>
        """
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(plistName)
        do {
            try plist.write(to: tmpURL, atomically: true, encoding: .utf8)
            return tmpURL
        } catch {
            return nil
        }
    }
}
