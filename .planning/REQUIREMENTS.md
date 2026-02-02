# Requirements: md-spotlighter

**Defined:** 2026-01-31
**Core Value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Markdown Rendering

- [x] **MDRNDR-01**: Render headings with visual hierarchy (h1-h6)
- [x] **MDRNDR-02**: Render bold text
- [x] **MDRNDR-03**: Render italic text
- [x] **MDRNDR-04**: Render strikethrough text
- [x] **MDRNDR-05**: Render unordered lists
- [x] **MDRNDR-06**: Render ordered lists
- [x] **MDRNDR-07**: Render code blocks with monospaced font
- [x] **MDRNDR-08**: Render blockquotes
- [ ] **MDRNDR-09**: Render tables (GFM)
- [x] **MDRNDR-10**: Render links as text (no clicking)
- [x] **MDRNDR-11**: Display images as placeholders `[Image: filename]`

### System Integration

- [x] **SYSINT-01**: Quick Look extension loads .md files from Finder
- [ ] **SYSINT-02**: Preview renders instantly (<1 second for typical files)
- [x] **SYSINT-03**: Works on macOS 26+ (Tahoe and later)
- [ ] **SYSINT-04**: Respects system appearance (light/dark mode)

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Enhanced Rendering

- **ENHRNDR-01**: Syntax highlighting in code blocks
- **ENHRNDR-02**: Render actual images (local files)
- **ENHRNDR-03**: Display YAML front matter as formatted metadata
- **ENHRNDR-04**: Render GFM task lists with checkboxes

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| macOS 14 or earlier support | Targeting latest OS only (26+), no legacy support needed |
| Clickable links | Breaks preview-only UX; Quick Look is for viewing, not interaction |
| HTML/CSS rendering | Security risk (XSS), complexity not needed for markdown |
| JavaScript execution | Impossible in sandbox, not needed |
| Remote image loading | Network delays, privacy issues, 30s timeout risk |
| Interactive widgets | No edit capability in preview context |
| Mermaid diagrams / MathJax | Requires JavaScript; timeout risk; high complexity |
| Custom CSS/theming | Use system appearance defaults |
| Other file formats | Markdown only |
| Mobile/iPad support | macOS Quick Look extension only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| MDRNDR-01 | Phase 2 | Complete |
| MDRNDR-02 | Phase 2 | Complete |
| MDRNDR-03 | Phase 2 | Complete |
| MDRNDR-04 | Phase 2 | Complete |
| MDRNDR-05 | Phase 2 | Complete |
| MDRNDR-06 | Phase 2 | Complete |
| MDRNDR-07 | Phase 2 | Complete |
| MDRNDR-08 | Phase 2 | Complete |
| MDRNDR-09 | Phase 3 | Pending |
| MDRNDR-10 | Phase 2 | Complete |
| MDRNDR-11 | Phase 2 | Complete |
| SYSINT-01 | Phase 1 | Complete |
| SYSINT-02 | Phase 4 | Pending |
| SYSINT-03 | Phase 1 | Complete |
| SYSINT-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 15 total
- Mapped to phases: 15
- Unmapped: 0

---
*Requirements defined: 2026-01-31*
*Last updated: 2026-01-31 after roadmap creation*
