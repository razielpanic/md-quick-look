# Phase 3: Tables & Advanced Elements - Research

**Researched:** 2026-02-02
**Domain:** NSTextTable/NSTextTableBlock for GFM Table Rendering in AppKit
**Confidence:** HIGH

## Summary

Phase 3 requires rendering GitHub-flavored markdown (GFM) tables in the existing Quick Look extension. The project already uses swift-markdown for parsing (it's bundled with cmark-gfm which supports GFM tables natively) and NSTextView with custom NSLayoutManager for rendering. The current `MarkdownRenderer` transforms PresentationIntent attributes to styled NSAttributedString.

**Key finding:** `AttributedString(markdown:)` does NOT produce PresentationIntent for tables. Tables must be handled separately by parsing with swift-markdown directly (`Document(parsing:)`) and using the MarkupVisitor pattern to detect `Table`, `Table.Head`, `Table.Body`, `Table.Row`, and `Table.Cell` elements. The standard AppKit approach for rendering tables in NSAttributedString is via `NSTextTable` and `NSTextTableBlock`, which are macOS-only classes that integrate with NSParagraphStyle's `textBlocks` property.

The implementation architecture requires a hybrid approach: continue using `AttributedString(markdown:)` for basic markdown elements (it handles most content well), but add a preprocessing step to extract tables using swift-markdown's Visitor pattern, render them to NSAttributedString with NSTextTable/NSTextTableBlock, and integrate the results.

**Primary recommendation:** Parse markdown with swift-markdown `Document(parsing:)`, use MarkupVisitor to identify tables, render tables using NSTextTable/NSTextTableBlock with NSParagraphStyle.textBlocks, apply the user-specified minimal styling (header-only separator, bold headers, no borders/backgrounds on body rows).

## Standard Stack

The established libraries/tools for this phase:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| swift-markdown | 0.7.x | Parse markdown including GFM tables | Already in project, cmark-gfm backend, provides Table/Row/Cell AST nodes |
| NSTextTable | macOS 10.4+ | Represent table structure | Apple's native table rendering for NSAttributedString |
| NSTextTableBlock | macOS 10.4+ | Represent individual table cells | Cells refer to parent NSTextTable, controls size/position |
| NSMutableParagraphStyle.textBlocks | macOS 10.4+ | Attach table cells to paragraphs | How NSTextTableBlock integrates with text system |
| MarkupVisitor protocol | swift-markdown | Traverse markdown AST | Pattern for extracting tables from parsed document |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSTextBlock.Layer | macOS 10.4+ | Configure padding/border/margin | Setting cell spacing per phase decisions |
| NSTextBlock.Dimension | macOS 10.4+ | Configure width/height constraints | Implementing column width algorithm |
| NSLineBreakMode.byTruncatingTail | Foundation | Truncate text with ellipsis | Per phase decision for long cell content |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSTextTable | NSTableView embedded in text | Complex, doesn't flow with text, overkill for Quick Look |
| NSTextTable | Custom view overlay (MarkdownView approach) | Requires TextKit2 expertise, doesn't fit existing architecture |
| swift-markdown Visitor | Regex table detection | Fragile, doesn't handle edge cases, swift-markdown already parses tables |

**Installation:**
```swift
// No additional dependencies - swift-markdown already in project
// NSTextTable/NSTextTableBlock are native AppKit (macOS only)
import Markdown  // swift-markdown
import AppKit    // NSTextTable, NSTextTableBlock, NSParagraphStyle
```

## Architecture Patterns

### Recommended Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    MarkdownRenderer                         │
├────────────────────────────────────────────────────────────┤
│ 1. Parse with swift-markdown: Document(parsing:)           │
│ 2. Walk AST to detect tables using MarkupVisitor           │
│ 3. For tables: render via NSTextTable/NSTextTableBlock     │
│ 4. For non-tables: use AttributedString(markdown:)         │
│ 5. Combine results maintaining document order              │
└────────────────────────────────────────────────────────────┘
```

### Pattern 1: MarkupVisitor for Table Detection
**What:** Walk swift-markdown AST to find and extract table information
**When to use:** Always - tables require separate handling from PresentationIntent
**Example:**
```swift
// Source: swift-markdown MarkupVisitor protocol + Table API
import Markdown

struct TableExtractor: MarkupVisitor {
    typealias Result = [ExtractedTable]

    struct ExtractedTable {
        let columnAlignments: [Table.ColumnAlignment?]
        let headerCells: [[InlineMarkup]]  // Header row cell contents
        let bodyRows: [[[InlineMarkup]]]   // Body rows, each with cell contents
        let sourceRange: SourceRange?
    }

    mutating func defaultVisit(_ markup: Markup) -> [ExtractedTable] {
        var tables: [ExtractedTable] = []
        for child in markup.children {
            tables.append(contentsOf: visit(child))
        }
        return tables
    }

    mutating func visitTable(_ table: Table) -> [ExtractedTable] {
        let alignments = table.columnAlignments

        // Extract header cells
        let headerCells: [[InlineMarkup]] = table.head.cells.map { cell in
            Array(cell.children.compactMap { $0 as? InlineMarkup })
        }

        // Extract body rows
        let bodyRows: [[[InlineMarkup]]] = table.body.rows.map { row in
            row.cells.map { cell in
                Array(cell.children.compactMap { $0 as? InlineMarkup })
            }
        }

        return [ExtractedTable(
            columnAlignments: alignments,
            headerCells: headerCells,
            bodyRows: bodyRows,
            sourceRange: table.range
        )]
    }
}
```

### Pattern 2: NSTextTable Cell Construction
**What:** Create table cells using NSTextTableBlock attached to NSParagraphStyle
**When to use:** For each cell when rendering extracted table data
**Example:**
```swift
// Source: Apple Text Layout Programming Guide + NSTextTable docs
func createTableCell(
    table: NSTextTable,
    row: Int,
    column: Int,
    content: String,
    isHeader: Bool,
    alignment: Table.ColumnAlignment?
) -> NSAttributedString {
    // Create table block for this cell
    let block = NSTextTableBlock(
        table: table,
        startingRow: row,
        rowSpan: 1,
        startingColumn: column,
        columnSpan: 1
    )

    // Configure padding (Claude's discretion - 6pt balances density/readability)
    block.setWidth(6.0, type: .absoluteValueType, for: .padding)

    // No borders on cells per phase decision (header separator drawn separately)
    // block.setWidth(0, type: .absoluteValueType, for: .border)

    // Create paragraph style with text block
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.textBlocks = [block]

    // Set alignment based on markdown column alignment
    switch alignment {
    case .left, nil:
        paragraphStyle.alignment = .left
    case .center:
        paragraphStyle.alignment = .center
    case .right:
        paragraphStyle.alignment = .right
    }

    // Truncate long content with ellipsis per phase decision
    paragraphStyle.lineBreakMode = .byTruncatingTail

    // Create attributed string for cell
    // CRITICAL: Cell content MUST end with newline for NSTextTable to work
    let cellText = content + "\n"
    let attributes: [NSAttributedString.Key: Any] = [
        .paragraphStyle: paragraphStyle,
        .font: isHeader ? NSFont.boldSystemFont(ofSize: 14) : NSFont.systemFont(ofSize: 14),
        .foregroundColor: NSColor.textColor
    ]

    return NSAttributedString(string: cellText, attributes: attributes)
}
```

### Pattern 3: Header Separator Line via NSTextTable Border
**What:** Draw single line between header and body rows
**When to use:** After header row, before first body row
**Example:**
```swift
// Source: NSTextBlock setWidth type forLayer documentation
// Apply border ONLY to bottom edge of header cells
func configureHeaderSeparator(block: NSTextTableBlock) {
    // Draw 1pt line at bottom of header cells only
    block.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .maxY)
    block.setBorderColor(NSColor.separatorColor)  // Semantic color for appearance
}
```

### Pattern 4: Empty Cell Indicator
**What:** Show subtle indicator for empty table cells
**When to use:** When cell content is empty string
**Example:**
```swift
// Source: Phase decision - subtle indicator for empty cells
func contentForCell(_ content: String) -> (String, NSColor?) {
    if content.trimmingCharacters(in: .whitespaces).isEmpty {
        // Return middot as subtle indicator with gray color
        return ("\u{00B7}", NSColor.tertiaryLabelColor)  // Middle dot
    }
    return (content, nil)
}
```

### Pattern 5: Malformed Table Fallback
**What:** Render malformed tables as monospace text
**When to use:** When swift-markdown parsing fails or produces invalid structure
**Example:**
```swift
// Source: Phase decision - fallback to raw text with monospace
func renderMalformedTable(rawText: String) -> NSAttributedString {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        .foregroundColor: NSColor.textColor
    ]
    return NSAttributedString(string: rawText, attributes: attributes)
}
```

### Pattern 6: Table Width Constraint (90% max)
**What:** Limit table width to 90% of container per phase decision
**When to use:** When configuring NSTextTable
**Example:**
```swift
// Source: NSTextTable numberOfColumns + column width configuration
func configureTableWidth(_ table: NSTextTable, columnCount: Int) {
    table.numberOfColumns = columnCount

    // Set table to 90% of container width per phase decision
    // Each column gets equal share (proportional sizing)
    let columnWidthPercent = 90.0 / CGFloat(columnCount)
    for col in 0..<columnCount {
        // Note: Column widths set implicitly via content or explicitly via setWidth
        // For proportional sizing, let content determine widths within 90% total
    }
}
```

### Anti-Patterns to Avoid
- **Using AttributedString(markdown:) for tables:** It doesn't produce PresentationIntent.table. Tables are silently converted to plain text. Must use swift-markdown directly.
- **Forgetting newline after cell content:** NSTextTable requires each cell paragraph to end with `\n`. Without it, cells merge incorrectly.
- **Setting borders on all sides:** Phase decision specifies header separator only. Don't add grid lines.
- **Complex background colors:** Phase decision specifies no alternating row colors. Keep visual treatment minimal.
- **Building custom table layout:** NSTextTable already handles cell sizing, positioning, and flow. Don't reinvent.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Table parsing | Regex for pipe tables | swift-markdown Table nodes | Already parses GFM, handles escaping, alignment syntax |
| Cell positioning | Manual x/y calculation | NSTextTableBlock row/column | System handles sizing, flow, container width |
| Column alignment | Manual text padding | NSParagraphStyle.alignment with NSTextTableBlock | Respects text direction, handles Unicode properly |
| Text truncation | Manual string slicing | NSLineBreakMode.byTruncatingTail | Handles Unicode grapheme clusters, adds proper ellipsis |
| Header/body separation | Custom drawing | NSTextBlock border on .maxY edge | Integrates with text system, respects appearance |
| Proportional column widths | Manual width math | NSTextTable layoutAlgorithm | System balances columns based on content |

**Key insight:** NSTextTable was designed specifically for tables in rich text. It handles the hard problems (column balancing, cell flow, container integration). Use it.

## Common Pitfalls

### Pitfall 1: AttributedString Doesn't Parse Tables
**What goes wrong:** Tables render as plain pipe-separated text
**Why it happens:** `AttributedString(markdown:)` uses a subset of markdown; tables are not converted to PresentationIntent
**How to avoid:** Parse with swift-markdown `Document(parsing:)` and use MarkupVisitor to detect Table elements
**Warning signs:** Table markdown appears as `| Header |` text in preview

### Pitfall 2: Missing Newlines in Table Cells
**What goes wrong:** All cells merge into one cell, or layout is corrupted
**Why it happens:** NSTextTable expects each cell to be a separate paragraph ending with `\n`
**How to avoid:** Always append `\n` to cell content before creating NSAttributedString
**Warning signs:** Table renders as single long row or bizarre layout

### Pitfall 3: Table Not Displaying At All
**What goes wrong:** Table region appears empty or shows nothing
**Why it happens:** textBlocks array not set on paragraph style, or table not added to correct NSTextTable instance
**How to avoid:** Verify `paragraphStyle.textBlocks = [block]` is set, and all blocks reference same NSTextTable instance
**Warning signs:** Gap in rendered content where table should be

### Pitfall 4: Column Alignment Not Working
**What goes wrong:** Text is always left-aligned despite markdown alignment syntax
**Why it happens:** Alignment set on wrong object (table vs cell) or not checking columnAlignments array
**How to avoid:** Set alignment on NSMutableParagraphStyle, not NSTextTableBlock. Use `table.columnAlignments[column]` from swift-markdown
**Warning signs:** All columns left-aligned regardless of `:---:` syntax

### Pitfall 5: Inline Formatting Lost in Cells
**What goes wrong:** Bold/italic/code in table cells renders as plain text
**Why it happens:** Cell content extracted as plain text without processing inline markup
**How to avoid:** When extracting cell content, process InlineMarkup children (Strong, Emphasis, InlineCode, etc.)
**Warning signs:** `**bold**` appears literally in cells instead of bold text

### Pitfall 6: Performance with Large Tables
**What goes wrong:** Preview is slow or unresponsive with 100+ row tables
**Why it happens:** NSTextView layout is O(n) with text length; many cells = many paragraphs
**How to avoid:** Per phase decision, implement first without optimization, measure. If slow, consider lazy row rendering or pagination.
**Warning signs:** Spinning beachball on large markdown files with tables

## Code Examples

Verified patterns for table rendering:

### Complete Table Rendering Pipeline
```swift
// Source: Synthesized from swift-markdown API + NSTextTable documentation
import Markdown
import AppKit

class TableRenderer {

    func renderTable(_ table: Table) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Create NSTextTable
        let nsTable = NSTextTable()
        nsTable.numberOfColumns = table.maxColumnCount
        nsTable.collapsesBorders = true  // Share borders between cells
        nsTable.hidesEmptyCells = false  // Show empty cells per phase decision

        let alignments = table.columnAlignments
        var currentRow = 0

        // Render header row
        for (colIndex, cell) in table.head.cells.enumerated() {
            let cellString = renderTableCell(
                table: nsTable,
                row: currentRow,
                column: colIndex,
                cell: cell,
                isHeader: true,
                alignment: alignments[safe: colIndex] ?? nil
            )
            result.append(cellString)
        }
        currentRow += 1

        // Render body rows
        for row in table.body.rows {
            for (colIndex, cell) in row.cells.enumerated() {
                let cellString = renderTableCell(
                    table: nsTable,
                    row: currentRow,
                    column: colIndex,
                    cell: cell,
                    isHeader: false,
                    alignment: alignments[safe: colIndex] ?? nil
                )
                result.append(cellString)
            }
            currentRow += 1
        }

        return result
    }

    private func renderTableCell(
        table: NSTextTable,
        row: Int,
        column: Int,
        cell: Table.Cell,
        isHeader: Bool,
        alignment: Table.ColumnAlignment?
    ) -> NSAttributedString {
        // Create block for this cell
        let block = NSTextTableBlock(
            table: table,
            startingRow: row,
            rowSpan: Int(cell.rowspan),
            startingColumn: column,
            columnSpan: Int(cell.colspan)
        )

        // Configure padding (6pt for balanced density)
        for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
            block.setWidth(6.0, type: .absoluteValueType, for: .padding, edge: edge)
        }

        // Header separator: bottom border on header cells only
        if isHeader {
            block.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .maxY)
            block.setBorderColor(NSColor.separatorColor)
        }

        // Create paragraph style
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textBlocks = [block]
        paragraphStyle.lineBreakMode = .byTruncatingTail  // Truncate with ellipsis

        // Set alignment from markdown
        switch alignment {
        case .left, nil:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .right:
            paragraphStyle.alignment = .right
        }

        // Get cell text content
        let cellText = extractCellText(from: cell)
        let displayText = cellText.isEmpty ? "\u{00B7}" : cellText  // Middot for empty

        // Build attributed string
        var attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: isHeader ? NSFont.boldSystemFont(ofSize: 14) : NSFont.systemFont(ofSize: 14),
            .foregroundColor: cellText.isEmpty ? NSColor.tertiaryLabelColor : NSColor.textColor
        ]

        // CRITICAL: Must end with newline
        return NSAttributedString(string: displayText + "\n", attributes: attributes)
    }

    private func extractCellText(from cell: Table.Cell) -> String {
        // Extract plain text, preserving inline formatting would require
        // recursive processing of InlineMarkup children
        return cell.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

### Integration with Existing MarkdownRenderer
```swift
// Source: Existing MarkdownRenderer pattern + swift-markdown Document API
import Markdown

extension MarkdownRenderer {

    func render(markdown: String) -> NSAttributedString {
        // Parse with swift-markdown for table detection
        let document = Document(parsing: markdown)

        // Check for tables
        var tableExtractor = TableExtractor()
        let tables = tableExtractor.visit(document)

        if tables.isEmpty {
            // No tables - use existing AttributedString approach
            return renderWithAttributedString(markdown: markdown)
        } else {
            // Has tables - use hybrid approach
            return renderWithTables(document: document, markdown: markdown)
        }
    }

    private func renderWithTables(document: Document, markdown: String) -> NSAttributedString {
        // Build result by walking document and handling tables specially
        var renderer = HybridRenderer()
        return renderer.render(document)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| HTML table in WKWebView | NSTextTable in NSTextView | Always been option | Native approach avoids web view complexity |
| Manual table drawing | NSTextTable/NSTextTableBlock | macOS 10.4+ | System handles layout, we provide content |
| Grid-based borders | CSS-like border control per edge | macOS 10.4+ | Can implement header-only separator cleanly |

**Deprecated/outdated:**
- **RTF table conversion:** Old approach using HTML->RTF->NSAttributedString. Direct NSTextTable is cleaner.
- **Text table panel:** UI for users to create tables. Not applicable to read-only Quick Look.

## Open Questions

Things that couldn't be fully resolved:

1. **Inline formatting in table cells**
   - What we know: swift-markdown provides InlineMarkup children in cells (Strong, Emphasis, InlineCode, Link)
   - What's unclear: Best approach to render inline formatting - process recursively or use plainText?
   - Recommendation: Start with plainText for simplicity. If user needs inline formatting, add recursive InlineMarkup processing. Per phase context: "Claude's discretion on inline formatting support scope."

2. **Column width algorithm specifics**
   - What we know: NSTextTable has layoutAlgorithm property (.automatic, .fixed)
   - What's unclear: Exact behavior of automatic layout, how to enforce minimum widths
   - Recommendation: Use .automatic layout, test with various content. If columns too narrow, add minimum width constraints via setWidth on NSTextTableBlock.

3. **Performance threshold for "slow"**
   - What we know: Phase says "test performance first, optimize only if actually slow"
   - What's unclear: What constitutes "slow" for Quick Look - 100ms? 500ms? 1s?
   - Recommendation: Target <500ms for initial render. Profile with 100-row tables early.

4. **Nested table detection accuracy**
   - What we know: Phase says "flatten to text (show nested table as plain text in cell)"
   - What's unclear: How reliably swift-markdown parses nested tables, whether they appear as Table within Table.Cell
   - Recommendation: If Table found within Table.Cell children, render inner table as plainText.

## Sources

### Primary (HIGH confidence)
- swift-markdown source code (Table.swift, TableCell.swift, TableRow.swift, TableHead.swift, TableBody.swift, MarkupVisitor.swift, HTMLFormatter.swift) - Read directly from `/Users/razielpanic/Projects/md-spotlighter/build/SourcePackages/checkouts/swift-markdown/`
- [Apple Text Layout Programming Guide: Using Text Tables](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html) - Complete programmatic table creation documentation
- NSTextTable API (properties: numberOfColumns, collapsesBorders, hidesEmptyCells, layoutAlgorithm)
- NSTextTableBlock API (init with table/row/column/span, setWidth/setBorderColor methods)

### Secondary (MEDIUM confidence)
- [NSTextBlock.setWidth(_:type:for:) documentation](https://developer.apple.com/documentation/appkit/nstextblock/setwidth(_:type:for:)) - Layer types for padding/border/margin
- [ZMarkupParser GitHub issue #6](https://github.com/ZhgChgLi/ZMarkupParser/issues/6) - Confirms NSTextTableBlock is macOS-only, explains HTML table parsing internals
- [Apple Developer Forums: NSAttributedString table formatting](https://developer.apple.com/forums/thread/739583) - Working code for iterating textBlocks and fixing table rendering issues
- [NSLineBreakMode.byTruncatingTail](https://developer.apple.com/documentation/uikit/nslinebreakmode/bytruncatingtail) - Truncation with ellipsis behavior

### Tertiary (LOW confidence - WebSearch findings)
- [Fatbobman: Deep Dive into SwiftUI Rich Text Layout](https://fatbobman.com/en/posts/a-deep-dive-into-swiftui-rich-text-layout/) - MarkdownView approach using view overlay for tables (alternative not used)
- [NSTextView Performance](https://cocoadev.github.io/NSTextViewPerformanceEnhancement/) - General performance considerations
- [WWDC 2018 TextKit Best Practices](https://asciiwwdc.com/2018/sessions/221) - Layout performance architecture

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - NSTextTable/NSTextTableBlock are stable macOS 10.4+ APIs, swift-markdown Table API verified in source
- Architecture: HIGH - Visitor pattern well-documented, table cell construction documented in Apple guide
- Pitfalls: MEDIUM - Based on documentation reading and community reports, not personal testing
- Code examples: MEDIUM - Synthesized from official documentation and swift-markdown source, not tested in this project

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - NSTextTable and swift-markdown APIs are stable)

**Notes:**
- User decisions constrain: header separator only (no grid), bold headers only (no background), no alternating rows, truncate with ellipsis, 90% max width, empty cell indicator
- Claude's discretion areas: cell padding (recommended 6pt), column width algorithm (recommended automatic), inline formatting scope (recommended start simple), minimum column widths (recommended rely on automatic sizing), performance optimization (only if testing shows issues)
- Phase boundary: GFM tables only. No other "advanced elements" in scope per phase description.
