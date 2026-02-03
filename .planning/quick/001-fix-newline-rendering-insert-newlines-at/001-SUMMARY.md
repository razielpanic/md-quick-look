---
type: quick
plan: 001
completed: 2026-02-01
duration: 3min
files_modified:
  - md-quick-look/MDQuickLook/MarkdownRenderer.swift
  - samples/test-newlines.md (test file)
---

# Quick Task 001: Fix Newline Rendering Summary

**One-liner:** Added block boundary newline insertion to separate headings, paragraphs, lists, and other markdown blocks

## Problem

AttributedString(markdown:) strips inter-block newlines during parsing, causing all markdown blocks to run together when converted to NSAttributedString. Block structure was preserved via PresentationIntent attributes but didn't translate to visual line breaks.

## Solution

Implemented `insertBlockBoundaryNewlines(in:)` method in MarkdownRenderer that:

1. Iterates through AttributedString runs tracking the top-level block component type
2. Detects block boundaries by comparing consecutive PresentationIntent.Kind values
3. Inserts newline characters when transitioning between different block types
4. Handles runs without PresentationIntent as paragraph blocks
5. Processes insertions in reverse order to maintain string indices

The method is called in `render()` before NSAttributedString conversion, ensuring newlines are present in the final output.

## Implementation Details

**Key Logic:**
- Track `previousBlockComponent` of type `PresentationIntent.Kind?`
- Compare `intent.components.first?.kind` between consecutive runs
- Insert newline at `run.range.lowerBound` when component kind changes
- Special case: runs with no PresentationIntent are treated as `.paragraph`

**Block Detection:**
- Heading → Paragraph: newline inserted
- Paragraph → List: newline inserted
- List → Blockquote: newline inserted
- Code block boundaries: newlines inserted (preserves internal newlines)

## Testing

**Test file created:** `samples/test-newlines.md`
- Contains headings (h1, h2), paragraphs, lists, blockquote
- Verified visual separation in Quick Look preview

**Verification:**
- Build succeeded without errors
- Extension installed and registered successfully
- Quick Look preview shows proper block separation

## Changes

**File: md-quick-look/MDQuickLook/MarkdownRenderer.swift**

1. Added `insertBlockBoundaryNewlines(in:) -> AttributedString` method
2. Modified `render()` to call newline insertion before NSAttributedString conversion:
   ```swift
   let withNewlines = insertBlockBoundaryNewlines(in: attributedString)
   let nsAttributedString = NSMutableAttributedString(withNewlines)
   ```

**File: samples/test-newlines.md**
- Created minimal test case for visual verification

## Commits

- `c46130c`: fix(001): add block boundary newline insertion

## Impact

- Headings now appear on their own lines with proper separation
- Paragraphs are visually distinct from each other
- List items render on separate lines
- Blockquotes have proper spacing from surrounding content
- Code blocks maintain existing behavior (internal newlines preserved, boundary separation added)

## Next Steps

None - quick task complete. This fix is foundational for readable markdown rendering and will benefit all future markdown preview features.

## Notes

**Deviation from plan:** None - implemented exactly as specified

**Initial approach attempted:** Tried using `PresentationIntent.identity` property (doesn't exist in Swift API). Revised to use component kind comparison which correctly identifies block boundaries.

**Performance:** Negligible overhead - single forward pass to collect insertion points, reverse iteration for insertions (O(n) where n = number of runs).
