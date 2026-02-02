---
phase: 02-core-markdown-rendering
plan: 16
status: complete
date_completed: 2026-02-01

dependency_graph:
  requires:
    - "Phase 02 core rendering foundation"
    - "Image placeholder infrastructure (02-03, 02-05, 02-07)"
  provides:
    - "Working image placeholder rendering with markers that survive AttributedString parsing"
    - "Photo icon + gray text display for images"
  affects:
    - "Any future markdown parsing changes must preserve alphanumeric markers"

tech_stack:
  added: []
  patterns:
    - "Alphanumeric-only markers for AttributedString-safe preprocessing"
    - "Two-phase image handling: preprocess with markers, then style replacement"

key_files:
  created: []
  modified:
    - path: "md-spotlighter/MDQuickLook/MarkdownRenderer.swift"
      changes:
        - "preprocessImages(): Changed marker format to IMAGEPLACEHOLDERSTART...END"
        - "applyImagePlaceholderStyles(): Updated regex pattern to match new markers"
        - "Preserved final display format: [Image: filename] with icon and gray text"

decisions:
  - decision: "Use IMAGEPLACEHOLDERSTART...END markers instead of [Image: filename] format"
    rationale: "AttributedString(markdown:) can interpret [text] as potential link syntax; alphanumeric-only markers are guaranteed safe from markdown parsing"
    alternatives:
      - "[Image: filename] - Risk of link conversion by AttributedString"
      - "__IMAGE_PLACEHOLDER__ - Underscores stripped as emphasis markers"
    impact: "Markers survive AttributedString parsing intact, enabling reliable replacement"

metrics:
  duration: 115
  tasks_completed: 1
  files_modified: 1
  commits: 1
  deviations: 0

subsystem: "markdown-rendering"
tags: ["image-placeholders", "preprocessing", "markers", "gap-closure"]
---

# Phase 02 Plan 16: Fix Image Placeholder Markers Summary

**One-liner:** Alphanumeric-only markers (IMAGEPLACEHOLDERSTART...END) survive AttributedString parsing for reliable image placeholder rendering

## What Was Done

### Task 1: Fix Image Placeholder Markers
**Status:** Complete
**Commit:** ea298a0

Changed image placeholder preprocessing to use alphanumeric-only markers that won't be interpreted by AttributedString(markdown:).

**Changes made:**
1. **preprocessImages()** (line ~474): Changed placeholder format from `[Image: filename]` to `IMAGEPLACEHOLDERSTART{filename}IMAGEPLACEHOLDEREND`
2. **applyImagePlaceholderStyles()** (line ~517): Updated regex pattern from `\\[Image: ([^\\]]+)\\]` to `IMAGEPLACEHOLDERSTART(.+?)IMAGEPLACEHOLDEREND`
3. Preserved final display: Still creates `[Image: filename]` output with SF Symbol photo icon and gray text

**Root cause addressed:** Previous attempts used:
- `__IMAGE_PLACEHOLDER__` markers - underscores stripped by AttributedString as emphasis
- `[Image: filename]` - risk of interpretation as markdown link syntax

New alphanumeric markers contain no special characters:
- No underscores (emphasis)
- No brackets (links)
- No asterisks (bold/italic)
- No angle brackets (consumed by parser)

## Technical Details

### Two-Phase Image Handling Pattern

**Phase 1: Preprocessing (before AttributedString)**
```swift
// Input:  ![alt](url/to/image.png)
// Output: IMAGEPLACEHOLDERSTARTimage.pngIMAGEPLACEHOLDEREND
```

**Phase 2: Style Application (after AttributedString → NSAttributedString)**
```swift
// Find markers with regex
// Replace with: [SF Symbol photo icon] + " " + "[Image: filename]" (gray text)
```

### Marker Safety

The marker `IMAGEPLACEHOLDERSTART...END` is safe because:
1. Contains only uppercase letters (A-Z)
2. No markdown special characters
3. Unlikely to appear naturally in content
4. Survives AttributedString parsing completely unchanged

### Display Format

Final rendered output for users:
```
📷 [Image: screenshot.png]
📷 [Image: logo.svg]
```
- Photo SF Symbol icon (system "photo")
- Gray text (secondaryLabelColor)
- Readable filename with extension

## Decisions Made

**Use alphanumeric-only markers for preprocessing**
- Why: Guaranteed safe from markdown interpretation by AttributedString
- Previous attempts: `__IMAGE_PLACEHOLDER__` (underscores stripped), `[Image: filename]` (potential link syntax)
- Impact: Markers survive parsing intact, enabling reliable replacement in NSAttributedString phase

## Deviations from Plan

None - plan executed exactly as written.

## Verification

**Build status:** ✓ Success
**Compilation:** No errors
**Preview test:** Completed successfully

**Expected behavior:**
1. Image markdown syntax `![alt](url)` preprocessed to markers
2. Markers survive AttributedString(markdown:) parsing
3. Markers found and replaced with styled output
4. Final display: photo icon + gray `[Image: filename]` text
5. No exposed markers in rendered output

## Performance

**Execution time:** 115 seconds (2 minutes)
**Tasks completed:** 1/1
**Commits:** 1 atomic commit

## Next Steps

**Immediate:** Run UAT to verify:
- Image placeholders display with photo icon
- Text format is `[Image: filename]`
- Text color is gray
- No markers visible (IMAGEPLACEHOLDER, __IMAGE_PLACEHOLDER__, etc.)

**Follow-up:** If UAT confirms fix, this resolves Gap #25 (image placeholder rendering failure)

## Context for Future Work

**If you need to modify image handling:**
1. Marker format: `IMAGEPLACEHOLDERSTART{filename}IMAGEPLACEHOLDEREND`
2. Markers created in: `preprocessImages()` function
3. Markers replaced in: `applyImagePlaceholderStyles()` function
4. Must be alphanumeric-only to survive AttributedString parsing
5. Final display format: `[Image: {filename}]` with icon

**Testing image placeholders:**
```bash
# Build and preview
make build
qlmanage -p samples/comprehensive.md

# Check for:
# - Photo icon before each image placeholder
# - Gray text showing "[Image: filename]"
# - No exposed marker text
```
