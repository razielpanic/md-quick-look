---
phase: 02-core-markdown-rendering
plan: 15
subsystem: rendering
tags: [swift, appkit, blockquote, newline, gap-closure]

# Dependency graph
requires:
  - phase: 02-11
    provides: Blockquote rendering with range merging and continuation detection
  - phase: 02-09
    provides: Block identity tracking and newline insertion logic
provides:
  - Simplified blockquote newline logic for proper paragraph separation
  - Consistent intra-block newline handling across list items and blockquotes
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Uniform intra-block newline handling: list items and blockquotes use same logic"
    - "Trust block boundary detection to prevent double-newlines between blocks"

key-files:
  created: []
  modified:
    - md-spotlighter/MDQuickLook/MarkdownRenderer.swift

key-decisions:
  - "Remove blockquote continuation peek-ahead logic from ensureIntraBlockNewlines()"
  - "Treat blockquotes like list items: always add newline at end if missing"
  - "Trust insertBlockBoundaryNewlines() to handle double-newline prevention"

patterns-established:
  - "Intra-block newlines: Always add if missing, let boundary detection handle spacing between blocks"
  - "Separation of concerns: ensureIntraBlockNewlines() adds run-ending newlines, insertBlockBoundaryNewlines() prevents double-spacing"

# Metrics
duration: 1min
completed: 2026-02-02
---

# Phase 02 Plan 15: Blockquote Newline Fix Summary

**Simplified blockquote newline logic to ensure proper paragraph separation within multi-paragraph blockquotes**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-02T02:14:00Z
- **Completed:** 2026-02-02T02:14:53Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Fixed missing newlines between blockquote paragraphs (Gap #20)
- Simplified blockquote handling to match list item logic
- Eliminated complex peek-ahead logic that was causing overcorrection
- Restored proper paragraph separation without reintroducing double-newlines

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix blockquote newline logic** - `59ec719` (fix)

## Files Created/Modified
- `md-spotlighter/MDQuickLook/MarkdownRenderer.swift` - Simplified blockquote newline insertion logic

## Decisions Made

**1. Remove blockquote continuation peek-ahead logic from ensureIntraBlockNewlines()**
- The peek-ahead logic (lines 213-236) was checking if the next run was also a blockquote
- Only added newline if current run was "last blockquote run"
- This prevented newlines between blockquote paragraphs within the same blockquote block
- Overcorrection from plan 02-11's double-newline fix

**2. Treat blockquotes like list items: always add newline at end if missing**
- List items always get newlines at the end (lines 203-209)
- Blockquotes should use the same logic
- Each blockquote paragraph/line needs its own newline for proper visual separation
- Simpler, more predictable behavior

**3. Trust insertBlockBoundaryNewlines() to handle double-newline prevention**
- The block boundary detection (lines 87-170) already prevents double-newlines between different blocks
- It checks block identity and component type changes
- No need for duplicate logic in ensureIntraBlockNewlines()
- Clear separation of concerns: boundary detection handles spacing between blocks, intra-block handling adds run-ending newlines

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None - the analysis in the plan was correct. The peek-ahead logic was indeed the cause of missing newlines between blockquote paragraphs.

## Root Cause Analysis

**Why the bug appeared:**
- Plan 02-11 added blockquote continuation detection to prevent double-newlines
- It worked by checking if the next run was also a blockquote
- Only added newline if it was the "last blockquote run" in the sequence
- This logic was correct for preventing double-newlines *between* different blockquote blocks
- But it also prevented newlines *within* a single multi-paragraph blockquote
- The markdown parser creates separate runs for each paragraph within a blockquote
- So "This is paragraph 1.\n\nThis is paragraph 2." becomes two runs, both marked as blockquote
- The peek-ahead logic saw the second paragraph was also a blockquote and didn't add a newline after the first

**Why the fix works:**
- Remove the peek-ahead complexity entirely from ensureIntraBlockNewlines()
- Let each blockquote run end with a newline (same as list items)
- The insertBlockBoundaryNewlines() function already has sophisticated logic to detect block boundaries
- It tracks block identity (different paragraph instances) and component types
- It will prevent double-newlines between different blocks automatically
- The two functions now have clear responsibilities:
  - ensureIntraBlockNewlines: "Make sure runs end with newlines"
  - insertBlockBoundaryNewlines: "Prevent double-spacing at boundaries"

## Next Phase Readiness

**Ready for next gap closure:** Yes - blockquote rendering is now complete

**Blockers:** None

**Remaining gaps from UAT round 5:**
- Gap #21: Unordered list huge gaps (requires investigation)
- Gap #22: Ordered list huge gaps (requires investigation)
- Gap #23: Image placeholder rendering broken (requires re-work)

Note: List gaps (#21, #22) are regressions - plan 02-12 fixes did not work. Need to debug why `paragraphSpacing = 0` didn't resolve the huge gaps.

---
*Phase: 02-core-markdown-rendering*
*Completed: 2026-02-02*
