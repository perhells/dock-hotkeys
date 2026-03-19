#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
APP_NAME="OpenAppHotkeys"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
LABEL="com.perhellstrom.openapphotkeys"
PLIST_DEST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_VAL=$(id -u)

echo "Building release binary..."
cd "$PROJECT_DIR"
swift build -c release

echo "Creating app bundle at $APP_BUNDLE..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources/LaunchAgents"
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
sed -e "s|/Applications/OpenAppHotkeys.app|$APP_BUNDLE|g" \
    -e "s|REPLACE_HOME|$HOME|g" \
    "$PROJECT_DIR/LaunchAgents/$LABEL.plist" \
    > "$APP_BUNDLE/Contents/Resources/LaunchAgents/$LABEL.plist"

echo "Installing LaunchAgent..."
mkdir -p "$HOME/Library/LaunchAgents"
sed -e "s|/Applications/OpenAppHotkeys.app|$APP_BUNDLE|g" \
    -e "s|REPLACE_HOME|$HOME|g" \
    "$PROJECT_DIR/LaunchAgents/$LABEL.plist" \
    > "$PLIST_DEST"

echo "Loading LaunchAgent..."
launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true
launchctl bootstrap "gui/$UID_VAL" "$PLIST_DEST"

echo ""
echo "Done! OpenAppHotkeys is now running."
echo "  App bundle: $APP_BUNDLE"
echo "  Hotkeys are read from your Dock pinned apps (Ctrl+1..0)."
echo "  Logs:   $HOME/Library/Logs/openapphotkeys.log"
echo ""
echo "To reload after Dock changes:"
echo "  launchctl kickstart -k gui/$UID_VAL/$LABEL"
