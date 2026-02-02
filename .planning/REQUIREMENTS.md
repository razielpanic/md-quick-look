# Requirements: MD Quick Look

**Defined:** 2026-02-02
**Core Value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## v1.1 Requirements - Public Release (GitHub)

Requirements for first public release on GitHub. Professional polish and distribution readiness.

### Naming & Cleanup

- [ ] **NAMING-01**: Remove all "spotlighter" references from codebase
- [ ] **NAMING-02**: Remove all "spotlighter" references from documentation
- [ ] **NAMING-03**: Update bundle identifiers to consistent naming scheme
- [ ] **NAMING-04**: Verify app name "MD Quick Look" appears in all user-facing locations

### App Icon

- [ ] **ICON-01**: Design beautiful app icon (1024x1024 master)
- [ ] **ICON-02**: Generate all required icon sizes for macOS
- [ ] **ICON-03**: Integrate icon into Assets.xcassets
- [ ] **ICON-04**: Verify icon appears in Finder, Dock, About window

### App UI (SwiftUI)

- [ ] **UI-01**: Create About window with app version
- [ ] **UI-02**: Add GitHub repository link to About window
- [ ] **UI-03**: Add credits/attribution to About window
- [ ] **UI-04**: Create Preferences window (minimal/placeholder)
- [ ] **UI-05**: Add first-launch welcome message or status indicator
- [ ] **UI-06**: Verify extension status can be displayed
- [ ] **UI-07**: Test UI in both light and dark appearance modes

### Code Signing & Notarization

- [ ] **SIGN-01**: Set up Apple Developer account
- [ ] **SIGN-02**: Configure code signing with hardened runtime
- [ ] **SIGN-03**: Sign Quick Look extension (.appex)
- [ ] **SIGN-04**: Sign host app (.app)
- [ ] **SIGN-05**: Notarize app via xcrun notarytool
- [ ] **SIGN-06**: Staple notarization ticket to app

### Distribution

- [ ] **DIST-01**: Create DMG with create-dmg tool
- [ ] **DIST-02**: Sign and notarize DMG
- [ ] **DIST-03**: Test DMG on clean Mac (verify installation works)
- [ ] **DIST-04**: Create GitHub release v1.1
- [ ] **DIST-05**: Attach signed DMG to GitHub release
- [ ] **DIST-06**: Write release notes for v1.1

### Documentation

- [ ] **DOCS-01**: Write README with hero screenshot
- [ ] **DOCS-02**: Add installation instructions to README
- [ ] **DOCS-03**: Add troubleshooting section to README
- [ ] **DOCS-04**: Create demo GIF showing "spacebar → preview" magic moment
- [ ] **DOCS-05**: Capture 2-3 feature screenshots (markdown rendering examples)
- [ ] **DOCS-06**: Add LICENSE file (MIT or Apache 2.0)
- [ ] **DOCS-07**: Ensure README is scannable (under 10-12 screens)

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
| NAMING-01 | TBD | Pending |
| NAMING-02 | TBD | Pending |
| NAMING-03 | TBD | Pending |
| NAMING-04 | TBD | Pending |
| ICON-01 | TBD | Pending |
| ICON-02 | TBD | Pending |
| ICON-03 | TBD | Pending |
| ICON-04 | TBD | Pending |
| UI-01 | TBD | Pending |
| UI-02 | TBD | Pending |
| UI-03 | TBD | Pending |
| UI-04 | TBD | Pending |
| UI-05 | TBD | Pending |
| UI-06 | TBD | Pending |
| UI-07 | TBD | Pending |
| SIGN-01 | TBD | Pending |
| SIGN-02 | TBD | Pending |
| SIGN-03 | TBD | Pending |
| SIGN-04 | TBD | Pending |
| SIGN-05 | TBD | Pending |
| SIGN-06 | TBD | Pending |
| DIST-01 | TBD | Pending |
| DIST-02 | TBD | Pending |
| DIST-03 | TBD | Pending |
| DIST-04 | TBD | Pending |
| DIST-05 | TBD | Pending |
| DIST-06 | TBD | Pending |
| DOCS-01 | TBD | Pending |
| DOCS-02 | TBD | Pending |
| DOCS-03 | TBD | Pending |
| DOCS-04 | TBD | Pending |
| DOCS-05 | TBD | Pending |
| DOCS-06 | TBD | Pending |
| DOCS-07 | TBD | Pending |

**Coverage:**
- v1.1 requirements: 33 total
- Mapped to phases: 0 (awaiting roadmap creation)
- Unmapped: 33

---
*Requirements defined: 2026-02-02*
*Last updated: 2026-02-02 after v1.1 milestone start*
