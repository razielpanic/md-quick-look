# Phase 2: Core Markdown Rendering - Context

**Gathered:** 2026-02-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Render all essential markdown elements (headings, formatting, lists, code, blockquotes, links, images) with proper visual hierarchy and formatting. This phase focuses on making markdown content visually accessible with appropriate styling for each element type. Performance optimization is deferred to Phase 4.

</domain>

<decisions>
## Implementation Decisions

### Code Block Presentation
- **Monospace font:** SF Mono (macOS default) - use system font for familiarity
- **Long lines:** Claude's discretion on wrap vs scroll behavior
- **Background treatment:** Claude's discretion (subtle background appropriate for system appearance)
- **Inline vs block code:** Claude's discretion on visual differentiation

### Links
- **Not clickable** - render as styled text only (blue/underlined)
- Quick Look preview is read-only, links should be visually identifiable but not interactive

### Image Placeholders
- **No emoji** - use SF Symbol if appropriate for image indication
- Format: `[Image: filename.png]` or similar with SF Symbol if available
- Simple, readable text-based placeholder

### Blockquotes
- **Left border bar** - vertical bar on left side (GitHub-style)
- May include subtle background color at Claude's discretion

### Claude's Discretion
- Heading sizes and visual hierarchy (h1-h6)
- Font weights for bold text
- Spacing between elements (paragraphs, lists, headings)
- List bullet styles and indentation depth
- Exact styling for code block backgrounds
- Whether inline code has lighter background than code blocks
- Overall text density and readability

</decisions>

<specifics>
## Specific Ideas

- Use native macOS typography and system appearance conventions
- Phase 1 established `AttributedString(markdown:)` as the rendering approach - build on that foundation

</specifics>

<deferred>
## Deferred Ideas

- **Large file handling/streaming** - User prefers to see actual performance first before deciding on optimization strategy. Phase 2 will implement straightforward rendering; if delays occur on large files (100KB+), Phase 4 (Performance & Polish) can address with progressive rendering or truncation. Decision deferred until we have real-world performance data.

</deferred>

---

*Phase: 02-core-markdown-rendering*
*Context gathered: 2026-02-01*
