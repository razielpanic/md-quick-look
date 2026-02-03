---
phase: 01-extension-foundation
plan: 02
subsystem: build-automation
tags: [makefile, xcodebuild, quick-look, attributed-string, qlmanage]

# Dependency graph
requires:
  - phase: 01-01
    provides: Xcode project structure with host app and Quick Look extension
provides:
  - Build automation with Makefile (build, install, clean, reload, test targets)
  - Working Quick Look extension using AttributedString for markdown rendering
  - Sample markdown files for testing
  - Extension registered and verified in Finder
affects: [02-rendering-engine, 03-ui-polish]

# Tech tracking
tech-stack:
  added: [AttributedString API (macOS 12+)]
  patterns: [Synchronous markdown rendering, OSLog for debug logging, NSTextView with scroll support]

key-files:
  created:
    - Makefile
    - samples/basic.md
    - samples/empty.md
  modified:
    - md-quick-look/MDQuickLook/PreviewViewController.swift
    - md-quick-look/MDQuickLook/Info.plist
    - md-quick-look/md-quick-look.xcodeproj

key-decisions:
  - "Use AttributedString(markdown:) instead of WKWebView for synchronous rendering"
  - "Install to /Applications instead of ~/Library/QuickLook for proper extension registration"
  - "Use pluginkit registration via 'open app then kill' pattern"

patterns-established:
  - "Makefile-based build automation for Xcode projects"
  - "OSLog subsystem logging for debugging Quick Look extensions"
  - "Synchronous Quick Look preview using AttributedString + NSTextView"

# Metrics
duration: 45min
completed: 2026-02-01
---

# Phase 1 Plan 2: Build Automation and Finder Verification Summary

**Working Quick Look extension using AttributedString for markdown rendering, installed to /Applications with Makefile automation**

## Performance

- **Duration:** 45 min
- **Started:** 2026-01-31T19:29:00Z
- **Completed:** 2026-02-01T05:11:59Z
- **Tasks:** 3 (2 auto + 1 human-verify checkpoint)
- **Files modified:** 4 primary files (Makefile, samples, PreviewViewController.swift, project config)

## Accomplishments
- Makefile with build, install, clean, reload, test targets for repeatable workflow
- Working Quick Look extension that renders markdown with styled text (bold, italic, code, links)
- Extension loads instantly in Finder (no spinner) with synchronous AttributedString rendering
- Extension registered with system and visible in System Settings > Extensions > Quick Look
- Solved multiple complex issues: async protocol, extension embedding, WKWebView limitations

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Makefile and sample markdown files** - `bd0ec6b` (chore)
2. **Task 2: Build, install, and reload extension** - Multiple debugging commits (see Deviations)
3. **Task 3: Human verification checkpoint** - APPROVED by user

**Plan metadata:** (to be committed with this SUMMARY)

## Files Created/Modified

### Created
- `Makefile` - Build automation with xcodebuild, install to /Applications, qlmanage reload
- `samples/basic.md` - Comprehensive test file (heading, bold, italic, list, code, blockquote, link)
- `samples/empty.md` - Edge case test for empty markdown files

### Modified
- `md-quick-look/MDQuickLook/PreviewViewController.swift` - Switched from WKWebView to AttributedString(markdown:) for synchronous rendering
- `md-quick-look/MDQuickLook/Info.plist` - Quick Look generator configuration
- `md-quick-look/md-quick-look.xcodeproj` - Project structure and embedding fixes

## Decisions Made

**1. Use AttributedString(markdown:) instead of WKWebView**
- **Context:** Initial implementation used WKWebView with HTML conversion, but async loading caused completion handler timing issues
- **Decision:** Switched to native AttributedString(markdown:) API (macOS 12+)
- **Rationale:** Synchronous rendering eliminates timing issues, simpler code, native macOS API, instant display
- **Impact:** Extension loads instantly without spinner, cleaner implementation

**2. Install to /Applications instead of ~/Library/QuickLook**
- **Context:** Plan specified ~/Library/QuickLook/, but extension wasn't registering with system
- **Decision:** Changed install path to /Applications (standard macOS app location)
- **Rationale:** macOS extension registration requires app bundle in standard location
- **Impact:** Extension properly registers with pluginkit and appears in System Settings

**3. Use "open app then kill" pattern for pluginkit registration**
- **Context:** Extension needed to register with system after installation
- **Decision:** Open app briefly, wait 2 seconds, then kill process in Makefile install target
- **Rationale:** Triggers pluginkit discovery without leaving app running
- **Impact:** Automatic registration on `make install`, no manual System Settings interaction

## Deviations from Plan

### Auto-fixed Issues (Deviation Rule Application)

**1. [Rule 1 - Bug] Fixed QLPreviewingController async protocol signature**
- **Found during:** Task 2 (Build and install)
- **Issue:** Initial implementation used synchronous protocol signature, but Quick Look expects async completion handler
- **Fix:** Changed `preparePreviewOfFile(at:completionHandler:)` to properly call handler after content ready
- **Files modified:** PreviewViewController.swift
- **Verification:** Extension compiles without protocol warnings
- **Committed in:** `8e812f3` (part of Task 2 debugging)

**2. [Rule 3 - Blocking] Fixed WKWebView async completion timing**
- **Found during:** Task 2 (Testing with qlmanage)
- **Issue:** WKWebView.loadHTMLString() is async, but handler was called before rendering complete (spinner showed)
- **Fix:** Added WKNavigationDelegate and called handler in didFinish navigation callback
- **Files modified:** PreviewViewController.swift
- **Verification:** Preview window stopped showing loading spinner
- **Committed in:** `46d90ed`

**3. [Rule 1 - Bug] Replaced WKWebView with AttributedString for synchronous rendering**
- **Found during:** Task 2 (Testing timing issues)
- **Issue:** Even with navigation delegate, WKWebView async behavior caused intermittent timing issues
- **Fix:** Completely replaced WKWebView approach with AttributedString(markdown:) + NSTextView
- **Files modified:** PreviewViewController.swift
- **Verification:** Extension renders instantly, no async timing issues
- **Committed in:** `105efc6`

**4. [Rule 3 - Blocking] Fixed Xcode project structure for extension embedding**
- **Found during:** Task 2 (Extension not loading)
- **Issue:** Extension bundle wasn't properly embedded in host app
- **Fix:** Recreated Xcode project with correct target dependencies and Copy Files build phase
- **Files modified:** md-quick-look.xcodeproj
- **Verification:** Extension bundle appears at Contents/PlugIns/MDQuickLook.appex
- **Committed in:** `a8cd11e`, `49c870e`

**5. [Rule 2 - Missing Critical] Added sandbox entitlements**
- **Found during:** Task 2 (Extension loading but not reading files)
- **Issue:** Extension lacked sandbox entitlements to read user-selected files
- **Fix:** Added com.apple.security.files.user-selected.read-only entitlement
- **Files modified:** MDQuickLook.entitlements
- **Verification:** Extension can read markdown file content
- **Committed in:** `bc9389b`

**6. [Rule 3 - Blocking] Changed Makefile install path from ~/Library/QuickLook to /Applications**
- **Found during:** Task 2 (Extension not appearing in System Settings)
- **Issue:** Extension in ~/Library/QuickLook wasn't registering with pluginkit
- **Fix:** Changed INSTALL_DIR to /Applications in Makefile
- **Files modified:** Makefile
- **Verification:** Extension appears in System Settings > Extensions
- **Committed in:** `9bd5b3c`, `0c62044`

---

**Total deviations:** 6 auto-fixed (3 bugs, 3 blocking issues)
**Impact on plan:** All deviations necessary to achieve working extension. Core objective achieved despite implementation path changes. Architectural pattern improved (AttributedString > WKWebView).

## Issues Encountered

**Complex debugging journey:** Quick Look extension development required solving multiple interconnected issues:

1. **Protocol compliance:** QLPreviewingController requires async completion pattern
2. **Extension embedding:** Xcode project structure must properly embed .appex in host app
3. **Sandbox permissions:** Extension needs explicit entitlements to read files
4. **Installation path:** macOS extension registration requires app in /Applications
5. **Rendering approach:** WKWebView async nature incompatible with Quick Look expectations
6. **Final solution:** AttributedString(markdown:) provides synchronous, native rendering

Each issue was debugged systematically using:
- Console.app logs with OSLog subsystem filtering
- `qlmanage -m` to verify registration
- `pluginkit -m -v` to inspect extension discovery
- Build phase inspection for embedding issues

## User Approval

User tested the extension in Finder with sample files and approved with feedback:

**Visual verification results:**
- "styled, no raw symbols" ✓
- "missing large headings but many attributes render correctly" ✓ (acceptable for Phase 1)
- "loads without spinner" ✓

**Working features verified:**
- Bold and italic text rendering correctly
- Inline code with monospace font
- Links displayed in blue
- No raw markdown symbols (**, *, `, etc.)
- Instant loading without progress indicator
- Extension appears in System Settings

**Known limitation (deferred to Phase 2/4):**
- Heading sizes: All text same size (AttributedString limitation in basic usage)
- Dark mode: Not implemented (Phase 4 enhancement)

## Next Phase Readiness

**Ready for Phase 2:**
- Working extension foundation established
- Build automation in place for rapid iteration
- Basic markdown rendering working (bold, italic, code, links)
- System integration verified (pluginkit, System Settings, Finder)

**Recommended Phase 2 focus:**
- Enhance heading size differentiation (requires AttributedString customization)
- Add table rendering support (planned for v1)
- Improve code block formatting (background color, better spacing)

**Blockers:** None - all Phase 1 objectives met

---
*Phase: 01-extension-foundation*
*Completed: 2026-02-01*
