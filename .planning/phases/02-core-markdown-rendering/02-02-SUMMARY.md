---
phase: 02-core-markdown-rendering
plan: 02
subsystem: markdown-rendering
tags: [swift, appkit, nslayoutmanager, presentationintent, markdown]

# Dependency graph
requires:
  - phase: 02-01
    provides: MarkdownRenderer foundation with heading styles
provides:
  - Code block styling (SF Mono font, background colors)
  - Inline code styling (lighter background than blocks)
  - List indentation (bullets and numbered lists)
  - Blockquote styling (background, indentation, left border bar)
  - Custom NSLayoutManager for blockquote border drawing
  - Custom text stack architecture (NSTextStorage -> MarkdownLayoutManager -> NSTextContainer)
affects: [02-03-links-and-images, performance-rendering]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Custom NSAttributedString.Key for cross-file attribute sharing"
    - "Custom NSLayoutManager for decorative drawing beyond attribute capabilities"
    - "Full text stack creation pattern (storage -> layout manager -> container -> view)"

key-files:
  created:
    - md-spotlighter/MDQuickLook/MarkdownLayoutManager.swift
  modified:
    - md-spotlighter/MDQuickLook/MarkdownRenderer.swift
    - md-spotlighter/MDQuickLook/PreviewViewController.swift
    - md-spotlighter/md-spotlighter.xcodeproj/project.pbxproj

key-decisions:
  - "PresentationIntent doesn't bridge to NSAttributedString - use custom blockquoteMarker attribute instead"
  - "Inline code gets lighter background (quaternarySystemFill) vs code blocks (secondarySystemFill)"
  - "Code blocks wrap text by default (no horizontal scroll)"
  - "Blockquote border drawn via custom NSLayoutManager.drawBackground"

patterns-established:
  - "Custom NSLayoutManager subclass pattern for decorative drawing"
  - "Separate block-level and inline styling methods in MarkdownRenderer"
  - "Custom attributes for layout manager communication"

# Metrics
duration: 4min
completed: 2026-02-01
---

# Phase 2 Plan 2: Block Element Styling Summary

**SF Mono code blocks with backgrounds, GitHub-style blockquote borders via custom NSLayoutManager, and proper list indentation**

## Performance

- **Duration:** 4 min
- **Started:** 2026-02-01T01:00:38Z
- **Completed:** 2026-02-01T01:05:08Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments
- Code blocks render with SF Mono font and semantic background colors
- Inline code distinguished from code blocks via lighter background
- Lists properly indented with bullets and numbers
- Blockquotes have GitHub-style left vertical border bar via custom NSLayoutManager
- All styling adapts to system appearance (Dark Mode support)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add code block and list styling to MarkdownRenderer** - `4750431` (feat)
2. **Task 2: Create MarkdownLayoutManager for blockquote borders** - `e4d9502` (feat)
3. **Task 3: Wire up custom text stack in PreviewViewController** - `7e2c623` (feat)

## Files Created/Modified
- `md-spotlighter/MDQuickLook/MarkdownRenderer.swift` - Added code block, inline code, list, and blockquote styling
- `md-spotlighter/MDQuickLook/MarkdownLayoutManager.swift` - Custom layout manager for drawing blockquote border bars
- `md-spotlighter/MDQuickLook/PreviewViewController.swift` - Custom text stack with MarkdownLayoutManager
- `md-spotlighter/md-spotlighter.xcodeproj/project.pbxproj` - Added MarkdownLayoutManager.swift to build

## Decisions Made

**1. PresentationIntent doesn't bridge to NSAttributedString**
- Discovered that PresentationIntent attributes don't convert when creating NSAttributedString from AttributedString
- Solution: Created custom `.blockquoteMarker` attribute that MarkdownRenderer adds when detecting blockquotes
- MarkdownLayoutManager enumerates this custom attribute instead of PresentationIntent
- Pattern establishes how to communicate intent from renderer to layout manager

**2. Inline code background differentiation**
- Inline code uses `quaternarySystemFill` (lighter)
- Code blocks use `secondarySystemFill` (more prominent)
- Provides subtle visual distinction while maintaining consistency

**3. Code block line wrapping**
- Chose to wrap long lines (NSTextView default with widthTracksTextView)
- Horizontal scroll would require custom NSScrollView configuration
- Wrapping simpler and more common in Quick Look context

**4. Blockquote border via custom NSLayoutManager**
- NSAttributedString has no built-in border attribute
- Custom NSLayoutManager.drawBackground method draws vertical bar
- Cleanly separates visual decoration from content attributes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added MarkdownLayoutManager.swift to Xcode project**
- **Found during:** Task 3 (Custom text stack wiring)
- **Issue:** New Swift file not included in Xcode project build - compiler couldn't find MarkdownLayoutManager class
- **Fix:** Manually edited project.pbxproj to add PBXFileReference, PBXBuildFile, group entry, and sources phase entry
- **Files modified:** md-spotlighter/md-spotlighter.xcodeproj/project.pbxproj
- **Verification:** Build succeeded after project file update
- **Committed in:** 7e2c623 (Task 3 commit)

**2. [Rule 3 - Blocking] Fixed PresentationIntent bridging issue**
- **Found during:** Task 3 build (Compiler error on MarkdownLayoutManager)
- **Issue:** `.presentationIntent` is not a valid NSAttributedString.Key - PresentationIntent doesn't bridge to NSAttributedString
- **Fix:** Created custom `.blockquoteMarker` NSAttributedString.Key extension, added attribute in MarkdownRenderer, enumerated in MarkdownLayoutManager
- **Files modified:** MarkdownLayoutManager.swift, MarkdownRenderer.swift
- **Verification:** Build succeeded, pattern documented for future use
- **Committed in:** 7e2c623 (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both fixes necessary for compilation. Discovered important AttributedString → NSAttributedString conversion limitation that affects architecture pattern.

## Issues Encountered

**PresentationIntent doesn't bridge to NSAttributedString**
- This is a fundamental limitation of the AttributedString/NSAttributedString bridging
- PresentationIntent is SwiftUI-specific and doesn't convert to AppKit attributes
- Established pattern: MarkdownRenderer reads PresentationIntent and adds custom NSAttributedString attributes for communication to other components (like MarkdownLayoutManager)
- This pattern will apply to any future features needing PresentationIntent information in NSAttributedString context

## Next Phase Readiness
- Block-level element styling complete (headings from 02-01, code/lists/blockquotes from 02-02)
- Ready for Plan 03: Links and image placeholders
- MarkdownRenderer architecture supports easy addition of new element types
- Custom attribute pattern established for complex rendering needs

---
*Phase: 02-core-markdown-rendering*
*Completed: 2026-02-01*
