# OpenAppHotkeys

A lightweight macOS menu bar utility that lets you launch Dock-pinned apps with keyboard shortcuts. The first 10 pinned apps are mapped to `Ctrl+1` through `Ctrl+0`.

## Features

- Global hotkeys for your first 10 pinned Dock apps
- Menu bar icon showing current hotkey assignments
- Automatic reload when you add, remove, or rearrange Dock apps
- Optional launch at login
- No external dependencies — built entirely on Apple frameworks
- Single-instance enforcement

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+
- Accessibility permission (prompted on first run)

## Build

```bash
swift build -c release
```

The binary is placed at `.build/release/OpenAppHotkeys`.

## Run

```bash
.build/release/OpenAppHotkeys
```

On first launch, macOS will prompt you to grant Accessibility permission in **System Settings > Privacy & Security > Accessibility**. The app needs this to listen for global keyboard events.

A keyboard icon (⌨) appears in the menu bar with a list of your current hotkey mappings, a toggle for launch at login, and a quit option.

## Install

An install script is provided that builds the binary, installs it to `/usr/local/bin`, and registers a LaunchAgent so it starts automatically on login:

```bash
./scripts/install.sh
```

This will:

1. Build a release binary
2. Copy it to `/usr/local/bin/openapphotkeys` (requires sudo)
3. Install a LaunchAgent to `~/Library/LaunchAgents/`
4. Load the agent so it starts immediately

### Uninstall

```bash
launchctl bootout gui/$(id -u)/com.perhellstrom.openapphotkeys
rm ~/Library/LaunchAgents/com.perhellstrom.openapphotkeys.plist
sudo rm /usr/local/bin/openapphotkeys
```

## Hotkeys

| Shortcut | App |
|----------|-----|
| `Ctrl+1` | 1st pinned Dock app |
| `Ctrl+2` | 2nd pinned Dock app |
| ... | ... |
| `Ctrl+0` | 10th pinned Dock app |

Hotkeys are automatically reloaded when you add, remove, or rearrange pinned Dock apps. No restart needed.

## Logs

When running via LaunchAgent:

```
/tmp/openapphotkeys.stdout.log
/tmp/openapphotkeys.stderr.log
```

## License

MIT
