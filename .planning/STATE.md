# Project State: md-spotlighter

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-31)

**Core value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.
**Current focus:** Phase 2 complete - ready for Phase 3

## Current Position

Phase: 2 of 4 (Core Markdown Rendering)
Plan: 3 of 3 in current phase
Status: Phase complete
Progress: [█████░░░░░] 50%

Last activity: 2026-02-01 — Completed Phase 2 (Core Markdown Rendering) + Quick fix 001 (block newline rendering)

## Performance Metrics

**Velocity:**
- Total plans completed: 5
- Average duration: 11 min
- Total execution time: 0.95 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Extension Foundation | 2/2 | 48 min | 24 min |
| 2. Core Markdown Rendering | 3/3 | 9 min | 3 min |

**Recent Trend:**
- Last 5 plans: 01-02 (45min), 02-01 (4min), 02-02 (4min), 02-03 (1min)
- Trend: Phase 2 consistently fast - solid foundation enables rapid iteration

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Decision | Rationale | Phase | Date |
|----------|-----------|-------|------|
| Track PresentationIntent.Kind for block boundaries | AttributedString strips inter-block newlines; detect boundaries by comparing component kinds | Quick-001 | 2026-02-01 |
| Default paragraph spacing (8pt) for all text | Ensures visual separation between paragraphs; element-specific styles can override | 02-03 | 2026-02-01 |
| SF Symbol with explicit bounds for image placeholders | NSTextAttachment needs bounds to display; y=-3 centers with baseline | 02-03 | 2026-02-01 |
| Blockquote border at x=4-8, text at x=20 | Prevents border from intersecting with text content | 02-03 | 2026-02-01 |
| Custom attributes for PresentationIntent bridging | PresentationIntent doesn't bridge to NSAttributedString; use custom attributes like .blockquoteMarker | 02-02 | 2026-02-01 |
| Inline code lighter background than code blocks | Visual distinction: quaternarySystemFill vs secondarySystemFill | 02-02 | 2026-02-01 |
| Code blocks wrap (no horizontal scroll) | Simpler implementation, more common in Quick Look | 02-02 | 2026-02-01 |
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
| PresentationIntent doesn't bridge to NSAttributedString | Cannot use PresentationIntent in NSLayoutManager | 02-02 | RESOLVED: Use custom attributes pattern |
| xcode-select points to Command Line Tools | Cannot verify build in 01-01 | 01-01 | RESOLVED: Built successfully in 01-02 |
| Heading sizes not differentiated | All text same size in preview | 01-02 | RESOLVED: Implemented in 02-01 with MarkdownRenderer |

## Session Continuity

Last session: 2026-02-01
Stopped at: Completed quick task 001 (fix newline rendering at block boundaries)
Resume file: None
Next: Plan Phase 3 (Tables & Advanced Elements)

**Quick fixes applied:**
- 001: Fixed block boundary newline rendering (3min) - Blocks now properly separated in preview

Config (if exists):
{
  "planning": {
    "commit_docs": true,
    "branching_strategy": "none"
  },
  "workflow": {
    "verifier": true
  },
  "model_profile": "balanced"
}
