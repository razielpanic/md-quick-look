# Phase 4: Performance & Polish - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Optimize rendering performance to achieve <1s preview generation for typical markdown files (10-500KB) and integrate with macOS system appearance for seamless light/dark mode support. The extension already renders markdown correctly (Phases 1-3), this phase focuses on speed and visual integration with the system.

</domain>

<decisions>
## Implementation Decisions

### Rendering performance
- Target file size: Up to 500KB (beyond typical 10-50KB, supports longer documentation and technical specs)
- Truncate large files rather than failing or rendering slowly
- Truncation message at bottom of preview with file size info (e.g., "Content truncated (file is 2.5 MB)")
- No caching between Quick Look invocations (re-render each time, simpler implementation)

### Dark mode appearance
- Use system label colors (NSColor.labelColor, .secondaryLabelColor) for text adaptation
- Use system fill colors (NSColor.secondarySystemFill, .tertiarySystemFill) for code block and blockquote backgrounds
- Preview background adapts with NSColor.textBackgroundColor (not fixed white/black)
- Table borders use NSColor.separatorColor for automatic adaptation
- Link colors adapt with NSColor.linkColor (brighter blue in dark mode)
- Inline code uses same background/text colors as code blocks (consistent styling)
- Blockquote borders adapt with NSColor.separatorColor (consistent with table borders)

### Performance measurement
- Use real-world markdown samples at various sizes for verification (README files, documentation)
- Performance metrics are development-only (remove before release)

### UI responsiveness
- No loading indicator (rendering fast enough that loading state isn't needed)

### Claude's Discretion
- Main thread vs background thread rendering (choose based on performance characteristics)
- Exact truncation threshold (set based on performance testing)
- Pattern-specific optimizations (optimize if profiling shows clear wins)
- Performance instrumentation approach (OSLog signposts vs simple timing)
- Passing performance criteria (interpret success criteria appropriately)
- Acceptable UI blocking duration (set based on UX research)
- Progressive vs all-at-once rendering (choose based on implementation complexity)
- File change detection while Quick Look is open (follow Quick Look conventions)

</decisions>

<specifics>
## Specific Ideas

- Embrace macOS system colors throughout for native look and feel
- Truncation is user-friendly (shows file size, appears after content so user can read what's available)
- Simplicity over complexity: no caching, no loading states, re-render each time

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-performance-and-polish*
*Context gathered: 2026-02-02*
