#!/bin/bash
# Composite Icon Composer design manually from icon.json specifications
# Based on: MDQuickLook/MDQuickLook/Resources/AppIcon.icon/icon.json

set -e

ICON_DIR="MDQuickLook/MDQuickLook/Resources/AppIcon.icon/Assets"
OUTPUT="scripts/icon_composer_rendered_1024.png"

echo "Compositing Icon Composer design..."

# Convert Display P3 gradient colors to sRGB approximations
# Top: display-p3:0.33728,0.17784,0.64589 ≈ rgb(86,45,165) #562DA5
# Bottom: display-p3:0.06481,0.01094,0.16908 ≈ rgb(17,3,43) #11032B
# Gradient runs from top (y=0) to 70% down (y=0.7)

echo "Creating purple gradient background..."
magick -size 1024x1024 gradient:'#562DA5'-'#11032B' \
  /tmp/bg.png

# Group 1: "Marks" - Contains 3 layers with group-level transforms
# Group scale: 0.57, translation: -218,-211

echo "Creating Marks group layers..."

# Layer 1: top hash (number.circle.fill)
# Layer scale: 0.3, translation: -81,-7
# Group scale: 0.57, translation: -218,-211
# Combined: layer scale × group scale = 0.171, layer translate + group translate
magick "$ICON_DIR/number.circle.fill.png" \
  -colorspace sRGB \
  -channel RGB -evaluate set 96.155% +channel \
  -resize 17.1% \
  -background none \
  -extent 1024x1024 \
  /tmp/marks_top_hash_base.png

# Apply glass effect (subtle blur/glow)
magick /tmp/marks_top_hash_base.png \
  \( +clone -blur 0x4 -alpha extract -evaluate multiply 0.5 \) \
  -compose DstIn -composite \
  /tmp/marks_top_hash.png

# Layer 2: asterisk (asterisk.circle.fill)
# Layer scale: 0.46, translation: -81,385
magick "$ICON_DIR/asterisk.circle.fill.png" \
  -colorspace sRGB \
  -channel RGB -evaluate set 96.321% +channel \
  -resize 26.22% \
  -background none \
  -extent 1024x1024 \
  /tmp/marks_asterisk_base.png

magick /tmp/marks_asterisk_base.png \
  \( +clone -blur 0x4 -alpha extract -evaluate multiply 0.5 \) \
  -compose DstIn -composite \
  /tmp/marks_asterisk.png

# Layer 3: bottom hash (number.circle.fill)
# Layer scale: 0.3, translation: -81,775
magick "$ICON_DIR/number.circle.fill.png" \
  -colorspace sRGB \
  -channel RGB -evaluate set 96.321% +channel \
  -resize 17.1% \
  -background none \
  -extent 1024x1024 \
  /tmp/marks_bottom_hash_base.png

magick /tmp/marks_bottom_hash_base.png \
  \( +clone -blur 0x4 -alpha extract -evaluate multiply 0.5 \) \
  -compose DstIn -composite \
  /tmp/marks_bottom_hash.png

# Composite marks group internally first
magick -size 1024x1024 xc:none \
  /tmp/marks_top_hash.png -geometry -81-7 -compose Over -composite \
  /tmp/marks_asterisk.png -geometry -81+385 -compose Over -composite \
  /tmp/marks_bottom_hash.png -geometry -81+775 -compose Over -composite \
  /tmp/marks_group_internal.png

# Now scale and position the entire marks group
magick /tmp/marks_group_internal.png \
  -resize 57% \
  -background none \
  -gravity center \
  -extent 1024x1024 \
  -geometry -218-211 \
  /tmp/marks_group.png

# Group 2: "bars" - Contains 1 layer (rectangle.grid.1x3.fill)
# Layer scale: 0.51, translation: 0,0
# Fill: srgb:0.60590,0.60590,0.60590 (about 60% gray)
# Translucency: 0.36 (64% opacity)

echo "Creating bars group layer..."
magick "$ICON_DIR/rectangle.grid.1x3.fill.png" \
  -colorspace sRGB \
  -channel RGB -evaluate set 60.59% +channel \
  -alpha set -channel A -evaluate multiply 0.64 +channel \
  -resize 51% \
  -background none \
  -extent 1024x1024 \
  /tmp/bars_base.png

# Apply glass effect
magick /tmp/bars_base.png \
  \( +clone -blur 0x4 -alpha extract -evaluate multiply 0.5 \) \
  -compose DstIn -composite \
  /tmp/bars_group.png

# Final composite: background + marks group + bars group
echo "Compositing final icon..."
magick /tmp/bg.png \
  /tmp/marks_group.png -compose Over -composite \
  /tmp/bars_group.png -compose Over -composite \
  "$OUTPUT"

echo "Icon composited to $OUTPUT"

# Generate all sizes for iconset
echo "Generating all icon sizes..."
mkdir -p scripts/IconComposer.iconset

sips -z 16 16 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_16x16.png" >/dev/null 2>&1
sips -z 32 32 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_16x16@2x.png" >/dev/null 2>&1
sips -z 32 32 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_32x32.png" >/dev/null 2>&1
sips -z 64 64 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_32x32@2x.png" >/dev/null 2>&1
sips -z 128 128 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_128x128.png" >/dev/null 2>&1
sips -z 256 256 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_128x128@2x.png" >/dev/null 2>&1
sips -z 256 256 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_256x256.png" >/dev/null 2>&1
sips -z 512 512 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_256x256@2x.png" >/dev/null 2>&1
sips -z 512 512 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_512x512.png" >/dev/null 2>&1
sips -z 1024 1024 "$OUTPUT" --out "scripts/IconComposer.iconset/icon_512x512@2x.png" >/dev/null 2>&1

echo "All sizes generated in scripts/IconComposer.iconset/"
echo "Done!"

# Cleanup temp files
rm -f /tmp/bg.png /tmp/marks_*.png /tmp/bars_*.png
