#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Build first
"$PROJECT_DIR/Scripts/build.sh"

APP_SRC="$PROJECT_DIR/build/Release/MarkdownFinder.app"
DEST_DIR="$HOME/Applications"
DEST_APP="$DEST_DIR/MarkdownFinder.app"

mkdir -p "$DEST_DIR"
echo "--> Installing to $DEST_APP..."
rm -rf "$DEST_APP"
cp -R "$APP_SRC" "$DEST_APP"

echo "--> Registering Finder Sync Extension with pluginkit..."
pluginkit -a "$DEST_APP/Contents/PlugIns/MarkdownFinderExtension.appex" || true
pluginkit -e use -i com.oneloop.MarkdownFinder.FinderSync || true

echo "--> Registering Quick Look Extension with pluginkit..."
pluginkit -a "$DEST_APP/Contents/PlugIns/MarkdownQuickLookExtension.appex" || true
pluginkit -e use -i com.oneloop.MarkdownFinder.QuickLook || true

echo "--> Resetting Quick Look cache..."
qlmanage -r || true
qlmanage -r cache || true

echo "--> Restarting Finder..."
killall Finder 2>/dev/null || true

echo "✅ Installation & Registration Complete!"
echo "You can now launch $DEST_APP or right-click inside Finder folders."
