# Phase 11: YAML Front Matter - Context

**Gathered:** 2026-02-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Detect, extract, and display YAML front matter metadata blocks as a visually distinct section above the rendered markdown body. The `---` delimiters must be consumed by the preprocessor and never appear as horizontal rules or garbled headings. Files without front matter render exactly as before.

</domain>

<decisions>
## Implementation Decisions

### Visual presentation
- Separation style between front matter and body: Claude's discretion (bordered card, divider, or other approach)
- Section label (e.g., "Front Matter" header): Claude's discretion
- Must adapt styling to system appearance (light mode and dark mode) with appropriate background/border colors for each
- Layout should condense intelligently — use multi-column layout for key-value pairs when space allows, so files with many keys don't consume excessive vertical space

### Key-value formatting
- List values (e.g., `tags: [a, b, c]`): Claude's discretion on inline comma-separated vs pill/badge style
- Key vs value styling: Claude's discretion on bold keys, muted keys, etc.
- Date values: display as-is from YAML (no conversion to human-readable format)
- Boolean values: plain text (true/false), no color coding or special treatment

### Claude's Discretion
- Exact separation style (bordered card, divider line, background tint, etc.)
- Whether to include a section header/label for the metadata block
- Key styling approach (bold, muted, colored, etc.)
- List value presentation style (comma-separated vs badges)
- Multi-column layout breakpoints and column count
- Edge case handling: empty front matter, missing closing delimiter, malformed YAML

</decisions>

<specifics>
## Specific Ideas

- Multi-column layout for front matter keys when space permits — don't force everything into a single column when there are many short key-value pairs
- Values should be shown exactly as authored in the YAML (dates, booleans) — this is a preview, not a reformatter

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 11-yaml-front-matter*
*Context gathered: 2026-02-05*
