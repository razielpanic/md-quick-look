# Phase 7: App Icon Design - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Create a professional app icon that represents markdown preview functionality and appears correctly across all macOS contexts (Finder, Dock, About window, DMG). This phase delivers a complete icon asset package with all required sizes integrated into Assets.xcassets.

</domain>

<decisions>
## Implementation Decisions

### Visual Metaphor
- **Primary concept:** Tribute to John Gruber's Daring Fireball - combine Unicode star (★) and markdown octothorpe (#)
- **Composition:** Overlapping symbols with carved-out/cutout effect (# cuts through the star)
- **Framing:** Tight crop showing fragments - icon bounds cut through both symbols for bold, abstract look
- **Focus:** Pure symbols only - no additional preview/magnifying glass elements
- **Intent:** Recognizable homage to markdown's origins, not infringement

### Style & Aesthetic
- **Visual treatment:** Glass/translucent with frosted/blur effect
- **Background:** Gradient (subtle variation within purple range)
- **Glass details:** Frosted glass effect with background blur - premium, sophisticated feel
- **Depth:** Layered composition with transparency showing background through symbols

### Color Palette
- **Direction:** Monochromatic purple
- **Background gradient:** Subtle variation within purple hues - almost solid but with gentle depth
- **Symbol color:** White/light tones for frosted glass effect - classic contrast, very readable
- **Overall mood:** Elegant, premium, creative without being playful

### Creation Approach
- **Base method:** Code-based generation using SF Symbols as foundation + CoreGraphics/ImageMagick
- **Workflow:** Hybrid approach - code generates base composition, manual touch-ups if needed for frosted glass effect
- **Asset pipeline:** Code generates entire .iconset with all required sizes (16x16 through 1024x1024)
- **Tool chain:** Swift/CoreGraphics or ImageMagick for generation, iconutil for .iconset → .icns conversion

### Claude's Discretion
- **Small-size optimization:** Determine if simplified versions needed for 16x16, 32x32 or if design scales well
- **Exact purple values:** Choose specific purple hues that work well across light/dark mode
- **Gradient direction/intensity:** Fine-tune gradient for optimal depth without overwhelming symbols
- **Frosted glass implementation:** Balance between code-achievable effects and manual refinement
- **Crop positioning:** Determine which portions of star/octothorpe create most recognizable fragments
- **Layer opacity/blur:** Exact transparency and blur values for frosted effect

</decisions>

<specifics>
## Specific Ideas

- **Inspiration reference:** Daring Fireball Unicode star (★) - this is the markdown heritage symbol
- **Tight crop aesthetic:** Think bold geometric abstraction - just recognizable portions of both symbols
- **Carved-out effect:** The # symbol should appear to cut through or be carved out of the star shape
- **Premium feel:** Frosted glass should feel sophisticated like modern macOS system preferences icons

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope

</deferred>

---

*Phase: 07-app-icon-design*
*Context gathered: 2026-02-02*
