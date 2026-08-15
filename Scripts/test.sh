#!/usr/bin/env bash
set -e

# Detect Developer Directory
if [ -d "/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Volumes/Ravindu/Applications/Xcode.app/Contents/Developer"
fi

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Running Markdown Finder Test Suites ==="
cd "$PROJECT_DIR"
swift test

echo "🎉 ALL TEST SUITES PASSED WITH 0 FAILURES!"
