# Phase 13: Table Rendering - Context

**Gathered:** 2026-02-06
**Status:** Ready for planning

<domain>
## Phase Boundary

Scale table widths, columns, and padding to fit available container space across all Quick Look contexts. Tables must remain readable from narrow Finder preview pane (~260px) to fullscreen. Builds on Phase 12's WidthTier system for width-aware rendering.

</domain>

<decisions>
## Implementation Decisions

### Column sizing
- Content-proportional column widths — wider content gets more space
- Both minimum and maximum column width constraints to prevent crushed or dominant columns
- Content-fitted table width — tables only as wide as needed, compact tables stay compact
- Maximum table width matches the same cap as body text content
- High column count (5+) handling: Claude's discretion

### Compact mode
- Tied to existing WidthTier system from Phase 12 — no separate threshold
- Compact mode reduces both cell padding AND font size for maximum data density
- Border thickness also reduces in compact mode
- Always render as table layout even at narrowest widths — no stacked/list conversion

### Cell content overflow
- Smart wrap/truncate hybrid: truncate by default to keep rows tight and scannable
- Allow wrapping ONLY when most cells in a row would benefit — avoid lopsided tall rows where one overflowing cell creates an otherwise empty tall row
- When wrapping is allowed, cap at a reasonable max line count (Claude determines the limit)
- Truncated cells show ellipsis (…) with tooltip revealing full content on hover
- Long unbreakable strings (URLs, paths): always truncate, never mid-break

### Visual style
- Minimal borders: header separator line only, no full grid or vertical borders
- Header row: bold text only, no background color distinction
- No zebra striping on data rows — all rows same background
- No rounded-corner container or background tint — table renders inline
- GFM column alignment markers (`:---`, `:---:`, `---:`) are respected — left/center/right alignment applied

### Claude's Discretion
- Exact min/max column width values
- High column count handling strategy
- Wrap line cap number
- Tooltip implementation approach (Quick Look constraints may apply)
- Dark mode border color and contrast tuning
- Spacing between table and surrounding content

</decisions>

<specifics>
## Specific Ideas

- "Think about making it beautiful and balanced and scannable" — the wrap/truncate logic should prioritize visual balance across a row, not just fitting content
- Tables should feel lightweight and minimal — closer to a clean data presentation than a heavy grid

</specifics>

<deferred>
## Deferred Ideas

- Rounded corners on code blocks and YAML front matter sections — visual polish for existing rendered elements, not in scope for table rendering

</deferred>

---

*Phase: 13-table-rendering*
*Context gathered: 2026-02-06*
