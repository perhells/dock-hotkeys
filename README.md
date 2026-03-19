# OpenAppHotkeys

Launch your macOS Dock-pinned apps with keyboard shortcuts. The first 10 pinned apps are mapped to `Ctrl+1` through `Ctrl+0`.

## Requirements

- macOS 13.0 (Ventura) or later
- Swift 5.9+
- Accessibility permission (you will be prompted on first run)

## Build

```bash
swift build -c release
```

The binary is placed at `.build/release/OpenAppHotkeys`.

## Run

Run directly from the build output:

```bash
.build/release/OpenAppHotkeys
```

On first launch, macOS will prompt you to grant Accessibility permission in **System Settings > Privacy & Security > Accessibility**. The app needs this to listen for global keyboard events.

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

### Logs

```
/tmp/openapphotkeys.stdout.log
/tmp/openapphotkeys.stderr.log
```

### Dock changes

Hotkeys are automatically reloaded when you add, remove, or rearrange pinned Dock apps. No restart needed.

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

## License

MIT
