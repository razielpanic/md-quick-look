# Project State: md-spotlighter

## Project Reference

See: .planning/PROJECT.md (updated 2026-01-31)

**Core value:** Instant, effortless context about markdown file content without leaving Finder or opening an editor.
**Current focus:** All v1 phases complete - documentation synchronized with implementation

## Current Position

Phase: 5 of 5 (Documentation Sync)
Plan: 1 of 1 in current phase
Status: Complete - all documentation synchronized with actual implementation state
Progress: [██████████] 100%

Last activity: 2026-02-02 — Completed 05-01-PLAN.md (documentation sync)

## Performance Metrics

**Velocity:**
- Total plans completed: 27
- Average duration: 4.9 min
- Total execution time: 2.6 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Extension Foundation | 2/2 | 48 min | 24 min |
| 2. Core Markdown Rendering | 22/22 | 60 min | 2.7 min |
| 3. Tables & Advanced Elements | 2/2 | 61 min | 30.5 min |
| 4. Performance & Polish | 2/2 | 2 min | 1 min |
| 5. Documentation Sync | 1/1 | 1 min | 1 min |

**Recent Trend:**
- Last 5 plans: 03-01 (1min), 03-02 (60min), 04-01 (1min), 04-02 (<1min), 05-01 (1min)
- Trend: Documentation and polish tasks extremely fast with solid foundation

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

| Decision | Rationale | Phase | Date |
|----------|-----------|-------|------|
| Use NSColor.secondarySystemFill for inline code backgrounds | Matches code block background for consistent styling across inline and block code; adapts to system appearance | 04-02 | 2026-02-02 |
| Use NSColor.separatorColor for blockquote borders | Subtle separator color that adapts to system appearance automatically; replaces fixed-color border | 04-02 | 2026-02-02 |
| Use NSColor.labelColor for all primary text | Replaces hard-coded .black with system-adaptive color that works in both light and dark mode | 04-02 | 2026-02-02 |
| 500KB truncation threshold for large files | Supports large documentation files while guaranteeing <1s render time; typical markdown is 10-50KB so 500KB covers most real-world docs | 04-01 | 2026-02-02 |
| Use FileHandle for partial file reading | Efficient - reads only needed bytes without loading entire file into memory; critical for multi-megabyte files | 04-01 | 2026-02-02 |
| Truncation message at end with markdown separator | User sees available content first, then clear notice; separator (---) renders as horizontal rule for visual distinction | 04-01 | 2026-02-02 |
| Increase header separator from 1pt to 2pt border width | 1pt border was not visible in rendered tables; 2pt with explicit edge parameter provides clear visual distinction | 03 | 2026-02-02 |
| Use ellipsis truncation (.byTruncatingTail) not wrapping for table overflow | Combined with content-based widths, keeps tables compact while handling long content gracefully | 03-02 | 2026-02-02 |
| Measure actual text widths using NSAttributedString.size() for content-based column sizing | Provides accurate rendered size including font metrics; add padding + breathing room + constraints for final widths | 03-02 | 2026-02-02 |
| Set explicit column widths with constraints (min 60pt, max 300pt per column, max 800pt total) | Content-based sizing with bounds prevents both tiny columns and unwieldy wide tables | 03-02 | 2026-02-02 |
| Use ensureBlockSeparation() helper for table/content spacing | Checks for proper block separation (\\n\\n) and adds missing newlines to ensure correct spacing | 03-02 | 2026-02-02 |
| Remove empty cell background, use subtle middot only | Gray background was too prominent; middot with quaternaryLabelColor provides subtle presence indicator | 03-02 | 2026-02-02 |
| NSTextTableBlock default vertical alignment used for table cells | NSTextTableBlock.verticalAlignment defaults to .middle (centered), satisfies phase decision without explicit override | 03-01 | 2026-02-02 |
| Middot indicator with gray color and subtle background for empty cells | Makes empty table cells visible without prominent decoration, uses tertiaryLabelColor with quaternaryLabelColor background at 0.2 alpha | 03-01 | 2026-02-02 |
| 6pt padding on all cell edges for table cells | Balances table density with readability, provides consistent spacing on all edges | 03-01 | 2026-02-02 |
| Use plainText extraction for table cell content | Simplifies initial implementation, defers inline formatting processing (bold/italic/code within cells) to future enhancement | 03-01 | 2026-02-02 |
| Convert blockquote soft breaks to hard breaks in preprocessing stage | AttributedString(markdown:) is CommonMark-compliant and converts soft breaks to spaces; adding two trailing spaces before newlines within blockquotes converts to hard breaks, preserving line separation | 02-22 | 2026-02-02 |
| Apply ordinal tracking pattern to insertListPrefixes | All runs of the same list item have the same ordinal; only the first run (when ordinal changes) should get a prefix to prevent duplicates for items with inline formatting | 02-21 | 2026-02-02 |
| Track blockquote identity in ensureIntraBlockNewlines | Same identity tracking pattern as list ordinal tracking; only insert newline when blockquote identity changes (paragraph boundary), skip for runs within same paragraph | 02-20 | 2026-02-01 |
| Remove list item handling from ensureIntraBlockNewlines | Both insertBlockBoundaryNewlines and ensureIntraBlockNewlines were adding newlines at list item boundaries causing double newlines; simplified to single responsibility pattern | 02-19 | 2026-02-02 |
| Apply ordinal tracking pattern to ensureIntraBlockNewlines | Same ordinal tracking pattern from insertBlockBoundaryNewlines prevents inline formatting splits by only adding newlines when next run has different ordinal | 02-18 | 2026-02-01 |
| Recognize duplicate implementation between plans | Plan 02-17 required same fix as plan 02-14; verified existing implementation meets requirements instead of reimplementing | 02-17 | 2026-02-02 |
| Use plain text [Image: filename] placeholders instead of markers | Marker-based approach failed because AttributedString modified/split markers; plain text survives parsing intact and is styled via pattern matching afterward | 02-13 | 2026-02-01 |
| Remove blockquote continuation peek-ahead logic | Peek-ahead prevented newlines within multi-paragraph blockquotes; simplified to always add newline at run end, trust block boundary detection for double-newline prevention | 02-15 | 2026-02-02 |
| Apply list paragraph style to prefix text during insertion | When prefixes inserted without paragraph style, applyBaseStyles applies default spacing (8pt), causing gaps; applying style during insertion prevents override | 02-14 | 2026-02-01 |
| Track list item ordinal to prevent inline formatting splits | Inline formatting creates multiple runs with same list item; comparing ordinal prevents newlines between runs | 02-12 | 2026-02-01 |
| Set paragraphSpacing = 0 for list items | Newlines already provide separation; paragraph spacing creates excessive gaps | 02-12 | 2026-02-01 |
| Merge blockquote ranges before drawing | Multi-paragraph blockquotes have separate attribute ranges; merging adjacent ranges creates continuous border without gaps | 02-11 | 2026-02-01 |
| Draw blockquote background in LayoutManager | Inline backgroundColor only draws behind text; LayoutManager draws full-width block background for uniform appearance | 02-11 | 2026-02-01 |
| Peek next run for blockquote continuation | Prevents double-newlines between blockquote paragraphs by checking if next run is also blockquote | 02-11 | 2026-02-01 |
| Force layout before handler completion | Text may not be laid out before handler returns; ensureLayout establishes proper content size for scrolling | 02-10 | 2026-02-01 |
| NSTextView vertical scrolling configuration pattern | isVerticallyResizable=true, heightTracksTextView=false, maxSize.height=greatestFiniteMagnitude enables infinite scroll height | 02-10 | 2026-02-01 |
| Use __IMAGE_PLACEHOLDER__ marker instead of <<IMAGE:>> | AttributedString(markdown:) consumes angle brackets; underscore markers are safe from parser modification | 02-07 | 2026-02-01 |
| Track block identity alongside kind | Different paragraphs have different identities even if same type; enables proper separation | 02-09 | 2026-02-01 |
| Check existing newlines before insertion | Prevents double-spacing from unconditional newline additions | 02-09 | 2026-02-01 |
| Use enumerateLineFragments instead of boundingRect | Eliminates per-line gaps by unioning all line rects before drawing | 02-08 | 2026-02-01 |
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

Last session: 2026-02-02
Stopped at: Completed 05-01-PLAN.md (all phases complete)
Resume file: None
Next: All v1 phases complete - project ready for v1.0 release

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
