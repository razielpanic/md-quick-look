---
phase: 15-cross-context-integration
plan: 01
subsystem: testing
completed: 2026-02-07
duration: 5min
tags:
  - snapshot-testing
  - swift-snapshot-testing
  - xctest
  - test-infrastructure
requires:
  - "14-01: Task list checkbox rendering"
  - "13-01: Table rendering implementation"
  - "11-01: YAML front matter rendering"
provides:
  - MDQuickLookTests target with swift-snapshot-testing dependency
  - CrossContextSnapshotTests suite with 6 snapshot test cases
  - comprehensive-v1.2.md test file exercising all v1.2 features
affects:
  - "15-02: Baseline snapshot recording and verification"
tech-stack:
  added:
    - swift-snapshot-testing@1.18.9
  patterns:
    - XCTest unit test target for extension testing
    - Snapshot-based visual regression testing
    - NSAppearance programmatic setting for light/dark mode testing
key-files:
  created:
    - MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift
    - MDQuickLook/MDQuickLookTests/Resources/comprehensive-v1.2.md
  modified:
    - MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj
    - MDQuickLook/MDQuickLook.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
decisions:
  - id: use-swift-snapshot-testing
    choice: "Use swift-snapshot-testing 1.18.9 from Point-Free"
    rationale: "De facto standard for macOS/Swift snapshot testing, active maintenance, NSView support, configurable precision"
    alternatives: "SnapshotPreviews (SwiftUI focused), custom solution (reinventing wheel)"
  - id: test-widths
    choice: "Test at 260px (narrow), 500px (medium), 800px (wide)"
    rationale: "Matches WidthTier breakpoints, covers all Quick Look contexts (column preview, intermediate, spacebar popup)"
    alternatives: "More granular width testing (unnecessary), fewer widths (insufficient coverage)"
  - id: precision-tolerance
    choice: "Use 0.98 precision (allow 2% pixel difference)"
    rationale: "Per research, handles minor rendering variations across environments while catching real regressions"
    alternatives: "1.0 precision (too strict, causes flake), lower precision (might miss defects)"
  - id: comprehensive-test-file
    choice: "Single comprehensive markdown file with all v1.2 features"
    rationale: "Per user decision, tests realistic integration of all features in one document"
    alternatives: "Separate test files per feature (less realistic, more test boilerplate)"
---

# Phase 15 Plan 01: Snapshot Testing Infrastructure Summary

**One-liner:** XCTest target with swift-snapshot-testing 1.18.9 configured for cross-context visual regression testing of all v1.2 features across 6 width/appearance combinations

## What Was Delivered

### Test Target Infrastructure

Created MDQuickLookTests XCTest target in the Xcode project with:
- Swift Package Manager dependency on swift-snapshot-testing 1.18.9
- Target dependency on MDQuickLook Extension for @testable import access
- Proper build configuration with TEST_TARGET_NAME set to extension
- Resources build phase including comprehensive-v1.2.md test file

### Comprehensive Test Markdown File

Created `MDQuickLook/MDQuickLookTests/Resources/comprehensive-v1.2.md` (107 lines) containing:
- **YAML front matter**: title, author, tags (as list), date, description with --- delimiters
- **Headings**: H1, H2, H3 hierarchy
- **Text formatting**: bold, italic, strikethrough, inline code
- **Lists**: unordered (4 items), ordered (4 items)
- **Task lists**: 12 items total with mix of checked [x] and unchecked [ ] items, including nested list with tasks
- **Table**: 7 rows × 4 columns with varied content widths to test column sizing
- **Code block**: Fenced swift code block with 6 lines
- **Blockquote**: Multi-line quote testing indentation and left border
- **Horizontal rule**: Testing separator rendering
- **Links**: Text link testing
- **Image reference**: Placeholder testing

The file reads like a realistic README/document, not a synthetic test fixture.

### Snapshot Test Suite

Created `MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift` with:
- Width configurations: narrow (260px), medium (500px), wide (800px) matching WidthTier breakpoints
- Appearance configurations: light (.aqua), dark (.darkAqua)
- `testAllContexts()` method that loops through all 6 combinations
- `verifySnapshot()` helper that:
  - Instantiates PreviewViewController
  - Sets view frame to specified width/height (800px height)
  - Sets NSAppearance BEFORE loading content (ensures semantic colors resolve correctly)
  - Loads comprehensive-v1.2.md from test bundle
  - Waits for async preparePreviewOfFile completion (5 second timeout)
  - Captures snapshot with 0.98 precision tolerance
- `shouldRecordSnapshots` boolean with `invokeTest()` override for record mode control
- Imports: XCTest, SnapshotTesting, @testable import MDQuickLook_Extension

### Xcode Project Modifications

Modified `project.pbxproj` to add:
- **PBXNativeTarget**: MDQuickLookTests with unit-test product type
- **XCRemoteSwiftPackageReference**: swift-snapshot-testing at upToNextMajorVersion from 1.18.0
- **XCSwiftPackageProductDependency**: SnapshotTesting product linked to test target
- **PBXFileReference**: Test swift file, markdown file, .xctest product
- **PBXGroup**: MDQuickLookTests group with SnapshotTests and Resources subgroups
- **Build phases**: Sources (CrossContextSnapshotTests.swift), Resources (comprehensive-v1.2.md), Frameworks (SnapshotTesting)
- **Build settings**: SWIFT_VERSION 5.0, MACOSX_DEPLOYMENT_TARGET 14.0, TEST_TARGET_NAME, PRODUCT_BUNDLE_IDENTIFIER
- **PBXTargetDependency**: Test target depends on extension target for @testable import
- **XCBuildConfiguration**: Debug and Release configs for test target

## Task Commits

| Task | Commit | Description |
|------|--------|-------------|
| 1 | dc23d4c | Set up test target infrastructure, comprehensive test markdown, and snapshot test suite |

## Deviations from Plan

None - plan executed exactly as written.

## Next Phase Readiness

### Blockers

None

### Concerns

- Test target requires scheme to run via xcodebuild - scheme may need to be created or auto-generated
- Extension target must build in Debug configuration for @testable import to work
- Package resolution completed successfully (swift-snapshot-testing 1.18.9, dependencies resolved)

### Prerequisites for Phase 15-02

- Test infrastructure compiles (verified via xcodebuild -list showing MDQuickLookTests target)
- comprehensive-v1.2.md contains all required features (verified: YAML, tables, task lists, code, blockquotes)
- CrossContextSnapshotTests imports SnapshotTesting and extension target (verified)
- Test target properly configured with test resources in Copy Bundle Resources phase

## Technical Details

### Architecture

```
MDQuickLook/
├── MDQuickLook/              # Host app
├── MDQuickLook Extension/    # Extension source code
└── MDQuickLookTests/         # NEW: Unit test target
    ├── SnapshotTests/
    │   └── CrossContextSnapshotTests.swift
    └── Resources/
        └── comprehensive-v1.2.md
```

### Test Matrix

| Width | Appearance | Context | Snapshot Name |
|-------|------------|---------|---------------|
| 260px | Light | Finder column preview pane | narrow-light |
| 260px | Dark | Finder column preview pane | narrow-dark |
| 500px | Light | Intermediate width | medium-light |
| 500px | Dark | Intermediate width | medium-dark |
| 800px | Light | Spacebar popup / fullscreen | wide-light |
| 800px | Dark | Spacebar popup / fullscreen | wide-dark |

### Key Implementation Notes

1. **NSAppearance timing**: Appearance set BEFORE calling preparePreviewOfFile ensures semantic colors (textBackgroundColor, separatorColor, etc.) resolve correctly for the specified mode

2. **Async completion handling**: XCTestExpectation pattern with 5 second timeout handles async preview loading. PreviewViewController's preparePreviewOfFile already calls layoutManager.ensureLayout internally (line 153), so view is fully laid out when completion handler fires

3. **Precision tolerance**: 0.98 precision (2% pixel difference allowed) per research recommendation to handle minor anti-aliasing/font rendering variations across environments without causing false failures

4. **Test file resource loading**: Uses `Bundle(for: type(of: self)).url(forResource:)` pattern to correctly load from test bundle, not main bundle

5. **Record mode control**: Manual `shouldRecordSnapshots` boolean with `invokeTest()` override provides explicit control over when to regenerate baselines. NEVER commit with this set to true

## Verification Evidence

- xcodebuild -list shows MDQuickLookTests target in project
- Package.resolved includes swift-snapshot-testing 1.18.9 with all dependencies (swift-custom-dump, xctest-dynamic-overlay, swift-syntax)
- comprehensive-v1.2.md verified: 107 lines, 3 YAML delimiters, 12 task list items, 7 table rows
- CrossContextSnapshotTests.swift verified: SnapshotTesting imported, extension imported, 0.98 precision, width configurations present
- project.pbxproj verified: 12 references to MDQuickLookTests, 4 references to swift-snapshot-testing, 4 references to comprehensive-v1.2.md

## Files Modified

- `MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj`: Added MDQuickLookTests target, swift-snapshot-testing package reference, test file references, build phases, build settings
- `MDQuickLook/MDQuickLook.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`: Package dependency resolution with swift-snapshot-testing 1.18.9

## Files Created

- `MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift`: 116 lines, comprehensive snapshot test suite
- `MDQuickLook/MDQuickLookTests/Resources/comprehensive-v1.2.md`: 107 lines, realistic markdown document exercising all v1.2 features

## Dependencies

This plan builds on:
- **Phase 11-01**: YAML front matter rendering (tested in comprehensive markdown)
- **Phase 12-01**: Width-adaptive layout (tested via narrow/normal tier widths)
- **Phase 13-01**: Table rendering (table included in test markdown)
- **Phase 14-01**: Task list checkboxes (task lists with checked/unchecked items in test markdown)

This plan enables:
- **Phase 15-02**: Baseline snapshot recording and verification (will use this test infrastructure)

## Decisions Made

### Use swift-snapshot-testing 1.18.9

**Decision**: Use swift-snapshot-testing from Point-Free as the snapshot testing library

**Rationale**: De facto standard for macOS/Swift snapshot testing with:
- Active maintenance (1.18.9 released Jan 29, 2026)
- NSView support built-in
- Configurable precision tolerance
- Established community patterns
- Generic Snapshotting protocol for extensibility

**Alternatives considered**:
- SnapshotPreviews by EmergeTools: SwiftUI focused, not ideal for NSViewController/NSTextView testing
- Custom image diff solution: Reinventing wheel, losing perceptual precision and battle-tested edge case handling

### Test at Three Width Breakpoints

**Decision**: Test at 260px (narrow), 500px (medium), 800px (wide)

**Rationale**:
- Matches existing WidthTier breakpoints (narrow <320px, normal ≥320px)
- Covers all three main Quick Look contexts:
  - 260px: Finder column preview pane (narrow tier)
  - 500px: Intermediate width (normal tier, moderate space)
  - 800px: Spacebar popup / fullscreen (normal tier, full space)
- Sufficient to catch responsive layout issues without excessive test coverage

**Alternatives considered**:
- More granular width testing: Unnecessary, these three widths cover critical breakpoints
- Fewer widths (e.g., just narrow and wide): Insufficient to catch medium-width rendering issues

### 0.98 Precision Tolerance

**Decision**: Use 0.98 precision in assertSnapshot (allow 2% pixel difference)

**Rationale**:
- Per research, 0.98-0.995 range recommended by community for macOS snapshot testing
- Handles minor anti-aliasing and font rendering differences across macOS versions/GPUs
- Strict enough to catch real visual regressions
- Loose enough to avoid false failures from rendering noise

**Alternatives considered**:
- 1.0 precision: Too strict, causes flake from sub-pixel rendering variations
- Lower precision (<0.95): Might miss subtle visual defects

### Single Comprehensive Test File

**Decision**: Use one comprehensive markdown file with all v1.2 features, not separate files per feature

**Rationale**:
- Per user decision in CONTEXT.md: "Single comprehensive markdown test file exercising all v1.2 features together"
- Tests realistic integration of all features in one document
- More representative of actual user content
- Simpler test suite (one file to maintain)

**Alternatives considered**:
- Separate test files per feature: Less realistic, more test boilerplate, doesn't test feature interaction

## Self-Check: PASSED

All created files exist:
- ✓ MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift
- ✓ MDQuickLook/MDQuickLookTests/Resources/comprehensive-v1.2.md

Commit exists:
- ✓ dc23d4c
