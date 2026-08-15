#!/usr/bin/env bash
set -e

# Detect Developer Directory
if [ -d "/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer"
fi

SDK_PATH=$(xcrun --sdk macosx --show-sdk-path)
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/Release"
APP_DIR="$BUILD_DIR/MarkdownFinder.app"
PLUGINS_DIR="$APP_DIR/Contents/PlugIns"

echo "=== Building Markdown Finder ==="
echo "Project Directory: $PROJECT_DIR"
echo "SDK: $SDK_PATH"
echo "Build Directory: $BUILD_DIR"

# Clean build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"
mkdir -p "$PLUGINS_DIR"

# 1. Build MarkdownRenderer Package
echo "--> Building MarkdownRenderer Swift package..."
cd "$PROJECT_DIR/Packages/MarkdownRenderer"
swift build -c release
RENDERER_BUILD_DIR="$PROJECT_DIR/Packages/MarkdownRenderer/.build/arm64-apple-macosx/release"
cd "$PROJECT_DIR"

# 2. Build Finder Sync Extension (MarkdownFinderExtension.appex)
echo "--> Building Finder Sync Extension..."
EXT_DIR="$PLUGINS_DIR/MarkdownFinderExtension.appex"
mkdir -p "$EXT_DIR/Contents/MacOS"
mkdir -p "$EXT_DIR/Contents/Resources"
cp "$PROJECT_DIR/MarkdownFinderExtension/Info.plist" "$EXT_DIR/Contents/Info.plist"

swiftc -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx13.0 \
    -emit-executable \
    -module-name MarkdownFinderExtension \
    -Xlinker -e -Xlinker _NSExtensionMain \
    -F "$SDK_PATH/System/Library/Frameworks" \
    -framework Cocoa \
    -framework FinderSync \
    "$PROJECT_DIR/Shared/SharedConstants.swift" \
    "$PROJECT_DIR/Shared/FilenameResolver.swift" \
    "$PROJECT_DIR/Shared/SharedPreferences.swift" \
    "$PROJECT_DIR/Shared/MarkdownFileCreator.swift" \
    "$PROJECT_DIR/MarkdownFinderExtension/FinderSync.swift" \
    -o "$EXT_DIR/Contents/MacOS/MarkdownFinderExtension"

# 3. Build Quick Look Preview Extension (MarkdownQuickLookExtension.appex)
echo "--> Building Quick Look Preview Extension..."
QL_DIR="$PLUGINS_DIR/MarkdownQuickLookExtension.appex"
mkdir -p "$QL_DIR/Contents/MacOS"
mkdir -p "$QL_DIR/Contents/Resources"
cp "$PROJECT_DIR/MarkdownQuickLookExtension/Info.plist" "$QL_DIR/Contents/Info.plist"

swiftc -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx13.0 \
    -emit-executable \
    -module-name MarkdownQuickLookExtension \
    -Xlinker -e -Xlinker _NSExtensionMain \
    -I "$RENDERER_BUILD_DIR/Modules" \
    -L "$RENDERER_BUILD_DIR" \
    -lMarkdownRenderer \
    -F "$SDK_PATH/System/Library/Frameworks" \
    -framework Cocoa \
    -framework QuickLook \
    -framework QuickLookUI \
    -framework UniformTypeIdentifiers \
    "$PROJECT_DIR/Shared/SharedConstants.swift" \
    "$PROJECT_DIR/Shared/FilenameResolver.swift" \
    "$PROJECT_DIR/Shared/SharedPreferences.swift" \
    "$PROJECT_DIR/MarkdownQuickLookExtension/PreviewProvider.swift" \
    -o "$QL_DIR/Contents/MacOS/MarkdownQuickLookExtension"

# 4. Build Main Host App (MarkdownFinder.app)
echo "--> Building Main macOS Application..."
cp "$PROJECT_DIR/MarkdownFinderApp/Info.plist" "$APP_DIR/Contents/Info.plist"

swiftc -O \
    -sdk "$SDK_PATH" \
    -target arm64-apple-macosx13.0 \
    -emit-executable \
    -module-name MarkdownFinder \
    -I "$RENDERER_BUILD_DIR/Modules" \
    -L "$RENDERER_BUILD_DIR" \
    -lMarkdownRenderer \
    -F "$SDK_PATH/System/Library/Frameworks" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework WebKit \
    -framework UniformTypeIdentifiers \
    "$PROJECT_DIR/Shared/SharedConstants.swift" \
    "$PROJECT_DIR/Shared/FilenameResolver.swift" \
    "$PROJECT_DIR/Shared/SharedPreferences.swift" \
    "$PROJECT_DIR/Shared/LocationManager.swift" \
    "$PROJECT_DIR/Shared/MarkdownFileCreator.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/MarkdownDocument.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/AppState.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/Components/WebView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/Components/StatusBadgeView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/Components/SourceTextEditor.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/SettingsView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/LocationsView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/OnboardingView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/DocumentViewerView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/ContentView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/Views/MarkdownEditorView.swift" \
    "$PROJECT_DIR/MarkdownFinderApp/MarkdownFinderApp.swift" \
    -o "$APP_DIR/Contents/MacOS/MarkdownFinder"

# 5. Ad-Hoc Code Signing
echo "--> Signing bundles..."
codesign --force --sign - --entitlements "$PROJECT_DIR/MarkdownFinderExtension/MarkdownFinderExtension.entitlements" "$EXT_DIR"
codesign --force --sign - --entitlements "$PROJECT_DIR/MarkdownQuickLookExtension/MarkdownQuickLookExtension.entitlements" "$QL_DIR"
codesign --force --sign - --deep --entitlements "$PROJECT_DIR/MarkdownFinderApp/MarkdownFinderApp.entitlements" "$APP_DIR"

echo "--> Verifying code signature..."
codesign -v --deep --strict "$APP_DIR"

echo "✅ Build Succeeded! Application available at: $APP_DIR"
