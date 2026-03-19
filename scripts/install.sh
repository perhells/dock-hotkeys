#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
INSTALL_BIN="/usr/local/bin/openapphotkeys"
LABEL="com.perhellstrom.openapphotkeys"
PLIST_DEST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_VAL=$(id -u)

echo "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "Installing binary to $INSTALL_BIN..."
sudo cp ".build/release/OpenAppHotkeys" "$INSTALL_BIN"

echo "Installing LaunchAgent..."
cp "$PROJECT_DIR/LaunchAgents/$LABEL.plist" "$PLIST_DEST"

echo "Loading LaunchAgent..."
launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_VAL" "$PLIST_DEST"

echo ""
echo "Done! OpenAppHotkeys is now running."
echo "  Hotkeys are read from your Dock pinned apps (Ctrl+1..0)."
echo "  Logs:   /tmp/openapphotkeys.stdout.log"
echo "          /tmp/openapphotkeys.stderr.log"
echo ""
echo "To reload after Dock changes:"
echo "  launchctl kickstart -k gui/$UID_VAL/$LABEL"
