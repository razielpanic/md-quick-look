# Architecture Research: v1.2 Rendering Polish & Features

**Domain:** Quick Look Extension Rendering Pipeline Modifications
**Milestone:** v1.2 - Rendering Polish & Features
**Researched:** 2026-02-05
**Confidence:** HIGH (existing codebase well-understood), MEDIUM (Quick Look sizing APIs)

## Executive Summary

This research maps how five new features integrate with the existing 240-line Swift extension architecture. The key finding is that three features (YAML front matter, task list checkboxes, Quick Look window sizing) require modifications at the **preprocessing/parsing layer** -- before `AttributedString(markdown:)` is called -- because Apple's native markdown parser does NOT support YAML front matter or task list checkboxes. The two remaining features (preview pane detection, table rendering in narrow spaces) operate at the **layout/view layer** and depend on understanding view geometry at render time.

**Critical architectural constraint:** `AttributedString(markdown:)` does not parse task list checkboxes (`- [ ]` / `- [x]`). The existing `swift-markdown` library (already a dependency) DOES parse them via `ListItem.checkbox`. This means task list rendering must follow the same hybrid approach used for tables: parse with `swift-markdown`, extract task list data, render custom attributed string segments.

**Recommendation:** Build features in dependency order: (1) window sizing first (affects all rendering), (2) preview pane detection (informs table and layout decisions), (3) YAML front matter (independent preprocessing), (4) task list checkboxes (extends existing swift-markdown integration), (5) table narrow-space improvements (depends on pane detection).

---

## Current Architecture Map

### Component Inventory (Extension Target)

```
MDQuickLook Extension/
  PreviewViewController.swift   -- QLPreviewingController entry point
  MarkdownRenderer.swift        -- Core rendering pipeline
  TableExtractor.swift          -- swift-markdown MarkupVisitor for tables
  TableRenderer.swift           -- NSTextTable-based table layout
  MarkdownLayoutManager.swift   -- Custom background/border drawing
```

### Current Data Flow

```
File URL (from quicklookd)
    |
    v
PreviewViewController.preparePreviewOfFile()
    |
    v
Read file contents (String)
    |
    v
MarkdownRenderer.render(markdown:)
    |
    +---> preprocessImages()           -- Replace ![alt](url) with markers
    +---> preprocessBlockquoteSoftBreaks()  -- Hard breaks in blockquotes
    |
    +---> hasGFMTables()?
    |       |
    |       YES --> renderWithTables()
    |       |         +---> TableExtractor (swift-markdown visitor)
    |       |         +---> Split document by source ranges
    |       |         +---> TableRenderer for table segments
    |       |         +---> renderNonTableSegment() for non-table parts
    |       |
    |       NO --> Standard pipeline
    |
    +---> AttributedString(markdown:)  -- Apple's native parser
    +---> insertBlockBoundaryNewlines()
    +---> ensureIntraBlockNewlines()
    +---> NSMutableAttributedString conversion
    +---> applyBlockStyles()           -- Headings, code blocks, lists, blockquotes
    +---> insertListPrefixes()         -- Bullet/number insertion
    +---> applyInlineStyles()          -- Inline code, strikethrough
    +---> applyLinkStyles()
    +---> applyImagePlaceholderStyles()
    +---> applyBaseStyles()
    |
    v
NSAttributedString (final styled output)
    |
    v
PreviewViewController creates NSScrollView + NSTextView
    +---> NSTextStorage
    +---> MarkdownLayoutManager (custom drawBackground)
    +---> NSTextContainer
    +---> NSTextView (isEditable: false, isSelectable: true)
    |
    v
handler(nil)  -- Preview complete
```

### Key Architectural Patterns Already Established

1. **Preprocessing pattern:** Raw markdown string is modified before parsing (images, blockquote breaks). New preprocessing steps slot in here naturally.

2. **Hybrid rendering pattern:** Tables use swift-markdown's AST to extract structured data, then render outside `AttributedString(markdown:)`. Task lists will use the same pattern.

3. **Custom attribute markers:** `.blockquoteMarker` and `.codeBlockMarker` custom `NSAttributedString.Key` values tell `MarkdownLayoutManager` where to draw backgrounds/borders. New visual elements can follow this pattern.

4. **Source range splitting:** Tables split the document into table and non-table segments by line number. This approach can extend to YAML front matter (always at document start).

---

## Feature 1: Quick Look Window Sizing

### Integration Point: PreviewViewController

**What changes:** PreviewViewController needs to set `preferredContentSize` to suggest window dimensions to the Quick Look system.

**How it works:** `NSViewController.preferredContentSize` is a `CGSize` property inherited by PreviewViewController. The Quick Look system (quicklookd) reads this to determine the initial window size for the spacebar popup. The property is settable and the system uses it as a hint.

**Current state:** PreviewViewController creates its view with a hardcoded frame `NSRect(x: 0, y: 0, width: 800, height: 600)` in `loadView()`. It does NOT set `preferredContentSize`. The Quick Look system currently determines sizing on its own.

**Modification needed:**

```
PreviewViewController (MODIFY)
  loadView()                    -- Update initial frame size
  preparePreviewOfFile()        -- Set preferredContentSize after content is rendered
```

**Architecture approach:**
- Set `preferredContentSize` in `preparePreviewOfFile()` after content is laid out
- Calculate content height from the laid-out text view to suggest appropriate height
- Width should be a sensible default (e.g., 720-800pt) that works well for markdown
- Height should be capped at a reasonable maximum but reflect actual content height for short documents

**Confidence:** MEDIUM -- `preferredContentSize` is a standard NSViewController property. The Quick Look system's exact behavior regarding whether it respects this hint fully, partially, or ignores it in certain contexts (preview pane) is not fully documented. Testing required.

**No new components needed.** Modification only to PreviewViewController.

### Sources

- [NSViewController.preferredContentSize](https://developer.apple.com/documentation/appkit/nsviewcontroller/preferredcontentsize) -- Apple Developer Documentation
- [QLMarkdown](https://github.com/sbarex/QLMarkdown) -- Reference implementation offers "Quick Look window" size customization option

---

## Feature 2: Preview Pane Detection

### Integration Point: PreviewViewController (view geometry)

**What changes:** The extension needs to detect whether it is rendering in Finder's narrow preview pane (column view sidebar, ~200-300pt wide) versus the full Quick Look popup window (~600-800pt wide) to adjust layout accordingly.

**Critical finding:** There is NO public Quick Look API to directly query "am I in a preview pane?" The Quick Look system does not expose this context to extensions.

**Available detection approach:** The extension's view is sized by the Quick Look system before and during rendering. The view's bounds/frame width at render time reflects the available space. The extension can read `self.view.bounds.size.width` in `preparePreviewOfFile()` or override `viewDidLayout()` to detect narrow contexts.

**Architecture approach:**

```
PreviewViewController (MODIFY)
  preparePreviewOfFile()   -- Read view.bounds.width
  viewDidLayout()          -- OPTIONAL: respond to resize events

  Width-based heuristic:
    width < 400pt  -->  "narrow" context (preview pane)
    width >= 400pt -->  "full" context (Quick Look popup)
```

**What this enables:**
- Pass a `isNarrowContext: Bool` or `availableWidth: CGFloat` to MarkdownRenderer
- MarkdownRenderer can adjust font sizes, margins, or skip certain decorations
- TableRenderer can switch to a more compact layout or scrollable container
- NSTextContainer width already tracks the text view via `widthTracksTextView = true`

**Data flow change:**

```
Current:  MarkdownRenderer().render(markdown: string) -> NSAttributedString
Proposed: MarkdownRenderer().render(markdown: string, availableWidth: CGFloat) -> NSAttributedString
```

Or alternatively, set a property on MarkdownRenderer before calling render. The `availableWidth` parameter propagates to TableRenderer when tables need rendering.

**Confidence:** MEDIUM -- The width-based heuristic is the standard community approach. There is no documented Apple API for context detection. The threshold value (400pt) will need empirical testing across different Finder configurations (column view, list view preview column, icon view). The view may also be resized AFTER initial render (user resizing Quick Look popup), but `autoresizingMask` on existing views should handle that for the text flow. Table layout may not reflow dynamically.

**No new components needed.** Modifications to PreviewViewController and MarkdownRenderer signatures.

### Sources

- [QLMarkdown issue #76](https://github.com/sbarex/QLMarkdown/issues/76) -- Discussion of preview column behavior
- [smittytone/PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) -- Reference implementation handles Finder preview pane

---

## Feature 3: Table Rendering in Narrow Spaces

### Integration Points: TableRenderer, MarkdownRenderer

**What changes:** TableRenderer currently uses fixed layout algorithm with content-based column widths (60pt min, 300pt max per column, 800pt max total). In a narrow preview pane (~200-300pt), tables overflow or get truncated.

**Current table sizing logic (TableRenderer):**

```swift
let maxTableWidth: CGFloat = 800.0      // Hard cap
let minColumnWidth: CGFloat = 60.0      // Per-column minimum
let maxColumnWidth: CGFloat = 300.0     // Per-column maximum
nsTable.layoutAlgorithm = .fixedLayoutAlgorithm
```

**Modifications needed:**

```
TableRenderer (MODIFY)
  render(_ table:)                      -- Accept availableWidth parameter
  measureColumnWidths()                 -- Scale constraints to available width
  renderCell()                          -- Adjust padding for narrow context

MarkdownRenderer (MODIFY)
  renderWithTables()                    -- Pass availableWidth to TableRenderer
  renderWithSourceRanges()              -- Pass availableWidth to TableRenderer
```

**Architecture approach:**

Option A (recommended): **Parameterize existing constraints**
- `TableRenderer.render(_ table: ExtractedTable, availableWidth: CGFloat)`
- Scale `maxTableWidth`, `maxColumnWidth`, and padding based on `availableWidth`
- In narrow context: reduce padding from 6pt to 3pt, reduce min column width, use proportional instead of absolute widths
- Keep `fixedLayoutAlgorithm` but adjust the total width constraint

Option B (complex, not recommended): **Horizontal scroll for tables**
- Wrap table in a nested NSScrollView with horizontal scrolling
- More complex, breaks the single-NSTextView architecture
- Only consider if Option A produces unreadable results

**No new components needed.** Modifications to TableRenderer and MarkdownRenderer method signatures.

**Confidence:** HIGH -- TableRenderer already has the sizing infrastructure. Parameterizing the constants is a straightforward modification.

---

## Feature 4: YAML Front Matter Display

### Integration Points: MarkdownRenderer (preprocessing), NEW component

**What changes:** Detect YAML front matter at the document start (`---` delimiters), extract it, and render it as a formatted metadata block above the markdown content.

**Critical finding:** Neither `AttributedString(markdown:)` nor `swift-markdown` support YAML front matter natively. swift-markdown's issue #73 (open since 2022) confirms this: front matter gets incorrectly parsed as a ThematicBreak followed by a Heading. The recommended approach is to strip YAML before parsing.

**Architecture approach:**

```
NEW: FrontMatterExtractor (simple utility, not a full component)
  - Detect `---` at line 0
  - Find closing `---`
  - Extract YAML string between delimiters
  - Return (yamlString: String?, remainingMarkdown: String)

NEW: FrontMatterRenderer (or inline in MarkdownRenderer)
  - Parse key-value pairs from YAML (simple regex or line splitting)
  - Render as styled NSAttributedString block (table or key: value list)
  - Visual: light background, monospace keys, regular values
```

**Pipeline position:** Front matter extraction must happen FIRST, before all other preprocessing. It strips the YAML from the markdown string so downstream parsers never see it.

**Modified data flow:**

```
Raw markdown string
    |
    v
NEW: Extract front matter          <-- NEW STEP (position 0)
    |
    +---> YAML string (if present)
    +---> Remaining markdown (YAML stripped)
    |
    v
preprocessImages()                 -- Existing step (now on clean markdown)
preprocessBlockquoteSoftBreaks()   -- Existing step
    |
    v
[... rest of existing pipeline ...]
    |
    v
NEW: Prepend front matter block    <-- Prepend to final NSAttributedString
    |
    v
Final NSAttributedString
```

**YAML parsing complexity decision:**

Option A (recommended): **Simple line-based parsing, no Yams dependency**
- Split YAML block by lines
- Parse `key: value` pairs with string splitting
- Handle multi-line values by detecting indentation
- Sufficient for typical front matter (title, date, author, tags)
- Zero new dependencies

Option B (overkill): **Add Yams SPM dependency**
- Full YAML parser (handles nested structures, arrays, etc.)
- Adds a C library dependency (LibYAML) to the extension sandbox
- Only justified if complex YAML structures need faithful rendering
- Risk: C library may have sandbox compatibility issues

**Recommendation:** Option A. Front matter in markdown files is typically flat key-value pairs. A simple parser handles 95% of real-world cases. The `PreviewMarkdown` reference app from smittytone also uses a custom approach rather than a full YAML library.

**Visual rendering approach:**
- Custom `NSAttributedString.Key.frontMatterMarker` for MarkdownLayoutManager
- Light background rectangle (like code blocks) with distinct color
- Key in bold, value in regular weight
- Or: render as a simple two-column table using existing NSTextTable infrastructure

**New components:** FrontMatterExtractor (utility function or small struct, ~30-50 lines). Could be a static method on MarkdownRenderer rather than a separate file -- depends on complexity.

**Confidence:** HIGH for extraction approach (well-established pattern), MEDIUM for visual rendering (needs design iteration).

### Sources

- [swift-markdown issue #73](https://github.com/swiftlang/swift-markdown/issues/73) -- YAML front matter not supported, recommended workaround
- [smittytone/PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) -- Reference app supports YAML front matter display
- [Yams](https://github.com/jpsim/Yams) -- Full Swift YAML parser (considered but not recommended)

---

## Feature 5: Task List Checkboxes

### Integration Points: MarkdownRenderer, TableExtractor pattern, MarkdownLayoutManager

**What changes:** Render GFM task list items (`- [ ] unchecked`, `- [x] checked`) with visual checkbox indicators instead of raw brackets.

**Critical finding:** `AttributedString(markdown:)` does NOT support task list checkboxes. The `[ ]` and `[x]` markers are stripped or parsed as regular text. However, the `swift-markdown` library (already a project dependency for table extraction) DOES parse them: `ListItem.checkbox` returns `.checked`, `.unchecked`, or `nil`.

**This means task lists require the same hybrid rendering approach as tables:** parse with `swift-markdown` to detect task lists, then render checkbox visuals separately.

**Architecture decision -- two viable approaches:**

### Approach A: Extend TableExtractor Pattern (Recommended)

Create a `TaskListExtractor` (MarkupVisitor) analogous to `TableExtractor`. Extract task list items from the AST, then render them with checkbox visuals.

```
NEW: TaskListExtractor (MarkupVisitor)
  - Visits ListItem nodes
  - Returns items where checkbox != nil
  - Captures: checkbox state, text content, source range

MarkdownRenderer (MODIFY)
  - Check for task lists alongside table check
  - Extract task list source ranges
  - Render task list items with checkbox prefix
```

**Checkbox visual rendering via NSTextAttachment:**

```swift
// SF Symbol checkbox images
let checkboxImage: NSImage
if checkbox == .checked {
    checkboxImage = NSImage(systemSymbolName: "checkmark.square.fill",
                           accessibilityDescription: "Checked")!
} else {
    checkboxImage = NSImage(systemSymbolName: "square",
                           accessibilityDescription: "Unchecked")!
}

let attachment = NSTextAttachment()
attachment.image = checkboxImage
// Insert as prefix before list item text, replacing the bullet
```

This follows the exact same pattern as `applyImagePlaceholderStyles()` which already uses NSTextAttachment with SF Symbols for image placeholders.

### Approach B: Preprocessing Substitution (Simpler but Less Robust)

Replace `- [ ]` and `- [x]` patterns in the raw markdown string BEFORE `AttributedString(markdown:)` parsing, substituting Unicode checkbox characters or placeholder markers.

```
preprocessTaskLists(in markdown: String) -> String
  - Regex: replace "- [ ] " with "- UNCHECKEDPLACEHOLDER "
  - Regex: replace "- [x] " with "- CHECKEDPLACEHOLDER "
  - After AttributedString parsing, replace placeholders with SF Symbol attachments
```

Simpler but fragile: regex may match false positives in code blocks or other contexts. The swift-markdown AST approach (Approach A) is more precise.

### Recommendation: Approach A

Task list extraction follows the established hybrid rendering pattern. It reuses the existing swift-markdown infrastructure. Source range tracking allows precise document splitting, same as tables.

**However**, there is an important complexity consideration: if a document has BOTH tables AND task lists, the source range splitting logic in `renderWithSourceRanges()` needs to handle both types of "special" segments. This suggests a refactor toward a more general "segment" abstraction:

```
enum DocumentSegment {
    case markdown(String)           // Regular markdown
    case table(ExtractedTable)      // Table segment
    case taskListItem(...)          // Task list item segment
}
```

This refactor is optional but recommended if the code starts to get complex with multiple special segment types.

**Modified components:**

```
NEW: TaskListExtractor.swift (~40-60 lines, similar to TableExtractor)
MODIFY: MarkdownRenderer.swift
  - hasTaskLists() detection (alongside hasGFMTables)
  - Task list items rendered with SF Symbol checkbox + list text
  - Possibly refactor renderWithTables to renderWithSpecialSegments
MODIFY: MarkdownLayoutManager.swift (OPTIONAL)
  - Only if task list items need custom background drawing
  - Likely NOT needed -- checkbox attachment handles the visual
```

**Confidence:** HIGH for swift-markdown checkbox API (verified in source code: `ListItem.checkbox` returns `Checkbox.checked` or `Checkbox.unchecked`). MEDIUM for integration complexity with existing hybrid pipeline (may require refactoring the table/non-table split logic).

### Sources

- [swift-markdown ListItem.checkbox](https://swiftinit.org/docs/swift-markdown/markdown/listitem.checkbox) -- API documentation
- [ListItem.swift source](verified in local build/SourcePackages) -- `Checkbox` enum with `.checked` and `.unchecked` cases
- [NSTextAttachment](https://developer.apple.com/documentation/uikit/nstextattachment) -- Image attachment in attributed strings
- [SF Symbols](https://developer.apple.com/sf-symbols/) -- `checkmark.square.fill` and `square` symbols

---

## Component Modification Summary

### Files Modified (Existing)

| File | Modifications | Features Affected |
|------|--------------|-------------------|
| **PreviewViewController.swift** | Set `preferredContentSize`, read `view.bounds.width`, pass width to renderer | Window sizing, Preview pane detection |
| **MarkdownRenderer.swift** | Add `availableWidth` parameter, front matter extraction/prepending, task list detection and rendering, pass width to TableRenderer | All 5 features |
| **TableRenderer.swift** | Accept `availableWidth` parameter, scale constraints dynamically | Table narrow rendering |
| **MarkdownLayoutManager.swift** | Add `frontMatterMarker` background drawing (if front matter uses custom background) | YAML front matter |

### New Files

| File | Purpose | Lines (est.) | Dependencies |
|------|---------|-------------|--------------|
| **TaskListExtractor.swift** | MarkupVisitor to extract task list items from swift-markdown AST | 40-60 | swift-markdown (existing) |

### Files Unchanged

| File | Reason |
|------|--------|
| **TableExtractor.swift** | Table extraction logic unchanged. Only TableRenderer's sizing changes. |

---

## Data Flow Changes (v1.2)

```
File URL (from quicklookd)
    |
    v
PreviewViewController.preparePreviewOfFile()
    |
    +---> Read view.bounds.width            <-- NEW: detect context
    |
    v
Read file contents (String)
    |
    v
MarkdownRenderer.render(markdown:, availableWidth:)    <-- MODIFIED signature
    |
    +---> extractFrontMatter()              <-- NEW: position 0
    |       +---> yamlString (if present)
    |       +---> cleanMarkdown (YAML stripped)
    |
    +---> preprocessImages()                -- Existing (on clean markdown)
    +---> preprocessBlockquoteSoftBreaks()  -- Existing
    |
    +---> hasGFMTables() OR hasTaskLists()? <-- MODIFIED: check both
    |       |
    |       YES --> renderWithSpecialSegments()  <-- MODIFIED/REFACTORED
    |       |         +---> TableExtractor
    |       |         +---> TaskListExtractor        <-- NEW
    |       |         +---> Split by source ranges
    |       |         +---> TableRenderer(availableWidth:)  <-- MODIFIED
    |       |         +---> Task list items with SF Symbol checkboxes  <-- NEW
    |       |         +---> renderNonTableSegment() for regular parts
    |       |
    |       NO --> Standard pipeline (unchanged)
    |
    +---> [existing style application pipeline]
    |
    +---> Prepend front matter block        <-- NEW: position last
    |
    v
NSAttributedString (final styled output)
    |
    v
PreviewViewController
    +---> Set preferredContentSize          <-- NEW
    +---> Create NSScrollView + NSTextView (existing)
    |
    v
handler(nil)
```

---

## Build Order (Dependency-Driven)

### Phase 1: Quick Look Window Sizing
**Depends on:** Nothing (standalone)
**Enables:** Better default display for all content
**Scope:** PreviewViewController only
**Risk:** Low
**Rationale:** Foundation change that affects user experience of all other features. Build first so all subsequent testing happens with proper sizing.

### Phase 2: Preview Pane Detection
**Depends on:** Phase 1 (sizing infrastructure)
**Enables:** Narrow-context awareness for Phase 3 and Phase 5
**Scope:** PreviewViewController, MarkdownRenderer signature
**Risk:** Medium (heuristic threshold needs testing)
**Rationale:** Must detect context before adapting layout. Tables (Phase 3) and potentially all rendering need width information.

### Phase 3: Table Rendering in Narrow Spaces
**Depends on:** Phase 2 (availableWidth parameter)
**Enables:** Readable tables in preview pane
**Scope:** TableRenderer, MarkdownRenderer
**Risk:** Low (parameterizing existing constants)
**Rationale:** Direct consumer of width detection. Improves existing feature rather than adding new parsing.

### Phase 4: YAML Front Matter
**Depends on:** Nothing (could run in parallel with Phases 1-3)
**Enables:** Metadata display
**Scope:** MarkdownRenderer (new preprocessing step), possibly MarkdownLayoutManager
**Risk:** Low (well-understood extraction pattern)
**Rationale:** Independent preprocessing step. No interaction with table/task list logic. Could be built at any point, placed here because it does not depend on width detection.

### Phase 5: Task List Checkboxes
**Depends on:** Established hybrid rendering pattern (existing from v1.0 tables)
**Enables:** GFM task list visual rendering
**Scope:** New TaskListExtractor, MarkdownRenderer modifications
**Risk:** Medium (integration with existing hybrid pipeline, possible refactor)
**Rationale:** Most complex integration. Extends the hybrid rendering pattern to a second element type. May require refactoring `renderWithTables()` into a more general segment-based approach. Build last to minimize rework if earlier phases reveal architectural adjustments needed.

---

## Architecture Patterns to Follow

### Pattern: Preprocessing Pipeline (for YAML)

Follow the established pattern of `preprocessImages()` and `preprocessBlockquoteSoftBreaks()`:
1. Operate on raw markdown string
2. Return modified string
3. Position in pipeline is ordered (YAML extraction must be first)
4. Pure function, no side effects beyond string transformation

### Pattern: MarkupVisitor Extraction (for Task Lists)

Follow the established `TableExtractor` pattern:
1. Implement `MarkupVisitor` protocol
2. Walk the AST, collect specific node types
3. Return structured data with source ranges
4. MarkdownRenderer uses source ranges to split document

### Pattern: Custom NSAttributedString.Key Markers (for Front Matter)

Follow the established `.blockquoteMarker` and `.codeBlockMarker` pattern:
1. Define custom key (e.g., `.frontMatterMarker`)
2. Apply to attributed string range during rendering
3. MarkdownLayoutManager reads marker in `drawBackground()` to draw visual decorations

### Pattern: NSTextAttachment for Inline Visuals (for Checkboxes)

Follow the established image placeholder pattern:
1. Create `NSTextAttachment` with SF Symbol image
2. Insert into attributed string at appropriate position
3. Text attachment flows inline with surrounding text

---

## Anti-Patterns to Avoid

### Anti-Pattern: Dual Parsing for Task Lists

**Wrong:** Parse with `AttributedString(markdown:)` AND `swift-markdown` independently, try to reconcile results.
**Why bad:** Two parsers may disagree on structure, source ranges won't align, bugs from inconsistency.
**Instead:** Use `swift-markdown` as the authoritative parser for task list detection, handle task list segments outside `AttributedString(markdown:)`.

### Anti-Pattern: Regex-Only Task List Detection

**Wrong:** Use regex to find `- [ ]` and `- [x]` patterns in raw markdown.
**Why bad:** False positives in code blocks, nested lists, or edge cases. Fragile.
**Instead:** Use `swift-markdown` AST parsing (ListItem.checkbox property) for reliable detection.

### Anti-Pattern: Adding Yams Dependency for Simple Front Matter

**Wrong:** Add full YAML parser library for key-value extraction.
**Why bad:** Adds C library dependency (LibYAML), increases binary size, potential sandbox issues, overkill for typical front matter.
**Instead:** Simple line-based key:value parsing handles 95% of real-world front matter.

### Anti-Pattern: Separate NSScrollView for Narrow Tables

**Wrong:** Wrap tables in a nested horizontal NSScrollView for narrow contexts.
**Why bad:** Breaks single-NSTextView architecture, complex layout management, poor UX (nested scroll views).
**Instead:** Scale table constraints proportionally to available width. Accept some truncation via `lineBreakMode: .byTruncatingTail` (already implemented).

### Anti-Pattern: Hardcoded Preview Pane Width

**Wrong:** Assume preview pane is always exactly 250pt wide.
**Why bad:** Users can resize the preview column in Finder. Column view, list view, and icon view have different defaults.
**Instead:** Use `view.bounds.width` at render time and apply width-based heuristic with a threshold.

---

## Scalability Considerations

| Concern | Current (v1.1) | v1.2 Impact | Mitigation |
|---------|----------------|-------------|------------|
| Special segment types | 1 (tables) | 2 (tables + task lists) | Consider generalizing to DocumentSegment enum if adding more |
| Preprocessing steps | 2 (images, blockquotes) | 3 (+ YAML extraction) | Pipeline is linear, order matters, document clearly |
| MarkdownRenderer complexity | ~810 lines | ~950-1050 lines (est.) | Consider splitting into MarkdownRenderer + MarkdownPreprocessor if exceeding 1000 lines |
| Custom attribute markers | 2 (blockquote, codeBlock) | 3 (+ frontMatter) | Pattern scales well, LayoutManager handles multiple markers |
| MarkdownLayoutManager cases | 2 (blockquote, codeBlock) | 3 (+ frontMatter) | drawBackground() stays manageable with sequential enumeration |

---

## Open Questions

1. **preferredContentSize behavior:** Does the Quick Look system respect `preferredContentSize` from the extension's view controller? Testing needed. Some extensions report the system overriding their preferences.

2. **Preview pane width threshold:** What is the right cutoff between "narrow" and "full" context? Need to test with Finder's column view, list view, and icon view preview panes at various window sizes.

3. **Task list + table interaction:** If a document has both tables AND task lists, the source range splitting logic needs to handle interleaved segments. Need to verify source ranges from both extractors don't overlap or create gaps.

4. **Front matter rendering style:** Should YAML front matter look like a code block (monospace, background), a table (key-value pairs in columns), or a custom card-like element? Design decision deferred to implementation phase.

5. **Dynamic resizing:** If the Quick Look window is resized after initial render, do tables reflow? Current `fixedLayoutAlgorithm` tables do not reflow. Is this acceptable, or should tables use `automaticLayoutAlgorithm`? Testing needed.

---

## Sources

### HIGH Confidence (verified in source code or official documentation)

- swift-markdown `ListItem.checkbox` API -- verified in local source at `build/SourcePackages/checkouts/swift-markdown/Sources/Markdown/Block Nodes/Block Container Blocks/ListItem.swift`
- swift-markdown `TableExtractor` pattern -- verified in local source at `MDQuickLook/MDQuickLook Extension/TableExtractor.swift`
- `NSViewController.preferredContentSize` -- [Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nsviewcontroller/preferredcontentsize)
- `AttributedString(markdown:)` does NOT support task list checkboxes -- [Apple Developer Forums](https://developer.apple.com/forums/thread/701223)

### MEDIUM Confidence (community sources, cross-verified)

- swift-markdown does not support YAML front matter -- [GitHub issue #73](https://github.com/swiftlang/swift-markdown/issues/73)
- PreviewMarkdown supports YAML front matter via custom extraction -- [GitHub](https://github.com/smittytone/PreviewMarkdown)
- QLMarkdown offers Quick Look window size customization -- [GitHub](https://github.com/sbarex/QLMarkdown)
- NSTextAttachment with SF Symbols for inline images -- [Hacking with Swift](https://www.hackingwithswift.com/example-code/system/how-to-insert-images-into-an-attributed-string-with-nstextattachment)
- [Yams YAML parser for Swift](https://github.com/jpsim/Yams) -- considered but not recommended

### LOW Confidence (needs validation during implementation)

- Preview pane detection via `view.bounds.width` heuristic -- community pattern, not officially documented
- Quick Look system behavior regarding `preferredContentSize` respect -- needs empirical testing
- NSTextTable reflow behavior in resizable Quick Look windows -- needs testing

---

*Architecture research for: v1.2 Rendering Polish & Features*
*Researched: 2026-02-05*
*Milestone: v1.2 - Rendering Polish & Features*
