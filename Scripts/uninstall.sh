#!/usr/bin/env bash

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=========================================="
echo " Completely Uninstalling PeekMD & Plugins "
echo "=========================================="

echo "--> Terminating running processes..."
killall PeekMD 2>/dev/null || true
killall MarkdownFinderExtension 2>/dev/null || true
killall MarkdownQuickLookExtension 2>/dev/null || true

echo "--> Unregistering FinderSync and QuickLook extensions from pluginkit..."
pluginkit -r /Applications/PeekMD.app/Contents/PlugIns/MarkdownFinderExtension.appex 2>/dev/null || true
pluginkit -r /Applications/PeekMD.app/Contents/PlugIns/MarkdownQuickLookExtension.appex 2>/dev/null || true
pluginkit -r "$PROJECT_DIR/build/Release/PeekMD.app/Contents/PlugIns/MarkdownFinderExtension.appex" 2>/dev/null || true
pluginkit -r "$PROJECT_DIR/build/Release/PeekMD.app/Contents/PlugIns/MarkdownQuickLookExtension.appex" 2>/dev/null || true
pluginkit -e ignore -i com.oneloop.PeekMD.FinderSync 2>/dev/null || true
pluginkit -e ignore -i com.oneloop.PeekMD.QuickLook 2>/dev/null || true

echo "--> Unregistering from LaunchServices (lsregister)..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u /Applications/PeekMD.app 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -u "$PROJECT_DIR/build/Release/PeekMD.app" 2>/dev/null || true

echo "--> Removing application bundles from /Applications..."
rm -rf /Applications/PeekMD.app 2>/dev/null || true
rm -rf "$HOME/Applications/PeekMD.app" 2>/dev/null || true
rm -rf /Applications/MarkdownFinder.app 2>/dev/null || true
rm -rf "$HOME/Applications/MarkdownFinder.app" 2>/dev/null || true

echo "--> Removing app containers, preferences, and caches..."
rm -rf "$HOME/Library/Containers/com.oneloop.PeekMD"*/Data 2>/dev/null || true
rm -rf "$HOME/Library/Group Containers/group.com.oneloop.markdownfinder" 2>/dev/null || true
defaults delete group.com.oneloop.markdownfinder 2>/dev/null || true
defaults delete com.oneloop.PeekMD 2>/dev/null || true

echo "--> Resetting Quick Look daemon and cache..."
qlmanage -r 2>/dev/null || true
qlmanage -r cache 2>/dev/null || true

echo "--> Restarting Finder..."
killall Finder 2>/dev/null || true

echo ""
echo "✅ Uninstallation complete! All traces of PeekMD have been removed from your system."
