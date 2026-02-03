# Phase 1: Extension Foundation - Context

**Gathered:** 2026-01-31
**Status:** Ready for planning

<domain>
## Phase Boundary

Quick Look extension that integrates with macOS Finder to load and display markdown files when users press spacebar. Extension must work on macOS 26+ (Tahoe), appear in System Settings as installed plugin, and display markdown content with basic rendering.

</domain>

<decisions>
## Implementation Decisions

### Extension delivery & installation
- **Distribution method:** Developer-only (manual build from source) for Phase 1
- **Installation automation:** Include build script that handles build, install, and clean operations
- **Build script targets:**
  - Build the Quick Look extension bundle
  - Install to ~/Library/QuickLook/ with qlmanage reload
  - Clean previous builds before installing to avoid conflicts
- **Script implementation:** Claude's discretion (Makefile vs shell script)

### Development & testing workflow
- **Testing approach:** Manual Finder testing with sample markdown files and debug logging
- **Sample files:** Minimal set (1-2 files: basic.md and empty.md) to verify loading works
- **Debug logging verbosity:** Key milestones only (extension loaded, file loaded, rendering complete)
- **Logging control:** Claude's discretion (build configuration, always-on, or toggleable)

### Initial content display
- **Priority:** Smooth, immediate rendering without jarring transitions — perceived smoothness and confidence with immediate utility
- **Rendering approach:** Styled rendering from the start (parse and apply basic styles immediately, no raw markdown visible)
- **Styling depth:** Claude's discretion to balance implementation speed and user experience
- **Progressive rendering:** If possible, render first paragraph immediately and stream the rest as user scans/scrolls — no loading indicators needed if first content appears instantly
- **Loading state:** Only show if rendering isn't fast enough for immediate first-paragraph display

### Extension metadata & branding
- **Extension name:** ".md for QuickLook" (as shown in System Settings)
- **Icon:** Default system icon (no custom icon in Phase 1)
- **Bundle identifier:** com.razielpanic.md-quick-look
- **Version numbering:** Claude's discretion

### Claude's Discretion
- Build script implementation format (Makefile vs shell script)
- Debug logging control mechanism
- Exact styling depth for initial rendering
- Progressive rendering implementation strategy
- Version numbering scheme

</decisions>

<specifics>
## Specific Ideas

- "depends on speed and smoothness" — if we can always get the first paragraph rendered "immediately" there's no need for fallbacks — just stream the rest in as the user scans, scrolls
- Rendering raw markdown then changing it would be jarring even though it's useful — avoid this pattern
- Focus on fast and reliable path towards rendered text with perceived smoothness and confidence

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-extension-foundation*
*Context gathered: 2026-01-31*
