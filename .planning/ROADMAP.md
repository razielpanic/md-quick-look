# Roadmap: md-spotlighter

## Overview

Deliver a working Quick Look extension for macOS that renders markdown files with essential formatting in Finder. Start with extension foundation and macOS integration, build core markdown rendering capabilities for all basic elements, add table support for GitHub-flavored markdown compatibility, and polish with performance optimization and system appearance support.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Extension Foundation** - Quick Look extension loads markdown files on macOS 26+
- [x] **Phase 2: Core Markdown Rendering** - Render essential markdown elements (headings, formatting, lists, code, blockquotes, links, images)
- [x] **Phase 3: Tables & Advanced Elements** - Render GitHub-flavored markdown tables
- [x] **Phase 4: Performance & Polish** - Instant rendering and system appearance support

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
**Plans**: 22 plans (3 original + 19 gap closure)

Plans:
- [x] 02-01-PLAN.md — Create MarkdownRenderer with heading hierarchy and inline formatting
- [x] 02-02-PLAN.md — Add code blocks, blockquotes with border, and list styling
- [x] 02-03-PLAN.md — Add link styling, image placeholders, and visual verification
- [x] 02-04-PLAN.md — (Gap closure 1) Fix list rendering and intra-block line breaks
- [x] 02-05-PLAN.md — (Gap closure 1) Fix image placeholder formatting and combined inline styles
- [x] 02-06-PLAN.md — (Gap closure 1) Fix code block background alignment and minor line breaks
- [x] 02-07-PLAN.md — (Gap closure 2) Fix image placeholder marker replacement (BLOCKER)
- [x] 02-08-PLAN.md — (Gap closure 2) Fix LayoutManager background/border gaps
- [x] 02-09-PLAN.md — (Gap closure 2) Fix list spacing and document newlines
- [x] 02-10-PLAN.md — (Gap closure 3) Enable Quick Look scrolling + verify image placeholders
- [x] 02-11-PLAN.md — (Gap closure 3) Fix blockquote border/background/spacing issues
- [x] 02-12-PLAN.md — (Gap closure 3) Fix list excessive spacing and inline formatting continuity
- [x] 02-13-PLAN.md — (Gap closure 4) Fix image placeholder rendering (BLOCKER regression)
- [x] 02-14-PLAN.md — (Gap closure 4) Fix list huge gaps (BLOCKER regression)
- [x] 02-15-PLAN.md — (Gap closure 4) Fix blockquote missing newline (MINOR)
- [x] 02-16-PLAN.md — (Gap closure 5) Fix image placeholder markers - use alphanumeric markers
- [x] 02-17-PLAN.md — (Gap closure 5) Fix list spacing - add paragraphStyle to prefix insertion
- [x] 02-18-PLAN.md — (Gap closure 6) Fix unordered list inline formatting split (BLOCKER)
- [x] 02-19-PLAN.md — (Gap closure 7) Fix list excessive spacing - remove duplicate newline insertion
- [x] 02-20-PLAN.md — (Gap closure 8) Fix blockquote excessive spacing (BLOCKER regression)
- [x] 02-21-PLAN.md — (Gap closure 8) Fix duplicate list item prefixes (BLOCKER)
- [x] 02-22-PLAN.md — (Gap closure 9) Fix blockquote soft break rendering (MAJOR)

### Phase 3: Tables & Advanced Elements
**Goal**: Render GitHub-flavored markdown tables
**Depends on**: Phase 2
**Requirements**: MDRNDR-09
**Success Criteria** (what must be TRUE):
  1. User sees markdown tables rendered with rows, columns, and borders
  2. User sees table headers visually distinguished from table body rows
  3. User sees table cell alignment (left, center, right) respected from markdown syntax
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Create TableExtractor and TableRenderer infrastructure
- [x] 03-02-PLAN.md — Integrate hybrid rendering in MarkdownRenderer with visual verification

### Phase 4: Performance & Polish
**Goal**: Instant rendering performance and system appearance integration
**Depends on**: Phase 3
**Requirements**: SYSINT-02, SYSINT-04
**Success Criteria** (what must be TRUE):
  1. User sees preview render in less than 1 second for typical markdown files (10-500KB)
  2. User sees preview respect macOS system appearance (light mode shows light preview, dark mode shows dark preview)
  3. User does not experience Finder UI freezing or delays when triggering Quick Look
**Plans**: 2 plans

Plans:
- [x] 04-01-PLAN.md — File size truncation for large files (>500KB) with user-friendly message
- [x] 04-02-PLAN.md — System color adoption for automatic dark mode support

### Phase 5: Documentation Sync
**Goal**: Update all verification and requirements documentation to reflect actual implementation state
**Depends on**: Phase 4
**Requirements**: None (documentation updates only)
**Gap Closure**: Closes documentation mismatches from milestone audit
**Success Criteria** (what must be TRUE):
  1. 02-VERIFICATION.md reflects final Phase 2 state (Gap #27 fixed, all 10 truths verified)
  2. ROADMAP.md Phase 4 shows correct completion status (2/2 plans complete)
  3. REQUIREMENTS.md marks SYSINT-02 and SYSINT-04 as complete
**Plans**: 2 plans (1 original + 1 gap closure)

Plans:
- [x] 05-01-PLAN.md — Sync verification files and requirements documentation with implementation state
- [x] 05-02-PLAN.md — (Gap closure) Update ROADMAP.md to reflect Phase 5 completion

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Extension Foundation | 2/2 | Complete | 2026-02-01 |
| 2. Core Markdown Rendering | 22/22 | Complete | 2026-02-02 |
| 3. Tables & Advanced Elements | 2/2 | Complete | 2026-02-02 |
| 4. Performance & Polish | 2/2 | Complete | 2026-02-02 |
| 5. Documentation Sync | 2/2 | Complete | 2026-02-02 |
