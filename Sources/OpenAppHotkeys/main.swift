import AppKit

/// Build Ctrl+1..0 hotkeys from the first 10 Dock apps.
func buildHotkeys(from dockApps: [DockApp]) -> [Hotkey] {
    let keys: [String] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    return zip(keys, dockApps.prefix(10)).compactMap { key, app in
        guard let keyCode = keyNameToCode[key] else { return nil }
        return Hotkey(keyCode: keyCode, modifiers: .maskControl, app: app.bundleIdentifier)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
