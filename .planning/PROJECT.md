# MD Quick Look

## What This Is

A Quick Look extension for macOS that renders markdown files as styled previews in Finder. When you select a `.md` file and press spacebar, you see formatted text (headings, bold, italic, lists, code blocks, tables, task list checkboxes) with YAML front matter displayed as a clean metadata section — all adapting responsively to the available width whether in a spacebar popup, narrow Finder preview pane, or fullscreen Quick Look.

## Core Value

Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## Current State

**Latest release:** v1.2 - Rendering Polish & Features (shipped 2026-02-07)

**What shipped in v1.2:**
- YAML front matter extraction and styled two-column rendering with field capping in narrow contexts
- Width-tier adaptive layout system (narrow/normal) with scaled fonts, spacing, and 640pt max content width
- Content-proportional table sizing with smart wrap/truncate hybrid and compact mode
- GFM task list checkbox rendering with SF Symbol circle icons and system accent blue
- Snapshot-based cross-context integration testing (6 baselines: 3 widths x 2 appearances)

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

**Codebase:** 352 lines of Swift, 52 plans across 15 phases

## Requirements

### Validated

All v1.0 + v1.1 + v1.2 requirements shipped and validated:

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
- ✓ Quick Look window uses system-managed sizing with proper autoresizing — v1.2
- ✓ Extension detects narrow context and passes available width to renderer — v1.2
- ✓ All font sizes scale proportionally in narrow contexts — v1.2
- ✓ Text container insets and padding adapt to available width — v1.2
- ✓ Rendering works correctly across all Quick Look contexts — v1.2
- ✓ Table widths scale to match available container width — v1.2
- ✓ Column min/max widths scale proportionally for narrow contexts — v1.2
- ✓ Cell padding reduces in narrow contexts — v1.2
- ✓ Compact table mode activates at very narrow widths — v1.2
- ✓ Tables remain readable and not clipped in Finder preview pane — v1.2
- ✓ YAML front matter detected and stripped before parsing — v1.2
- ✓ Front matter displayed as styled metadata section — v1.2
- ✓ List values rendered as comma-separated inline text — v1.2
- ✓ Front matter section visually distinct from body content — v1.2
- ✓ Front matter edge cases handled gracefully — v1.2
- ✓ Task list checkboxes with SF Symbol rendering — v1.2
- ✓ Checkboxes colored with system accent blue, baseline-aligned — v1.2
- ✓ Mixed lists (regular + task items) render correctly — v1.2
- ✓ Task list syntax in code blocks not converted — v1.2

### Active

(None — no active milestone. Start next milestone with `/gsd:new-milestone`)

### Future (candidates)

- [ ] Code signing and notarization (App Store prerequisite)
- [ ] Syntax highlighting in code blocks
- [ ] Render actual images (local files)
- [ ] Homebrew Cask formula

### Out of Scope

- Clickable links — preview-only UX
- HTML/CSS/JavaScript rendering — security risk
- Remote image loading — network delays, privacy issues
- Custom CSS/theming — use system appearance defaults
- Other file formats — markdown only
- Mobile/iPad — macOS Quick Look extension only
- macOS 25 or earlier — targeting macOS 26+ only
- Interactive/clickable checkboxes — Quick Look is read-only
- Collapsible front matter — Quick Look is non-interactive
- Horizontal scroll for tables — breaks single-NSTextView architecture
- preferredContentSize — breaks Quick Look auto-resizing

## Context

**User:** Solo developer, project-managing rather than coding. Values learning checkpoints but may request full execution mode later. Three public releases shipped on GitHub.

**Use Case:** Quick visual scan of 3-5 markdown files in Finder to decide which to open. Not a deep-dive tool. Disposable preview experience.

**Target audience:** End users (not just developers) who work with markdown files, especially with AI coding tools. Filling a gap in Finder's Quick Look coverage.

**Distribution:** GitHub release live (v1.2). Eventual App Store submission (future milestone). Pricing deferred until App Store viability is clearer.

**Positioning:** "Very Mac-assed" - feature complete, beautiful, polished, simple. Native feel, follows Apple design guidelines.

**Stack Notes:** Swift + Xcode for modern macOS Quick Look extensions. ImageMagick for icon generation. create-dmg for DMG packaging. swift-snapshot-testing for visual regression testing.

**Timeline:** 19 days from project start (2026-01-19), 52 plans across 15 phases across 3 milestones.

**Known issues:** Dark mode background color inconsistency across YAML/blockquote/code sections (minor visual polish). Test target uses source compilation workaround for SPM C module dependency issue.

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
| Two-tier breakpoint system (narrow/normal) | Matches Quick Look's actual usage contexts; simpler than smooth scaling | ✓ Good - Clean width adaptation |
| Disproportionate heading scaling | Headings shrink 30-40% vs 14% body; maximizes content in narrow views | ✓ Good - Readable at all sizes |
| 640pt max content width | ~75 chars per line for comfortable fullscreen reading | ✓ Good - No wall-of-text |
| Content-proportional table columns | Tables stay compact when content is small, scale when needed | ✓ Good - Balanced layouts |
| Circle SF Symbol checkboxes | User preference over square; matches macOS Reminders aesthetic | ✓ Good - Native feel |
| swift-snapshot-testing for regression | De facto standard, 0.98 precision, NSView support | ✓ Good - Regression safety |
| Extension sources in test target (Option C) | Workaround for SPM C module transitive dependency limitation | ⚠️ Revisit - When Xcode/SPM fix lands |

---
*Last updated: 2026-02-07 after v1.2 milestone*
