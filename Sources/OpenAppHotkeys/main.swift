import Foundation

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

let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
let hotkeys: [Hotkey] = zip(keys, dockApps.prefix(10)).compactMap { key, app in
    guard let keyCode = keyNameToCode[key] else { return nil }
    return Hotkey(keyCode: keyCode, modifiers: .maskControl, app: app.bundleIdentifier)
}

print("Loaded \(hotkeys.count) hotkey(s) from Dock:")
for (i, hk) in hotkeys.enumerated() {
    let label = dockApps[i].label
    let keyLabel = keys[i] == "0" ? "0" : keys[i]
    print("  Ctrl+\(keyLabel) → \(label) (\(hk.app))")
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

// 5. Handle SIGTERM and SIGINT for clean shutdown
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

// 6. Run the main run loop (required for CGEvent tap to receive events)
CFRunLoopRun()
