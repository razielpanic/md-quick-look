# Requirements: MD Quick Look

**Defined:** 2026-02-05
**Core Value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## v1.2 Requirements

Requirements for v1.2 Rendering Polish & Features milestone. Each maps to roadmap phases.

### Layout & Sizing

- [ ] **LAYOUT-01**: Quick Look window uses system-managed sizing with proper autoresizing (no preferredContentSize)
- [ ] **LAYOUT-02**: Extension detects narrow context via view.bounds.width and passes available width to renderer
- [ ] **LAYOUT-03**: All font sizes scale proportionally in narrow contexts (headings, body, code, etc.)
- [ ] **LAYOUT-04**: Text container insets and padding adapt to available width
- [ ] **LAYOUT-05**: Rendering works correctly in spacebar popup, Finder preview pane, and fullscreen Quick Look

### Table Rendering

- [ ] **TABLE-01**: Table maxTableWidth scales to match available container width
- [ ] **TABLE-02**: Column min/max widths scale proportionally for narrow contexts
- [ ] **TABLE-03**: Cell padding reduces in narrow contexts
- [ ] **TABLE-04**: Compact table mode (smaller font + reduced padding) activates at very narrow widths
- [ ] **TABLE-05**: Tables remain readable and not clipped in Finder preview pane

### YAML Front Matter

- [ ] **YAML-01**: YAML front matter detected between `---` delimiters at file start
- [ ] **YAML-02**: Front matter stripped from body before markdown parsing
- [ ] **YAML-03**: Key-value pairs displayed as styled section (bold keys, normal values)
- [ ] **YAML-04**: List values rendered as comma-separated inline text
- [ ] **YAML-05**: Front matter section visually distinct from body content
- [ ] **YAML-06**: Handles edge cases (empty front matter, Windows line endings, no closing delimiter)

### Task List Checkboxes

- [ ] **TASK-01**: `- [ ]` renders with SF Symbol empty checkbox (square)
- [ ] **TASK-02**: `- [x]` renders with SF Symbol filled checkbox (checkmark.square.fill)
- [ ] **TASK-03**: Checkboxes colored for visual contrast
- [ ] **TASK-04**: Checkbox vertically aligned with list item text baseline
- [ ] **TASK-05**: Mixed lists (regular items + task items) render correctly
- [ ] **TASK-06**: Task list items in code blocks are not converted to checkboxes

## Future Requirements

Deferred to later milestones. Tracked but not in current roadmap.

### Distribution

- **SIGN-01**: Code signing with Developer ID certificate
- **SIGN-02**: Notarization via xcrun notarytool
- **SIGN-03**: Hardened runtime enabled
- **SIGN-04**: Stapled notarization ticket
- **SIGN-05**: Homebrew Cask formula

### Advanced Rendering

- **RENDER-01**: Syntax highlighting in code blocks
- **RENDER-02**: Render actual images (local files)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Interactive/clickable checkboxes | Quick Look is read-only |
| Saving checkbox state | No write access; preview only |
| Collapsible front matter | Quick Look is non-interactive |
| Interpreting front matter semantics | Just display, don't interpret layout/permalink values |
| Nested YAML rendering | Deep nesting rare; show as raw text fallback |
| Full YAML parser (Yams) | Overkill for display-only; adds C dependency |
| Horizontal scroll for tables | Breaks single-NSTextView architecture |
| Responsive table stacking | Confusing; loses tabular comparison value |
| Task progress counting | Over-engineering; not a project management tool |
| preferredContentSize | Research found it breaks Quick Look auto-resizing |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| YAML-01 | Phase 11 | Pending |
| YAML-02 | Phase 11 | Pending |
| YAML-03 | Phase 11 | Pending |
| YAML-04 | Phase 11 | Pending |
| YAML-05 | Phase 11 | Pending |
| YAML-06 | Phase 11 | Pending |
| LAYOUT-01 | Phase 12 | Pending |
| LAYOUT-02 | Phase 12 | Pending |
| LAYOUT-03 | Phase 12 | Pending |
| LAYOUT-04 | Phase 12 | Pending |
| TABLE-01 | Phase 13 | Pending |
| TABLE-02 | Phase 13 | Pending |
| TABLE-03 | Phase 13 | Pending |
| TABLE-04 | Phase 13 | Pending |
| TABLE-05 | Phase 13 | Pending |
| TASK-01 | Phase 14 | Pending |
| TASK-02 | Phase 14 | Pending |
| TASK-03 | Phase 14 | Pending |
| TASK-04 | Phase 14 | Pending |
| TASK-05 | Phase 14 | Pending |
| TASK-06 | Phase 14 | Pending |
| LAYOUT-05 | Phase 15 | Pending |

**Coverage:**
- v1.2 requirements: 22 total
- Mapped to phases: 22
- Unmapped: 0

---
*Requirements defined: 2026-02-05*
*Last updated: 2026-02-05 after roadmap creation*
