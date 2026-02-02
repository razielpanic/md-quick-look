# UAT Round 7 - Phase 2: Core Markdown Rendering

**Date:** 2026-02-01
**Tester:** User visual inspection
**Test Method:** Quick Look preview via `qlmanage -p samples/comprehensive.md`
**Previous Status:** UAT Round 6 - 7/10 tests passed, 2 BLOCKER gaps
**Gap Closure Round 5 Executed:** Plans 02-16, 02-17

## Test Results

| # | Test | Expected | Actual | Status | Notes |
|---|------|----------|--------|--------|-------|
| 1 | Heading Visual Hierarchy | h1→h6 size progression, all bold | Size progression visible, bold applied | ✓ PASS | - |
| 2 | Inline Text Formatting | Bold, italic, strikethrough work | Formatting applied correctly | ✓ PASS | - |
| 3 | Code Blocks | Monospace font, gray background | Monospace + background visible | ✓ PASS | - |
| 4 | Blockquotes | Blue border, gray background | Continuous border + background | ✓ PASS | Fixed in round 4, still working |
| 5 | Unordered Lists | Bullets, minimal spacing, inline formatting on same line | **"Third item with" and "bold" on separate lines** | ✗ FAIL | **NEW REGRESSION** - inline formatting splits list item |
| 6 | Ordered Lists | Numbers, minimal spacing | Items on consecutive lines with minimal spacing | ✓ PASS | Gap #24 fix working for ordered lists |
| 7 | Links | Blue, underlined, non-interactive | Blue underlined text visible | ✓ PASS | - |
| 8 | Image Placeholders | Photo icon + "[Image: filename]" in gray, no markers | Photo icon + correct format, no exposed markers | ✓ PASS | Gap #25 fix working! |
| 9 | Document Scrolling | Can scroll full document | Scrolling works | ✓ PASS | - |
| 10 | Overall Visual Quality | Professional rendering | Good except list item #3 issue | ◐ PARTIAL | One issue remaining |

**Overall Score:** 9/10 tests passed
**Critical Issues:** 1 (unordered list inline formatting split)

## Gap Analysis

### Gap #26: Unordered list item with inline formatting splits across lines (BLOCKER)

**Severity:** BLOCKER
**Affected Element:** Unordered lists (requirement MDRNDR-05)
**Test:** #5 (Unordered Lists)

**Observed Behavior:**
- List item "• Third item with **bold**" renders as:
  ```
  • Third item with
  • bold
  ```
- The inline formatting (**bold**) causes the text to split across two lines
- Each line gets its own bullet point
- This makes the list item unreadable and breaks the visual structure

**Expected Behavior:**
- List item should render as single line: "• Third item with **bold**"
- Inline formatting should NOT cause line breaks within a list item
- Only one bullet point per list item

**Root Cause Hypothesis:**
The `ensureIntraBlockNewlines()` function may be adding a newline when it encounters the bold formatting change within the list item. The decision from 02-12 was to "Track list item ordinal to prevent inline formatting splits" but this may not be working correctly for unordered lists.

**Code Context:**
- Decision from 02-12: "Track list item ordinal to prevent inline formatting splits"
- Rationale: "Inline formatting creates multiple runs with same list item; comparing ordinal prevents newlines between runs"
- Implementation: Likely in `ensureIntraBlockNewlines()` around line 200-250 of MarkdownRenderer.swift

**Previous Related Fixes:**
- Plan 02-04: Added intra-block newlines detection
- Plan 02-12: Fixed list spacing and inline formatting continuity
- Plans 02-14, 02-17: Fixed paragraph spacing on list prefixes

**Impact:**
- Makes unordered lists with inline formatting unreadable
- Breaks requirement MDRNDR-05 (unordered lists with proper formatting)
- Ordered lists appear to be working correctly (Test #6 passed)

### Gaps Closed in Round 5

✓ **Gap #24:** List huge gaps - CLOSED
- Fix: Added paragraphSpacing=0 to list prefix (plan 02-17 verified 02-14 implementation)
- Verification: Ordered lists show minimal spacing (Test #6 passed)
- Status: Working for ordered lists, partial regression for unordered lists with inline formatting

✓ **Gap #25:** Image placeholder markers visible - CLOSED
- Fix: Alphanumeric-only markers IMAGEPLACEHOLDERSTART...END (plan 02-16)
- Verification: Test #8 shows correct rendering with no exposed markers
- Status: Fully working

## Recommendations

### Gap Closure Round 6 Required

**Priority:** HIGH (1 BLOCKER gap)

**Focus:**
1. **Gap #26 (BLOCKER):** Fix unordered list inline formatting split
   - Root cause: Newline inserted when bold formatting changes within list item
   - Solution approach: Extend ordinal tracking logic to work for unordered lists
   - May need to check if consecutive runs have same list item identity

**Estimated Plans:** 1 plan

**Expected Outcome:** 10/10 UAT tests pass, all rendering correct

## Progress Summary

**Gap Closure Journey:**
- Round 1: 0/10 → 5/10 (fixed structure, some styling)
- Round 2: 5/10 → 6/10 (fixed major issues)
- Round 3: 6/10 → 6/9 (fixed blockquotes)
- Round 4: 6/9 → 7/10 (fixed images, lists partially)
- Round 5: 7/10 → 9/10 (fixed image markers, list spacing for ordered lists)
- **Current (Round 7 UAT):** 9/10 (unordered list inline formatting issue)

**Remaining Work:**
- 1 BLOCKER gap to address
- Gap closure round 6 needed

---

_UAT Round 7 - 2026-02-01_
_Screenshot evidence provided by user_
_Next: /gsd:plan-phase 2 --gaps_
