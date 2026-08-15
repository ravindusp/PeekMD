#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Build first
"$PROJECT_DIR/Scripts/build.sh"

APP_SRC="$PROJECT_DIR/build/Release/PeekMD.app"
DEST_DIR="/Applications"
DEST_APP="$DEST_DIR/PeekMD.app"

# Clean up any conflicting instances
rm -rf "$HOME/Applications/PeekMD.app" "$HOME/Applications/MarkdownFinder.app"
rm -rf "$DEST_APP" "/Applications/MarkdownFinder.app"
cp -R "$APP_SRC" "$DEST_APP"

echo "--> Registering with LaunchServices (lsregister)..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST_APP" || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST_APP/Contents/PlugIns/MarkdownFinderExtension.appex" || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST_APP/Contents/PlugIns/MarkdownQuickLookExtension.appex" || true

echo "--> Registering Finder Sync Extension with pluginkit..."
pluginkit -a "$DEST_APP/Contents/PlugIns/MarkdownFinderExtension.appex" || true
pluginkit -e use -i com.oneloop.PeekMD.FinderSync || true

echo "--> Registering Quick Look Extension with pluginkit..."
pluginkit -a "$DEST_APP/Contents/PlugIns/MarkdownQuickLookExtension.appex" || true
pluginkit -e use -i com.oneloop.PeekMD.QuickLook || true

echo "--> Resetting Quick Look cache..."
qlmanage -r || true
qlmanage -r cache || true

echo "--> Restarting Finder..."
killall Finder 2>/dev/null || true

echo "✅ Installation & Registration Complete!"
