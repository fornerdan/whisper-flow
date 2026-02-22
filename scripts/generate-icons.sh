#!/bin/bash
# generate-icons.sh — Generate all required App Store icon sizes from a 1024x1024 source.
#
# Usage: ./scripts/generate-icons.sh <path-to-1024x1024-icon.png>
#
# This script uses sips (built into macOS) to resize the source icon to every
# required size for macOS and iOS app icons.

set -euo pipefail

SOURCE="${1:?Usage: $0 <path-to-1024x1024.png>}"

if [ ! -f "$SOURCE" ]; then
    echo "Error: Source file not found: $SOURCE"
    exit 1
fi

# Verify source is at least 1024x1024
WIDTH=$(sips -g pixelWidth "$SOURCE" | tail -n1 | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE" | tail -n1 | awk '{print $2}')

if [ "$WIDTH" -lt 1024 ] || [ "$HEIGHT" -lt 1024 ]; then
    echo "Error: Source image must be at least 1024x1024. Got ${WIDTH}x${HEIGHT}."
    exit 1
fi

# Output directories
MACOS_DIR="Resources/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$MACOS_DIR"

echo "Generating macOS icons..."

# macOS icon sizes: (point_size, scale, filename)
# 16pt@1x=16, 16pt@2x=32, 32pt@1x=32, 32pt@2x=64
# 128pt@1x=128, 128pt@2x=256, 256pt@1x=256, 256pt@2x=512
# 512pt@1x=512, 512pt@2x=1024
MACOS_SIZES=(
    "16:1:icon_16x16.png"
    "16:2:icon_16x16@2x.png"
    "32:1:icon_32x32.png"
    "32:2:icon_32x32@2x.png"
    "128:1:icon_128x128.png"
    "128:2:icon_128x128@2x.png"
    "256:1:icon_256x256.png"
    "256:2:icon_256x256@2x.png"
    "512:1:icon_512x512.png"
    "512:2:icon_512x512@2x.png"
)

for entry in "${MACOS_SIZES[@]}"; do
    IFS=: read -r pt scale name <<< "$entry"
    pixels=$((pt * scale))
    echo "  ${name} (${pixels}x${pixels})"
    sips -z "$pixels" "$pixels" "$SOURCE" --out "$MACOS_DIR/$name" > /dev/null 2>&1
done

# Generate Contents.json for macOS
cat > "$MACOS_DIR/Contents.json" << 'CONTENTS'
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
CONTENTS

echo ""
echo "Done! Icons generated in:"
echo "  macOS: $MACOS_DIR"
echo ""
echo "Note: For iOS, Xcode 15+ uses a single 1024x1024 icon."
echo "Add the source image directly to the iOS asset catalog."
