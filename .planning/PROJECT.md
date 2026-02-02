# md-spotlighter

## What This Is

A Quick Look extension for macOS that renders markdown files as styled previews in Finder. When you select a `.md` file and press spacebar, you see formatted text (headings, bold, italic, lists, code blocks, tables) instead of raw markdown—enabling quick context scanning before deciding which file to open.

## Core Value

Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## Current State

**Latest release:** v1.0 - Initial Release (shipped 2026-02-02)

**What shipped:**
- Quick Look extension with full markdown rendering (headings, formatting, lists, code blocks, blockquotes, tables)
- Image placeholders and text-only links
- Instant rendering performance (<1 second, 500KB truncation for large files)
- Automatic dark mode support via system semantic colors
- macOS 26+ (Tahoe) support

**Codebase:** 14,482 lines of Swift

**Next milestone:** Planning v2.0 features (syntax highlighting, actual image rendering, YAML front matter, task lists)

## Requirements

### Validated

All v1.0 requirements shipped and validated:

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
- ✓ Preview renders instantly (<1 second for typical files) — v1.0 (achieved with 500KB truncation)
- ✓ Works on macOS 26+ (Tahoe and later) — v1.0
- ✓ Respects system appearance (light/dark mode) — v1.0

### Active

Next milestone features (v2.0 candidates):

- [ ] Syntax highlighting in code blocks
- [ ] Render actual images (local files)
- [ ] Display YAML front matter as formatted metadata
- [ ] Render GFM task lists with checkboxes

### Out of Scope

- Syntax highlighting (deferred to v2)
- Actual image rendering (deferred to v2) — placeholders only in v1
- YAML front matter display (deferred to v2)
- Clickable links — preview-only UX
- HTML/CSS/JavaScript rendering — security risk
- Remote image loading — network delays, privacy issues
- Custom CSS/theming — use system appearance defaults
- Other file formats — markdown only
- Mobile/iPad — macOS Quick Look extension only
- macOS 25 or earlier — targeting macOS 26+ only

## Context

**User:** Solo developer, project-managing rather than coding. Values learning checkpoints but may request full execution mode later.

**Use Case:** Quick visual scan of 3-5 markdown files in Finder to decide which to open. Not a deep-dive tool. Disposable preview experience.

**Distribution:** GitHub first (code-first sharing), eventual App Store submission considered. Pricing (free vs. paid) deferred until App Store viability is clearer.

**Stack Notes:** Swift + Xcode for modern macOS Quick Look extensions. User has Xcode installed, comfortable delegating technical implementation.

**v1.0 shipped:** 14 days from project start (2026-01-19) to ship (2026-02-02), 30 plans across 5 phases, zero tech debt.

## Constraints

- **Tech stack**: Swift, macOS Quick Look extension API — no alternatives
- **macOS support**: macOS 26+ (Tahoe) only, no legacy support
- **Performance**: Instant rendering (<1 second) — no processing delays acceptable
- **Scope**: Minimal feature set for speed of creation and deployment

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Include tables in v1, defer images | Tables are text-based (low complexity), images require sandbox workarounds | ✓ Good - Tables shipped successfully |
| macOS 26+ only (Tahoe) | Target latest OS, avoid legacy API complexity | ✓ Good - Simplified development |
| macOS-only Quick Look extension | True system integration vs. standalone app | ✓ Good - Seamless Finder integration |
| GitHub + eventual App Store | Community-first with commercial consideration | — Pending |
| No syntax highlighting in v1 | Keep v1 simple and fast, defer to v2 | ✓ Good - Fast delivery |
| AttributedString(markdown:) instead of WKWebView | Synchronous rendering, simpler code, instant display | ✓ Good - Core rendering approach |
| Custom attributes for PresentationIntent bridging | PresentationIntent doesn't bridge to NSAttributedString | ✓ Good - Enabled advanced layout |
| LayoutManager custom drawing for backgrounds/borders | Uniform appearance instead of per-line jagging | ✓ Good - Professional appearance |
| Hybrid table rendering | Source range splitting preserves document structure | ✓ Good - Tables + markdown coexist |
| 500KB truncation threshold | Supports large docs while guaranteeing <1s render | ✓ Good - Prevents hangs |
| System semantic colors throughout | Automatic dark mode support | ✓ Good - Zero manual handling |

---
*Last updated: 2026-02-02 after v1.0 milestone completion*
