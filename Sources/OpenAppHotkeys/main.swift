import Foundation

/// Build Ctrl+1..0 hotkeys from the first 10 Dock apps.
func buildHotkeys(from dockApps: [DockApp]) -> [Hotkey] {
    let keys: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    return zip(keys, dockApps.prefix(10)).compactMap { key, app in
        guard let keyCode = keyNameToCode[key] else { return nil }
        return Hotkey(keyCode: keyCode, modifiers: .maskControl, app: app.bundleIdentifier)
    }
}

// 1. Check Accessibility permissions
if !checkAccessibility(prompt: true) {
    fputs("Accessibility permission is required.\n", stderr)
    fputs("Grant access in: System Settings > Privacy & Security > Accessibility\n", stderr)
    fputs("Then restart OpenAppHotkeys.\n", stderr)
    exit(1)
}

// 2. Read pinned apps from the Dock and assign Ctrl+1..0 hotkeys
let dockApps: [DockApp]
do {
    dockApps = try readDockApps()
} catch {
    fputs("Dock error: \(error)\n", stderr)
    exit(1)
}

let hotkeys = buildHotkeys(from: dockApps)

let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
print("Loaded \(hotkeys.count) hotkey(s) from Dock:")
for (i, hk) in hotkeys.enumerated() {
    let label = dockApps[i].label
    print("  Ctrl+\(keys[i]) → \(label) (\(hk.app))")
}

// 3. Build components
let matcher = HotkeyMatcher(hotkeys: hotkeys)
let launcher = AppLauncher()

// 4. Create and start the event tap
let tapManager = EventTapManager(matcher: matcher, launcher: launcher)
do {
    try tapManager.start()
} catch {
    fputs("Error: \(error)\n", stderr)
    exit(1)
}
print("Event tap active. Listening for hotkeys...")

// 5. Watch the Dock for changes and reload hotkeys automatically
let dockWatcher = DockWatcher(matcher: matcher)
dockWatcher.start()

// 6. Handle SIGTERM and SIGINT for clean shutdown
signal(SIGTERM, SIG_IGN)
signal(SIGINT, SIG_IGN)

let sigTermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
sigTermSource.setEventHandler {
    print("Received SIGTERM, shutting down.")
    exit(0)
}
sigTermSource.resume()

let sigIntSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigIntSource.setEventHandler {
    print("Received SIGINT, shutting down.")
    exit(0)
}
sigIntSource.resume()

// 7. Run the main run loop (required for CGEvent tap and FSEvents to receive events)
CFRunLoopRun()
