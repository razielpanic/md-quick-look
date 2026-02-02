---
phase: 02-core-markdown-rendering
plan: 22
subsystem: rendering
tags: [markdown, commonmark, blockquote, soft-breaks, regex, preprocessing]

# Dependency graph
requires:
  - phase: 02-21
    provides: Duplicate list prefix fix via ordinal tracking
provides:
  - Blockquote soft break preprocessing converts soft breaks to hard breaks
  - Multi-line blockquotes render each line on separate visual line
  - preprocessBlockquoteSoftBreaks method in markdown preprocessing pipeline
affects: [Phase 3 - Advanced markdown features may need preprocessing pattern]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Regex-based markdown preprocessing before AttributedString parsing"
    - "Hard break insertion via trailing double-space pattern"

key-files:
  created: []
  modified:
    - md-spotlighter/MDQuickLook/MarkdownRenderer.swift

key-decisions:
  - "Convert blockquote soft breaks to hard breaks in preprocessing stage"
  - "Use regex pattern (>[^\n]*)\n(>) with replacement $1  \n$2 for hard breaks"

patterns-established:
  - "Markdown preprocessing pipeline: preprocessImages → preprocessBlockquoteSoftBreaks → AttributedString parsing"

# Metrics
duration: 2min
completed: 2026-02-02
---

# Phase 02 Plan 22: Blockquote Soft Break Preprocessing Summary

**Blockquote soft breaks converted to hard breaks via preprocessing, ensuring multi-line blockquotes render each line separately**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-02T00:11:54Z
- **Completed:** 2026-02-02T00:13:22Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added preprocessBlockquoteSoftBreaks method to convert soft breaks to hard breaks in blockquotes
- Integrated preprocessing into render pipeline before AttributedString parsing
- Multi-line blockquotes now display each `>` line on separate visual line instead of collapsing to single line
- Solves CommonMark-compliant AttributedString converting soft breaks to spaces

## Task Commits

Each task was committed atomically:

1. **Task 1: Add blockquote soft break preprocessing** - `f77f0e3` (feat)
   - Added preprocessBlockquoteSoftBreaks(in:) method
   - Pattern: `(>[^\n]*)\n(>)` replaced with `$1  \n$2`
   - Two trailing spaces create CommonMark hard break
   - Integrated into preprocessing pipeline

2. **Task 2: Build, install, and verify blockquote rendering** - No commit (verification only)
   - Built and installed extension successfully
   - Verified blockquote rendering behavior

## Files Created/Modified
- `md-spotlighter/MDQuickLook/MarkdownRenderer.swift` - Added preprocessBlockquoteSoftBreaks method and integrated into render pipeline

## Decisions Made

**Convert blockquote soft breaks to hard breaks in preprocessing stage**
- Rationale: AttributedString(markdown:) is CommonMark-compliant and converts soft breaks (single newlines) to spaces within paragraphs. This causes multi-line blockquotes to collapse. Adding two trailing spaces before newlines within blockquotes converts them to hard breaks, preserving line separation.

**Use regex pattern (>[^\n]*)\n(>) with replacement $1  \n$2**
- Rationale: Pattern matches blockquote line content followed by newline when next line also starts with `>` (continuation). Replacement adds two trailing spaces before newline, creating CommonMark hard break.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Gap #28 from UAT Round 10 closed. Blockquote line rendering now correct. Ready for next gap closure or Phase 3 planning.

---
*Phase: 02-core-markdown-rendering*
*Completed: 2026-02-02*
