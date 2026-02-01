# Project State: md-spotlighter

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-31)

**Core value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.
**Current focus:** Phase 2 complete - ready for Phase 3

## Current Position

Phase: 2 of 4 (Core Markdown Rendering)
Plan: 6 of 6 in current phase (gap closure)
Status: Phase complete - ready for Phase 3
Progress: [██████░░░░] 63%

Last activity: 2026-02-01 — Completed 02-06 (code block backgrounds and line breaks)

## Performance Metrics

**Velocity:**
- Total plans completed: 8
- Average duration: 7 min
- Total execution time: 1.07 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Extension Foundation | 2/2 | 48 min | 24 min |
| 2. Core Markdown Rendering | 6/6 | 19 min | 3 min |

**Recent Trend:**
- Last 5 plans: 02-03 (1min), 02-04 (3min), 02-05 (5min), 02-06 (2min)
- Trend: Phase 2 consistently fast - solid foundation enables rapid iteration

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Decision | Rationale | Phase | Date |
|----------|-----------|-------|------|
| Track previous run newline status | Prevents double-newlines while ensuring proper paragraph separation | 02-06 | 2026-02-01 |
| Use LayoutManager custom drawing for code block backgrounds | Achieves uniform appearance instead of per-line jagging from inline backgroundColor | 02-06 | 2026-02-01 |
| Set attachment.image before bounds | AppKit requires NSTextAttachment.image to be set before bounds for proper rendering | 02-05 | 2026-02-01 |
| Remove .link attribute from image placeholders | Image placeholders were inheriting link styling (blue color), explicit removal prevents this | 02-05 | 2026-02-01 |
| Use .strikethroughStyle attribute for strikethrough | AttributedString parses ~~text~~ but NSAttributedString requires explicit .strikethroughStyle attribute | 02-05 | 2026-02-01 |
| Detect list type from PresentationIntent component stack | PresentationIntent includes both .listItem and parent components (.orderedList/.unorderedList); examine full stack to determine type | 02-04 | 2026-02-01 |
| Add intra-block newlines in AttributedString | AttributedString provides run boundaries with PresentationIntent; adding newlines before NSAttributedString conversion ensures proper structure | 02-04 | 2026-02-01 |
| Insert list prefixes in NSAttributedString after block styling | Avoid manipulation of AttributedString with PresentationIntent; NSAttributedString manipulation is simpler and more direct | 02-04 | 2026-02-01 |
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
Stopped at: Completed 02-06 (code block backgrounds and line breaks) - Phase 2 complete
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
