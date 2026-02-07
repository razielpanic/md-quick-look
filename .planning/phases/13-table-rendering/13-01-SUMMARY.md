---
phase: 13-table-rendering
plan: 01
type: execute
subsystem: rendering
tags: [tables, layout, responsive, compact-mode]
requires: [12-layout-sizing]
provides: [width-aware-tables, content-proportional-columns, compact-table-mode]
affects: []
tech-stack:
  added: []
  patterns: [content-proportional-sizing, available-width-threading]
key-files:
  created: []
  modified:
    - MDQuickLook/MDQuickLook Extension/PreviewViewController.swift
    - MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift
    - MDQuickLook/MDQuickLook Extension/TableRenderer.swift
decisions:
  - id: thread-available-width
    summary: Thread availableWidth from PreviewViewController through MarkdownRenderer to TableRenderer
    rationale: Tables need actual container width to scale proportionally instead of using hardcoded maxTableWidth caps
  - id: content-proportional-sizing
    summary: Column widths based on measured content with proportional scaling when total exceeds available width
    rationale: Content-fitted tables stay compact, wide tables scale proportionally to fit container
  - id: compact-mode-11pt
    summary: Narrow tier uses 11pt font (was 12pt), 2pt padding (was 3pt), 1pt header border
    rationale: Maximize data density in narrowest Finder preview pane while maintaining readability
  - id: normal-mode-640pt-cap
    summary: Normal mode caps table width at 640pt to match body content max width
    rationale: Tables align with body text width for visual consistency
  - id: high-column-count-cap
    summary: Tables with 5+ columns cap individual column width at 1.5x equal share
    rationale: Prevents any single wide column from dominating, ensures balanced layout
metrics:
  duration: 173s
  completed: 2026-02-07
---

# Phase 13 Plan 01: Width-Aware Table Rendering Summary

**One-liner:** Tables now scale to available container width with content-proportional columns and 11pt compact mode in narrow contexts.

## What Was Built

Implemented width-aware table rendering that uses actual container dimensions instead of hardcoded maxTableWidth caps (400/800pt). Tables now produce content-fitted layouts that scale proportionally when content exceeds available width. Compact mode (narrow tier) uses smaller font (11pt), tighter padding (2pt), and thinner borders (1pt) for maximum data density.

**Key capability:** Tables respond to actual preview pane width, columns are content-proportional with enforced min/max constraints, and compact styling activates in narrow contexts.

## Tasks Completed

| Task | Description | Commit | Key Changes |
|------|-------------|--------|-------------|
| 1 | Thread availableWidth through rendering pipeline | e1abc8a | PreviewViewController calculates available content width from text container and passes to MarkdownRenderer; MarkdownRenderer stores and forwards to TableRenderer |
| 2 | Implement content-proportional column sizing and compact mode | 52b58c7 | Rewrite measureColumnWidths to use availableWidth instead of hardcoded caps; implement 7-step content-proportional sizing with min/max enforcement; add compact mode config (11pt font, 2pt padding, 1pt border) |

## Technical Details

**Available width threading:**
- PreviewViewController: Calculate `scrollView.contentSize.width - (textContainerInset.width * 2)`
- MarkdownRenderer: Store as instance property, forward to TableRenderer in both source range and placeholder rendering paths
- TableRenderer: Accept in initializer, use for max table width calculation

**Content-proportional sizing algorithm:**
1. Measure raw content width per column using NSString.size(withAttributes:)
2. Add tier-aware padding (2pt narrow, 6pt normal) and breathing room (6pt narrow, 16pt normal)
3. Apply tier-aware min/max constraints (30-120pt narrow, 50-280pt normal)
4. High column count (5+): reduce max column width to `min(maxColumnWidth, equalShare * 1.5)` to prevent dominance
5. Calculate max table width: narrow = availableWidth, normal = min(availableWidth, 640pt)
6. Content-fitted: if total measured width <= max table width, use measured widths as-is (tables stay compact)
7. Proportional scaling: if total > max, scale all columns down; re-enforce min column width; redistribute remaining space among flexible columns

**Compact mode (narrow tier):**
- Body font: 11pt (was 12pt)
- Cell padding: 2pt (was 3pt)
- Breathing room: 6pt (was 10pt)
- Min column width: 30pt (was 40pt)
- Max column width: 120pt (was 150pt)
- Header border: 1pt (was 2pt)

**Normal mode:**
- Body font: 14pt
- Cell padding: 6pt
- Breathing room: 16pt
- Min column width: 50pt
- Max column width: 280pt (capped further for 5+ columns)
- Header border: 2pt
- Max table width: 640pt (matches body content cap)

## Decisions Made

**Thread availableWidth from container to table renderer:**
Tables need actual pixel width available in the container to scale proportionally. PreviewViewController calculates this from text container size after accounting for insets, passes through MarkdownRenderer to TableRenderer. Default value (640pt) preserves backward compatibility.

**Content-proportional column sizing with content-fitted behavior:**
Instead of forcing tables to expand to fill maxTableWidth, measure actual content needs per column. If total fits within available width, use measured widths (content-fitted). If exceeds available width, scale proportionally while respecting minimum column widths. This ensures compact tables stay compact while wide tables scale gracefully.

**Compact mode uses 11pt font for max data density:**
Narrowest Finder preview pane (~260px) requires maximum data density. Reduced font from 12pt to 11pt, padding from 3pt to 2pt, header border from 2pt to 1pt. Still readable but fits more content.

**Normal mode caps table width at 640pt:**
Matches the body content max width cap established in Phase 12. Tables align with paragraph width for visual consistency. In wider containers, tables don't expand beyond 640pt (unless they need to due to content).

**High column count (5+) caps individual column width:**
For tables with 5+ columns, prevent any single wide column from dominating by capping max column width at `1.5x equal share`. This ensures balanced layouts even when one column has significantly longer content.

## Deviations from Plan

None - plan executed exactly as written.

## Files Modified

**MDQuickLook/MDQuickLook Extension/PreviewViewController.swift:**
- Added `availableContentWidth` instance property (default 640)
- Calculate available content width from text container in `preparePreviewOfFile` (after creating scroll view and text container but before rendering)
- Pass availableWidth to `MarkdownRenderer.render(markdown:widthTier:availableWidth:)`
- Recalculate availableContentWidth in `regenerateContent()` from current text container size

**MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift:**
- Added `availableWidth` instance property (default 640)
- Updated `render(markdown:widthTier:)` signature to `render(markdown:widthTier:availableWidth:)`
- Store availableWidth at top of render method
- Pass availableWidth when creating TableRenderer in both `renderWithSourceRanges` and `renderWithPlaceholders`

**MDQuickLook/MDQuickLook Extension/TableRenderer.swift:**
- Added `availableWidth` instance property (default 640)
- Updated `init(widthTier:)` to `init(widthTier:availableWidth:)`
- Changed `bodyFontSize` for narrow tier from 12.0 to 11.0 (compact mode)
- Rewrote `measureColumnWidths(for:columnCount:)` with 7-step content-proportional algorithm using availableWidth
- Updated `renderCell` padding from 3pt to 2pt in narrow tier (compact mode)
- Updated `renderCell` header border from fixed 2pt to tier-aware (1pt narrow, 2pt normal)
- Updated `render(_ table:)` to cap total table width at maxTableWidth

## Integration Points

**PreviewViewController → MarkdownRenderer:**
- Calculate available content width from text container: `textContainer.size.width`
- Pass to `renderer.render(markdown:widthTier:availableWidth:)`
- Recalculate on re-renders when tier changes

**MarkdownRenderer → TableRenderer:**
- Store availableWidth from render method parameter
- Forward to `TableRenderer(widthTier:availableWidth:)` in both hybrid rendering paths

**TableRenderer → NSTextTable:**
- Use availableWidth to calculate max table width (narrow = availableWidth, normal = min(availableWidth, 640))
- Apply to column width measurement, scaling, and table content width

## Next Phase Readiness

**Blockers:** None

**Concerns:** None

**Recommendations:**
- Visual verification with various table sizes (2-column compact, 5+ column wide) in both narrow and normal tiers
- Test edge case: very narrow container (<200px) with 5+ column table
- Verify 640pt cap in normal mode aligns visually with body content width

## Verification Results

Build: ✅ Successful (`make build`)

Code verification:
- ✅ availableWidth flows from PreviewViewController → MarkdownRenderer → TableRenderer
- ✅ TableRenderer.measureColumnWidths uses availableWidth instead of hardcoded 400/800
- ✅ Content-fitted: total width is NOT forced to expand when columns are small
- ✅ Proportional scaling: when total > maxTableWidth, all columns scale down with min enforcement
- ✅ Compact mode: narrow tier uses 11pt font, 2pt padding, 1pt border, 30pt min column, 120pt max column
- ✅ Normal mode: 14pt font, 6pt padding, 2pt border, 50pt min column, 280pt max column, 640pt cap
- ✅ High column count (5+): max column width capped at 1.5x equal share
- ✅ Default parameter values (640) preserve backward compatibility

## Self-Check: PASSED
