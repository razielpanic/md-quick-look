# Phase 7: App Icon Design - Research

**Researched:** 2026-02-02
**Domain:** macOS app icon creation, programmatic asset generation, frosted glass effects
**Confidence:** HIGH

## Summary

This phase involves creating a professional macOS app icon with a frosted glass aesthetic combining a star and octothorpe (#) symbol as a tribute to Daring Fireball. The research focused on macOS icon requirements, the hybrid code-based generation approach using Swift/CoreGraphics and ImageMagick, and the asset catalog integration process.

The standard approach for macOS app icons involves creating a 1024x1024 master image, then generating all required sizes (16x16 through 512x512 at both 1x and 2x resolutions) programmatically. The icon must be integrated into an Assets.xcassets folder with proper Contents.json configuration. The frosted glass effect can be achieved through CoreImage's CIGaussianBlur filter or ImageMagick's blur and composite operations.

**Primary recommendation:** Create a Swift command-line tool that generates the master icon using CoreGraphics with CIGaussianBlur for the frosted effect, then use the built-in `sips` utility and `iconutil` to generate all required sizes and produce the final .icns file.

## Standard Stack

The established tools for macOS app icon generation:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `sips` | Built-in | Image resizing | macOS native, handles PNG properly, no dependencies |
| `iconutil` | Built-in | .iconset to .icns conversion | Apple's official tool, handles compression |
| CoreGraphics | macOS 14+ | Programmatic image generation | Native Swift framework, full control |
| CoreImage | macOS 14+ | Blur/filter effects | CIGaussianBlur for frosted glass |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| ImageMagick | 7.x | Complex image manipulation | Alternative for blur/gradient effects if CoreImage insufficient |
| Xcode | 16.x | Asset catalog integration | Adding Assets.xcassets to project |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Swift/CoreGraphics | ImageMagick only | ImageMagick: more mature blur tools, but less control over exact rendering |
| Manual Xcode integration | actool CLI | actool is for CI/CD builds; manual is simpler for initial setup |

**No installation required** - all core tools are built into macOS.

## Architecture Patterns

### Recommended Asset Structure
```
MDQuickLook/
├── MDQuickLook/
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/
│   │       ├── Contents.json
│   │       ├── icon_16x16.png
│   │       ├── icon_16x16@2x.png
│   │       ├── icon_32x32.png
│   │       ├── icon_32x32@2x.png
│   │       ├── icon_128x128.png
│   │       ├── icon_128x128@2x.png
│   │       ├── icon_256x256.png
│   │       ├── icon_256x256@2x.png
│   │       ├── icon_512x512.png
│   │       └── icon_512x512@2x.png
│   ├── Info.plist
│   └── main.swift
└── ...
```

### Pattern 1: Icon Generation Script
**What:** Shell script that creates all icon sizes from a master PNG
**When to use:** Generating the complete iconset from a single 1024x1024 source

```bash
#!/bin/bash
# Source: https://gist.github.com/jamieweavis/b4c394607641e1280d447deed5fc85fc

INPUT=$1
ICONSET="AppIcon.iconset"

mkdir -p "$ICONSET"

# Generate all required sizes
sips -z 16 16     "$INPUT" --out "$ICONSET/icon_16x16.png"
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_16x16@2x.png"
sips -z 32 32     "$INPUT" --out "$ICONSET/icon_32x32.png"
sips -z 64 64     "$INPUT" --out "$ICONSET/icon_32x32@2x.png"
sips -z 128 128   "$INPUT" --out "$ICONSET/icon_128x128.png"
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_128x128@2x.png"
sips -z 256 256   "$INPUT" --out "$ICONSET/icon_256x256.png"
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_256x256@2x.png"
sips -z 512 512   "$INPUT" --out "$ICONSET/icon_512x512.png"
sips -z 1024 1024 "$INPUT" --out "$ICONSET/icon_512x512@2x.png"

# Convert to icns (optional - for DMG/manual use)
iconutil -c icns "$ICONSET" -o AppIcon.icns
```

### Pattern 2: Contents.json Structure
**What:** JSON manifest for Xcode asset catalog
**When to use:** Required for Assets.xcassets AppIcon integration

```json
{
  "images": [
    { "filename": "icon_16x16.png", "idiom": "mac", "scale": "1x", "size": "16x16" },
    { "filename": "icon_16x16@2x.png", "idiom": "mac", "scale": "2x", "size": "16x16" },
    { "filename": "icon_32x32.png", "idiom": "mac", "scale": "1x", "size": "32x32" },
    { "filename": "icon_32x32@2x.png", "idiom": "mac", "scale": "2x", "size": "32x32" },
    { "filename": "icon_128x128.png", "idiom": "mac", "scale": "1x", "size": "128x128" },
    { "filename": "icon_128x128@2x.png", "idiom": "mac", "scale": "2x", "size": "128x128" },
    { "filename": "icon_256x256.png", "idiom": "mac", "scale": "1x", "size": "256x256" },
    { "filename": "icon_256x256@2x.png", "idiom": "mac", "scale": "2x", "size": "256x256" },
    { "filename": "icon_512x512.png", "idiom": "mac", "scale": "1x", "size": "512x512" },
    { "filename": "icon_512x512@2x.png", "idiom": "mac", "scale": "2x", "size": "512x512" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
```

### Pattern 3: CoreImage Gaussian Blur for Frosted Effect
**What:** Applying blur to create frosted glass appearance
**When to use:** Generating the translucent frosted effect in Swift

```swift
// Source: Apple Developer Documentation - CIGaussianBlur
import CoreImage

func applyFrostedEffect(to image: CIImage, sigma: Double = 10.0) -> CIImage? {
    // Clamp to extent to avoid edge artifacts
    let clamped = image.clampedToExtent()

    // Apply Gaussian blur
    let blurred = clamped.applyingGaussianBlur(sigma: sigma)

    // Crop back to original bounds
    return blurred.cropped(to: image.extent)
}
```

### Anti-Patterns to Avoid
- **Not including alpha channel:** All macOS icon PNGs must include alpha channel
- **Using transparency in background:** App icons must have opaque backgrounds (no transparency showing through)
- **Wrong file naming:** Files must match exact naming convention (icon_16x16.png, icon_16x16@2x.png, etc.) or iconutil fails
- **Skipping small sizes:** Even if you provide a 1024x1024, macOS needs explicit small sizes for Finder list view

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image resizing | Custom resize algorithm | `sips -z` | Handles color profiles, alpha properly |
| .icns generation | Manual binary format | `iconutil -c icns` | Apple's format evolves, tool handles compression |
| Blur edge artifacts | Manual edge handling | `ciImage.clampedToExtent()` | Proper infinite edge extension |
| Asset catalog JSON | Manual JSON building | Copy template | Exact format required for Xcode |

**Key insight:** macOS provides excellent built-in tools (sips, iconutil) that handle edge cases and format requirements. Using these ensures forward compatibility as Apple updates icon formats.

## Common Pitfalls

### Pitfall 1: iconutil "Failed to generate ICNS" Error
**What goes wrong:** iconutil refuses to create .icns file
**Why it happens:** File naming doesn't match expected pattern exactly, wrong dimensions, or alpha channel issues
**How to avoid:**
- Use exact naming: `icon_16x16.png`, `icon_16x16@2x.png`, etc.
- Verify dimensions match the filename (icon_16x16@2x.png must be 32x32 pixels)
- Ensure PNG files have alpha channel even if background is opaque
**Warning signs:** Error message mentions "Iconset not found" or "Failed to generate"

### Pitfall 2: Blur Edge Artifacts
**What goes wrong:** Gray/dark edges appear around blurred elements
**Why it happens:** Gaussian blur samples pixels outside the image bounds, using default (black/transparent)
**How to avoid:** Use `clampedToExtent()` on CIImage before applying blur, or extend canvas before blur and crop after
**Warning signs:** Visible dark halo around frosted elements

### Pitfall 3: Icon Not Appearing After Build
**What goes wrong:** App builds but shows generic icon in Finder/Dock
**Why it happens:** Assets.xcassets not added to target, or ASSETCATALOG_COMPILER_APPICON_NAME not set
**How to avoid:**
- Ensure Assets.xcassets is in "Copy Bundle Resources" build phase
- Set ASSETCATALOG_COMPILER_APPICON_NAME = "AppIcon" in build settings
**Warning signs:** Icon appears in Xcode preview but not in built app

### Pitfall 4: Small Icon Legibility
**What goes wrong:** 16x16 and 32x32 icons are muddy, details lost
**Why it happens:** Complex designs don't scale down well; fine details blur together
**How to avoid:**
- Design with bold shapes, avoid thin lines
- Consider simplified versions for 16x16 and 32x32
- Test at actual size on screen
**Warning signs:** Icon unrecognizable in Finder list view

### Pitfall 5: Color Profile Mismatch
**What goes wrong:** Colors look different in icon vs source design
**Why it happens:** sRGB vs Display P3 color space mismatch
**How to avoid:** Work in sRGB for consistency, or explicitly manage color profiles with sips --matchTo
**Warning signs:** Purple appears more blue or more red than expected

## Code Examples

### Complete Icon Generation Script
```bash
#!/bin/bash
# generate-icons.sh - Creates all macOS app icon sizes from 1024x1024 master

set -e

MASTER="$1"
OUTPUT_DIR="${2:-AppIcon.appiconset}"

if [ -z "$MASTER" ]; then
    echo "Usage: $0 <master-1024x1024.png> [output-dir]"
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

# Size mappings: filename_suffix actual_pixels
declare -a SIZES=(
    "16x16:16"
    "16x16@2x:32"
    "32x32:32"
    "32x32@2x:64"
    "128x128:128"
    "128x128@2x:256"
    "256x256:256"
    "256x256@2x:512"
    "512x512:512"
    "512x512@2x:1024"
)

for size_spec in "${SIZES[@]}"; do
    name="${size_spec%%:*}"
    pixels="${size_spec##*:}"
    sips -z "$pixels" "$pixels" "$MASTER" --out "$OUTPUT_DIR/icon_$name.png" >/dev/null
    echo "Generated icon_$name.png ($pixels x $pixels)"
done

echo "Icon set generated in $OUTPUT_DIR"
```

### ImageMagick Frosted Glass Effect
```bash
# Create frosted glass effect with purple gradient background
magick -size 1024x1024 \
    \( gradient:'#6B46C1'-'#553C9A' -rotate 45 \) \
    \( -size 1024x1024 xc:none \
       -font "Helvetica-Bold" -pointsize 600 \
       -fill white -gravity center \
       -annotate 0 "#" \
       -blur 0x15 -modulate 100,0,100 \) \
    -compose Over -composite \
    icon_master.png
```

### Swift CoreGraphics Icon Generator (Basic Structure)
```swift
// IconGenerator.swift - Generates icon with CoreGraphics
import Cocoa
import CoreImage

class IconGenerator {
    let size: CGSize = CGSize(width: 1024, height: 1024)

    // Purple gradient colors (monochromatic purple palette)
    let gradientStart = NSColor(red: 0.42, green: 0.27, blue: 0.76, alpha: 1.0) // #6B46C1
    let gradientEnd = NSColor(red: 0.33, green: 0.24, blue: 0.60, alpha: 1.0)   // #553C9A

    func generateMasterIcon() -> NSImage? {
        let image = NSImage(size: size)
        image.lockFocus()

        // Draw gradient background
        drawPurpleGradient()

        // Draw symbols with frosted effect
        drawFrostedSymbols()

        image.unlockFocus()
        return image
    }

    private func drawPurpleGradient() {
        let gradient = NSGradient(
            starting: gradientStart,
            ending: gradientEnd
        )
        gradient?.draw(in: NSRect(origin: .zero, size: size), angle: 135)
    }

    private func drawFrostedSymbols() {
        // Implementation: Draw star and # with frosted glass effect
        // Use CoreImage blur on symbol layers
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .icns files only | Asset catalogs preferred | macOS 11 (2020) | Use Assets.xcassets for modern apps |
| 512x512 max | 1024x1024 for Retina | macOS 10.7 (2011) | Include 1024x1024 as icon_512x512@2x |
| Flat design | Liquid Glass (iOS 26) | 2025-2026 | Rounded corners, translucency preferred |
| Sharp edges | Rounded/soft shapes | 2025 | Better for glass material effects |

**Current recommendations:**
- Avoid sharp edges and thin lines in favor of rounded shapes
- Use bold line weights to preserve detail at small scales
- Embrace translucency and depth for premium feel

## Open Questions

1. **Exact frosted glass blur intensity**
   - What we know: CIGaussianBlur sigma around 10-20 works for frosted effect
   - What's unclear: Exact value for this specific design at 1024x1024
   - Recommendation: Start with sigma=15, iterate based on visual result

2. **Small icon simplification threshold**
   - What we know: 16x16 and 32x32 may need simplified versions
   - What's unclear: Whether the star/# design is simple enough to scale well
   - Recommendation: Generate scaled versions first, evaluate legibility, create simplified variants only if needed

3. **Tight crop exact positioning**
   - What we know: Design calls for fragments of star and #
   - What's unclear: Which portions create most recognizable abstraction
   - Recommendation: Create multiple crop variations, evaluate visual impact

## Recommended Purple Palette

Based on research, these purple values work well across light/dark modes:

| Name | Hex | RGB | Usage |
|------|-----|-----|-------|
| Purple 600 | #6B46C1 | rgb(107, 70, 193) | Gradient start (lighter) |
| Purple 700 | #553C9A | rgb(85, 60, 154) | Gradient end (darker) |
| Purple 800 | #44337A | rgb(68, 51, 122) | Deep accent (if needed) |
| White/Frost | #FFFFFF @ 70-90% | rgba(255, 255, 255, 0.7-0.9) | Frosted symbol overlay |

These values are from the Tailwind CSS purple palette, which is tested for accessibility and works well in both light and dark contexts.

## Sources

### Primary (HIGH confidence)
- Apple Developer Documentation: Asset Catalog Format Reference - AppIcon sizes and JSON structure
- Apple `sips` man page - Image resizing and format conversion
- Apple `iconutil` man page - .iconset to .icns conversion
- Apple CoreImage CIGaussianBlur documentation - Blur effect API

### Secondary (MEDIUM confidence)
- [GitHub Gist: jamieweavis/b4c394607641e1280d447deed5fc85fc](https://gist.github.com/jamieweavis/b4c394607641e1280d447deed5fc85fc) - Complete iconset generation workflow
- [SAP macOS-icon-generator Contents.json](https://github.com/SAP/macOS-icon-generator) - Verified JSON structure
- [Apple HIG: App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons) - Design guidelines

### Tertiary (LOW confidence)
- Various ImageMagick discussions - Frosted glass techniques (verify with testing)
- Medium articles on glassmorphism in SwiftUI - General patterns (iOS-focused)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Built-in macOS tools, well-documented
- Architecture: HIGH - Asset catalog format is stable, well-documented
- Pitfalls: HIGH - Common issues documented across multiple sources
- Frosted glass implementation: MEDIUM - Multiple approaches possible, requires testing

**Research date:** 2026-02-02
**Valid until:** 60 days (macOS icon format is stable)
