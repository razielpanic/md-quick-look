# Project Research Summary

**Project:** MD Quick Look v1.1 - Public Release
**Domain:** macOS Quick Look Extension GitHub Distribution
**Researched:** 2026-02-02
**Confidence:** HIGH

## Executive Summary

MD Quick Look v1.1 focuses on transforming an existing, working Quick Look extension (v1.0 with full markdown rendering) into a polished, publicly distributable macOS application via GitHub. Research reveals that successful first-time public releases require three critical pillars: **removal of installation friction** (code signing + notarization eliminates security warnings), **visual proof before documentation** (demo GIFs and screenshots engage users instantly), and **professional polish** aligned with "Very Mac-assed" positioning (custom app icon, About window, clear README).

The recommended approach prioritizes end-user experience over developer convenience. This means investing in Apple Developer account ($99/year) for notarization (non-negotiable for macOS 10.15+), using DMG distribution over ZIP for better permission handling, and creating comprehensive-but-scannable documentation. The host app should use pure SwiftUI (macOS 13+) for About and Settings windows, avoiding AppKit complexity. The extension itself requires no changes for v1.1.

Key risks center on first-timer mistakes: shipping unsigned code (destroys trust), assuming technical knowledge in documentation (users don't know what Quick Look is), or using deprecated .qlgenerator format (broken on macOS 15+). The v1.0 extension already uses the modern App Extension API, so the main risk is release mechanics (signing, documentation, visual assets) rather than core functionality.

## Key Findings

### Recommended Stack

The v1.1 milestone adds three technology layers to the existing v1.0 Quick Look extension: **SwiftUI host app UI** (About/Settings windows), **icon tooling** (Icon Composer or Image2icon), and **release automation** (gh CLI, create-dmg, notarytool). The existing extension stack (swift-markdown, NSAttributedString rendering, syntax highlighting) remains unchanged.

**Core technologies for v1.1:**
- **SwiftUI Settings scene** (macOS 11+) — Automatic Preferences menu item and Cmd+, shortcut with TabView for multi-page settings; zero external dependencies
- **SwiftUI Window scene** (macOS 13+) — Custom About window replacing default Credits.rtf; full control over layout, links, version display
- **Icon Composer** (macOS 15.3+) — Apple's official tool for multi-layer icons with Liquid Glass effects; exports Xcode-compatible format
- **gh CLI** (latest) — Official GitHub release creation with simple workflow (`gh release create v1.0 ./app.dmg`); no CI/CD complexity for first release
- **create-dmg** (Node.js) — Professional DMG generation with background images and proper layout; industry standard for macOS releases
- **xcrun notarytool** (Xcode 14+) — Required for macOS apps distributed outside App Store; replaced deprecated altool (Nov 2023)

**Anti-stack (what NOT to use):**
- SF Symbols for app icon (UI elements only, not app icons; wrong format/design language)
- altool for notarization (deprecated Nov 2023; must use notarytool)
- Third-party Settings libraries (sindresorhus/Settings adds dependency when native SwiftUI Settings scene exists since macOS 11)
- GitHub Actions for v1.1 (adds complexity for first-timer; manual gh CLI is simpler to debug)
- manual DMG creation with hdiutil (error-prone, time-consuming; create-dmg provides better UX)

### Expected Features

Research into successful macOS app releases and first-timer guidance reveals a clear hierarchy: **table stakes** (users expect these or product feels incomplete), **differentiators** (competitive advantage for "Very Mac-assed" positioning), and **anti-features** (commonly requested but problematic for first releases).

**Must have (table stakes):**
- Clear README with app description — First impression; users judge projects by README quality in 2026
- Installation instructions — Users need step-by-step guidance including "launch app once" requirement for Quick Look extensions
- Screenshots or demo GIF — Visual proof the app works; text-only READMEs underperform
- LICENSE file — Without license, code isn't truly open source; users/contributors avoid legally ambiguous projects
- GitHub Releases page with DMG — Standard distribution for macOS apps; requires notarization for macOS 10.15+
- App icon — Polished apps have recognizable, professional icons; 1024x1024 master image
- Code signing + notarization — macOS 10.15+ shows security warnings for unsigned apps; users abandon immediately
- macOS version compatibility statement — Users need to know if it works on their system before downloading
- Installation troubleshooting — Quick Look plugins require specific setup (de-quarantine, `qlmanage -r`, common errors)

**Should have (competitive advantage):**
- Animated demo GIF in README — Shows "magic moment" of spacebar → rendered markdown in 5-10 seconds; much more engaging than screenshots
- "Very Mac-assed" positioning — Emphasize native feel, polish, "fits right in" messaging in README
- Before/after comparison — Shows problem → solution visually (plain text view vs. rendered preview)
- One-line value prop at top — "Beautiful markdown previews in Finder" instantly communicates benefit
- Clean, scannable README — Comprehensive but not overwhelming; users can find info quickly; keep under 10-12 screens

**Defer (v2+):**
- Homebrew cask — Add after validation (10+ GitHub stars OR 3+ user requests); manual download sufficient for v1.0
- CONTRIBUTING.md — Add after first external contributor or "good first issue" request; premature for first release
- Multi-page documentation site — Overkill for v1.0; creates maintenance burden; README sufficient
- App Store submission — Review delays release, $99/year cost, Quick Look extension App Store complications; validate on GitHub first
- Extensive configuration options — End users want "it just works", not settings; adds support burden; defer to post-v1 based on demand

### Architecture Approach

The v1.1 architecture is straightforward: pure SwiftUI host app containing the existing Quick Look extension (unchanged). The host app and extension are **independent** — the app doesn't control the extension at runtime, it just contains it and provides user-facing UI. Use App scenes (Window for About, Settings for Preferences) targeting macOS 13+, avoiding AppKit entirely. Extension registration is automatic on first app launch; macOS scans PlugIns/ and registers with quicklookd.

**Major components:**
1. **App.swift** — SwiftUI app entry point with Window scene (About) and Settings scene (Preferences); replaces main.swift with NSApplication.shared.run()
2. **AboutWindow.swift** — SwiftUI view showing app icon, version from Bundle, description, GitHub link, optional extension status via `qlmanage -m` parsing
3. **SettingsView.swift** — SwiftUI Form with placeholder content for v1.1; future expansion for theme/font settings using @AppStorage for UserDefaults persistence
4. **ExtensionStatus.swift (optional)** — ObservableObject running `qlmanage -m` to check if extension is enabled; displays "Extension Active ✓" or "Enable in System Settings"
5. **MDQuickLook.appex** — Existing Quick Look extension (PreviewViewController, MarkdownRenderer, TableRenderer) — UNCHANGED for v1.1

**Key architectural decisions:**
- NSApplicationActivationPolicyRegular (default) — App appears in Dock normally; not LSUIElement background app
- Stay open after About window closes — Simpler than quit-on-close; allows reopening from Dock without relaunch
- No direct app-to-extension communication — Extension runs in separate quicklookd process; settings shared via UserDefaults app group (future v1.2+)

### Critical Pitfalls

Research into first-time macOS releases and Quick Look extension distribution identified 15 pitfalls. The top 5 with highest user impact:

1. **Unsigned/unnotarized app creates scary warnings** — Without code signing and notarization, users see "macOS can't verify your app" warnings. In macOS Sequoia, right-click workaround is removed. **Prevention:** Sign with Developer ID certificate, enable hardened runtime, submit to notarytool, staple ticket to app bundle, test on clean Mac.

2. **Wrong release asset format (ZIP vs DMG)** — ZIP files work but may fail to grant permissions; DMG provides better UX and permission handling. **Prevention:** Use DMG for primary distribution, sign and notarize the DMG itself (not just app inside), name following semantic versioning (MDQuickLook-1.0.0.dmg).

3. **App icon missing or wrong format** — App displays with generic icon, or icon appears in Finder but not About window, or Xcode rejects during notarization. **Prevention:** Use Icon Composer (macOS 15.3+) for layered icons, provide all required sizes (512x512 through 16x16 at 1x/2x), don't add shadows/corners (Apple applies automatically).

4. **Installation instructions assume technical knowledge** — README says "install the Quick Look generator" without explaining what Quick Look is or how to verify. **Prevention:** Step-by-step numbered instructions with screenshots, explain "Quick Look = spacebar preview in Finder", troubleshooting section for common issues (extension not appearing, quarantine warnings).

5. **Forgetting to launch app once** — User downloads app, tries spacebar preview, nothing happens. Extension doesn't appear in System Settings. **Prevention:** Make "launch app once" step #1 in installation, app first-launch UI explains extension is installed, include in troubleshooting section.

**Additional pitfalls to avoid:**
- Bundle identifier mistakes (using "com.example" or "spotlighter" in production)
- No screenshots in README (visual proof is table stakes in 2026)
- Version numbering confusion (CFBundleVersion must be integer, CFBundleShortVersionString is semantic version)
- .qlgenerator deprecated format (broken on macOS 15+; verify using .appex App Extension)
- No hardened runtime (notarization fails; enable in Build Settings or use `--options=runtime`)
- Testing only on development Mac (clean Mac test required to catch signing/quarantine issues)

## Implications for Roadmap

Based on research, v1.1 Public Release naturally splits into **5 phases** with clear dependencies. The order prioritizes removing blockers (icon, signing) before documentation (README needs screenshots of signed app).

### Phase 1: App Icon Design & Integration
**Rationale:** Icon is required for About window, DMG creation, and GitHub screenshots. Must come first so other phases can reference polished visuals. Icon Composer requires macOS 15.3+; fallback to Image2icon if unavailable.

**Delivers:** 1024x1024 master icon, AppIcon.appiconset in Assets.xcassets, all required sizes (512x512 through 16x16 at 1x/2x)

**Uses:** Icon Composer (primary), Image2icon ($9.99 fallback), or IconGenerator (free fallback)

**Avoids:** Pitfall #3 (missing icon), using SF Symbols as app icon (wrong format), adding shadows/corners (Apple applies automatically)

### Phase 2: SwiftUI Host App UI
**Rationale:** About and Settings windows provide user-facing polish required for "Very Mac-assed" positioning. Pure SwiftUI targets macOS 13+ without AppKit complexity. Extension registration is automatic (no code needed), but app needs UI to show it's installed.

**Delivers:** App.swift with Window/Settings scenes, AboutWindow.swift with icon/version/GitHub link, SettingsView.swift placeholder, optional ExtensionStatus.swift for activation checking

**Addresses:** Table stakes features (About window, version display, Settings menu integration)

**Implements:** Architecture components #1-4 (App.swift, AboutWindow, SettingsView, ExtensionStatus)

**Avoids:** Pitfall #8 (no first-launch explanation), using LSUIElement (hides from Dock), AppKit when SwiftUI sufficient

### Phase 3: Code Signing & Notarization Setup
**Rationale:** Must notarize before creating DMG or screenshots (test on clean Mac requires signed build). One-time setup (Apple Developer account, certificates) followed by per-release workflow. Hardened runtime and stapling are non-negotiable for macOS 10.15+ distribution.

**Delivers:** Developer ID certificate, notarytool credentials stored, hardened runtime enabled, signed and notarized .app bundle, stapled notarization ticket

**Uses:** xcrun notarytool (Xcode 14+), xcrun stapler, Developer ID Application certificate

**Avoids:** Pitfall #1 (unsigned app), Pitfall #10 (no hardened runtime), using altool (deprecated Nov 2023)

**Research flag:** May need deeper research if first-time code signing issues arise; Apple documentation is comprehensive but error messages are cryptic.

### Phase 4: Distribution Packaging & GitHub Release
**Rationale:** DMG creation requires signed app (Phase 3). GitHub release requires DMG asset. create-dmg handles professional layout with minimal config. gh CLI simplifies release creation without CI/CD complexity.

**Delivers:** MDQuickLook-1.0.0.dmg (signed and notarized), GitHub Release v1.0.0 with DMG asset, release notes, semantic version Git tag

**Uses:** create-dmg (Node.js), gh CLI, semantic versioning (CFBundleShortVersionString = 1.0.0, CFBundleVersion = incremental integer)

**Addresses:** Table stakes features (GitHub Releases with DMG, release notes, version compatibility statement)

**Avoids:** Pitfall #2 (wrong asset format - using ZIP instead of DMG), Pitfall #7 (version numbering confusion), Pitfall #14 (no release notes)

### Phase 5: Documentation & Marketing Materials
**Rationale:** README is last because it needs screenshots of signed app running on clean Mac. Demo GIF requires fully functional installation flow. Documentation is most visible part of release but depends on all prior phases.

**Delivers:** README.md with value prop, demo GIF (spacebar → preview), 2-3 screenshots, installation steps, troubleshooting section, LICENSE file (MIT or Apache 2.0)

**Addresses:** Table stakes features (clear README, screenshots/GIF, installation instructions, troubleshooting, LICENSE), differentiators (demo GIF, before/after comparison, "Very Mac-assed" positioning)

**Avoids:** Pitfall #5 (unclear instructions), Pitfall #6 (screenshot mistakes), Pitfall #12 (no troubleshooting), Pitfall #13 (no uninstall instructions)

**Research flag:** Well-documented patterns for README structure and screenshots; skip additional research.

### Phase Ordering Rationale

- **Icon first** because About window, screenshots, and DMG all reference it; blocking dependency
- **Host app UI second** because it provides structure for first-launch experience and validates extension integration
- **Code signing third** because DMG and screenshots require signed build; can't test on clean Mac without it
- **Distribution fourth** because DMG creation needs signed app; GitHub release depends on DMG asset
- **Documentation last** because README needs screenshots of installed app; demo GIF requires full installation flow

This order **minimizes rework** (don't write README before screenshots exist) and **surfaces blockers early** (icon design, Apple Developer account) before dependent tasks.

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 3 (Code Signing)** — Apple documentation is comprehensive but first-timer error messages (hardened runtime, entitlements, signing order) can be cryptic; may need troubleshooting research if issues arise.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Icon)** — Well-documented with Icon Composer guide, multiple fallback tools, clear HIG
- **Phase 2 (SwiftUI UI)** — Standard SwiftUI patterns; Settings/Window scenes documented extensively
- **Phase 4 (Distribution)** — create-dmg and gh CLI have clear documentation and examples
- **Phase 5 (Documentation)** — README structure well-established; numerous successful examples in research sources

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All tools are official (Apple) or well-established (create-dmg, gh CLI); alternatives documented for each |
| Features | HIGH | Research based on successful macOS app patterns, first-timer guidance from multiple sources, Quick Look plugin ecosystem analysis |
| Architecture | HIGH | Pure SwiftUI approach is well-documented for macOS 13+; extension independence confirmed by Apple docs and community examples |
| Pitfalls | MEDIUM-HIGH | Pitfalls sourced from official Apple docs, real-world GitHub issues, and first-timer mistakes; some pitfalls inferred from patterns rather than explicit sources |

**Overall confidence:** HIGH

The v1.1 milestone has lower technical risk than v1.0 (extension already works) and focuses on well-documented release mechanics. The main uncertainty is first-timer execution (signing workflow, documentation clarity) rather than technical feasibility.

### Gaps to Address

**Icon design skills:**
- Research identified tools (Icon Composer, Image2icon) but not design process for first-timers without graphic design experience
- **Resolution:** Use Figma templates from research sources (macOS Icon Design Template), or ship simple placeholder icon for v1.0 and commission designer for v1.1
- **Not blocking:** Placeholder icon (single letter "M" on gradient) is acceptable for first release

**Notarization wait times:**
- Some reports (Jan 2026) of notarization submissions stuck "In Progress" for 24-72+ hours vs. usual 5-10 minutes
- **Resolution:** Budget extra time for first notarization; if stuck >1 hour, check Apple Developer system status
- **Not blocking:** Happens during Phase 3; doesn't affect earlier phases

**Bundle identifier final naming:**
- Research emphasizes choosing carefully (can't change after App Store submission) but project still uses "md-quick-look" internally
- **Resolution:** Decide final naming (MDQuickLook? MarkdownQuickLook?) in Phase 4 before public release; search/replace across project
- **Not blocking:** Internal development can continue with current naming; update before first GitHub release

**Homebrew cask timing:**
- Research suggests deferring to v1.x after validation (10+ stars), but unclear if should be v1.1 or later
- **Resolution:** Ship v1.0 with manual download; monitor GitHub stars/issues for week; add Homebrew in v1.1 if demand warrants
- **Not blocking:** Manual download sufficient for initial validation

## Sources

### Primary (HIGH confidence)
- [Apple Developer Documentation: Icon Composer](https://developer.apple.com/icon-composer/)
- [Apple Developer Documentation: Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Apple Developer Documentation: SwiftUI Settings Scene](https://developer.apple.com/documentation/swiftui/settings)
- [GitHub CLI Manual: gh release create](https://cli.github.com/manual/gh_release_create)
- [create-dmg by sindresorhus](https://github.com/sindresorhus/create-dmg)
- [QLMarkdown - Reference Quick Look extension](https://github.com/sbarex/QLMarkdown)
- [PreviewMarkdown - Reference implementation](https://github.com/smittytone/PreviewMarkdown)

### Secondary (MEDIUM confidence)
- [Custom About Window in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/)
- [Presenting Preferences Window in SwiftUI](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/)
- [Figma macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027/macos-icon-design-template)
- [Image2icon - Icon converter](https://img2icnsapp.com/)
- [macOS distribution guide](https://gist.github.com/rsms/929c9c2fec231f0cf843a1a746a416f5)
- [Open Source GitHub Repository Pre-Launch Checklist](https://medium.com/binbash-inc/open-source-github-repository-pre-launch-checklist-4a52dbbe4af1)
- [awesome-readme - Curated examples](https://github.com/matiassingers/awesome-readme)

### Tertiary (LOW confidence - first-timer guidance patterns)
- [5 Common Documentation Mistakes](https://medium.com/@AnweshaB/5-common-documentation-mistakes-and-how-to-fix-them-9d095572947c)
- [Sequoia No Longer Supports QuickLook Generator Plug-ins](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)
- [macOS Notarization wait time issues - community reports Jan 2026]

---
*Research completed: 2026-02-02*
*Ready for roadmap: yes*
