# Roadmap: MD Quick Look

## Overview

v1.1 transforms the working Quick Look extension (v1.0) into a polished, publicly distributable macOS application via GitHub. The journey spans six phases: clean up all naming artifacts from development, design a professional app icon, build SwiftUI host app UI (About/Preferences windows), configure code signing and notarization for secure distribution, package into a signed DMG for GitHub release, and create comprehensive documentation with screenshots and demo GIFs showing the "spacebar to preview" magic moment.

## Milestones

- ✅ **v1.0 Initial Release** - Phases 1-5 (shipped 2026-02-02)
- 🚧 **v1.1 Public Release (GitHub)** - Phases 6-11 (in progress)

## Phases

<details>
<summary>✅ v1.0 Initial Release (Phases 1-5) - SHIPPED 2026-02-02</summary>

### Phase 1: Extension Foundation
**Goal**: Quick Look extension successfully loads and renders basic markdown
**Plans**: 2 plans

Plans:
- [x] 01-01: Quick Look extension scaffolding and basic markdown rendering
- [x] 01-02: Extension registration and Finder integration

### Phase 2: Core Markdown Rendering
**Goal**: All essential markdown elements render with proper visual hierarchy
**Plans**: 22 plans

Plans:
- [x] 02-01 through 02-22: Headings, bold, italic, strikethrough, lists, code blocks, blockquotes, links, images

### Phase 3: Tables & Advanced Elements
**Goal**: GitHub-flavored markdown tables render correctly alongside other markdown
**Plans**: 2 plans

Plans:
- [x] 03-01: Table parsing and hybrid rendering
- [x] 03-02: Table styling and layout

### Phase 4: Performance & Polish
**Goal**: Preview renders instantly for all file sizes with proper dark mode support
**Plans**: 2 plans

Plans:
- [x] 04-01: Performance optimization and file truncation
- [x] 04-02: Dark mode semantic colors

### Phase 5: Documentation Sync
**Goal**: Documentation reflects shipped v1.0 capabilities
**Plans**: 2 plans

Plans:
- [x] 05-01: Update README and documentation
- [x] 05-02: Final requirements verification

</details>

### 🚧 v1.1 Public Release (GitHub) (In Progress)

**Milestone Goal:** Prepare MD Quick Look for public release on GitHub with polished app experience, secure distribution, and clear documentation for end users.

#### Phase 6: Naming Cleanup
**Goal**: Remove all legacy "spotlighter" references and establish consistent "MD Quick Look" naming
**Depends on**: Nothing (prerequisite for all v1.1 work)
**Requirements**: NAMING-01, NAMING-02, NAMING-03, NAMING-04
**Success Criteria** (what must be TRUE):
  1. No "spotlighter" references exist in codebase (Swift files, comments, strings)
  2. No "spotlighter" references exist in documentation (README, comments, file names)
  3. Bundle identifiers follow consistent naming scheme (com.rocketpop.MDQuickLook)
  4. "MD Quick Look" appears in all user-facing locations (app name, menu bar, About window placeholder)
**Plans**: 3 plans

Plans:
- [x] 06-01: Complete codebase rename (directories, bundle IDs, Swift files, Makefile)
- [x] 06-02: GitHub repository rename
- [x] 06-03: Planning documentation update

#### Phase 7: App Icon Design
**Goal**: Professional app icon that represents markdown preview functionality
**Depends on**: Phase 6
**Requirements**: ICON-01, ICON-02, ICON-03, ICON-04
**Success Criteria** (what must be TRUE):
  1. 1024x1024 master icon exists following macOS design guidelines
  2. All required icon sizes generated and integrated into Assets.xcassets
  3. Icon appears correctly in Finder (Applications folder, Get Info)
  4. Icon appears in Dock when app is launched
  5. Icon will be available for About window and DMG background (verified in Phase 8+)
**Plans**: 2 plans

Plans:
- [ ] 07-01: Create master icon and generate all sizes
- [ ] 07-02: Integrate into Xcode project and verify display

#### Phase 8: SwiftUI Host App UI
**Goal**: Professional app UI with About window, Preferences, and extension status indicator
**Depends on**: Phase 7 (needs icon for About window)
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-05, UI-06, UI-07
**Success Criteria** (what must be TRUE):
  1. User can open About window from menu bar showing app version and icon
  2. About window displays clickable GitHub repository link
  3. About window includes credits and attribution
  4. User can open Preferences window from menu (minimal placeholder content)
  5. App displays first-launch welcome message or status indicator on launch
  6. Extension status (enabled/disabled) can be displayed to user
  7. All UI elements render correctly in both light and dark appearance modes
**Plans**: TBD

Plans:
- [ ] 08-01: TBD

#### Phase 9: Code Signing & Notarization
**Goal**: App is signed and notarized for secure distribution without security warnings
**Depends on**: Phase 8 (needs working app to sign)
**Requirements**: SIGN-01, SIGN-02, SIGN-03, SIGN-04, SIGN-05, SIGN-06
**Success Criteria** (what must be TRUE):
  1. Apple Developer account is set up and active
  2. App builds with code signing and hardened runtime enabled
  3. Quick Look extension (.appex) is signed with Developer ID
  4. Host app (.app) is signed with Developer ID
  5. App successfully notarizes via xcrun notarytool without errors
  6. Notarization ticket is stapled to app bundle
  7. Signed app launches on clean Mac without security warnings
**Plans**: TBD

Plans:
- [ ] 09-01: TBD

#### Phase 10: Distribution Packaging
**Goal**: Professional DMG distribution package available on GitHub Releases
**Depends on**: Phase 9 (must sign app before packaging)
**Requirements**: DIST-01, DIST-02, DIST-03, DIST-04, DIST-05, DIST-06
**Success Criteria** (what must be TRUE):
  1. Professional DMG created with app icon and layout
  2. DMG is signed and notarized
  3. DMG installation verified on clean Mac (app installs and launches correctly)
  4. GitHub release v1.1 exists with semantic version tag
  5. Signed DMG is attached to GitHub release as downloadable asset
  6. Release notes describe v1.1 changes and installation instructions
**Plans**: TBD

Plans:
- [ ] 10-01: TBD

#### Phase 11: Documentation & Marketing
**Goal**: Comprehensive, engaging documentation that shows users the value and guides installation
**Depends on**: Phase 10 (needs screenshots of signed app, working installation flow)
**Requirements**: DOCS-01, DOCS-02, DOCS-03, DOCS-04, DOCS-05, DOCS-06, DOCS-07
**Success Criteria** (what must be TRUE):
  1. README includes hero screenshot showing markdown preview in Finder
  2. Installation instructions are clear, step-by-step, with screenshots
  3. Troubleshooting section addresses common issues (extension not appearing, quarantine warnings)
  4. Demo GIF demonstrates "spacebar to preview" magic moment in under 10 seconds
  5. 2-3 feature screenshots show different markdown rendering examples
  6. LICENSE file exists (MIT or Apache 2.0)
  7. README is scannable and comprehensive (under 10-12 screens of scrolling)
**Plans**: TBD

Plans:
- [ ] 11-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 6 → 7 → 8 → 9 → 10 → 11

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Extension Foundation | v1.0 | 2/2 | Complete | 2026-01-19 |
| 2. Core Markdown Rendering | v1.0 | 22/22 | Complete | 2026-01-27 |
| 3. Tables & Advanced Elements | v1.0 | 2/2 | Complete | 2026-01-30 |
| 4. Performance & Polish | v1.0 | 2/2 | Complete | 2026-02-01 |
| 5. Documentation Sync | v1.0 | 2/2 | Complete | 2026-02-02 |
| 6. Naming Cleanup | v1.1 | 3/3 | Complete | 2026-02-02 |
| 7. App Icon Design | v1.1 | 0/2 | Not started | - |
| 8. SwiftUI Host App UI | v1.1 | 0/TBD | Not started | - |
| 9. Code Signing & Notarization | v1.1 | 0/TBD | Not started | - |
| 10. Distribution Packaging | v1.1 | 0/TBD | Not started | - |
| 11. Documentation & Marketing | v1.1 | 0/TBD | Not started | - |

---
*Roadmap created: 2026-02-02*
*Last updated: 2026-02-02 (Phase 7 planned)*
