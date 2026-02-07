# Project Milestones: md-quick-look

## v1.2 Rendering Polish & Features (Shipped: 2026-02-07)

**Delivered:** Width-adaptive rendering with YAML front matter display, responsive tables, task list checkboxes, and cross-context snapshot testing.

**Phases completed:** 11-15 (8 plans total)

**Key accomplishments:**

- YAML front matter extraction and styled two-column rendering with field capping in narrow contexts
- Width-tier adaptive layout system — two-tier responsive rendering with scaled fonts, spacing, and 640pt max content width
- Content-proportional table sizing with smart wrap/truncate hybrid and compact mode for narrow contexts
- GFM task list checkbox rendering with SF Symbol circle icons and system accent blue
- Snapshot-based cross-context integration testing — 6 baselines covering 3 widths x 2 appearances

**Stats:**

- 56 files modified
- 352 lines of Swift (codebase total)
- 5 phases, 8 plans, 22 requirements
- 2 days (2026-02-06 → 2026-02-07)

**Git range:** `feat(11-01)` → `docs(v1.2)`

**What's next:** Code signing and notarization, syntax highlighting, or image rendering

---

## v1.1 Public Release (GitHub) (Shipped: 2026-02-05)

**Delivered:** Polished, publicly distributable macOS app with professional UI, app icon, unsigned DMG on GitHub Releases, and comprehensive documentation.

**Phases completed:** 6-10 (14 plans total)

**Key accomplishments:**

- Complete naming cleanup — removed all "spotlighter" references, established "MD Quick Look" branding with com.rocketpop.MDQuickLook bundle IDs
- Professional app icon — geometric star/octothorpe design with purple gradient, all macOS icon sizes generated via ImageMagick
- Full SwiftUI host app UI — About window with version and GitHub link, Preferences with extension status, first-launch welcome with setup guidance
- GitHub distribution — unsigned DMG (3.5MB) published as GitHub release v1.1.0 with Gatekeeper bypass instructions
- Comprehensive documentation — README with hero screenshot, demo GIF, installation guide, troubleshooting section, and MIT license

**Stats:**

- 14 plans across 5 phases
- 240 lines of Swift (codebase total)
- 28 requirements shipped (SIGN-01–06 deferred by design)
- 4 days (2026-02-02 → 2026-02-05)
- 115 commits

**Git range:** `feat(06-01)` → `docs(09-02)`

**What's next:** v1.2 App Store preparation or v2.0 advanced features (syntax highlighting, image rendering, YAML front matter, task lists)

---

## v1.0 Initial Release (Shipped: 2026-02-02)

**Delivered:** Working Quick Look extension that renders markdown files with essential formatting in Finder.

**Phases completed:** 1-5 (30 plans total)

**Key accomplishments:**

- Quick Look extension successfully loads and renders markdown files in Finder - spacebar preview works with full system integration
- All essential markdown elements render correctly - headings, bold, italic, lists, code blocks, blockquotes, links, images (as placeholders)
- GitHub-flavored markdown tables supported - hybrid rendering preserves document order with proper table layout
- Instant rendering performance - <1 second for typical files, 500KB truncation for large files
- Automatic dark mode support - semantic colors adapt to system appearance
- Production-ready codebase - zero technical debt, comprehensive error handling, 100% requirements coverage

**Stats:**

- 30 plans across 5 phases
- 14,482 lines of Swift
- 15 requirements (11 markdown rendering, 4 system integration)
- 14 days from project start to ship (2026-01-19 → 2026-02-02)

**Git range:** `feat(01-01)` → `feat(04-02)`

**What's next:** Plan v2.0 features (syntax highlighting, actual image rendering, YAML front matter, task lists)

---
