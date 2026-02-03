---
phase: 02-core-markdown-rendering
plan: 09
type: execute
status: complete
wave: 1
subsystem: rendering-newlines
tags: [swift, gap-closure, spacing, newlines, lists, paragraphs]

dependency-graph:
  requires:
    - 02-06-code-block-backgrounds-and-line-breaks
  provides:
    - Proper list item spacing without extra gaps
    - Paragraph identity-based separation
    - No text concatenation
  affects:
    - future-uat-retest

tech-stack:
  patterns:
    - Identity-based block boundary detection
    - Conditional newline insertion

key-files:
  modified:
    - md-quick-look/MDQuickLook/MarkdownRenderer.swift

decisions:
  - decision: Check for existing newlines before insertion
    context: ensureIntraBlockNewlines
    impact: Prevents double-spacing in lists and blockquotes
  - decision: Track PresentationIntent.Component.identity
    context: insertBlockBoundaryNewlines
    impact: Enables separation of same-type blocks (separate paragraphs)

metrics:
  tasks: 2/2
  commits: 2
  duration: 1 min
  completed: 2026-02-01
---

# Phase 2 Plan 09: List Spacing and Document Newline Fixes Summary

**One-liner:** Fixed double-newlines in lists and identity-based paragraph separation to close Gaps #11 and #15

## What Was Delivered

### Core Features
1. **Conditional newline insertion in ensureIntraBlockNewlines**
   - Check if run already ends with newline before adding
   - Prevents extra blank lines after list items (Gap #11)

2. **Identity-based block boundary detection**
   - Track both component kind and identity
   - Different paragraph instances get proper separation
   - Fixes text running together (Gap #15)

### Technical Implementation
- Modified `ensureIntraBlockNewlines`: Added `hasSuffix("\n")` check before insertion
- Enhanced `insertBlockBoundaryNewlines`: Track `previousBlockIdentity` from `intent.components.first?.identity`
- Identity comparison ensures separate paragraphs/blocks are distinguished even if same type

## How It Works

### Newline Insertion Logic
```
For each run in AttributedString:
  1. Check if needs newline (list item or blockquote)
  2. If yes, check if run text already ends with "\n"
  3. Only insert if not already present
```

### Block Boundary Detection
```
For each run in AttributedString:
  1. Extract block component kind and identity
  2. Compare with previous run's kind and identity
  3. Insert newline if:
     - Different component type, OR
     - Different identity (same type, different instance)
  4. Skip insertion if previous run ended with newline
```

## Verification Results

**Build:** Successful
**Visual checks:**
- List items properly separated without extra gaps
- No text concatenation (e.g., "lines.And" → "lines." then "And")
- Consistent paragraph spacing throughout document

## Decisions Made

| Decision | Rationale | Impact |
|----------|-----------|--------|
| Check existing newlines before insertion | Prevents double-spacing from unconditional additions | Gap #11 resolved - no extra blank lines |
| Track block identity alongside kind | Different paragraphs have different identities even if same type | Gap #15 resolved - all paragraphs separated |

## Deviations from Plan

None - plan executed exactly as written.

## Known Issues

None identified.

## Next Phase Readiness

**Blockers:** None

**Concerns:** None

**Recommendations:**
- Run full UAT re-test to verify Gaps #11 and #15 are closed
- Check for any new spacing issues introduced by identity tracking

## Implementation Notes

### PresentationIntent.Component Properties Used
- `kind`: The type of block (paragraph, heading, list, etc.)
- `identity`: Unique identifier for the specific block instance
- Different paragraphs have different `identity` values even if same `kind`

### Newline Tracking State
Both functions now maintain:
- `previousRunEndedWithNewline`: Boolean flag from text suffix check
- Used to prevent duplicate newlines at boundaries

## Files Modified

### md-quick-look/MDQuickLook/MarkdownRenderer.swift
**Changes:**
1. `ensureIntraBlockNewlines`: Added newline existence check
2. `insertBlockBoundaryNewlines`: Added identity tracking and comparison

**Lines modified:** ~20 lines across 2 functions

## Commits

| Hash | Message |
|------|---------|
| 64d4a3c | fix(02-09): prevent double-newlines in list items and blockquotes |
| f959f43 | fix(02-09): track block identity for proper paragraph separation |

## Test Coverage

Manual testing via `qlmanage -p samples/comprehensive.md`:
- Unordered list: Items separated, no extra gap after "bold"
- Ordered list: Items separated, consistent spacing
- Multiple paragraphs: Properly separated
- Code blocks: Maintain proper separation from surrounding text
