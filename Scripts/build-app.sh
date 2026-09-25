#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
CONFIG="${CONFIG:-release}"
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
export SWIFTPM_MODULECACHE_OVERRIDE="$PWD/.build/module-cache"
swift build --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security -c "$CONFIG"
BIN_DIR="$(swift build --disable-sandbox --cache-path .build/cache --config-path .build/config --security-path .build/security -c "$CONFIG" --show-bin-path)"
DESTINATION="$PWD/build.noindex/${APP_NAME:-Molaway}.app"
mkdir -p "$PWD/build.noindex"
STAGING="$(mktemp -d "$PWD/build.noindex/.molaway-build.XXXXXX")"
trap 'rm -rf "$STAGING"' EXIT
APP="$STAGING/${APP_NAME:-Molaway}.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/Molaway" "$APP/Contents/MacOS/Molaway"
if [[ "$CONFIG" == "release" ]]; then
    # Keep machine-specific debug paths out of the distributed executable.
    strip -S "$APP/Contents/MacOS/Molaway"
fi
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
cp LICENSE "$APP/Contents/Resources/LICENSE.txt"
cp -R Resources/Localization/*.lproj "$APP/Contents/Resources/"
cp -R Resources/Sounds "$APP/Contents/Resources/"
if [[ "${PREVIEW_BUILD:-0}" == "1" ]]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier local.mola.preview" "$APP/Contents/Info.plist"
    /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName Molaway Preview" "$APP/Contents/Info.plist"
fi
codesign --force --sign - --options runtime --entitlements Resources/Mola.entitlements --timestamp=none "$APP"
codesign --verify --deep --strict "$APP"
# Publish a complete verified bundle; never overwrite a running executable in place.
if [[ -e "$DESTINATION" ]]; then mv "$DESTINATION" "$STAGING/previous.app"; fi
if ! mv "$APP" "$DESTINATION"; then
    if [[ -e "$STAGING/previous.app" ]]; then mv "$STAGING/previous.app" "$DESTINATION"; fi
    exit 1
fi
echo "Built: $DESTINATION"
