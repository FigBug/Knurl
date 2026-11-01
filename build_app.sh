#!/bin/bash
# Builds Knurl.app into bin/ from the Swift package.
set -euo pipefail
cd "$(dirname "$0")"
CONFIG="${1:-release}"
swift build -c "$CONFIG" 2>&1 | grep -v '^\[' || true
APP="bin/Knurl.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/Knurl" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
echo 'APPL????' > "$APP/Contents/PkgInfo"
codesign --force --sign - "$APP" >/dev/null 2>&1 || true
echo "Built $APP"
