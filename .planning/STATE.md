# Project State: md-spotlighter

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-31)

**Core value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.
**Current focus:** Phase 2 - Core Markdown Rendering

## Current Position

Phase: 2 of 4 (Core Markdown Rendering)
Plan: 1 of 4 in current phase
Status: In progress
Progress: [███░░░░░░░] 30%

Last activity: 2026-02-01 — Completed 02-01-PLAN.md (MarkdownRenderer foundation)

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: 17 min
- Total execution time: 0.87 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Extension Foundation | 2/2 | 48 min | 24 min |
| 2. Core Markdown Rendering | 1/4 | 4 min | 4 min |

**Recent Trend:**
- Last 5 plans: 01-01 (3min), 01-02 (45min), 02-01 (4min)
- Trend: 02-01 very fast - foundation was solid, only needed MarkdownRenderer implementation

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Decision | Rationale | Phase | Date |
|----------|-----------|-------|------|
| AttributedString → NSAttributedString conversion | AttributedString font/color are SwiftUI-specific; NSAttributedString for AppKit | 02-01 | 2026-02-01 |
| PresentationIntent for heading detection | Reliable semantic structure from AttributedString(markdown:) | 02-01 | 2026-02-01 |
| Use AttributedString(markdown:) instead of WKWebView | Synchronous rendering, simpler code, instant display | 01-02 | 2026-02-01 |
| Install to /Applications instead of ~/Library/QuickLook | Required for proper pluginkit extension registration | 01-02 | 2026-02-01 |
| Use "open app then kill" for registration | Triggers pluginkit discovery automatically | 01-02 | 2026-02-01 |
| Use AttributedString(markdown:) for rendering | Native macOS 12+ support, simpler than AST traversal | 01-01 | 2026-01-31 |
| Combine Task 1+2 implementation | Avoid non-compilable intermediate state | 01-01 | 2026-01-31 |
| OSLog for debug logging | Standard macOS subsystem logging pattern | 01-01 | 2026-01-31 |

Project-level decisions (from PROJECT.md):
- macOS 26+ (Tahoe) only: Target latest OS, avoid legacy API complexity
- macOS-only Quick Look extension: True system integration vs. standalone app
- No syntax highlighting in v1: Keep v1 simple and fast, defer to v2
- Include tables in v1, defer images: Tables are text-based (low complexity), images require sandbox workarounds

### Pending Todos

None yet.

### Blockers/Concerns

| Issue | Impact | Phase | Resolution |
|-------|--------|-------|------------|
| xcode-select points to Command Line Tools | Cannot verify build in 01-01 | 01-01 | RESOLVED: Built successfully in 01-02 |
| Heading sizes not differentiated | All text same size in preview | 01-02 | RESOLVED: Implemented in 02-01 with MarkdownRenderer |

## Session Continuity

Last session: 2026-02-01
Stopped at: Completed 02-01-PLAN.md execution (MarkdownRenderer foundation)
Resume file: None
Next: Plan 02-02 - Code Block Styling (monospace fonts, background colors, syntax indication)
