---
phase: 02
plan: 03
subsystem: rendering
tags: [links, images, placeholders, styling, debugging]

requires: [02-02]
provides: [link-styling, image-placeholders, paragraph-spacing]
affects: [02-04]

tech-stack:
  added: []
  patterns: [SF-Symbols, NSTextAttachment, text-attachment-bounds]

key-files:
  created: [samples/comprehensive.md]
  modified:
    - md-spotlighter/MDQuickLook/MarkdownRenderer.swift
    - md-spotlighter/MDQuickLook/MarkdownLayoutManager.swift

decisions:
  - key: default-paragraph-spacing
    choice: 8pt spacing for all text elements
    rationale: Ensures visual separation between paragraphs without explicit styling
    date: 2026-02-01
  - key: image-placeholder-format
    choice: SF Symbol icon + text description
    rationale: Visual indicator without loading actual images in Quick Look
    date: 2026-02-01
  - key: blockquote-border-position
    choice: Border at x=4-8, text starts at x=20
    rationale: Prevents border from intersecting with text content
    date: 2026-02-01

metrics:
  duration: 1 min
  completed: 2026-02-01
---

# Phase 02 Plan 03: Links and Image Placeholders Summary

**One-liner:** Blue underlined links, SF Symbol image placeholders, paragraph spacing for all text elements

## What Was Built

### Link Styling
- Links rendered in system blue with underline
- Uses .link attribute from AttributedString markdown parsing
- Non-clickable (Quick Look context)

### Image Placeholders
- Converts markdown image syntax `![alt](url)` to placeholders
- Displays SF Symbol "photo" icon + "[Image: filename]" text
- Regex preprocessing before markdown parsing
- NSTextAttachment with explicit bounds for icon display

### Comprehensive Test File
- Created samples/comprehensive.md with all supported elements
- Tests headings, formatting, code blocks, lists, blockquotes, links, images
- Used for Quick Look verification

### Critical Fixes (Post-Verification)
- **Paragraph spacing:** Added default 8pt spacing to ALL text elements
- **Blockquote border:** Repositioned from x=8 to x=4 to prevent text intersection
- **Image icon:** Added explicit bounds to NSTextAttachment for SF Symbol display

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Missing paragraph spacing throughout**
- **Found during:** Task 3 verification
- **Issue:** All text running together - no spacing between paragraphs, headings, lists
- **Root cause:** Only specific elements (headings, code blocks) had paragraphSpacing set; regular body text had none
- **Fix:** Added default paragraphSpacing (8pt) to all text in applyBaseStyles
- **Files modified:** MarkdownRenderer.swift
- **Commit:** 4db7c11

**2. [Rule 1 - Bug] Blockquote border intersecting text**
- **Found during:** Task 3 verification
- **Issue:** Vertical blue bar overlapping blockquote text instead of being positioned to left
- **Root cause:** Bar at x=8 while text indentation starts at x=20, causing overlap
- **Fix:** Moved bar from x=8 to x=4 (bar now spans 4-8, text starts at 20)
- **Files modified:** MarkdownLayoutManager.swift
- **Commit:** 7024352

**3. [Rule 2 - Missing Critical] Image icon not displaying**
- **Found during:** Task 3 verification
- **Issue:** SF Symbol "photo" icon not appearing in image placeholders
- **Root cause:** NSTextAttachment needs explicit bounds to display correctly
- **Fix:** Added bounds setting: CGRect(x: 0, y: -3, width: 14, height: 14)
- **Files modified:** MarkdownRenderer.swift
- **Commit:** 4db7c11 (combined with spacing fix)

## Technical Decisions Made

**Default paragraph spacing approach:**
- Set baseline 8pt spacing in applyBaseStyles for all text
- Element-specific styles (headings, code blocks) can override
- Ensures consistent spacing without explicit per-element configuration

**Image preprocessing with regex:**
- Convert markdown images to placeholder markers before parsing
- Allows AttributedString to process placeholders as plain text
- Post-processing replaces markers with styled NSAttributedString

**SF Symbol attachment bounds:**
- Explicit bounds required for NSTextAttachment display
- Y offset (-3) vertically centers icon with text baseline
- Size (14x14) matches body font size

**Blockquote border positioning:**
- Fixed position before text indentation
- Bar at 4-8, text at 20+ ensures 12pt gap
- Prevents visual intersection issues

## Verification Results

**Initial verification (Task 3):**
- User found 3 issues: missing line feeds, border intersection, missing icons
- All correctly identified as bugs requiring fixes (deviation Rules 1-2)

**Post-fix verification (pending):**
- Fixes committed and extension rebuilt
- Ready for user verification of corrected rendering

## Next Phase Readiness

**Blockers:** None

**Concerns:** None

**Ready for 02-04:** Yes
- Link and image placeholder infrastructure complete
- Paragraph spacing foundation solid
- Next: Table rendering (final element type)

## Performance Notes

- Execution fast (1 min total including fixes)
- Human verification found bugs immediately
- Fix-rebuild-test cycle: ~1 min

## Files Changed

**Created:**
- samples/comprehensive.md (79 lines)

**Modified:**
- md-spotlighter/MDQuickLook/MarkdownRenderer.swift
  - Added link styling in applyLinkStyles
  - Added image preprocessing regex
  - Added image placeholder creation with SF Symbol
  - Added default paragraph spacing in applyBaseStyles
  - Added explicit bounds for image icon attachment
- md-spotlighter/MDQuickLook/MarkdownLayoutManager.swift
  - Repositioned blockquote border from x=8 to x=4

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| ef848a1 | feat | Add link styling and image placeholders to MarkdownRenderer |
| 75d3969 | feat | Add comprehensive markdown test file |
| 4db7c11 | fix | Add paragraph spacing to all text elements |
| 7024352 | fix | Correct blockquote border position |

## Key Learnings

**NSAttributedString paragraph spacing:**
- Must set default for ALL text, not just specific elements
- Element-specific overrides work correctly when default exists
- Missing default causes text to run together

**NSTextAttachment display:**
- SF Symbol images require explicit bounds setting
- Y offset needed for baseline alignment
- Size should match surrounding text size

**Layout coordinate debugging:**
- Bar position must account for text indentation
- Visual intersection issues need geometric analysis
- Fixed positions need margin from dynamic content

## Dependencies

**Required from previous phases:**
- 02-02: Block element styling and custom attributes pattern
- 02-01: MarkdownRenderer architecture
- 01-02: Extension build and install infrastructure

**Provides for future phases:**
- Link styling foundation (if links become clickable in v2)
- Image placeholder pattern (for actual image rendering in v2)
- Paragraph spacing baseline for all text rendering
