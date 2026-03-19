import AppKit

final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let launcher: AppLauncher
    private var dockApps: [DockApp] = []
    private var hotkeys: [Hotkey] = []

    init(launcher: AppLauncher, dockApps: [DockApp], hotkeys: [Hotkey]) {
        self.launcher = launcher
        self.dockApps = dockApps
        self.hotkeys = hotkeys
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "OpenAppHotkeys")
        }

        rebuildMenu()
    }

    func update(dockApps: [DockApp], hotkeys: [Hotkey]) {
        dispatchPrecondition(condition: .onQueue(.main))
        self.dockApps = dockApps
        self.hotkeys = hotkeys
        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()

        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        for (i, app) in dockApps.prefix(hotkeys.count).enumerated() {
            let item = NSMenuItem(
                title: "Ctrl+\(keys[i])  \(app.label)",
                action: #selector(openApp(_:)),
                keyEquivalent: ""
            )
            item.tag = i
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let loginItem = NSMenuItem(
            title: "Start at Login",
            action: #selector(toggleLogin(_:)),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.state = LoginItemManager.isEnabled() ? .on : .off
        menu.addItem(loginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit OpenAppHotkeys",
            action: #selector(quit(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    @objc private func openApp(_ sender: NSMenuItem) {
        let index = sender.tag
        guard index >= 0, index < hotkeys.count else { return }
        launcher.open(app: hotkeys[index].app)
    }

    @objc private func toggleLogin(_ sender: NSMenuItem) {
        let nowEnabled = LoginItemManager.isEnabled()
        LoginItemManager.setEnabled(!nowEnabled)
        sender.state = LoginItemManager.isEnabled() ? .on : .off
    }

    @objc private func quit(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
}
