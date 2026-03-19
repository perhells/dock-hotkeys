#!/bin/bash
set -euo pipefail

APP_NAME="OpenAppHotkeys"
APP_BUNDLE="$HOME/Applications/$APP_NAME.app"
LABEL="com.perhellstrom.openapphotkeys"
PLIST_DEST="$HOME/Library/LaunchAgents/$LABEL.plist"
UID_VAL=$(id -u)

echo "Unloading LaunchAgent..."
launchctl bootout "gui/$UID_VAL/$LABEL" 2>/dev/null || true

echo "Removing LaunchAgent plist..."
rm -f "$PLIST_DEST"

echo "Removing app bundle..."
rm -rf "$APP_BUNDLE"

echo ""
echo "Done! OpenAppHotkeys has been uninstalled."
