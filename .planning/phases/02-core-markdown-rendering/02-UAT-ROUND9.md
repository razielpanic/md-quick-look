# UAT Round 9 Results - After Gap Closure Round 7

**Date:** 2026-02-02T03:50:00Z
**Tester:** User
**Test Command:** `qlmanage -p samples/comprehensive.md`
**Status:** FAILED — 8/10 tests passed, 2 new gaps found (regressions from Gap #27 fix)

## Test Results

| # | Element | Expected | Actual | Status |
|---|---------|----------|--------|--------|
| 1 | Headings | Visual hierarchy h1-h6 | ✓ Correct | PASS |
| 2 | Bold | Increased font weight | ✓ Correct | PASS |
| 3 | Italic | Oblique font style | ✓ Correct | PASS |
| 4 | Strikethrough | Line through text | ✓ Correct | PASS |
| 5 | Unordered Lists | Bullets, proper spacing, inline formatting | ✗ Duplicate bullet prefixes - "• Third item with • bold" | **FAIL** |
| 6 | Ordered Lists | Numbers, proper spacing | ✓ Correct | PASS |
| 7 | Code Blocks | Monospace, distinct background | ✓ Correct | PASS |
| 8 | Blockquotes | Visual differentiation | ✗ Excessive spacing between lines | **FAIL** |
| 9 | Links | Blue text, not clickable | ✓ Correct | PASS |
| 10 | Images | Placeholders with "[Image: filename]" | ✓ Correct | PASS |

**Score:** 8/10 tests passed

## Gaps Found (Regressions from Gap #27 Fix)

### Gap #28: Blockquote Excessive Spacing (BLOCKER)

**Symptom:** Large gaps (extra blank lines) between blockquote lines/paragraphs

**Evidence from screenshot:**
```
> This is a blockquote.
[large gap]
> It can span multiple lines.
[large gap]
> And have multiple paragraphs.
```

**Expected:** Lines 1-2 should be consecutive (same paragraph), then ONE blank line, then line 3

**Root Cause Analysis:**
After plan 02-19 simplified `ensureIntraBlockNewlines()` to only handle blockquotes, the function now adds a newline after EVERY blockquote run. However:

1. Lines 55-56 in comprehensive.md are continuous blockquote lines (same paragraph):
   ```markdown
   > This is a blockquote.
   > It can span multiple lines.
   ```

2. AttributedString creates separate runs for each line within a blockquote paragraph
3. `ensureIntraBlockNewlines()` adds a newline after EACH run (lines 196-198)
4. This creates excessive gaps between lines that should be consecutive

**The function is not differentiating between:**
- Intra-paragraph runs (should NOT get extra newlines - just natural wrapping)
- Inter-paragraph runs (should get newlines for separation)

**Introduced by:** Plan 02-19 - when list item logic was removed, blockquote logic became unconditional

**Severity:** BLOCKER - blockquote rendering is broken

### Gap #29: Duplicate List Item Prefixes (BLOCKER)

**Symptom:** List items with inline formatting show duplicate bullet/number prefixes

**Evidence from screenshot:**
```
• Third item with • bold
```

**Expected:** "• Third item with **bold**" (only one bullet at the start)

**Markdown source (line 44):**
```markdown
- Third item with **bold**
```

**Root Cause Analysis:**
Inline formatting (bold) creates multiple AttributedString runs for the same list item:
1. Run 1: "Third item with " (normal text, listItem ordinal=3)
2. Run 2: "bold" (bold text, listItem ordinal=3)

The `insertListPrefixes()` function (lines 246-288) inserts prefix at the START of every run that has `.listItem` in its presentation intent. It currently has:
```swift
if isListItem {
    // Insert prefix at run start
    let insertPosition = run.range.lowerBound
    // ... inserts "• " or "\(ordinal). "
}
```

**The function doesn't check if this is the FIRST run of the list item** - it just inserts a prefix for every run with `isListItem=true`.

**The fix from plan 02-12 tracked ordinals to prevent NEWLINES between runs of the same item, but did not prevent DUPLICATE PREFIXES.**

**Introduced by:** Existing bug that was hidden by other issues, now visible after spacing fixes

**Severity:** BLOCKER - list items with inline formatting are broken

## Impact Assessment

**Gap #27 (from UAT round 8):** FIXED ✓
- List spacing is now correct for simple items (no excessive gaps)
- "First item", "Second item", "Fourth item" all render correctly

**New Regressions:** 2 blockers
- Gap #28: Blockquote spacing broken
- Gap #29: List prefixes duplicated for inline formatting

**Overall Phase 2 Status:** 8/10 tests passing, down from 9/10 in UAT round 8

## Recommendation

Create two new gap closure plans:

1. **Plan 02-20:** Fix blockquote excessive spacing
   - Modify `ensureIntraBlockNewlines()` to only add newlines at paragraph boundaries
   - Use blockquote identity comparison (like `insertBlockBoundaryNewlines()` does for other blocks)
   - Preserve newlines at the end of blockquote paragraphs, skip newlines for intra-paragraph runs

2. **Plan 02-21:** Fix duplicate list item prefixes
   - Track "last processed ordinal" in `insertListPrefixes()`
   - Only insert prefix when ordinal changes (first run of each list item)
   - Similar to the ordinal tracking pattern used in `insertBlockBoundaryNewlines()`

Next command: `/gsd:plan-phase 2 --gaps`
