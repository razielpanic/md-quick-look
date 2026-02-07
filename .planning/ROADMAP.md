# Roadmap: MD Quick Look

## Milestones

- ✅ **v1.0 MVP** - Phases 1-5 (shipped 2026-02-02)
- ✅ **v1.1 Public Release** - Phases 6-10 (shipped 2026-02-05)
- ✅ **v1.2 Rendering Polish & Features** - Phases 11-15 (shipped 2026-02-07)
- 🚧 **v1.3 Visual Polish** - Phases 16-17 (in progress)

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-5) - SHIPPED 2026-02-02</summary>

### Phase 1: Foundation
**Goal**: Project structure and basic markdown rendering infrastructure
**Plans**: 3 plans

Plans:
- [x] 01-01: Project setup and scaffolding
- [x] 01-02: AttributedString markdown conversion
- [x] 01-03: Quick Look preview integration

### Phase 2: Text Formatting
**Goal**: Core inline text styles (bold, italic, strikethrough)
**Plans**: 2 plans

Plans:
- [x] 02-01: Inline formatting support
- [x] 02-02: Text appearance testing

### Phase 3: Block Elements
**Goal**: Structural markdown elements (headings, lists, code blocks, blockquotes)
**Plans**: 4 plans

Plans:
- [x] 03-01: Heading hierarchy
- [x] 03-02: List rendering (ordered and unordered)
- [x] 03-03: Code blocks with monospaced font
- [x] 03-04: Blockquote styling

### Phase 4: Links, Images, Tables
**Goal**: Complex content (links as text, image placeholders, table rendering)
**Plans**: 3 plans

Plans:
- [x] 04-01: Link and image handling
- [x] 04-02: Table parsing and rendering
- [x] 04-03: Table layout refinement

### Phase 5: Performance & Dark Mode
**Goal**: Instant rendering and automatic dark mode support
**Plans**: 2 plans

Plans:
- [x] 05-01: Performance optimization (500KB truncation)
- [x] 05-02: System semantic colors for dark mode

</details>

<details>
<summary>✅ v1.1 Public Release (Phases 6-10) - SHIPPED 2026-02-05</summary>

### Phase 6: Branding
**Goal**: Remove "spotlighter" references, establish "MD Quick Look" identity
**Plans**: 2 plans

Plans:
- [x] 06-01: Rename bundle identifiers and display names
- [x] 06-02: Update documentation and strings

### Phase 7: App Icon
**Goal**: Professional app icon across all macOS sizes
**Plans**: 2 plans

Plans:
- [x] 07-01: Icon design and generation pipeline
- [x] 07-02: Asset catalog integration

### Phase 8: SwiftUI Host App
**Goal**: About window, Preferences, first-launch welcome
**Plans**: 3 plans

Plans:
- [x] 08-01: SwiftUI app structure with About window
- [x] 08-02: Preferences window
- [x] 08-03: First-launch welcome

### Phase 9: Distribution
**Goal**: DMG packaging and GitHub release infrastructure
**Plans**: 2 plans

Plans:
- [x] 09-01: DMG creation with create-dmg
- [x] 09-02: GitHub release workflow

### Phase 10: Documentation
**Goal**: README, installation guide, screenshots
**Plans**: 2 plans

Plans:
- [x] 10-01: README with hero screenshot
- [x] 10-02: Installation and troubleshooting docs

</details>

<details>
<summary>✅ v1.2 Rendering Polish & Features (Phases 11-15) - SHIPPED 2026-02-07</summary>

### Phase 11: Width-Adaptive Layout
**Goal**: Rendering adapts to available width (narrow Finder pane vs fullscreen)
**Plans**: 4 plans

Plans:
- [x] 11-01: Detect available width and tier classification
- [x] 11-02: Font scaling system for narrow contexts
- [x] 11-03: Inset and padding adaptation
- [x] 11-04: Max content width for fullscreen

### Phase 12: Responsive Tables
**Goal**: Tables scale correctly across all Quick Look contexts
**Plans**: 4 plans

Plans:
- [x] 12-01: Content-proportional column sizing
- [x] 12-02: Narrow-context scaling (min/max, padding)
- [x] 12-03: Compact table mode for very narrow widths
- [x] 12-04: Table integration testing

### Phase 13: YAML Front Matter
**Goal**: Extract and display YAML metadata as styled section
**Plans**: 3 plans

Plans:
- [x] 13-01: YAML extraction and stripping
- [x] 13-02: Two-column metadata rendering
- [x] 13-03: Edge case handling (nested lists, capping)

### Phase 14: Task Lists
**Goal**: GFM task list checkboxes with SF Symbol rendering
**Plans**: 3 plans

Plans:
- [x] 14-01: Checkbox detection and SF Symbol rendering
- [x] 14-02: Baseline alignment and system accent color
- [x] 14-03: Edge cases (mixed lists, code blocks)

### Phase 15: Cross-Context Integration
**Goal**: Snapshot-based regression testing across widths and appearances
**Plans**: 2 plans

Plans:
- [x] 15-01: swift-snapshot-testing integration
- [x] 15-02: Baseline recording and visual verification

</details>

### 🚧 v1.3 Visual Polish (In Progress)

**Milestone Goal:** Harmonize visual appearance with rounded corners, consistent dark mode colors, balanced typography, and complete About window.

#### Phase 16: Rendering Polish
**Goal**: Harmonized dark mode colors, rounded corners, and balanced typography throughout rendered previews
**Depends on**: Nothing (independent polish work)
**Requirements**: DARK-01, TYPO-01, TYPO-02, VIS-01
**Success Criteria** (what must be TRUE):
  1. Shaded backgrounds (code blocks, blockquotes, YAML front matter) use consistent color palette in dark mode
  2. All shaded background blocks have rounded corners instead of sharp edges
  3. Padding around content blocks is visually balanced across all block types
  4. Line spacing produces comfortable, readable text throughout the preview
**Plans**: TBD

Plans:
- [ ] 16-01: [TBD during planning]

#### Phase 17: About Window Polish
**Goal**: Complete About window with MIT license and developer credit
**Depends on**: Nothing (independent of rendering)
**Requirements**: ABOUT-01, ABOUT-02
**Success Criteria** (what must be TRUE):
  1. About window displays MIT license attribution
  2. About window displays developer credit (app creator name)
**Plans**: TBD

Plans:
- [ ] 17-01: [TBD during planning]

## Progress

**Execution Order:**
Phases execute in numeric order: 16 → 17

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Foundation | v1.0 | 3/3 | Complete | 2026-02-02 |
| 2. Text Formatting | v1.0 | 2/2 | Complete | 2026-02-02 |
| 3. Block Elements | v1.0 | 4/4 | Complete | 2026-02-02 |
| 4. Links, Images, Tables | v1.0 | 3/3 | Complete | 2026-02-02 |
| 5. Performance & Dark Mode | v1.0 | 2/2 | Complete | 2026-02-02 |
| 6. Branding | v1.1 | 2/2 | Complete | 2026-02-05 |
| 7. App Icon | v1.1 | 2/2 | Complete | 2026-02-05 |
| 8. SwiftUI Host App | v1.1 | 3/3 | Complete | 2026-02-05 |
| 9. Distribution | v1.1 | 2/2 | Complete | 2026-02-05 |
| 10. Documentation | v1.1 | 2/2 | Complete | 2026-02-05 |
| 11. Width-Adaptive Layout | v1.2 | 4/4 | Complete | 2026-02-07 |
| 12. Responsive Tables | v1.2 | 4/4 | Complete | 2026-02-07 |
| 13. YAML Front Matter | v1.2 | 3/3 | Complete | 2026-02-07 |
| 14. Task Lists | v1.2 | 3/3 | Complete | 2026-02-07 |
| 15. Cross-Context Integration | v1.2 | 2/2 | Complete | 2026-02-07 |
| 16. Rendering Polish | v1.3 | 0/TBD | Not started | - |
| 17. About Window Polish | v1.3 | 0/TBD | Not started | - |

---
*Last updated: 2026-02-07 after v1.3 roadmap creation*
