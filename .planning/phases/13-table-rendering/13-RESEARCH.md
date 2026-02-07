# Phase 13: Table Rendering - Research

**Researched:** 2026-02-07
**Domain:** NSTextTable/NSTextTableBlock in Swift AppKit, adaptive table rendering
**Confidence:** HIGH

## Summary

Phase 13 enhances the existing TableRenderer implementation (Phase 9) to make tables width-adaptive across Quick Look contexts. The current implementation uses NSTextTable with fixedLayoutAlgorithm and content-based column measurement, which works well but doesn't adapt to the WidthTier system introduced in Phase 12.

The research confirms that NSTextTable/NSTextTableBlock is the correct approach for tables in NSAttributedString, and the existing architecture is sound. The enhancement strategy is straightforward: integrate the WidthTier system into TableRenderer's measurement and rendering logic by adjusting min/max column constraints, cell padding, font sizes, and border thickness based on the current tier.

Tooltip implementation in Quick Look extensions is challenging - NSTextView tooltips require interactive events that may not be available in all Quick Look contexts. The recommended approach is to implement truncation with ellipsis first, and optionally attempt tooltip support with appropriate fallback handling.

**Primary recommendation:** Enhance existing TableRenderer with tier-aware scaling parameters. Use content-proportional column widths with tier-specific min/max constraints. Apply compact mode styling (smaller fonts, reduced padding, thinner borders) in narrow tier. Implement smart wrap/truncate using NSParagraphStyle.lineBreakMode with optional tooltip support if Quick Look context permits.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Column sizing:**
- Content-proportional column widths — wider content gets more space
- Both minimum and maximum column width constraints to prevent crushed or dominant columns
- Content-fitted table width — tables only as wide as needed, compact tables stay compact
- Maximum table width matches the same cap as body text content
- High column count (5+) handling: Claude's discretion

**Compact mode:**
- Tied to existing WidthTier system from Phase 12 — no separate threshold
- Compact mode reduces both cell padding AND font size for maximum data density
- Border thickness also reduces in compact mode
- Always render as table layout even at narrowest widths — no stacked/list conversion

**Cell content overflow:**
- Smart wrap/truncate hybrid: truncate by default to keep rows tight and scannable
- Allow wrapping ONLY when most cells in a row would benefit — avoid lopsided tall rows where one overflowing cell creates an otherwise empty tall row
- When wrapping is allowed, cap at a reasonable max line count (Claude determines the limit)
- Truncated cells show ellipsis (…) with tooltip revealing full content on hover
- Long unbreakable strings (URLs, paths): always truncate, never mid-break

**Visual style:**
- Minimal borders: header separator line only, no full grid or vertical borders
- Header row: bold text only, no background color distinction
- No zebra striping on data rows — all rows same background
- No rounded-corner container or background tint — table renders inline
- GFM column alignment markers (`:---`, `:---:`, `---:`) are respected — left/center/right alignment applied

### Claude's Discretion

- Exact min/max column width values
- High column count handling strategy
- Wrap line cap number
- Tooltip implementation approach (Quick Look constraints may apply)
- Dark mode border color and contrast tuning
- Spacing between table and surrounding content

### Deferred Ideas (OUT OF SCOPE)

- Rounded corners on code blocks and YAML front matter sections — visual polish for existing rendered elements, not in scope for table rendering

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| NSTextTable | macOS 10.4+ | Table structure representation | Official AppKit API for tables in NSAttributedString |
| NSTextTableBlock | macOS 10.4+ | Individual table cell representation | Only way to implement cells within NSTextTable |
| NSParagraphStyle | Foundation | Cell text formatting and layout | Required for attaching text blocks to paragraphs |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| WidthTier enum | Custom (Phase 12) | Width-aware rendering mode | All tier-dependent rendering decisions |
| MarkdownLayoutManager | Custom | Custom background drawing | Not needed for tables (no special background) |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSTextTable | Manual UITableView embedding | Would break single NSTextView architecture; Quick Look doesn't support embedded views |
| NSTextTable | HTML table import via NSAttributedString(html:) | Loses control over tier-aware styling; HTML/CSS overhead; security concerns |
| Content-based measurement | Fixed column widths | Wastes space on compact tables; doesn't scale to content |

**Installation:**
No external dependencies — using built-in AppKit APIs only.

## Architecture Patterns

### Recommended Project Structure

Current structure is already optimal:
```
MDQuickLook Extension/
├── TableExtractor.swift        # Parses markdown tables via swift-markdown
├── TableRenderer.swift         # Renders ExtractedTable → NSAttributedString
├── MarkdownRenderer.swift      # Orchestrates rendering, passes widthTier
└── PreviewViewController.swift # Detects width tier, re-renders on change
```

### Pattern 1: Tier-Aware Table Measurement

**What:** Column width measurement that scales min/max constraints based on WidthTier

**When to use:** When measuring column widths in `measureColumnWidths(for:columnCount:)`

**Example:**
```swift
// Current implementation (TableRenderer.swift lines 133-142)
let (minColumnWidth, maxColumnWidth, breathingRoom): (CGFloat, CGFloat, CGFloat)
if widthTier == .narrow {
    minColumnWidth = 40.0
    maxColumnWidth = 150.0
    breathingRoom = 10.0
} else {
    minColumnWidth = 60.0
    maxColumnWidth = 300.0
    breathingRoom = 20.0
}
```

**Enhancement for Phase 13:** This pattern is already implemented in current TableRenderer.swift. Phase 13 should add font size reduction and border thickness reduction to complete the compact mode implementation.

### Pattern 2: Content-Proportional Column Widths

**What:** Measure actual text width for each column, apply proportional scaling when total exceeds max table width

**When to use:** When allocating column widths to fit available space

**Example:**
```swift
// Current implementation (TableRenderer.swift lines 104-162)
// 1. Measure each column's content width
for (colIndex, headerContent) in table.headerCells.enumerated() {
    let text = headerContent.isEmpty ? "\u{00B7}" : headerContent
    let size = (text as NSString).size(withAttributes: headerAttrs)
    columnWidths[colIndex] = max(columnWidths[colIndex], size.width)
}

// 2. Apply min/max constraints
for i in 0..<columnCount {
    columnWidths[i] += cellPadding + breathingRoom
    columnWidths[i] = min(max(columnWidths[i], minColumnWidth), maxColumnWidth)
}

// 3. Proportionally scale if total exceeds max table width
let totalWidth = columnWidths.reduce(0, +)
if totalWidth > maxTableWidth {
    let scale = maxTableWidth / totalWidth
    for i in 0..<columnCount {
        columnWidths[i] *= scale
    }
}
```

**Enhancement for Phase 13:** Current implementation is sound. Should adjust `maxTableWidth` to match body text content cap from Phase 12 (640pt for normal tier).

### Pattern 3: NSTextTableBlock Cell Configuration

**What:** Configure each cell with padding, borders, alignment, and paragraph style

**When to use:** When rendering each table cell in `renderCell(table:row:column:content:isHeader:alignment:columnWidths:)`

**Example:**
```swift
// Current implementation (TableRenderer.swift lines 165-239)
let block = NSTextTableBlock(
    table: table,
    startingRow: row,
    rowSpan: 1,
    startingColumn: column,
    columnSpan: 1
)

// Set explicit column width based on measurements
block.setContentWidth(columnWidth, type: .absoluteValueType)

// Configure padding (tier-aware)
let cellPadding: CGFloat = widthTier == .narrow ? 3.0 : 6.0
for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
    block.setWidth(cellPadding, type: .absoluteValueType, for: .padding, edge: edge)
}

// Header separator: bottom border on header cells only
if isHeader {
    block.setWidth(2.0, type: .absoluteValueType, for: .border, edge: .maxY)
    block.setBorderColor(NSColor.separatorColor, for: .maxY)
}
```

**Enhancement for Phase 13:** Reduce border width in narrow tier (1.0pt instead of 2.0pt). Add font size reduction for compact mode.

### Pattern 4: Smart Truncation with Ellipsis

**What:** Use NSParagraphStyle.lineBreakMode = .byTruncatingTail to truncate overflowing cell content

**When to use:** Default for all cells to keep rows tight and scannable

**Example:**
```swift
// Current implementation (TableRenderer.swift line 215)
paragraphStyle.lineBreakMode = .byTruncatingTail

// Cell content with ellipsis for overflow
let attributes: [NSAttributedString.Key: Any] = [
    .paragraphStyle: paragraphStyle,
    .font: isHeader ? NSFont.boldSystemFont(ofSize: bodyFontSize) : NSFont.systemFont(ofSize: bodyFontSize),
    .foregroundColor: foregroundColor
]
```

**Enhancement for Phase 13:** This is already implemented. Optionally add tooltip support for revealing full content on hover.

### Pattern 5: Column Alignment Respect

**What:** Map GFM alignment markers to NSParagraphStyle.alignment

**When to use:** When configuring paragraph style for each cell

**Example:**
```swift
// Current implementation (TableRenderer.swift lines 203-211)
switch alignment {
case .left, nil:
    paragraphStyle.alignment = .left
case .center:
    paragraphStyle.alignment = .center
case .right:
    paragraphStyle.alignment = .right
}
```

**Enhancement for Phase 13:** No changes needed — current implementation respects GFM alignment markers correctly.

### Anti-Patterns to Avoid

- **Per-cell background colors:** Quick Look should use minimal styling — header separator line only, not full grid
- **Automatic layout algorithm:** NSTextTable.automaticLayoutAlgorithm doesn't respect explicit column widths — stick with fixedLayoutAlgorithm
- **Horizontal scrolling:** Breaks single NSTextView architecture — use truncation and proportional scaling instead
- **Wrapping all cells:** Creates lopsided tall rows — only wrap when most cells in row would benefit
- **Fixed pixel widths without scaling:** Doesn't adapt to available width — use content-proportional widths with tier-aware constraints

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Table layout in NSAttributedString | Custom UITableView embedding or manual layout | NSTextTable + NSTextTableBlock | Only official way to create tables in NSAttributedString; handles cell positioning, borders, padding automatically |
| Column width calculation | Simple equal distribution | Content-based measurement with proportional scaling | Avoids wasted space on narrow columns and crushing of wide columns |
| Text truncation with ellipsis | Manual string truncation | NSParagraphStyle.lineBreakMode = .byTruncatingTail | Automatic ellipsis rendering, respects font metrics, handles edge cases |
| Tooltip for truncated text | Custom overlay views | NSView.toolTip or NSAttributedString.Key.toolTip | Built-in AppKit support, respects system appearance, handles timing/positioning |

**Key insight:** NSTextTable is surprisingly capable once you understand the tier-specific measurement pattern. Don't try to work around it with custom layout code — enhance the existing TableRenderer with tier-aware parameters instead.

## Common Pitfalls

### Pitfall 1: Forgetting to End Cell Content with Newline

**What goes wrong:** NSTextTable silently fails to render cells if content doesn't end with "\n"

**Why it happens:** NSTextTableBlock expects paragraph markers to delimit cell boundaries

**How to avoid:** Always append "\n" to cell content strings before creating attributed string

**Warning signs:** Tables render as empty or show only first cell

**Example from codebase:**
```swift
// CRITICAL: Cell content MUST end with "\n" for NSTextTable to work (line 237)
let cellText = displayText + "\n"
return NSAttributedString(string: cellText, attributes: attributes)
```

### Pitfall 2: Using Automatic Layout Algorithm

**What goes wrong:** Explicit column widths are ignored, table expands to full container width

**Why it happens:** NSTextTable.automaticLayoutAlgorithm treats setContentWidth() as suggestions, not constraints

**How to avoid:** Always use `.fixedLayoutAlgorithm` when you need explicit column widths

**Warning signs:** Narrow tables expand to full width; proportional scaling doesn't work

**Example from codebase:**
```swift
// Must use fixedLayoutAlgorithm to respect explicit column widths (line 51)
nsTable.layoutAlgorithm = .fixedLayoutAlgorithm
```

### Pitfall 3: Inconsistent Tier-Aware Styling

**What goes wrong:** Some elements adapt to WidthTier but tables don't, creating visual inconsistency

**Why it happens:** Forgot to pass widthTier to TableRenderer or forgot to apply tier-specific values

**How to avoid:** Ensure TableRenderer receives widthTier parameter and applies it to ALL tier-dependent values (fonts, padding, borders, constraints)

**Warning signs:** Tables look too large in narrow contexts; padding doesn't match other elements

**Example from codebase:**
```swift
// TableRenderer MUST receive tier in init (line 21-22)
init(widthTier: WidthTier = .normal) {
    self.widthTier = widthTier
}

// MarkdownRenderer MUST pass tier when creating TableRenderer (line 223, 305)
let tableRenderer = TableRenderer(widthTier: widthTier)
```

### Pitfall 4: Not Scaling Border Thickness in Compact Mode

**What goes wrong:** Heavy borders overwhelm compact tables, making them look clunky

**Why it happens:** Border width is set as fixed 2.0pt without checking tier

**How to avoid:** Reduce border width to 1.0pt in narrow tier for visual balance

**Warning signs:** Header separator looks too thick in Finder preview pane

### Pitfall 5: Tooltip Not Working in Quick Look Context

**What goes wrong:** Added NSView.toolTip or NSAttributedString.Key.toolTip attribute but tooltip never appears

**Why it happens:** Quick Look extensions may not have full interactive event handling in all contexts (especially Finder preview pane)

**How to avoid:** Implement tooltip support optimistically but design truncation to be usable without tooltips

**Warning signs:** Tooltips work in Quick Look popup but not in Finder preview pane

## Code Examples

Verified patterns from official sources and existing codebase:

### NSTextTable Basic Setup

**Source:** [Apple Developer Archive - Using Text Tables](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html)

```swift
// Create table with explicit column count
let table = NSTextTable()
table.numberOfColumns = 3
table.collapsesBorders = true
table.layoutAlgorithm = .fixedLayoutAlgorithm

// Set total table width (optional - defaults to container width)
table.setContentWidth(600.0, type: .absoluteValueType)
```

### NSTextTableBlock Cell Creation

**Source:** Existing TableRenderer.swift (lines 165-239)

```swift
// Create cell block with position and span
let block = NSTextTableBlock(
    table: table,
    startingRow: row,
    rowSpan: 1,
    startingColumn: column,
    columnSpan: 1
)

// Set explicit width for this column
block.setContentWidth(columnWidth, type: .absoluteValueType)

// Configure padding on all edges
let padding: CGFloat = 6.0
for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
    block.setWidth(padding, type: .absoluteValueType, for: .padding, edge: edge)
}

// Add border to header cells only
if isHeader {
    block.setWidth(2.0, type: .absoluteValueType, for: .border, edge: .maxY)
    block.setBorderColor(NSColor.separatorColor, for: .maxY)
}

// Attach block to paragraph style
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.textBlocks = [block]
paragraphStyle.alignment = .left
paragraphStyle.lineBreakMode = .byTruncatingTail

// Create attributed string for cell (MUST end with \n)
let cellText = content + "\n"
return NSAttributedString(string: cellText, attributes: [
    .paragraphStyle: paragraphStyle,
    .font: NSFont.systemFont(ofSize: 14.0),
    .foregroundColor: NSColor.labelColor
])
```

### Content-Based Column Width Measurement

**Source:** Existing TableRenderer.swift (lines 104-162)

```swift
private func measureColumnWidths(for table: ExtractedTable, columnCount: Int) -> [CGFloat] {
    var columnWidths = [CGFloat](repeating: 0, count: columnCount)

    // Define font attributes for measurement
    let headerAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.boldSystemFont(ofSize: bodyFontSize)
    ]
    let bodyAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: bodyFontSize)
    ]

    // Measure header cells
    for (colIndex, headerContent) in table.headerCells.enumerated() {
        let text = headerContent.isEmpty ? "\u{00B7}" : headerContent
        let size = (text as NSString).size(withAttributes: headerAttrs)
        columnWidths[colIndex] = max(columnWidths[colIndex], size.width)
    }

    // Measure body cells
    for rowCells in table.bodyRows {
        for (colIndex, cellContent) in rowCells.enumerated() {
            guard colIndex < columnCount else { continue }
            let text = cellContent.isEmpty ? "\u{00B7}" : cellContent
            let size = (text as NSString).size(withAttributes: bodyAttrs)
            columnWidths[colIndex] = max(columnWidths[colIndex], size.width)
        }
    }

    // Add padding and breathing room
    let cellPadding: CGFloat = 12.0  // 6pt each side
    let breathingRoom: CGFloat = 20.0

    for i in 0..<columnCount {
        columnWidths[i] += cellPadding + breathingRoom
    }

    // Apply min/max constraints
    let minColumnWidth: CGFloat = 60.0
    let maxColumnWidth: CGFloat = 300.0

    for i in 0..<columnCount {
        columnWidths[i] = min(max(columnWidths[i], minColumnWidth), maxColumnWidth)
    }

    // Scale proportionally if total exceeds max table width
    let maxTableWidth: CGFloat = 800.0
    let totalWidth = columnWidths.reduce(0, +)
    if totalWidth > maxTableWidth {
        let scale = maxTableWidth / totalWidth
        for i in 0..<columnCount {
            columnWidths[i] *= scale
        }
    }

    return columnWidths
}
```

### Tier-Aware Font Sizing for Compact Mode

**Source:** Phase 13 enhancement (recommended pattern)

```swift
// Add to TableRenderer class
private var currentBodyFontSize: CGFloat {
    widthTier == .narrow ? 10.0 : 14.0  // Reduce from 12pt to 10pt for compact mode
}

// Use in cell rendering
let attributes: [NSAttributedString.Key: Any] = [
    .paragraphStyle: paragraphStyle,
    .font: isHeader ? NSFont.boldSystemFont(ofSize: currentBodyFontSize) : NSFont.systemFont(ofSize: currentBodyFontSize),
    .foregroundColor: foregroundColor
]
```

### Tier-Aware Border Thickness

**Source:** Phase 13 enhancement (recommended pattern)

```swift
// Header separator with tier-aware thickness
if isHeader {
    let borderWidth: CGFloat = widthTier == .narrow ? 1.0 : 2.0
    block.setWidth(borderWidth, type: .absoluteValueType, for: .border, edge: .maxY)
    block.setBorderColor(NSColor.separatorColor, for: .maxY)
}
```

### Optional: Tooltip for Truncated Content

**Source:** [NSAttributedString.Key.toolTip Documentation](https://developer.apple.com/documentation/foundation/nsattributedstring/key/1532319-tooltip)

```swift
// Add tooltip attribute if content is truncated
if cellContent.count > estimatedVisibleLength {
    attributes[.toolTip] = cellContent  // Full content as tooltip
}

// Note: May not work in all Quick Look contexts
// Implement as optional enhancement, not critical path
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed column widths | Content-proportional widths with constraints | Phase 9 (v1.0) | Tables adapt to actual content instead of wasting space |
| No tier awareness | WidthTier-based padding | Phase 9 (v1.0) | Tables work in narrow contexts but not optimally |
| Missing compact mode | Need font/border reduction | Phase 13 (this phase) | Tables will be readable at very narrow widths |
| No max table width cap | Need to match body content cap | Phase 13 (this phase) | Visual consistency with Phase 12 |

**Deprecated/outdated:**
- NSTextTable.automaticLayoutAlgorithm for content-fitted tables — Use .fixedLayoutAlgorithm with explicit column widths instead
- HTML table import via NSAttributedString(html:) — Loses tier-aware styling control, adds unnecessary overhead

## Open Questions

1. **Should tooltip support be attempted in Quick Look context?**
   - What we know: NSAttributedString.Key.toolTip exists, NSView.toolTip exists
   - What's unclear: Whether Quick Look extensions receive mouse hover events in all contexts (popup vs preview pane)
   - Recommendation: Implement truncation first (critical path), attempt tooltip as optional enhancement with graceful degradation

2. **What's the optimal max line count for cell wrapping?**
   - What we know: User wants to avoid lopsided tall rows
   - What's unclear: Exact threshold for "most cells in a row would benefit"
   - Recommendation: Start with 2-3 lines max, apply wrapping only if >50% of cells would wrap (implementation detail for planner)

3. **Should high column count (5+) tables use smaller fonts even in normal tier?**
   - What we know: 5+ columns may not fit at full size even with proportional scaling
   - What's unclear: User preference for readability vs fitting
   - Recommendation: Keep current approach (proportional scaling within max table width) for consistency; revisit if verification reveals issues

4. **What's the ideal max table width for normal tier?**
   - What we know: Body content cap is 640pt (Phase 12), current tables use 800pt
   - What's unclear: Whether tables should match exactly or be slightly wider
   - Recommendation: Match body content cap (640pt) for visual consistency

## Sources

### Primary (HIGH confidence)

- [Apple Developer Archive - Using Text Tables](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html) - Official NSTextTable/NSTextTableBlock guide with code examples
- [NSTextTable Documentation](https://developer.apple.com/documentation/appkit/nstexttable) - API reference
- [NSTextTableBlock Documentation](https://developer.apple.com/documentation/appkit/nstexttableblock) - API reference
- [NSTextTable.LayoutAlgorithm Documentation](https://developer.apple.com/documentation/appkit/nstexttable/layoutalgorithm) - Fixed vs automatic layout
- [NSLineBreakMode.byTruncatingTail Documentation](https://developer.apple.com/documentation/uikit/nslinebreakmode/bytruncatingtail) - Truncation with ellipsis
- [NSAttributedString.Key.toolTip Documentation](https://developer.apple.com/documentation/foundation/nsattributedstring/key/1532319-tooltip) - Tooltip attribute
- Existing codebase: TableRenderer.swift, TableExtractor.swift, MarkdownRenderer.swift (Phase 9, 11, 12 implementations)

### Secondary (MEDIUM confidence)

- [Medium: Better macOS/iOS Markdown Renderer](https://medium.com/@colbyn/a-better-macos-ios-markdown-renderer-proof-of-concept-d59b8b2d74fc) - NSTextTable usage example
- [Quarto: Tables Documentation](https://quarto.org/docs/authoring/tables.html) - Responsive markdown table patterns
- [Master Table Layouts: Creating Perfectly Balanced Columns in Markdown](https://medium.com/@shouke.wei/master-table-layouts-creating-perfectly-balanced-columns-in-markdown-3425f12c0fa1) - Column balance strategies
- [How to Write Responsive HTML Tables](https://johnfraney.ca/blog/how-to-write-responsive-html-tables/) - Responsive table patterns

### Tertiary (LOW confidence)

- GitHub discussions on NSTextTable usage - Verify with official docs
- Stack Overflow tooltip examples - Test in Quick Look context before relying on

## Metadata

**Confidence breakdown:**
- NSTextTable/NSTextTableBlock API: HIGH - Official Apple documentation and verified existing implementation
- Tier-aware enhancement strategy: HIGH - Extends proven Phase 12 pattern to tables
- Tooltip support in Quick Look: MEDIUM - API exists but Quick Look context constraints unclear
- Column wrapping heuristics: MEDIUM - User requirements clear, implementation details need experimentation

**Research date:** 2026-02-07
**Valid until:** 60 days (stable APIs, no fast-moving ecosystem changes expected)
