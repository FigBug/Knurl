#!/bin/bash
# Builds Knurl.app into bin/ from the Swift package. Signing and notarization
# are handled by ci/build.sh; this script is the plain local build.
set -euo pipefail
cd "$(dirname "$0")"
CONFIG="${1:-release}"
VERSION=$(cat VERSION)
swift build -c "$CONFIG" 2>&1 | grep -v '^\[' || true
APP="bin/Knurl.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp ".build/$CONFIG/Knurl" "$APP/Contents/MacOS/"
cp Resources/Info.plist "$APP/Contents/"
cp Resources/Knurl.icns "$APP/Contents/Resources/"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP/Contents/Info.plist"
echo 'APPL????' > "$APP/Contents/PkgInfo"
if [ -z "${SKIP_ADHOC_SIGN:-}" ]; then
  codesign --force --sign - "$APP" >/dev/null 2>&1 || true
fi
echo "Built $APP ($VERSION)"
