---
phase: 15-cross-context-integration
plan: 02
subsystem: testing
tags: [snapshot-testing, visual-regression, baseline-recording, swift-snapshot-testing]

# Dependency graph
requires:
  - phase: 15-01
    provides: Snapshot testing infrastructure with swift-snapshot-testing 1.18.9 and CrossContextSnapshotTests.swift
provides:
  - Verified baseline snapshots for all 6 width/appearance combinations (narrow/medium/wide x light/dark)
  - Visual verification that all v1.2 features render correctly across Quick Look contexts
  - Regression safety for future rendering changes
affects: [future-rendering-changes, visual-polish-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - snapshot-baseline-recording
    - full-content-height-capture
    - test-target-source-compilation

key-files:
  created:
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-light.png
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-dark.png
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-light.png
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-dark.png
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-light.png
    - MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-dark.png
  modified:
    - MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift
    - MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj
    - MDQuickLook/MDQuickLook.xcodeproj/xcshareddata/xcschemes/MDQuickLookTests.xcscheme

key-decisions:
  - "Compile extension sources directly in test target (Option C) to bypass SPM C module transitive dependency issue with @testable import"
  - "Use 3000px snapshot height to capture full document content including features below 800px fold"
  - "Accept snapshot filename pattern verifySnapshot-width-appearance-named.{context}.png from method signature change"

patterns-established:
  - "Test target source compilation workaround for app extension testing in Xcode/SPM projects"
  - "Full-height snapshot capture (3000px) ensures complete document visibility"
  - "Human visual verification checkpoint for baseline approval before test suite lock-in"

# Metrics
duration: 15min
completed: 2026-02-07
---

# Phase 15 Plan 02: Baseline Recording & Visual Verification Summary

**Six baseline snapshots recorded at full content height (3000px) and visually verified across all width tiers and appearance modes, confirming correct rendering of all v1.2 features**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-02-07T16:30:00Z (approximate)
- **Completed:** 2026-02-07T16:53:00Z
- **Tasks:** 2 (auto task + human-verify checkpoint)
- **Files modified:** 9 (6 snapshot PNGs + 3 project files)

## Accomplishments

- **Baseline snapshots recorded:** Six PNG files covering narrow/medium/wide widths in light/dark appearance modes
- **Build fix applied:** Added extension .swift source files directly to test target compile sources (Option C), bypassing SPM C module transitive dependency issue
- **Snapshot height optimized:** Increased from 800px to 3000px to capture full document content including tables, code blocks, blockquotes below initial fold
- **Visual verification completed:** All v1.2 features (YAML front matter, tables, task lists, code blocks, blockquotes) confirmed rendering correctly across all contexts

## Task Commits

Each task was committed atomically:

1. **Task 1: Record baseline snapshots and run verification** - Multiple commits for iterative fixes:
   - `27e6c18` (fix) - Add MDQuickLookTests shared scheme
   - `aaf204b` (fix) - Resolve test build by adding extension sources to test target
   - `7a7baeb` (test) - Record baseline snapshots (first attempt, 800px height)
   - `d82928f` (fix) - Increase snapshot height to capture full document content (800px → 3000px)
   - `7d38fed` (test) - Re-record baseline snapshots with full content height

2. **Task 2: Human visual verification checkpoint** - Approved by user visual inspection

**Plan metadata:** (this commit)

## Files Created/Modified

**Created:**
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-light.png` - Narrow width (260px) light mode baseline (503 KB)
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-dark.png` - Narrow width (260px) dark mode baseline (513 KB)
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-light.png` - Medium width (500px) light mode baseline (656 KB)
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-dark.png` - Medium width (500px) dark mode baseline (659 KB)
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-light.png` - Wide width (800px) light mode baseline (725 KB)
- `MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-dark.png` - Wide width (800px) dark mode baseline (728 KB)

**Modified:**
- `MDQuickLook/MDQuickLookTests/SnapshotTests/CrossContextSnapshotTests.swift` - Snapshot height increased to 3000px, record mode toggled for baseline generation
- `MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj` - Added extension source files to test target compile sources
- `MDQuickLook/MDQuickLook.xcodeproj/xcshareddata/xcschemes/MDQuickLookTests.xcscheme` - Created shared scheme for command-line testing

## Decisions Made

**1. Test target build approach (Option C)**
- **Decision:** Compile extension .swift source files directly in test target compile sources
- **Rationale:** Bypasses SPM C module transitive dependency visibility issue that prevents `@testable import MDQuickLook_Extension` from working in Xcode 16.1+. Known Xcode/SPM limitation with app extensions.
- **Tradeoff:** Duplicates source compilation but provides pragmatic workaround for testing app extension code
- **Committed in:** `aaf204b`

**2. Full content height snapshots (3000px)**
- **Decision:** Use 3000px snapshot height instead of original 800px
- **Rationale:** Original 800px only captured top portion of comprehensive-v1.2.md test document. Tables, code blocks, and blockquotes were below fold and not visible in baseline snapshots.
- **Impact:** All document features now visible and verified in baselines
- **Committed in:** `d82928f`, `7d38fed`

**3. Snapshot filename pattern acceptance**
- **Decision:** Accept `verifySnapshot-width-appearance-named.{context}.png` naming from method signature change
- **Rationale:** swift-snapshot-testing derives snapshot filename from test method name and parameters. Method signature `verifySnapshot(width:appearance:named:)` produces this pattern.
- **Impact:** Plan expected `testAllContexts.{context}.png` but actual filenames differ slightly. Functionally equivalent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Missing MDQuickLookTests shared scheme**
- **Found during:** Task 1 (Initial test execution attempt)
- **Issue:** `xcodebuild test -target MDQuickLookTests` failed because no shared scheme existed for the test target
- **Fix:** Created `MDQuickLookTests.xcscheme` in `xcshareddata/xcschemes/` to enable command-line testing
- **Files modified:** `MDQuickLook/MDQuickLook.xcodeproj/xcshareddata/xcschemes/MDQuickLookTests.xcscheme`
- **Verification:** `xcodebuild test` succeeded after scheme creation
- **Committed in:** `27e6c18`

**2. [Rule 3 - Blocking] Test target build failure due to @testable import**
- **Found during:** Task 1 (Test compilation attempt)
- **Issue:** `@testable import MDQuickLook_Extension` failed with SPM C module transitive dependency visibility error. markdown-c module from swift-cmark not visible to test target.
- **Fix:** Applied user-selected Option C - added all extension .swift source files directly to test target compile sources in project.pbxproj
- **Files modified:** `MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj`, `CrossContextSnapshotTests.swift` (removed @testable import)
- **Verification:** Test target compiled successfully, tests executable
- **Committed in:** `aaf204b`

**3. [Rule 1 - Bug] Snapshot height insufficient to capture full document**
- **Found during:** Task 1 (Visual inspection of first baseline snapshots)
- **Issue:** 800px snapshot height only captured top ~60% of comprehensive-v1.2.md document. Tables, code blocks, and blockquotes were below fold and not visible for verification.
- **Fix:** Increased snapshot height from 800px to 3000px in CrossContextSnapshotTests.swift. Re-recorded all baselines.
- **Files modified:** `CrossContextSnapshotTests.swift`, all 6 snapshot PNG files (re-recorded)
- **Verification:** Visual inspection confirmed full document content visible in all baselines
- **Committed in:** `d82928f` (height increase), `7d38fed` (re-recorded snapshots)

---

**Total deviations:** 3 auto-fixed (1 missing scheme, 1 build blocker, 1 visual bug)
**Impact on plan:** All auto-fixes necessary for test execution and complete visual coverage. No scope creep. Build workaround (Option C) was anticipated in plan as one of three options and selected by user decision during execution.

## Issues Encountered

**Test infrastructure challenges:**
1. **Shared scheme requirement:** Xcode projects require shared schemes for command-line `xcodebuild` access to targets. Auto-generated schemes are user-specific and gitignored.
2. **App extension testing limitation:** Known Xcode/SPM issue where app extensions with SPM dependencies containing C modules cannot be tested via `@testable import`. Transitive C module visibility breaks in test targets. Workaround: compile extension sources directly in test target.
3. **Snapshot height calibration:** Initial 800px height based on Quick Look window size estimation. Actual document height exceeded this. Iterated to 3000px to ensure full content capture.

All issues resolved during Task 1 execution.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Phase 15 complete:**
- All v1.2 features (YAML front matter, tables, task lists, code blocks, blockquotes) verified rendering correctly
- Cross-context integration confirmed across narrow/medium/wide widths in light/dark modes
- Snapshot test suite provides regression safety for future rendering changes
- LAYOUT-05 requirement satisfied

**Blockers/Concerns:**
None. v1.2 rendering complete and verified.

**Pending items from STATE.md todos:**
1. MIT license attribution in app UI (area: ui)
2. Preferences toggle for YAML front matter display (area: ui, requires App Group)
3. Dark mode background color inconsistency across sections (area: rendering)

These are deferred feature enhancements, not blockers for v1.2 release.

## Self-Check: PASSED

**Files verified:**
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-light.png
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.narrow-dark.png
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-light.png
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.medium-dark.png
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-light.png
- FOUND: MDQuickLook/MDQuickLookTests/SnapshotTests/__Snapshots__/CrossContextSnapshotTests/verifySnapshot-width-appearance-named.wide-dark.png

**Commits verified:**
- FOUND: 27e6c18
- FOUND: aaf204b
- FOUND: 7a7baeb
- FOUND: d82928f
- FOUND: 7d38fed

---
*Phase: 15-cross-context-integration*
*Completed: 2026-02-07*
