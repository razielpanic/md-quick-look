# Project Research Summary

**Project:** MD Quick Look v1.2 -- Rendering Polish & New Markdown Features
**Domain:** macOS Quick Look extension enhancement
**Researched:** 2026-02-05
**Confidence:** HIGH (existing codebase well-understood; all features use built-in APIs)

## Executive Summary

MD Quick Look v1.2 is a rendering polish milestone for an existing macOS Quick Look extension that previews markdown files. The five target features -- Quick Look window sizing, preview pane optimization, responsive table rendering, YAML front matter display, and GFM task list checkboxes -- all build on the established NSTextView + NSAttributedString architecture from v1.0/v1.1. Research confirms that **zero new dependencies are needed**. Every feature can be implemented using the existing stack: Swift, AppKit, and the swift-markdown library (already a dependency for table extraction). This is the single most important finding of the research.

The recommended approach is to treat this milestone as two parallel workstreams: a **layout adaptation workstream** (window sizing, preview pane detection, responsive tables) where features have strict ordering dependencies, and a **feature addition workstream** (YAML front matter, task list checkboxes) where features are independent and follow established preprocessing patterns. The layout workstream must come first because preview pane width detection is foundational -- tables cannot be made responsive without knowing the available width. YAML front matter extraction must happen very early in the rendering pipeline (before all other preprocessing) because stripping front matter shifts line numbers and affects source-range-based table/task-list extraction downstream.

The key risks are: (1) `preferredContentSize` breaking auto-resizing of subviews in Quick Look windows (Critical -- may be best to skip setting it entirely), (2) text container width being calculated from the initial 800x600 frame before the Quick Look host resizes the view to its actual dimensions, and (3) YAML front matter stripping desynchronizing source ranges used by the existing table extraction pipeline. All three have clear preventions identified in the pitfalls research. The architecture is well-understood because this is the project's third milestone -- the codebase is small (~240 lines in the extension), the rendering pipeline is documented, and all integration points are mapped.

## Key Findings

### Recommended Stack

All five v1.2 features require **zero new SPM dependencies**. The existing stack provides everything needed.

**Core technologies (no changes from v1.1):**
- **Swift + AppKit** -- NSViewController, NSTextView, NSTextTable, NSTextAttachment provide all rendering APIs
- **swift-markdown** (existing dependency) -- `ListItem.checkbox` API for task list detection; `Document(parsing:)` already used for table extraction
- **NSAttributedString pipeline** -- existing preprocessing/postprocessing pattern extends naturally to front matter and task lists

**What NOT to add (and why):**
- **Yams** (YAML parser): overkill for display-only key-value extraction; adds LibYAML C dependency
- **WKWebView**: documented Quick Look issues on Sequoia; contradicts existing NSTextView architecture
- **swift-markdown-ui**: maintenance mode; targets SwiftUI, not NSTextView

### Expected Features

**Must have (table stakes):**
- Content fills available width and reflows on resize (already working via autoresizing masks)
- Tables visible and readable at narrow widths (currently broken -- absolute widths clip in preview pane)
- YAML front matter stripped from body and displayed as styled metadata block (currently renders as garbled ThematicBreak + Heading)
- Task list checkboxes render as visual checkboxes, not raw `[ ]` / `[x]` text (currently no checkbox support)
- No horizontal scrollbar for body text at any width (already implemented)

**Should have (differentiators):**
- SF Symbol checkboxes (`checkmark.square.fill` / `square`) matching native macOS appearance
- Adaptive text insets (smaller padding at narrow widths for more content visibility)
- Width-aware table column sizing (scale constraints proportionally to container width)
- Color-coded front matter keys with styled key-value display
- Dimmed text for checked task list items (`.secondaryLabelColor`)

**Defer (v2+):**
- Horizontal scroll for individual tables (HIGH complexity, breaks single-NSTextView architecture)
- Collapsible/interactive front matter (Quick Look is non-interactive)
- Full YAML parsing with Yams library (only if users report issues with nested YAML)
- Dynamic table reflow on window resize (current fixed layout does not reflow; acceptable for v1.2)
- Task progress counting ("3/7 complete")

### Architecture Approach

The existing rendering pipeline has two well-established patterns that all v1.2 features follow: (1) **preprocessing** -- modify raw markdown before `AttributedString(markdown:)` parses it (used for images, blockquote breaks; now extended for YAML stripping and task list markers), and (2) **hybrid rendering** -- use swift-markdown's `Document` AST for structured content that `AttributedString(markdown:)` cannot handle (used for tables; now extended for task list checkboxes). The architecture requires modifying 4 existing files and creating 1 new file.

**Components modified:**
1. **PreviewViewController.swift** -- read `view.bounds.width` for context detection; optionally set `preferredContentSize`
2. **MarkdownRenderer.swift** -- add `availableWidth` parameter; add YAML extraction as first preprocessing step; add task list detection alongside table detection; prepend front matter display block
3. **TableRenderer.swift** -- accept `availableWidth` parameter; scale constraints proportionally
4. **MarkdownLayoutManager.swift** -- add `frontMatterMarker` custom attribute for background drawing

**New component:**
5. **TaskListExtractor.swift** (~40-60 lines) -- MarkupVisitor that extracts `ListItem.checkbox` state and source ranges from swift-markdown AST, analogous to existing `TableExtractor`

### Critical Pitfalls

1. **preferredContentSize breaks auto-resizing** -- Setting this property causes Quick Look subviews to stop tracking window size during manual resize and fullscreen. Prevention: do not set `preferredContentSize` for text content; let the system manage window size. Test all resize scenarios (spacebar, drag-resize, fullscreen toggle).

2. **Text container width calculated from initial 800x600 frame** -- `scrollView.contentSize.width - 40` is computed before the Quick Look host resizes the view to its actual dimensions (~260px for preview pane). Prevention: override `viewDidLayout()` to recalculate text container width from actual bounds; do not call `ensureLayout` in `preparePreviewOfFile`.

3. **NSTextTable absolute widths overflow in narrow containers** -- Current `fixedLayoutAlgorithm` with `absoluteValueType` renders tables at measured content width regardless of container. In a 260px preview pane, content is silently clipped. Prevention: switch to percentage-based column widths; cap total table width to available container width.

4. **YAML front matter parsed as ThematicBreak + Heading** -- Neither `AttributedString(markdown:)` nor swift-markdown support YAML front matter. The `---` delimiter is parsed as a horizontal rule. Prevention: pre-strip front matter before ANY parsing; anchor regex to absolute file start with `\A`; pass stripped content consistently to ALL parsers to avoid source range desynchronization.

5. **insertListPrefixes overwrites task list checkboxes** -- `PresentationIntent` has no concept of task lists; all unordered items receive bullet prefixes unconditionally. Prevention: use custom `NSAttributedString.Key` marker from swift-markdown AST to identify task list items; modify `insertListPrefixes` to insert checkbox attachments instead of bullets for marked ranges.

## Implications for Roadmap

Based on combined research, the v1.2 milestone should have 5 phases with a specific ordering driven by architectural dependencies and pitfall analysis.

### Phase 1: YAML Front Matter Detection and Display

**Rationale:** Front matter extraction must be the FIRST preprocessing step in the pipeline. It must happen before all other parsing because: (a) the `---` delimiters cause garbled rendering if passed to any markdown parser, and (b) stripping front matter changes line numbers, which affects source-range-based extraction used by tables and task lists. Building this first ensures the rest of the pipeline receives clean markdown.
**Delivers:** Detection, extraction, and styled display of YAML metadata blocks; clean markdown passed to downstream parsers.
**Addresses:** Feature 4 (YAML front matter detection and formatted display)
**Avoids:** Pitfall 4 (ThematicBreak parsing), Pitfall 8 (source range desynchronization), Pitfall 11 (greedy regex), Pitfall 12 (empty front matter whitespace), Pitfall 15 (Windows line endings)
**Stack:** Swift String/Regex processing, custom `NSAttributedString.Key.frontMatterMarker`, MarkdownLayoutManager background drawing

### Phase 2: Quick Look Window Sizing and Preview Pane Width Detection

**Rationale:** Width detection is foundational for phases 3 and 4. Before making tables responsive or adjusting any layout, the extension must know how wide its container is. Window sizing and preview pane detection are tightly coupled -- both involve how the Quick Look host provides view geometry. Combining them avoids redundant testing of resize behavior.
**Delivers:** `availableWidth` parameter plumbed through the rendering pipeline; `preferredContentSize` assessment (may decide not to set it based on pitfall 1); verified behavior across spacebar popup, Finder column view, and fullscreen.
**Addresses:** Feature 1 (Quick Look window sizing), Feature 2 (preview pane rendering optimization)
**Avoids:** Pitfall 1 (preferredContentSize breaks auto-resize), Pitfall 2 (narrow width without notice), Pitfall 6 (text container width from initial frame), Pitfall 7 (hardcoded LayoutManager offsets)
**Stack:** `NSViewController.preferredContentSize`, `view.bounds.size.width`, `viewDidLayout()` override

### Phase 3: Table Rendering Improvements

**Rationale:** Depends on Phase 2 providing the `availableWidth` parameter. Tables are the element most likely to break at narrow widths. The existing TableRenderer has all the infrastructure; this phase parameterizes the hardcoded width constants to accept container width.
**Delivers:** Tables that scale proportionally to available width; readable table content in Finder preview pane; adaptive padding and column minimums.
**Addresses:** Feature 3 (table rendering improvements for small/narrow spaces)
**Avoids:** Pitfall 3 (absolute widths overflow), Pitfall 14 (truncation hides content without indication)
**Stack:** `NSTextTable` percentage-based widths, `measureColumnWidths` parameterization, adaptive `lineBreakMode`

### Phase 4: GFM Task List Checkboxes

**Rationale:** Independent of the layout workstream but benefits from having Phase 1 complete (front matter stripping ensures clean markdown for `Document(parsing:)` calls). Follows the established hybrid rendering pattern from table extraction. Placed after tables because it may require refactoring `renderWithTables()` into a more general segment-based approach if both tables and task lists appear in the same document.
**Delivers:** Visual checkboxes (SF Symbols via NSTextAttachment) for GFM task list items; checked/unchecked visual distinction; proper integration with existing list prefix system.
**Addresses:** Feature 5 (GFM task list checkboxes)
**Avoids:** Pitfall 5 (no native AttributedString support), Pitfall 9 (vertical misalignment), Pitfall 10 (insertListPrefixes overwrites), Pitfall 13 (low contrast symbols), Pitfall 16 (mixed list items)
**Stack:** swift-markdown `ListItem.checkbox`, `NSTextAttachment` with SF Symbols, new `TaskListExtractor.swift`

### Phase 5: Cross-Context Testing and Polish

**Rationale:** All features must be tested in combination across Quick Look contexts (spacebar popup, Finder column view preview pane, fullscreen, Spotlight). Edge cases emerge from feature interactions -- e.g., a document with YAML front matter + tables + task lists in a narrow preview pane exercises all four previous phases simultaneously.
**Delivers:** Verified rendering across all Quick Look presentation contexts; edge case fixes; visual polish (adaptive padding, proportional offsets).
**Addresses:** Integration testing for all 5 features
**Avoids:** Regression from feature interactions; untested context combinations

### Phase Ordering Rationale

- **YAML first** because it is a preprocessing step that affects all downstream parsing. If built later, existing table rendering would break when front matter is present.
- **Width detection before tables** because table responsiveness requires knowing the container width. Building tables first would mean hardcoding another set of assumptions that get replaced.
- **Task lists after tables** because task lists extend the same hybrid rendering pattern. If both tables and task lists exist in a document, the source-range splitting logic may need refactoring -- better to have tables stable first.
- **Testing last** because cross-context testing only has value when all features are implemented. Individual phases should include per-feature testing, but the final phase exercises interactions.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2 (Window Sizing + Preview Pane):** `preferredContentSize` behavior in Quick Look is poorly documented by Apple. The exact threshold for "narrow" vs "full" context needs empirical testing. The research suggests possibly NOT setting `preferredContentSize` at all due to auto-resize breakage risk. This phase needs hands-on experimentation.
- **Phase 4 (Task List Checkboxes):** Integration with the existing `insertListPrefixes` method and potential refactoring of `renderWithTables()` into a general segment renderer adds complexity. The NSTextAttachment baseline alignment on macOS requires iterative testing.

Phases with standard patterns (skip deeper research):
- **Phase 1 (YAML Front Matter):** Well-documented pattern. String detection + regex extraction + styled rendering. Multiple reference implementations exist (PreviewMarkdown, QLMarkdown). The research already covers edge cases thoroughly.
- **Phase 3 (Table Improvements):** Straightforward parameterization of existing TableRenderer constants. NSTextTable APIs are stable since macOS 10.4. The research fully specifies what to change.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Zero new dependencies confirmed. All APIs verified in existing codebase or Apple documentation. |
| Features | HIGH | Features well-scoped; table stakes and differentiators clearly distinguished. Implementation approaches validated against reference apps (QLMarkdown, PreviewMarkdown). |
| Architecture | HIGH | Existing codebase is small and well-understood. Integration points mapped precisely. Data flow changes documented. All modification targets identified by file and method. |
| Pitfalls | HIGH | 16 pitfalls identified with specific code-level analysis. Critical pitfalls verified against Apple Developer Forums, swift-markdown source code, and direct codebase inspection. |

**Overall confidence:** HIGH

### Gaps to Address

- **preferredContentSize Quick Look behavior:** Apple does not document whether the Quick Look host respects, partially respects, or ignores this property. May need to abandon the feature if testing shows it causes more problems than it solves. Mitigate by testing early in Phase 2 and having a "do nothing" fallback.
- **Preview pane width thresholds:** No official documentation on typical Finder preview pane widths across different view modes (column view, list view, icon view). Need empirical measurements on different screen sizes during Phase 2 implementation.
- **AttributedString(markdown:) handling of `- [ ]` markers:** Not documented whether Foundation's parser strips, preserves, or mangles checkbox syntax. The preprocessing approach avoids this uncertainty, but it should be validated empirically during Phase 4.
- **NSTextTable automatic vs fixed layout at narrow widths:** Apple documentation does not explain the behavioral differences in detail. Research recommends staying with fixed layout but parameterizing widths. If results are poor, automatic layout is a fallback.
- **Task list + table co-existence:** If a document contains both GFM tables and task lists, the source range splitting logic in `renderWithSourceRanges` must handle interleaved segment types. This interaction has not been tested and may require a refactor to a general `DocumentSegment` enum.

## Sources

### Primary (HIGH confidence -- verified from source code or official documentation)

- swift-markdown `ListItem.checkbox` API -- verified in local build cache source
- swift-markdown `tasklist` cmark extension always enabled -- verified in `CommonMarkConverter.swift`
- swift-markdown issue #73 -- YAML front matter not supported, confirmed
- `AttributedString(markdown:)` does not support task lists -- Apple Developer Forums thread 701223
- `NSViewController.preferredContentSize` -- Apple Developer Documentation
- `NSTextTable` layout algorithms and percentage width types -- stable AppKit APIs since macOS 10.4
- Current codebase architecture -- direct code inspection of all 5 extension files

### Secondary (MEDIUM confidence -- community sources, cross-verified)

- [Apple Developer Forums thread 673369](https://developer.apple.com/forums/thread/673369) -- preferredContentSize caveats in Quick Look
- [smittytone/PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) -- reference implementation for YAML front matter display
- [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) -- reference Quick Look markdown extension
- [WWDC 2019 Session 719](https://developer.apple.com/videos/play/wwdc2019/719/) -- QLPreviewView contexts
- [WWDC 2018 Session 237](https://asciiwwdc.com/2018/sessions/237) -- Quick Look extension lifecycle
- [Jekyll Front Matter docs](https://jekyllrb.com/docs/front-matter/) -- standard front matter fields
- [Hugo Front Matter docs](https://gohugo.io/content-management/front-matter/) -- standard front matter fields
- [NSTextAttachment macOS vs iOS](https://bdewey.com/til/2023/08/21/nstextattachment-in-macos-vs-ios/) -- macOS-specific baseline alignment

### Tertiary (LOW confidence -- needs validation during implementation)

- Preview pane detection via `view.bounds.width` heuristic -- community pattern, not officially documented
- Quick Look system behavior regarding `preferredContentSize` respect -- needs empirical testing
- NSTextTable reflow behavior in resizable Quick Look windows -- needs testing
- `AttributedString(markdown:)` handling of `- [ ]` syntax -- needs empirical testing

---
*Research completed: 2026-02-05*
*Ready for roadmap: yes*
