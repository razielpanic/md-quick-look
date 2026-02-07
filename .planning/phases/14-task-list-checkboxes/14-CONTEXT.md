# Phase 14: Task List Checkboxes - Context

**Gathered:** 2026-02-07
**Status:** Ready for planning

<domain>
## Phase Boundary

Render GFM task list items (`- [ ]` / `- [x]`) as visual SF Symbol checkboxes in the Quick Look preview. Checkboxes are read-only visual elements — no interactivity. Task items must coexist correctly with regular bullet items in mixed lists.

</domain>

<decisions>
## Implementation Decisions

### Checkbox appearance
- Unchecked: `circle` SF Symbol (empty circle)
- Checked: `checkmark.circle.fill` SF Symbol (filled circle with checkmark)
- Both states use system accent blue — only fill/outline distinguishes checked from unchecked
- Checkbox size scales with font size across width tiers (shrinks in narrow contexts like Finder preview pane)

### Checked item styling
- No text change on completed items — same font weight, color, and style as unchecked items
- Only the checkbox icon itself changes (empty circle vs filled checkmark)
- Task item text is plain text only — no inline formatting (bold, code, links) within task items
- No visual grouping or background for consecutive task items — they're just list items with checkboxes

### Nested task lists
- Same checkbox style at all nesting levels (no size or icon variation by depth)
- Follow GFM spec: each item renders by its own syntax, not determined by parent type
- A regular bullet parent can have task sub-items and vice versa
- Indentation only for hierarchy — no connecting lines or tree-view guides

### Alignment & spacing
- Checkboxes baseline-aligned with the text of their list item
- Tight gap (2-3pt) between checkbox and text
- Same vertical spacing between task items as regular list items — uniform list appearance
- Long text wraps with indent, aligning to the first line of text (not to the checkbox)

### Claude's Discretion
- Nesting depth limit (reasonable cap vs unlimited)
- Exact checkbox point size relative to font size
- How `- [ ]` / `- [x]` inside code blocks is excluded from checkbox conversion (implementation detail)

</decisions>

<specifics>
## Specific Ideas

- Circle style inspired by Apple Reminders aesthetic — soft, modern feel
- System blue for both states keeps the palette clean and native-feeling
- Baseline alignment for typographic precision over centering

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 14-task-list-checkboxes*
*Context gathered: 2026-02-07*
