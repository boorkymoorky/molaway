#!/bin/bash
# Installs a locally built app. No downloads, sudo, credentials or Gatekeeper changes.
set -euo pipefail
cd "$(dirname "$0")/.."
SOURCE="$PWD/build.noindex/Molaway.app"
APPS="$HOME/Applications"
DEST="$APPS/Molaway.app"
if [[ ! -d "$SOURCE" || -L "$SOURCE" ]]; then
    echo 'Build first: bash Scripts/build-app.sh' >&2; exit 1
fi
if /usr/bin/pgrep -x Molaway >/dev/null; then
    echo 'Quit Molaway from its menu panel, then run this installer again.' >&2; exit 1
fi
if [[ -L "$DEST" || -L "$APPS" ]]; then
    echo 'Refusing a symbolic-link installation destination.' >&2; exit 1
fi
ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$SOURCE/Contents/Info.plist")
[[ "$ID" == 'local.mola.desktop' ]] || { echo 'Unexpected app identifier.' >&2; exit 1; }
/usr/bin/codesign --verify --deep --strict "$SOURCE"
if [[ -e "$DEST" ]]; then
    OLD_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEST/Contents/Info.plist")
    [[ "$OLD_ID" == "$ID" ]] || { echo 'Refusing to replace a different app.' >&2; exit 1; }
fi
mkdir -p "$APPS"
STAGING=$(mktemp -d "$APPS/.molaway-install.XXXXXX")
cleanup() {
    if [[ ! -e "$DEST" && -e "$STAGING/previous.app" ]]; then
        mv "$STAGING/previous.app" "$DEST"
    fi
    rm -rf "$STAGING"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
/usr/bin/ditto "$SOURCE" "$STAGING/Molaway.app"
/usr/bin/codesign --verify --deep --strict "$STAGING/Molaway.app"
if [[ -e "$DEST" ]]; then mv "$DEST" "$STAGING/previous.app"; fi
mv "$STAGING/Molaway.app" "$DEST"
echo 'Installed in your home Applications folder. Open Molaway from Finder or Spotlight.'
echo 'This is locally signed, not Apple Developer ID signed or notarized.'
