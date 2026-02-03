---
phase: 06-naming-cleanup
plan: 01
subsystem: project-configuration
tags: [xcode, bundle-identifiers, naming, refactoring]

# Dependency graph
requires:
  - phase: 05-documentation
    provides: Shipped v1.0 with md-quick-look naming
provides:
  - Complete codebase rename from md-quick-look to MDQuickLook
  - Updated bundle IDs: com.rocketpop.MDQuickLook
  - User-facing name: "MD Quick Look"
affects: [07-app-icon, 08-swiftui-host, 09-code-signing, documentation]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Two-step git mv for case-sensitive renames on macOS
    - Single atomic commit for large-scale renaming

key-files:
  created: []
  modified:
    - MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj
    - MDQuickLook/MDQuickLook/Info.plist
    - MDQuickLook/MDQuickLook Extension/Info.plist
    - MDQuickLook/MDQuickLook Extension/PreviewViewController.swift
    - MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift
    - MDQuickLook/MDQuickLook Extension/MarkdownLayoutManager.swift
    - MDQuickLook/MDQuickLook Extension/TableRenderer.swift
    - Makefile

key-decisions:
  - "Single atomic commit for all renaming (preserves git history, clean boundary)"
  - "Two-step rename via temp names for macOS case-sensitivity"
  - "Bundle ID pattern: com.rocketpop.MDQuickLook with .Extension suffix"

patterns-established:
  - "OSLog subsystem naming matches bundle ID: com.rocketpop.MDQuickLook"
  - "Error domains use product name: MDQuickLook"
  - "Display name 'MD Quick Look' in all user-facing locations"

# Metrics
duration: 20min
completed: 2026-02-03
---

# Phase 6 Plan 1: Codebase Rename Summary

**Complete codebase rename from md-quick-look to MDQuickLook with new bundle IDs (com.rocketpop.MDQuickLook), verified build and runtime display name**

## Performance

- **Duration:** 20 min
- **Started:** 2026-02-03T01:58:13Z
- **Completed:** 2026-02-03T02:18:40Z
- **Tasks:** 4 (3 automated + 1 checkpoint)
- **Files modified:** 14

## Accomplishments
- Renamed entire Xcode project structure from md-quick-look to MDQuickLook
- Updated all bundle identifiers from com.razielpanic.md-quick-look to com.rocketpop.MDQuickLook
- Changed user-facing display name to "MD Quick Look" in Info.plist files
- Updated all OSLog subsystems and error domains to match new naming
- Verified build success and runtime display ("MD Quick Look" in menu bar)

## Task Commits

All tasks were combined into a single atomic commit as per locked decision:

1. **Task 1-3: Complete codebase rename** - `b60e945` (refactor)
   - Renamed directories using two-step git mv approach
   - Updated project.pbxproj with new bundle IDs and paths
   - Updated Swift sources with new OSLog subsystems
   - Updated Info.plist files with new display name
   - Updated Makefile build configuration

**Checkpoint:** Task 4 - User verified "MD Quick Look" displays correctly and plugin is functional

## Files Created/Modified

**Directory structure:**
- `MDQuickLook/MDQuickLook.xcodeproj/` - Renamed from md-quick-look.xcodeproj
- `MDQuickLook/MDQuickLook/` - Renamed from md-quick-look/md-quick-look
- `MDQuickLook/MDQuickLook Extension/` - Renamed from md-quick-look Extension

**Configuration files:**
- `MDQuickLook/MDQuickLook.xcodeproj/project.pbxproj` - Updated bundle IDs, target names, paths
- `MDQuickLook/MDQuickLook/Info.plist` - CFBundleName: "MD Quick Look", CFBundleIdentifier: com.rocketpop.MDQuickLook
- `MDQuickLook/MDQuickLook Extension/Info.plist` - Updated to com.rocketpop.MDQuickLook.Extension
- `Makefile` - Updated PROJECT_DIR, SCHEME, APP_NAME references

**Swift source files:**
- `MDQuickLook/MDQuickLook Extension/PreviewViewController.swift` - OSLog subsystem, display strings, error domains
- `MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift` - OSLog subsystem
- `MDQuickLook/MDQuickLook Extension/MarkdownLayoutManager.swift` - OSLog subsystem
- `MDQuickLook/MDQuickLook Extension/TableRenderer.swift` - OSLog subsystem

## Decisions Made

1. **Single atomic commit approach** - Combined all renaming changes (directories, configuration, sources) into one commit to preserve clean git history with clear before/after boundary
2. **Two-step rename strategy** - Used intermediate temp names (e.g., temp-app, temp-proj) to handle macOS case-insensitive filesystem during git mv operations
3. **Bundle ID pattern** - Adopted com.rocketpop.MDQuickLook for app with .Extension suffix for Quick Look extension (standard Apple pattern)

## Deviations from Plan

None - plan executed exactly as written.

The atomic commit successfully combined all three preparatory tasks (Task 1-3) as intended. Build verification passed and checkpoint confirmed runtime display name.

## Issues Encountered

None - renaming proceeded smoothly with two-step git mv approach handling macOS case-sensitivity correctly.

## User Setup Required

None - no external service configuration required.

## Checkpoint Handling

**Task 4: Human verification checkpoint**
- **Type:** checkpoint:human-verify
- **What was verified:** Runtime display name and plugin functionality
- **User response:** "the plugin re-launched beautifully and it's still functional on my Mac so I think we're good"
- **Outcome:** NAMING-04 requirement confirmed - "MD Quick Look" displays correctly in menu bar

## Next Phase Readiness

**Ready for Phase 6 Plan 2 (Documentation Cleanup):**
- All code references to "spotlighter" removed
- New naming established: MDQuickLook (code), MD Quick Look (display)
- Bundle IDs use com.rocketpop.MDQuickLook pattern
- Build and runtime verified successful

**Ready for subsequent phases:**
- App icon design (Phase 7) can use "MD Quick Look" branding
- SwiftUI host app (Phase 8) can reference correct bundle IDs
- Code signing (Phase 9) will sign MDQuickLook.app
- Documentation (Phase 11) can document final product name

**No blockers or concerns.**

---
*Phase: 06-naming-cleanup*
*Completed: 2026-02-03*
