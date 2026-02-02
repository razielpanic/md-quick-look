# Phase 3: Tables & Advanced Elements - Context

**Gathered:** 2026-02-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Render GitHub-flavored markdown tables with proper structure, alignment, and visual formatting. This phase delivers table display capabilities for Quick Look - fast information scanning without prominent decoration.

</domain>

<decisions>
## Implementation Decisions

### Visual style
- **Header separator only** - Single line separating header row from body, no other borders
- **Header distinction** - Bold text only for headers (no background color)
- **Body rows** - Plain rows, no alternating backgrounds or visual treatment
- **Cell padding** - Claude's discretion to balance density with scanability

**Design philosophy:** "Quick Look" means fast scanning - minimize visual decoration, maximize information clarity.

### Layout behavior
- **Column widths** - Claude's discretion on auto-fit vs proportional sizing
- **Text overflow** - Truncate with ellipsis to keep rows single-line
- **Wide tables** - Shrink to fit window width (scale proportionally)
- **Minimum column width** - Claude's discretion on readability minimums
- **Maximum table width** - Cap at 90% of window width (leave breathing room margin)

### Cell content
- **Horizontal alignment** - Respect markdown alignment syntax (left/center/right from `|:---|:---:|---:|`)
- **Vertical alignment** - Center-align text vertically within cell height
- **Inline formatting** - Claude's discretion on supporting bold/italic/code/links within cells
- **Special content** - Simplified styling in tables (e.g., code gets monospace but not full background treatment)

### Edge cases
- **Empty cells** - Subtle indicator (light gray background or dot) to show cell exists but is empty
- **Malformed tables** - Fallback to raw text with monospace font (don't attempt best-effort rendering)
- **Long cell content** - Truncate aggressively with ellipsis (align with "quick look" philosophy)
- **Large tables (100+ rows)** - Show all rows; test performance first, optimize only if actually slow
- **Nested tables** - Flatten to text (show nested table as plain text in the cell)
- **Header-only tables** - Render normally (display as table with just header row)

### Claude's Discretion
- Cell padding amount
- Column width algorithm
- Inline formatting support scope
- Minimum column widths
- Performance optimization strategy (only if testing reveals issues)

</decisions>

<specifics>
## Specific Ideas

- **Quick Look philosophy**: Present information for fast scanning, not prominent decoration. This is a viewing tool, not an editor.
- **Performance testing approach**: Implement show-all-rows first, measure with 100+ row tables, only add optimization complexity if measurements show unacceptable slowness
- **Truncation strategy**: Aggressive truncation aligns with quick scanning - user can open full file if they need complete content

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope.

</deferred>

---

*Phase: 03-tables-advanced-elements*
*Context gathered: 2026-02-02*
