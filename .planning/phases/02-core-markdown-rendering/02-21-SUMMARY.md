---
phase: 02-core-markdown-rendering
plan: 21
subsystem: rendering
tags: [swift, appkit, attributed-string, presentation-intent, markdown, list-rendering]

# Dependency graph
requires:
  - phase: 02-04
    provides: List prefix insertion in NSAttributedString
  - phase: 02-12
    provides: Ordinal tracking pattern for list item boundaries
provides:
  - Ordinal-based deduplication for list prefix insertion
  - Single prefix per list item regardless of inline formatting
affects: [list-rendering, inline-formatting]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ordinal tracking in insertListPrefixes() prevents duplicate prefixes for formatted items"
    - "Same pattern as insertBlockBoundaryNewlines() and ensureIntraBlockNewlines()"

key-files:
  created: []
  modified:
    - md-spotlighter/MDQuickLook/MarkdownRenderer.swift

key-decisions:
  - "Apply ordinal tracking pattern to insertListPrefixes() to prevent duplicate prefixes for list items with inline formatting"

patterns-established:
  - "Ordinal tracking pattern now used consistently across all list processing functions"

# Metrics
duration: 1min
completed: 2026-02-02
---

# Phase 2 Plan 21: Fix Duplicate List Prefixes Summary

**Ordinal tracking prevents duplicate prefixes for list items with inline formatting**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-02T04:09:10Z
- **Completed:** 2026-02-02T04:10:28Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Added ordinal tracking to insertListPrefixes() function
- Eliminated duplicate prefixes for list items with inline formatting
- "Third item with **bold**" now shows as "• Third item with bold" (one bullet, not two)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add ordinal tracking to insertListPrefixes** - `644858e` (fix)

## Files Created/Modified
- `md-spotlighter/MDQuickLook/MarkdownRenderer.swift` - Added lastProcessedOrdinal tracking to prevent duplicate list prefixes

## Decisions Made

**Apply ordinal tracking pattern to insertListPrefixes()**
- Rationale: All runs of the same list item have the same ordinal. Only the first run (when ordinal changes) should get a prefix. This follows the established pattern from insertBlockBoundaryNewlines() and ensureIntraBlockNewlines().
- Impact: List items with inline formatting (bold, italic, etc.) now render correctly with a single prefix instead of one prefix per formatting run.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Gap #29 is now closed. This completes the ordinal tracking pattern across all list-processing functions in MarkdownRenderer.

All list rendering issues have been addressed. Phase 2 gap closure continues.

---
*Phase: 02-core-markdown-rendering*
*Completed: 2026-02-02*
