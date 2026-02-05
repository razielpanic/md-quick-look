# MD Quick Look

## What This Is

A Quick Look extension for macOS that renders markdown files as styled previews in Finder. When you select a `.md` file and press spacebar, you see formatted text (headings, bold, italic, lists, code blocks, tables) instead of raw markdown—enabling quick context scanning before deciding which file to open. Publicly available on GitHub with a polished host app, professional icon, and comprehensive documentation.

## Core Value

Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## Current State

**Latest release:** v1.1 - Public Release (GitHub) (shipped 2026-02-05)

**What shipped in v1.1:**
- Complete "MD Quick Look" branding (com.rocketpop.MDQuickLook)
- Professional app icon (purple gradient star/octothorpe)
- SwiftUI host app with About window, Preferences, first-launch welcome
- Unsigned DMG on GitHub Releases with Gatekeeper bypass instructions
- README with hero screenshot, demo GIF, installation guide, troubleshooting
- MIT license

**What shipped in v1.0:**
- Quick Look extension with full markdown rendering (headings, formatting, lists, code blocks, blockquotes, tables)
- Image placeholders and text-only links
- Instant rendering performance (<1 second, 500KB truncation for large files)
- Automatic dark mode support via system semantic colors
- macOS 26+ (Tahoe) support

**Codebase:** 240 lines of Swift, 44 plans across 10 phases

## Requirements

### Validated

All v1.0 + v1.1 requirements shipped and validated:

- ✓ Render headings with visual hierarchy (h1-h6) — v1.0
- ✓ Render bold text — v1.0
- ✓ Render italic text — v1.0
- ✓ Render strikethrough text — v1.0
- ✓ Render unordered lists — v1.0
- ✓ Render ordered lists — v1.0
- ✓ Render code blocks with monospaced font — v1.0
- ✓ Render blockquotes — v1.0
- ✓ Render tables (GFM) — v1.0
- ✓ Render links as text (no clicking) — v1.0
- ✓ Display images as placeholders `[Image: filename]` — v1.0
- ✓ Quick Look extension loads .md files from Finder — v1.0
- ✓ Preview renders instantly (<1 second for typical files) — v1.0
- ✓ Works on macOS 26+ (Tahoe and later) — v1.0
- ✓ Respects system appearance (light/dark mode) — v1.0
- ✓ Remove all "spotlighter" references from codebase and documentation — v1.1
- ✓ Professional about window with version, credits, GitHub link — v1.1
- ✓ Preferences window with extension status — v1.1
- ✓ First-launch welcome with extension setup guidance — v1.1
- ✓ Professional app icon (all macOS sizes) — v1.1
- ✓ GitHub README with screenshots and installation instructions — v1.1
- ✓ Unsigned DMG distribution on GitHub Releases — v1.1
- ✓ Release notes and documentation for end users — v1.1

### Active

Future milestones (candidates):

- [ ] Code signing and notarization (App Store prerequisite)
- [ ] Preview pane rendering optimization (narrow column view context)
- [ ] Table rendering improvements for small spaces
- [ ] Syntax highlighting in code blocks
- [ ] Render actual images (local files)
- [ ] Display YAML front matter as formatted metadata
- [ ] Render GFM task lists with checkboxes
- [ ] Homebrew Cask formula

### Out of Scope

- Clickable links — preview-only UX
- HTML/CSS/JavaScript rendering — security risk
- Remote image loading — network delays, privacy issues
- Custom CSS/theming — use system appearance defaults
- Other file formats — markdown only
- Mobile/iPad — macOS Quick Look extension only
- macOS 25 or earlier — targeting macOS 26+ only

## Context

**User:** Solo developer, project-managing rather than coding. Values learning checkpoints but may request full execution mode later. First public release shipped on GitHub.

**Use Case:** Quick visual scan of 3-5 markdown files in Finder to decide which to open. Not a deep-dive tool. Disposable preview experience.

**Target audience:** End users (not just developers) who work with markdown files, especially with AI coding tools. Filling a gap in Finder's Quick Look coverage.

**Distribution:** GitHub release live (v1.1). Eventual App Store submission (future milestone). Pricing deferred until App Store viability is clearer.

**Positioning:** "Very Mac-assed" - feature complete, beautiful, polished, simple. Native feel, follows Apple design guidelines.

**Stack Notes:** Swift + Xcode for modern macOS Quick Look extensions. ImageMagick for icon generation. create-dmg for DMG packaging.

**Timeline:** 18 days from project start (2026-01-19) to public release (2026-02-05), 44 plans across 10 phases.

## Constraints

- **Tech stack**: Swift, macOS Quick Look extension API — no alternatives
- **macOS support**: macOS 26+ (Tahoe) only, no legacy support
- **Performance**: Instant rendering (<1 second) — no processing delays acceptable
- **Scope**: Minimal feature set for speed of creation and deployment
- **Distribution**: Unsigned for now — code signing deferred to App Store milestone

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Include tables in v1, defer images | Tables are text-based (low complexity), images require sandbox workarounds | ✓ Good - Tables shipped successfully |
| macOS 26+ only (Tahoe) | Target latest OS, avoid legacy API complexity | ✓ Good - Simplified development |
| macOS-only Quick Look extension | True system integration vs. standalone app | ✓ Good - Seamless Finder integration |
| GitHub + eventual App Store | Community-first with commercial consideration | ✓ Good - v1.1 shipped on GitHub |
| No syntax highlighting in v1 | Keep v1 simple and fast, defer to v2 | ✓ Good - Fast delivery |
| AttributedString(markdown:) instead of WKWebView | Synchronous rendering, simpler code, instant display | ✓ Good - Core rendering approach |
| Custom attributes for PresentationIntent bridging | PresentationIntent doesn't bridge to NSAttributedString | ✓ Good - Enabled advanced layout |
| LayoutManager custom drawing for backgrounds/borders | Uniform appearance instead of per-line jagging | ✓ Good - Professional appearance |
| Hybrid table rendering | Source range splitting preserves document structure | ✓ Good - Tables + markdown coexist |
| 500KB truncation threshold | Supports large docs while guaranteeing <1s render | ✓ Good - Prevents hangs |
| System semantic colors throughout | Automatic dark mode support | ✓ Good - Zero manual handling |
| GitHub first, App Store later | Get feedback from early adopters before App Store polish | ✓ Good - v1.1 shipped on GitHub |
| Defer preview pane optimization to v1.2 | Ship GitHub release faster, polish for App Store | ✓ Good - Shipped on time |
| Unsigned release with Gatekeeper bypass | Ship faster, defer signing to App Store milestone | ✓ Good - Functional distribution |
| Geometric icon generation (ImageMagick) | No Ghostscript dependency, more reliable than fonts | ✓ Good - Portable pipeline |
| SwiftUI Settings scene | Standard macOS Cmd+, shortcut behavior | ✓ Good - Native feel |
| MIT License | Standard permissive license for open source | ✓ Good - Community-friendly |
| create-dmg for packaging | Automated DMG layout with Applications symlink | ✓ Good - Professional installer |

---
*Last updated: 2026-02-05 after v1.1 milestone*
