---
phase: 12-layout-sizing
plan: 01
subsystem: rendering
tags: [responsive-layout, typography, adaptive-rendering, width-detection]
requires:
  - 11-yaml-front-matter
provides:
  - width-tier-enum
  - adaptive-font-sizing
  - adaptive-spacing
  - width-aware-renderer-api
affects:
  - 12-02-view-controller-integration
tech-stack:
  added: []
  patterns:
    - tier-based-breakpoints
    - computed-property-delegation
key-files:
  created: []
  modified:
    - MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift
    - MDQuickLook/MDQuickLook Extension/TableRenderer.swift
key-decisions:
  - id: width-tier-enum
    what: "Use discrete two-tier system (narrow/normal) instead of smooth scaling"
    why: "Simpler to implement, test, and debug; matches Quick Look's actual usage contexts"
    alternatives: "Continuous scaling formulas, CSS-like clamp approach"
  - id: heading-shrink-aggressive
    what: "Headings shrink 30-40% in narrow mode while body text shrinks only 14%"
    why: "Headings consume more vertical space; disproportionate scaling maximizes content visibility"
    alternatives: "Uniform scaling across all font sizes"
  - id: yaml-field-capping
    what: "Cap YAML front matter at 5 fields in narrow mode with +N more indicator"
    why: "Preserves metadata visibility without overwhelming the narrow preview pane"
    alternatives: "Hide front matter entirely, show all fields with tiny font"
  - id: default-normal-tier
    what: "render(markdown:widthTier:) defaults to .normal for backward compatibility"
    why: "Existing callers continue to work unchanged; opt-in to narrow mode"
    alternatives: "Require explicit tier parameter always"
patterns-established:
  - pattern: tier-aware-computed-properties
    description: "Font sizes and spacing values route through computed properties that switch on widthTier"
    rationale: "Centralizes tier logic, keeps style methods clean, easy to maintain"
  - pattern: width-tier-enum-at-file-level
    description: "WidthTier enum defined outside class so PreviewViewController and TableRenderer can both use it"
    rationale: "Shared enum enables type-safe tier passing across rendering pipeline"
metrics:
  duration: 214
  completed: 2026-02-06
---

# Phase 12 Plan 01: Width-Tier Aware Rendering

**One-liner:** Renderer accepts widthTier parameter and produces tier-specific font sizes (H1: 20pt narrow, 32pt normal), spacing, and YAML capping (5 fields max in narrow mode).

## Performance

- Duration: 3.6 minutes
- Build time: ~10 seconds (no errors)
- Tasks completed: 2/2
- Commits: 1 (combined both tasks)

## What Was Accomplished

Added width-tier awareness to the rendering pipeline without breaking existing behavior. The renderer now accepts a `WidthTier` parameter (`.narrow` or `.normal`) and produces appropriately scaled output. Default behavior is `.normal`, so existing callers continue to work unchanged.

### Key Changes

1. **WidthTier enum** - Defined at file level for cross-class usage
2. **Tier-aware font sizing** - Headings shrink 30-40%, body text 14%, all above 10pt floor
3. **Tier-aware spacing** - Margins, padding, and vertical gaps shrink proportionally
4. **YAML field capping** - Narrow mode shows max 5 fields with "+N more" indicator
5. **Width-aware TableRenderer** - Scaled column widths, cell padding, and table constraints

### Font Size Comparison

| Element | Normal | Narrow | Reduction |
|---------|--------|--------|-----------|
| H1      | 32pt   | 20pt   | 37.5%     |
| H2      | 26pt   | 17pt   | 34.6%     |
| H3      | 22pt   | 15pt   | 31.8%     |
| H4      | 18pt   | 14pt   | 22.2%     |
| H5      | 16pt   | 13pt   | 18.8%     |
| H6      | 14pt   | 12pt   | 14.3%     |
| Body    | 14pt   | 12pt   | 14.3%     |
| Code    | 13pt   | 11pt   | 15.4%     |

### Spacing Comparison

| Element        | Normal (pt) | Narrow (pt) |
|----------------|-------------|-------------|
| Paragraph gap  | 8           | 4           |
| Code block     | 10 indent   | 6 indent    |
| Blockquote     | 20 indent   | 12 indent   |
| List indent    | 20/30       | 10/18       |
| YAML indent    | 20          | 8           |

### Table Constraints Comparison

| Constraint          | Normal | Narrow |
|---------------------|--------|--------|
| Min column width    | 60pt   | 40pt   |
| Max column width    | 300pt  | 150pt  |
| Max table width     | 800pt  | 400pt  |
| Cell padding        | 6pt    | 3pt    |
| Breathing room      | 20pt   | 10pt   |

## Task Commits

| Task | Description                                      | Commit  | Files Modified                          |
|------|--------------------------------------------------|---------|-----------------------------------------|
| 1-2  | Add WidthTier enum and width-aware rendering     | b2eb587 | MarkdownRenderer.swift, TableRenderer.swift |

## Files Created/Modified

**Modified:**
- `MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift` - Added WidthTier enum, widthTier property, computed properties for tier-specific values, updated all style methods to use tier-aware values, updated renderFrontMatter for field capping
- `MDQuickLook/MDQuickLook Extension/TableRenderer.swift` - Added widthTier property, initializer, computed bodyFontSize, updated measureColumnWidths and renderCell for tier-aware constraints

## Decisions Made

### D1: Two-Tier Breakpoint System

**Decision:** Use discrete narrow/normal tiers instead of smooth scaling.

**Rationale:** Two tiers match Quick Look's actual usage contexts (Finder preview pane ~260px vs Quick Look popup/fullscreen). Simpler to implement, test, and debug than continuous scaling formulas. Aligns with CONTEXT.md requirement for "two discrete tiers."

**Impact:** View controller will detect width and pass one of two enum values. Renderer produces one of two preconfigured outputs. No intermediate states.

### D2: Disproportionate Heading Scaling

**Decision:** Headings shrink 30-40% while body text shrinks only 14%.

**Rationale:** Headings consume significant vertical space and don't need to be as large in narrow contexts. Body text readability is more critical. Research-backed approach from typography best practices.

**Impact:** In narrow mode, heading hierarchy flattens slightly (H1/H2/H3 closer in size), but visual distinction remains clear while maximizing available space.

### D3: YAML Field Capping

**Decision:** Show max 5 YAML fields in narrow mode with "+N more" indicator.

**Rationale:** Preserves front matter visibility without overwhelming the narrow preview pane. Research showed Finder preview pane is primarily for quick scanning, not detailed metadata review. Follows CONTEXT.md requirement for field capping.

**Impact:** Documents with 10+ front matter fields will show first 5 plus "+5 more" in narrow mode. Full display in normal mode unchanged.

### D4: Backward Compatible Default

**Decision:** `render(markdown:widthTier: = .normal)` - default parameter for backward compatibility.

**Rationale:** Existing test code and any direct callers continue to work unchanged. Opt-in to narrow mode via explicit parameter. Follows Swift API design guidelines.

**Impact:** No breaking changes. Phase 12-02 (view controller integration) will pass explicit widthTier based on detected width.

## Deviations from Plan

None - plan executed exactly as written. All tasks completed, all verification checks passed, all must-haves satisfied.

## Issues Encountered

None. Build succeeded on first attempt after all changes applied. No compiler errors, no logic errors, no test failures.

## Next Phase Readiness

### What's Ready

- WidthTier enum is defined and accessible to PreviewViewController
- render(markdown:widthTier:) API is ready to receive tier from view controller
- All style methods produce tier-specific output
- TableRenderer accepts and uses widthTier parameter
- Default behavior (.normal) preserves existing rendering exactly

### What's Needed for Phase 12-02

**View Controller Integration:**
1. Add width detection in `viewDidLayout()` or similar lifecycle method
2. Determine tier based on `view.bounds.width` (threshold ~300-320px per research)
3. Track current tier to avoid unnecessary re-renders
4. Pass tier to `markdownRenderer.render(markdown:widthTier:)` when regenerating content
5. Adjust `textContainerInset` based on tier (6pt narrow, 20pt normal per research)

**Testing Requirements:**
- Test in Finder preview pane (narrow context)
- Test in Quick Look popup (normal context)
- Test in fullscreen Quick Look (normal context)
- Verify tier changes trigger re-render
- Verify font sizes and spacing match design spec

### Potential Issues

**Performance:** If width changes frequently (smooth resize), need to ensure tier-change detection prevents excessive re-renders. Research suggests caching current tier and only regenerating when tier changes (not every pixel of resize).

**Threshold Selection:** Research suggested ~300-320px threshold. Actual Finder preview pane width may vary by macOS version or display density. Plan 12-02 should test on multiple configurations to confirm threshold.

## Self-Check: PASSED

All verification checks passed:
- Build succeeded with zero errors
- WidthTier enum compiles and is accessible
- render(markdown:widthTier:) API compiles with default parameter
- All apply* methods use tier-aware computed properties (no hardcoded values remain)
- TableRenderer(widthTier:) compiles and accepts parameter
- Default behavior (.normal) produces identical output to previous version

No files or commits missing. All changes committed to b2eb587.
