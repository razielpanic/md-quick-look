# Milestone v1.2: Rendering Polish & Features

**Status:** In Progress
**Phases:** 11-15
**Total Plans:** 9

## Overview

v1.2 enhances the Quick Look extension's rendering pipeline to handle real-world markdown documents gracefully across all Finder presentation contexts. The journey starts with YAML front matter preprocessing (which must happen before all other parsing), then establishes width-aware layout detection (foundational for downstream rendering), makes tables responsive to available space, adds GFM task list checkboxes as visual elements, and concludes with cross-context integration testing to verify all features work together in spacebar popup, preview pane, and fullscreen Quick Look.

## Phases

- [x] **Phase 11: YAML Front Matter** - Detect, extract, and display YAML metadata blocks before markdown parsing
- [x] **Phase 12: Layout & Sizing** - Detect available width and adapt fonts, padding, and text layout to context
- [x] **Phase 13: Table Rendering** - Scale table widths, columns, and padding to fit available container space
- [x] **Phase 14: Task List Checkboxes** - Render GFM task list items with SF Symbol checkboxes
- [ ] **Phase 15: Cross-Context Integration** - Verify all features render correctly across all Quick Look contexts

## Phase Details

### Phase 11: YAML Front Matter
**Goal**: Users see YAML front matter displayed as a clean, styled metadata section instead of garbled markdown artifacts
**Depends on**: Nothing (first phase; preprocessing step that must precede all other pipeline changes)
**Requirements**: YAML-01, YAML-02, YAML-03, YAML-04, YAML-05, YAML-06
**Success Criteria** (what must be TRUE):
  1. A markdown file with `---` delimited YAML front matter at the top shows a visually distinct metadata section (bold keys, normal values) above the rendered body
  2. The `---` delimiters no longer appear as horizontal rules or garbled headings in the preview
  3. List values in front matter (e.g., `tags: [a, b, c]`) display as comma-separated inline text, not raw YAML syntax
  4. Files without front matter render exactly as before (no regression)
  5. Edge cases handled: empty front matter block, Windows line endings, missing closing delimiter all produce reasonable output without crashes
**Plans:** 1 plan
Plans:
- [x] 11-01-PLAN.md -- YAML extraction, parsing, styled rendering, and visual verification

### Phase 12: Layout & Sizing
**Goal**: The extension adapts its rendering to the available width, producing readable output whether in a spacebar popup, narrow Finder preview pane, or fullscreen Quick Look
**Depends on**: Phase 11 (clean markdown pipeline established)
**Requirements**: LAYOUT-01, LAYOUT-02, LAYOUT-03, LAYOUT-04
**Success Criteria** (what must be TRUE):
  1. Quick Look window sizing is system-managed with proper autoresizing -- no hardcoded preferredContentSize that breaks resize behavior
  2. The extension detects narrow contexts (Finder preview pane ~260px) and passes available width to the renderer
  3. Font sizes scale down proportionally in narrow contexts so headings, body text, and code all remain readable without clipping
  4. Text container insets and padding shrink in narrow contexts, maximizing content visibility in limited space
**Plans:** 2 plans
Plans:
- [x] 12-01-PLAN.md -- WidthTier enum, width-aware MarkdownRenderer and TableRenderer
- [x] 12-02-PLAN.md -- PreviewViewController wiring, LayoutManager adaptation, visual verification

### Phase 13: Table Rendering
**Goal**: Tables remain readable and properly sized in any Quick Look context, from narrow preview pane to fullscreen
**Depends on**: Phase 12 (requires availableWidth parameter from layout detection)
**Requirements**: TABLE-01, TABLE-02, TABLE-03, TABLE-04, TABLE-05
**Success Criteria** (what must be TRUE):
  1. Table total width scales to match the available container width instead of overflowing or clipping
  2. Column min/max widths scale proportionally so narrow contexts show balanced columns, not one giant column and one crushed column
  3. A compact table mode activates at very narrow widths with smaller font and reduced padding to maximize data visibility
  4. Tables in the Finder preview pane are readable -- all cell content visible, no silent clipping of text
**Plans:** 2 plans
Plans:
- [x] 13-01-PLAN.md -- Available-width pipeline, content-proportional column sizing, compact mode
- [x] 13-02-PLAN.md -- Smart wrap/truncate hybrid, table spacing, build verification

### Phase 14: Task List Checkboxes
**Goal**: GFM task list items render as visual checkboxes that match native macOS appearance
**Depends on**: Phase 11 (clean markdown for AST parsing), Phase 12 (width-aware rendering context)
**Requirements**: TASK-01, TASK-02, TASK-03, TASK-04, TASK-05, TASK-06
**Success Criteria** (what must be TRUE):
  1. `- [ ]` items display an empty checkbox (SF Symbol circle) and `- [x]` items display a filled checkbox (SF Symbol checkmark.circle.fill)
  2. Checkboxes are colored with system accent blue and vertically aligned with the text baseline of their list item
  3. Mixed lists containing both regular bullet items and task list items render correctly -- bullets for regular items, checkboxes for task items
  4. Task list syntax inside code blocks is NOT converted to checkboxes (rendered as literal text)
**Plans:** 1 plan
Plans:
- [x] 14-01-PLAN.md -- Task list preprocessing, SF Symbol checkbox rendering, visual verification

### Phase 15: Cross-Context Integration
**Goal**: All v1.2 features work together correctly across every Quick Look presentation context
**Depends on**: Phase 14 (all features implemented)
**Requirements**: LAYOUT-05
**Success Criteria** (what must be TRUE):
  1. A markdown file containing YAML front matter, tables, and task lists renders correctly in spacebar popup Quick Look
  2. The same file renders correctly in Finder column view preview pane (narrow context) with scaled fonts, responsive tables, and properly sized checkboxes
  3. The same file renders correctly in fullscreen Quick Look with appropriate use of available space
  4. Switching between contexts (e.g., spacebar then fullscreen) does not produce layout artifacts or stale rendering
**Plans:** 2 plans
Plans:
- [ ] 15-01-PLAN.md -- Snapshot test infrastructure, test target setup, comprehensive test file
- [ ] 15-02-PLAN.md -- Record baselines, visual defect review, rendering fixes, verification

## Progress

**Execution Order:** 11 -> 12 -> 13 -> 14 -> 15

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 11. YAML Front Matter | v1.2 | 1/1 | Complete | 2026-02-06 |
| 12. Layout & Sizing | v1.2 | 2/2 | Complete | 2026-02-06 |
| 13. Table Rendering | v1.2 | 2/2 | Complete | 2026-02-07 |
| 14. Task List Checkboxes | v1.2 | 1/1 | Complete | 2026-02-07 |
| 15. Cross-Context Integration | v1.2 | 0/2 | Not started | - |
