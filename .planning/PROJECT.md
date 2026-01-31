# md-spotlighter

## What This Is

A Quick Look extension for macOS that renders markdown files as styled previews in Finder. When you select a `.md` file and press spacebar, you see formatted text (headings, bold, italic, lists, code blocks) instead of raw markdown—enabling quick context scanning before deciding which file to open.

## Core Value

Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## Current Milestone: v1.0 - Initial Release

**Goal:** Deliver a working Quick Look extension that renders markdown files with essential formatting in Finder.

**Target features:**
- All basic markdown elements (headings, text formatting, lists, code blocks, blockquotes, tables)
- Image placeholders and text-only links
- Instant rendering performance
- System appearance support

**See:** `.planning/REQUIREMENTS.md` for full requirements (15 total)

## Requirements

### Validated

(None yet — ship to validate)

### Active

See `.planning/REQUIREMENTS.md` for complete v1.0 requirements.

**Summary:** 15 requirements across Markdown Rendering and System Integration categories, covering all essential markdown elements, instant rendering, and macOS 26+ support.

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

## Constraints

- **Tech stack**: Swift, macOS Quick Look extension API — no alternatives
- **macOS support**: macOS 26+ (Tahoe) only, no legacy support
- **Performance**: Instant rendering (<1 second) — no processing delays acceptable
- **Scope**: Minimal feature set for speed of creation and deployment

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Include tables in v1, defer images | Tables are text-based (low complexity), images require sandbox workarounds | — Pending |
| macOS 26+ only (Tahoe) | Target latest OS, avoid legacy API complexity | — Pending |
| macOS-only Quick Look extension | True system integration vs. standalone app | — Pending |
| GitHub + eventual App Store | Community-first with commercial consideration | — Pending |
| No syntax highlighting in v1 | Keep v1 simple and fast, defer to v2 | — Pending |

---
*Last updated: 2026-01-31 after v1.0 milestone definition*
