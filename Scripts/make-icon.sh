#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
export CLANG_MODULE_CACHE_PATH="$PWD/.build/clang-cache"
swiftc -module-cache-path "$PWD/.build/module-cache" -parse-as-library Sources/Offscreen/Support/BrandGeometry.swift Scripts/make-icon.swift -o "$TEMP_DIR/render"
"$TEMP_DIR/render" "$TEMP_DIR/png"
mkdir -p "$TEMP_DIR/AppIcon.iconset"
for size in 16 32 128 256 512; do
    cp "$TEMP_DIR/png/icon-$size.png" "$TEMP_DIR/AppIcon.iconset/icon_${size}x${size}.png"
    double=$((size * 2))
    cp "$TEMP_DIR/png/icon-$double.png" "$TEMP_DIR/AppIcon.iconset/icon_${size}x${size}@2x.png"
done
cp "$TEMP_DIR/png/icon-1024.png" Resources/AppIcon.png
iconutil -c icns "$TEMP_DIR/AppIcon.iconset" -o Resources/AppIcon.icns
