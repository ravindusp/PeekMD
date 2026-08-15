#!/usr/bin/env bash
set -e

# Detect Developer Directory
if [ -d "/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer"
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/Release"
APP_PATH="$BUILD_DIR/PeekMD.app"
VERSION="0.3"
DMG_NAME="PeekMD-v${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGING_DIR="$BUILD_DIR/dmg_staging"

echo "=========================================="
echo " Packaging PeekMD v${VERSION} Release DMG "
echo "=========================================="

# 1. Build application
echo "--> Compiling latest release build..."
"$PROJECT_DIR/Scripts/build.sh"

# 2. Prepare staging directory
echo "--> Preparing DMG staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"

# 3. Create DMG installer
echo "--> Generating stylized DMG with create-dmg..."
rm -f "$DMG_PATH"

create-dmg \
    --volname "PeekMD" \
    --volicon "$PROJECT_DIR/Assets/AppIcon.icns" \
    --background "$PROJECT_DIR/Assets/dmg_background.png" \
    --window-pos 200 120 \
    --window-size 1024 768 \
    --text-size 14 \
    --icon-size 128 \
    --icon "PeekMD.app" 220 410 \
    --hide-extension "PeekMD.app" \
    --app-drop-link 800 410 \
    --no-internet-enable \
    --overwrite \
    "$DMG_PATH" \
    "$STAGING_DIR"

# 4. Clean up staging
rm -rf "$STAGING_DIR"

# 5. Generate SHA256 Checksum
echo "--> Computing SHA256 checksum..."
cd "$BUILD_DIR"
shasum -a 256 "$DMG_NAME" > "${DMG_NAME}.sha256"
cd "$PROJECT_DIR"

echo ""
echo "=========================================="
echo " ✅ Release Package Generated Successfully!"
echo " DMG:      $DMG_PATH"
echo " SHA256:   $(cat "$BUILD_DIR/${DMG_NAME}.sha256")"
echo "=========================================="
