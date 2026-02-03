#!/bin/bash
# generate-icon.sh - Creates MD Quick Look app icon with frosted glass aesthetic
#
# Design: Star (★) overlapping with octothorpe (#) - tribute to Daring Fireball
# Style: Frosted glass effect with purple gradient background
# Output: Master 1024x1024 icon + complete iconset with all required sizes
#
# Requirements: ImageMagick (install via: brew install imagemagick)

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/AppIcon.iconset"
MASTER_ICON="$SCRIPT_DIR/icon_master_1024.png"

# Color palette (monochromatic purple)
GRADIENT_START="#6B46C1"  # Purple 600 (lighter)
GRADIENT_END="#553C9A"    # Purple 700 (darker)
SYMBOL_COLOR="white"

# Check for ImageMagick
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick not found"
    echo "Install with: brew install imagemagick"
    exit 1
fi

echo "Generating MD Quick Look app icon..."
echo "-----------------------------------"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Generate master 1024x1024 icon
echo "Creating master icon (1024x1024)..."

# Step 1: Create purple gradient background
# Rotate then crop to exact 1024x1024 to avoid dimension inflation
magick -size 1024x1024 \
    gradient:"${GRADIENT_START}-${GRADIENT_END}" \
    -rotate 135 \
    -gravity center \
    -extent 1024x1024 \
    /tmp/icon_bg.png

# Step 2: Create star symbol (★) with frosted glass effect
# Using geometric drawing (5-pointed star) - more reliable than font rendering
magick -size 1024x1024 xc:none \
    -fill "$SYMBOL_COLOR" \
    -draw "translate 512,512 path 'M 0,-400 L -117,-123 L -381,-123 L -191,50 L -235,315 L 0,154 L 235,315 L 191,50 L 381,-123 L 117,-123 Z'" \
    -blur 0x8 \
    /tmp/icon_star.png

# Step 3: Create octothorpe (#) symbol for carving effect
# Using rectangles to draw # shape - more reliable than font rendering
magick -size 1024x1024 xc:none \
    -fill "$SYMBOL_COLOR" \
    -draw "rectangle 280,200 420,824" \
    -draw "rectangle 604,200 744,824" \
    -draw "rectangle 200,350 824,470" \
    -draw "rectangle 200,554 824,674" \
    -blur 0x6 \
    /tmp/icon_hash.png

# Step 4: Create the carved-out effect
# First composite: star with frosted blur
magick /tmp/icon_bg.png \
    /tmp/icon_star.png \
    -compose Over -composite \
    /tmp/icon_with_star.png

# Second composite: Add # with Dst_Out to carve through the star
# This creates depth by knocking out portions of the star
magick /tmp/icon_with_star.png \
    /tmp/icon_hash.png \
    -compose Dst_Out -composite \
    /tmp/icon_carved.png

# Step 5: Add back the # as a frosted overlay
magick /tmp/icon_hash.png \
    -blur 0x12 \
    -modulate 100,0,100 \
    /tmp/icon_hash_frosted.png

# Final composite: Combine carved base with frosted # overlay
magick /tmp/icon_carved.png \
    /tmp/icon_hash_frosted.png \
    -compose Over -composite \
    "$MASTER_ICON"

# Cleanup temp files
rm -f /tmp/icon_*.png

echo "✓ Master icon created: $MASTER_ICON"

# Generate all required icon sizes using sips
echo ""
echo "Generating all icon sizes..."

# Size mappings: filename -> actual pixel dimensions
declare -a SIZES=(
    "icon_16x16.png:16"
    "icon_16x16@2x.png:32"
    "icon_32x32.png:32"
    "icon_32x32@2x.png:64"
    "icon_128x128.png:128"
    "icon_128x128@2x.png:256"
    "icon_256x256.png:256"
    "icon_256x256@2x.png:512"
    "icon_512x512.png:512"
    "icon_512x512@2x.png:1024"
)

for size_spec in "${SIZES[@]}"; do
    filename="${size_spec%%:*}"
    pixels="${size_spec##*:}"
    sips -z "$pixels" "$pixels" "$MASTER_ICON" \
        --out "$OUTPUT_DIR/$filename" &>/dev/null
    echo "  ✓ $filename (${pixels}x${pixels})"
done

echo ""
echo "✓ Icon generation complete!"
echo ""
echo "Output:"
echo "  Master: $MASTER_ICON"
echo "  Iconset: $OUTPUT_DIR/ (10 files)"
echo ""
echo "Next step: Integrate into Assets.xcassets (Plan 07-02)"
