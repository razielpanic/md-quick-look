import Foundation
import AppKit
import os.log
import Markdown

extension OSLog {
    static let tableRenderer = OSLog(subsystem: "com.razielpanic.md-spotlighter", category: "tableRenderer")
}

/// Renders ExtractedTable to NSAttributedString using NSTextTable and NSTextTableBlock
class TableRenderer {

    private let bodyFontSize: CGFloat = 14.0

    /// Renders an extracted table to NSAttributedString with proper cell structure and styling
    /// - Parameter table: The extracted table data
    /// - Returns: NSAttributedString with NSTextTable-based layout
    func render(_ table: ExtractedTable) -> NSAttributedString {
        os_log("TableRenderer: Starting table render", log: .tableRenderer, type: .info)

        let result = NSMutableAttributedString()

        // Determine column count (max of header vs body rows)
        let headerColumnCount = table.headerCells.count
        let bodyMaxColumnCount = table.bodyRows.map { $0.count }.max() ?? 0
        let columnCount = max(headerColumnCount, bodyMaxColumnCount)

        guard columnCount > 0 else {
            os_log("TableRenderer: Empty table (no columns)", log: .tableRenderer, type: .error)
            return result
        }

        // Measure actual column widths based on content
        let columnWidths = measureColumnWidths(for: table, columnCount: columnCount)

        // Create NSTextTable with content-based sizing
        let nsTable = NSTextTable()
        nsTable.numberOfColumns = columnCount
        nsTable.collapsesBorders = true
        nsTable.hidesEmptyCells = false
        nsTable.layoutAlgorithm = .fixedLayoutAlgorithm

        // Set total table width based on measured column widths
        let totalWidth = columnWidths.reduce(0, +)
        nsTable.setContentWidth(totalWidth, type: .absoluteValueType)

        os_log("TableRenderer: Rendering table with %d columns (measured widths: %@, total: %.1fpt)", log: .tableRenderer, type: .debug, columnCount, columnWidths.map { String(format: "%.1f", $0) }.joined(separator: ", "), totalWidth)

        // Render header row (row 0)
        for (colIndex, headerContent) in table.headerCells.enumerated() {
            let alignment = table.columnAlignments[safe: colIndex] ?? nil
            let cellString = renderCell(
                table: nsTable,
                row: 0,
                column: colIndex,
                content: headerContent,
                isHeader: true,
                alignment: alignment,
                columnWidths: columnWidths
            )
            result.append(cellString)
        }

        // Render body rows starting at row 1
        for (rowIndex, rowCells) in table.bodyRows.enumerated() {
            for (colIndex, cellContent) in rowCells.enumerated() {
                let alignment = table.columnAlignments[safe: colIndex] ?? nil
                let cellString = renderCell(
                    table: nsTable,
                    row: rowIndex + 1,  // +1 because row 0 is header
                    column: colIndex,
                    content: cellContent,
                    isHeader: false,
                    alignment: alignment,
                    columnWidths: columnWidths
                )
                result.append(cellString)
            }
        }

        let totalCells = table.headerCells.count + table.bodyRows.flatMap { $0 }.count
        os_log("TableRenderer: Render complete, %d cells", log: .tableRenderer, type: .info, totalCells)

        return result
    }

    // MARK: - Private Helpers

    /// Measures actual rendered text widths for each column
    /// - Parameters:
    ///   - table: The extracted table data
    ///   - columnCount: Number of columns in the table
    /// - Returns: Array of column widths in points
    private func measureColumnWidths(for table: ExtractedTable, columnCount: Int) -> [CGFloat] {
        var columnWidths = [CGFloat](repeating: 0, count: columnCount)

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

        // Add padding (6pt each side = 12pt total) plus breathing room (20pt)
        // Apply min/max constraints
        let minColumnWidth: CGFloat = 60.0
        let maxColumnWidth: CGFloat = 300.0

        for i in 0..<columnCount {
            columnWidths[i] += 12.0 + 20.0  // padding + breathing room
            columnWidths[i] = min(max(columnWidths[i], minColumnWidth), maxColumnWidth)
        }

        // Cap total table width
        let maxTableWidth: CGFloat = 800.0
        let totalWidth = columnWidths.reduce(0, +)
        if totalWidth > maxTableWidth {
            // Scale all columns proportionally to fit
            let scale = maxTableWidth / totalWidth
            for i in 0..<columnCount {
                columnWidths[i] *= scale
            }
        }

        return columnWidths
    }

    private func renderCell(
        table: NSTextTable,
        row: Int,
        column: Int,
        content: String,
        isHeader: Bool,
        alignment: Table.ColumnAlignment?,
        columnWidths: [CGFloat]
    ) -> NSAttributedString {
        // Create NSTextTableBlock for this cell
        let block = NSTextTableBlock(
            table: table,
            startingRow: row,
            rowSpan: 1,
            startingColumn: column,
            columnSpan: 1
        )

        // Set explicit column width based on measurements
        let columnWidth = columnWidths[safe: column] ?? 100.0
        block.setContentWidth(columnWidth, type: .absoluteValueType)

        // Configure padding: 6pt on all edges for balanced density/readability
        for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
            block.setWidth(6.0, type: .absoluteValueType, for: .padding, edge: edge)
        }

        // Header separator: bottom border on header cells only
        if isHeader {
            block.setWidth(2.0, type: .absoluteValueType, for: .border, edge: .maxY)
            block.setBorderColor(NSColor.separatorColor, for: .maxY)
        }

        // Create paragraph style with text block
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.textBlocks = [block]

        // Set horizontal alignment based on markdown column alignment
        switch alignment {
        case .left, nil:
            paragraphStyle.alignment = .left
        case .center:
            paragraphStyle.alignment = .center
        case .right:
            paragraphStyle.alignment = .right
        }

        // Use truncation with ellipsis for long content
        // Content-based column widths prevent huge tables while ellipsis handles overflow
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // Handle empty cells: show middot indicator with subtle color, no background
        let displayText: String
        let foregroundColor: NSColor

        if content.isEmpty {
            displayText = "\u{00B7}"  // middot
            foregroundColor = NSColor.quaternaryLabelColor  // Lighter/more subtle
        } else {
            displayText = content
            foregroundColor = NSColor.labelColor
        }

        // Build attributes
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: isHeader ? NSFont.boldSystemFont(ofSize: bodyFontSize) : NSFont.systemFont(ofSize: bodyFontSize),
            .foregroundColor: foregroundColor
        ]

        // CRITICAL: Cell content MUST end with "\n" for NSTextTable to work
        let cellText = displayText + "\n"

        return NSAttributedString(string: cellText, attributes: attributes)
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
