import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var tapManager: EventTapManager?
    private var dockWatcher: DockWatcher?
    private var statusBar: StatusBarController?
    private var sigTermSource: DispatchSourceSignal?
    private var sigIntSource: DispatchSourceSignal?

    func applicationWillTerminate(_ notification: Notification) {
        dockWatcher?.stop()
        tapManager?.stop()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // 0. Ensure only one instance is running
        let dominated = NSRunningApplication.runningApplications(
            withBundleIdentifier: Bundle.main.bundleIdentifier ?? ""
        ).filter { $0 != .current }
        if !dominated.isEmpty {
            fputs("Another instance of OpenAppHotkeys is already running.\n", stderr)
            NSApp.terminate(nil)
            return
        }

        // 1. Check Accessibility permissions
        if !checkAccessibility(prompt: true) {
            fputs("Accessibility permission is required.\n", stderr)
            fputs("Grant access in: System Settings > Privacy & Security > Accessibility\n", stderr)
            fputs("Then restart OpenAppHotkeys.\n", stderr)
            NSApp.terminate(nil)
            return
        }

        // 2. Read pinned apps from the Dock
        let dockApps: [DockApp]
        do {
            dockApps = try readDockApps()
        } catch {
            fputs("Dock error: \(error)\n", stderr)
            NSApp.terminate(nil)
            return
        }

        let hotkeys = buildHotkeys(from: dockApps)

        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        print("Loaded \(hotkeys.count) hotkey(s) from Dock:")
        for (i, hk) in hotkeys.enumerated() {
            guard i < dockApps.count else { break }
            let label = dockApps[i].label
            print("  Ctrl+\(keys[i]) → \(label) (\(hk.app))")
        }

        // 3. Build components
        let matcher = HotkeyMatcher(hotkeys: hotkeys)
        let launcher = AppLauncher()

        // 4. Create and start the event tap
        let tap = EventTapManager(matcher: matcher, launcher: launcher)
        do {
            try tap.start()
        } catch {
            fputs("Error: \(error)\n", stderr)
            NSApp.terminate(nil)
            return
        }
        self.tapManager = tap
        print("Event tap active. Listening for hotkeys...")

        // 5. Status bar
        let bar = StatusBarController(launcher: launcher, dockApps: dockApps, hotkeys: hotkeys)
        self.statusBar = bar

        // 6. Watch the Dock for changes
        let watcher = DockWatcher(matcher: matcher)
        watcher.onReload = { [weak bar] newDockApps, newHotkeys in
            bar?.update(dockApps: newDockApps, hotkeys: newHotkeys)
        }
        do {
            try watcher.start()
        } catch {
            fputs("Warning: \(error) — Dock changes won't be detected.\n", stderr)
        }
        self.dockWatcher = watcher

        // 7. Handle SIGTERM and SIGINT
        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)

        let termSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        termSource.setEventHandler {
            print("Received SIGTERM, shutting down.")
            NSApp.terminate(nil)
        }
        termSource.resume()
        self.sigTermSource = termSource

        let intSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        intSource.setEventHandler {
            print("Received SIGINT, shutting down.")
            NSApp.terminate(nil)
        }
        intSource.resume()
        self.sigIntSource = intSource
    }
}
