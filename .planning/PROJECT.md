# md-spotlighter

## What This Is

A Quick Look extension for macOS that renders markdown files as styled previews in Finder. When you select a `.md` file and press spacebar, you see formatted text (headings, bold, italic, lists, code blocks) instead of raw markdown—enabling quick context scanning before deciding which file to open.

## Core Value

Instant, effortless context about markdown file content without leaving Finder or opening an editor.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Quick Look extension loads `.md` files from Finder
- [ ] Renders headings with visual hierarchy
- [ ] Renders bold and italic text
- [ ] Renders unordered and ordered lists
- [ ] Renders code blocks with syntax highlighting
- [ ] Links display as normal text
- [ ] Images display as `[Image: filename]` placeholder
- [ ] Tables display as raw markdown
- [ ] Preview loads instantly without perceptible delay
- [ ] Works on macOS 14+ (latest versions only)

### Out of Scope

- Table rendering — deferred, adds processing complexity without value for quick scans
- Image rendering — expensive for quick preview use case, placeholder sufficient
- Custom CSS/theming — use system appearance defaults
- Other file formats — markdown only
- Mobile/iPad — macOS Quick Look extension only
- Older macOS versions — targeting newest versions only

## Context

**User:** Solo developer, project-managing rather than coding. Values learning checkpoints but may request full execution mode later.

**Use Case:** Quick visual scan of 3-5 markdown files in Finder to decide which to open. Not a deep-dive tool. Disposable preview experience.

**Distribution:** GitHub first (code-first sharing), eventual App Store submission considered. Pricing (free vs. paid) deferred until App Store viability is clearer.

**Stack Notes:** Swift + Xcode for modern macOS Quick Look extensions. User has Xcode installed, comfortable delegating technical implementation.

## Constraints

- **Tech stack**: Swift, macOS Quick Look extension API — no alternatives
- **macOS support**: Latest versions only (14+), no legacy support required
- **Performance**: Instant rendering — no processing delays acceptable
- **Scope**: Minimal feature set for speed of creation and deployment

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Minimal rendering (no tables/images) | Fast deployment, can add later if needed | — Pending |
| macOS-only Quick Look extension | True system integration vs. standalone app | — Pending |
| GitHub + eventual App Store | Community-first with commercial consideration | — Pending |

---
*Last updated: 2025-01-19 after initialization*
