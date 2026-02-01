# Roadmap: md-spotlighter

## Overview

Deliver a working Quick Look extension for macOS that renders markdown files with essential formatting in Finder. Start with extension foundation and macOS integration, build core markdown rendering capabilities for all basic elements, add table support for GitHub-flavored markdown compatibility, and polish with performance optimization and system appearance support.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Extension Foundation** - Quick Look extension loads markdown files on macOS 26+
- [ ] **Phase 2: Core Markdown Rendering** - Render essential markdown elements (headings, formatting, lists, code, blockquotes, links, images)
- [ ] **Phase 3: Tables & Advanced Elements** - Render GitHub-flavored markdown tables
- [ ] **Phase 4: Performance & Polish** - Instant rendering and system appearance support

## Phase Details

### Phase 1: Extension Foundation
**Goal**: Quick Look extension loads markdown files from Finder on macOS 26+
**Depends on**: Nothing (first phase)
**Requirements**: SYSINT-01, SYSINT-03
**Success Criteria** (what must be TRUE):
  1. User can select a .md file in Finder and press spacebar to trigger Quick Look
  2. Quick Look extension launches and displays markdown content (even if basic/unstyled)
  3. Extension works on macOS 26 (Tahoe) and later versions
  4. Extension appears in System Settings as installed Quick Look plugin
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Create Xcode project with host app and Quick Look extension, implement PreviewViewController
- [x] 01-02-PLAN.md — Create build automation (Makefile) and verify extension works in Finder

### Phase 2: Core Markdown Rendering
**Goal**: Render all essential markdown elements with proper formatting
**Depends on**: Phase 1
**Requirements**: MDRNDR-01, MDRNDR-02, MDRNDR-03, MDRNDR-04, MDRNDR-05, MDRNDR-06, MDRNDR-07, MDRNDR-08, MDRNDR-10, MDRNDR-11
**Success Criteria** (what must be TRUE):
  1. User sees headings (h1-h6) with visual hierarchy (larger to smaller sizes)
  2. User sees bold text rendered with increased font weight
  3. User sees italic text rendered with oblique font style
  4. User sees strikethrough text rendered with line through characters
  5. User sees unordered lists with bullet points and proper indentation
  6. User sees ordered lists with numbers and proper indentation
  7. User sees code blocks with monospaced font and distinct background
  8. User sees blockquotes with visual differentiation (indentation or border)
  9. User sees links rendered as text (not clickable)
  10. User sees images rendered as placeholders showing `[Image: filename]`
**Plans**: 3 plans

Plans:
- [ ] 02-01-PLAN.md — Create MarkdownRenderer with heading hierarchy and inline formatting
- [ ] 02-02-PLAN.md — Add code blocks, blockquotes with border, and list styling
- [ ] 02-03-PLAN.md — Add link styling, image placeholders, and visual verification

### Phase 3: Tables & Advanced Elements
**Goal**: Render GitHub-flavored markdown tables
**Depends on**: Phase 2
**Requirements**: MDRNDR-09
**Success Criteria** (what must be TRUE):
  1. User sees markdown tables rendered with rows, columns, and borders
  2. User sees table headers visually distinguished from table body rows
  3. User sees table cell alignment (left, center, right) respected from markdown syntax
**Plans**: TBD

Plans:
- [ ] TBD

### Phase 4: Performance & Polish
**Goal**: Instant rendering performance and system appearance integration
**Depends on**: Phase 3
**Requirements**: SYSINT-02, SYSINT-04
**Success Criteria** (what must be TRUE):
  1. User sees preview render in less than 1 second for typical markdown files (10-50KB)
  2. User sees preview respect macOS system appearance (light mode shows light preview, dark mode shows dark preview)
  3. User does not experience Finder UI freezing or delays when triggering Quick Look
**Plans**: TBD

Plans:
- [ ] TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Extension Foundation | 2/2 | Complete | 2026-02-01 |
| 2. Core Markdown Rendering | 0/3 | Not started | - |
| 3. Tables & Advanced Elements | 0/TBD | Not started | - |
| 4. Performance & Polish | 0/TBD | Not started | - |
