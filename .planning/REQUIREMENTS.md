# Requirements: MD Quick Look

**Defined:** 2026-02-07
**Core Value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## v1.3 Requirements

Requirements for v1.3 Visual Polish milestone. Each maps to roadmap phases.

### Dark Mode

- [ ] **DARK-01**: Shaded background colors (code blocks, blockquotes, YAML front matter) use a consistent, harmonized color palette in dark mode

### Typography

- [ ] **TYPO-01**: Padding around content blocks (code, blockquotes, YAML) is visually balanced and consistent across block types
- [ ] **TYPO-02**: Line leading (line spacing) produces comfortable, readable text throughout the rendered preview

### Visual

- [ ] **VIS-01**: All shaded background blocks (code blocks, blockquotes, YAML front matter) have rounded corners instead of sharp rectangle edges

### About Window

- [ ] **ABOUT-01**: About window displays MIT license attribution
- [ ] **ABOUT-02**: About window displays developer credit (app creator name)

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

### Settings

- **PREF-01**: Preferences toggle for YAML front matter display (requires App Group)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Interactive/clickable checkboxes | Quick Look is read-only |
| Collapsible front matter | Quick Look is non-interactive |
| Horizontal scroll for tables | Breaks single-NSTextView architecture |
| preferredContentSize | Breaks Quick Look auto-resizing |
| YAML front matter toggle | Requires App Group infrastructure — deferred |
| New rendering features | This milestone is polish only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DARK-01 | - | Pending |
| TYPO-01 | - | Pending |
| TYPO-02 | - | Pending |
| VIS-01 | - | Pending |
| ABOUT-01 | - | Pending |
| ABOUT-02 | - | Pending |

**Coverage:**
- v1.3 requirements: 6 total
- Mapped to phases: 0
- Unmapped: 6

---
*Requirements defined: 2026-02-07*
*Last updated: 2026-02-07 after initial definition*
