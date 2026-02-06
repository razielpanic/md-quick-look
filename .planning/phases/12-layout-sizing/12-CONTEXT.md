# Phase 12: Layout & Sizing - Context

**Gathered:** 2026-02-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Detect available width and adapt fonts, padding, and text layout to context. The extension produces readable output whether in a spacebar popup, narrow Finder preview pane, or fullscreen Quick Look. Window sizing remains system-managed; this phase focuses on content adaptation within whatever space macOS provides.

</domain>

<decisions>
## Implementation Decisions

### Width breakpoints
- Two discrete tiers: narrow and normal (no smooth scaling)
- Narrow tier threshold: Claude's discretion based on actual Quick Look contexts (Finder preview pane is ~260px)
- Window sizing stays system-managed (no preferredContentSize) — current autoresizing mask approach is correct
- Extension adapts content to whatever width macOS provides

### Font scaling
- Scaled shrink approach: headings shrink more aggressively than body text (headings eat the most space)
- Minimum font size floor enforced — nothing goes below a readable minimum (~9-10pt range)
- Code blocks (inline and fenced) scale at the same rate as body text
- Heading hierarchy flattens in narrow mode — H1/H2/H3 sizes converge closer together to save vertical space
- In normal mode, heading hierarchy stays as-is with distinct size steps

### Spacing & density
- Narrow mode: minimal margins (~5-8pt), almost edge-to-edge content to maximize the ~260px
- Narrow mode: paragraph spacing and vertical gaps shrink proportionally
- Narrow mode: decorative element inner padding (code blocks, blockquotes, YAML) also shrinks
- Normal mode: add a max content width cap to prevent uncomfortably long lines in fullscreen (typographic best practice, ~65-80 chars per line)
- Normal mode: otherwise stays as-is

### YAML front matter at narrow widths
- Shrink the YAML section (smaller font, tighter spacing) — not hidden, not collapsed
- Truncate long values with ellipsis to keep the section compact
- Keep the background styling (rounded colored container) even in narrow mode
- Cap displayed fields at ~4-5 in narrow mode, with a "+N more" indicator for additional fields
- Future: Preferences toggle for YAML display is a separate todo (already captured)

### Claude's Discretion
- Exact narrow breakpoint threshold (likely around 300px but test to confirm)
- Specific font size ratios for narrow mode
- Exact minimum font size floor
- Max content width value for normal mode
- Heading size convergence ratios in narrow mode

</decisions>

<specifics>
## Specific Ideas

- "We get more mileage out of shrinking headings, so hit them harder" — disproportionate scaling, not uniform
- Finder preview pane is a glance context, not a reading context — optimize for quick scanning
- Follow the pattern of built-in Quick Look renderers (PDF, text) — adapt to container, don't fight the system

</specifics>

<deferred>
## Deferred Ideas

- Preferences toggle for YAML front matter display (show/hide) — already captured as pending todo

</deferred>

---

*Phase: 12-layout-sizing*
*Context gathered: 2026-02-06*
