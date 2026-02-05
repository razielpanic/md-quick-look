# Requirements: MD Quick Look

**Defined:** 2026-02-02
**Core Value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## v1.1 Requirements - Public Release (GitHub)

Requirements for first public release on GitHub. Professional polish and distribution readiness.

### Naming & Cleanup

- [x] **NAMING-01**: Remove all "spotlighter" references from codebase
- [x] **NAMING-02**: Remove all "spotlighter" references from documentation
- [x] **NAMING-03**: Update bundle identifiers to consistent naming scheme
- [x] **NAMING-04**: Verify app name "MD Quick Look" appears in all user-facing locations

### App Icon

- [x] **ICON-01**: Design beautiful app icon (1024x1024 master)
- [x] **ICON-02**: Generate all required icon sizes for macOS
- [x] **ICON-03**: Integrate icon into Assets.xcassets
- [x] **ICON-04**: Verify icon appears in Finder, Dock, About window

### App UI (SwiftUI)

- [x] **UI-01**: Create About window with app version
- [x] **UI-02**: Add GitHub repository link to About window
- [x] **UI-03**: Add credits/attribution to About window
- [x] **UI-04**: Create Preferences window (minimal/placeholder)
- [x] **UI-05**: Add first-launch welcome message or status indicator
- [x] **UI-06**: Verify extension status can be displayed
- [x] **UI-07**: Test UI in both light and dark appearance modes

### Code Signing & Notarization

- [ ] **SIGN-01**: Set up Apple Developer account
- [ ] **SIGN-02**: Configure code signing with hardened runtime
- [ ] **SIGN-03**: Sign Quick Look extension (.appex)
- [ ] **SIGN-04**: Sign host app (.app)
- [ ] **SIGN-05**: Notarize app via xcrun notarytool
- [ ] **SIGN-06**: Staple notarization ticket to app

### Distribution

- [x] **DIST-01**: Create DMG with create-dmg tool
- [x] **DIST-02**: DMG is unsigned with Gatekeeper bypass instructions (signing deferred)
- [x] **DIST-03**: Test DMG installation (verify app installs and launches correctly)
- [x] **DIST-04**: Create GitHub release v1.1.0
- [x] **DIST-05**: Attach unsigned DMG to GitHub release as downloadable asset
- [x] **DIST-06**: Write release notes with installation instructions and Gatekeeper bypass

### Documentation

- [x] **DOCS-01**: Write README with hero screenshot
- [x] **DOCS-02**: Add installation instructions to README
- [x] **DOCS-03**: Add troubleshooting section to README
- [x] **DOCS-04**: Create demo GIF showing "spacebar → preview" magic moment
- [x] **DOCS-05**: Capture 2-3 feature screenshots (markdown rendering examples)
- [x] **DOCS-06**: Add LICENSE file (MIT or Apache 2.0)
- [x] **DOCS-07**: Ensure README is scannable (under 10-12 screens)

## v1.2+ Requirements

Future milestones (App Store, advanced features).

### App Store Preparation

- **STORE-01**: Preview pane rendering optimization (narrow column view)
- **STORE-02**: Table rendering improvements for small spaces
- **STORE-03**: App Store screenshots and metadata
- **STORE-04**: App Store submission
- **STORE-05**: Privacy manifest (if required)

### Advanced Features (v2.0+)

- **FEAT-01**: Syntax highlighting in code blocks
- **FEAT-02**: Render actual images (local files)
- **FEAT-03**: Display YAML front matter as formatted metadata
- **FEAT-04**: Render GFM task lists with checkboxes
- **FEAT-05**: Homebrew Cask formula

## Out of Scope

Explicitly excluded from v1.1 to maintain focus on GitHub release.

| Feature | Reason |
|---------|--------|
| Preview pane optimization | Deferred to v1.2 App Store milestone - not critical for GitHub release |
| Syntax highlighting | Deferred to v2.0 - v1.0 already works without it |
| Actual image rendering | Deferred to v2.0 - placeholders sufficient for initial release |
| YAML front matter | Deferred to v2.0 - niche feature, not essential |
| Homebrew Cask | Deferred until after validation (10+ GitHub stars) |
| Auto-update mechanism | Not needed for GitHub DMG distribution |
| App Store submission | Deferred to v1.2 milestone after GitHub feedback |
| Multi-language README | English-only for initial release |
| macOS 14 or earlier | Targeting macOS 26+ only |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| NAMING-01 | Phase 6 | Complete |
| NAMING-02 | Phase 6 | Complete |
| NAMING-03 | Phase 6 | Complete |
| NAMING-04 | Phase 6 | Complete |
| ICON-01 | Phase 7 | Complete |
| ICON-02 | Phase 7 | Complete |
| ICON-03 | Phase 7 | Complete |
| ICON-04 | Phase 7 | Complete |
| UI-01 | Phase 8 | Complete |
| UI-02 | Phase 8 | Complete |
| UI-03 | Phase 8 | Complete |
| UI-04 | Phase 8 | Complete |
| UI-05 | Phase 8 | Complete |
| UI-06 | Phase 8 | Complete |
| UI-07 | Phase 8 | Complete |
| SIGN-01 | Phase 9 | Pending |
| SIGN-02 | Phase 9 | Pending |
| SIGN-03 | Phase 9 | Pending |
| SIGN-04 | Phase 9 | Pending |
| SIGN-05 | Phase 9 | Pending |
| SIGN-06 | Phase 9 | Pending |
| DIST-01 | Phase 9 | Complete |
| DIST-02 | Phase 9 | Complete |
| DIST-03 | Phase 9 | Complete |
| DIST-04 | Phase 9 | Complete |
| DIST-05 | Phase 9 | Complete |
| DIST-06 | Phase 9 | Complete |
| DOCS-01 | Phase 11 | Complete |
| DOCS-02 | Phase 11 | Complete |
| DOCS-03 | Phase 11 | Complete |
| DOCS-04 | Phase 11 | Complete |
| DOCS-05 | Phase 11 | Complete |
| DOCS-06 | Phase 11 | Complete |
| DOCS-07 | Phase 11 | Complete |

**Coverage:**
- v1.1 requirements: 34 total
- Mapped to phases: 34 (100% coverage)
- Unmapped: 0

---
*Requirements defined: 2026-02-02*
*Last updated: 2026-02-05 after Phase 9 completion*
