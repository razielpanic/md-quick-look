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

        // Create NSTextTable
        let nsTable = NSTextTable()
        nsTable.numberOfColumns = columnCount
        nsTable.collapsesBorders = true
        nsTable.hidesEmptyCells = false

        // Calculate content-aware column widths
        let columnWidths = calculateColumnWidths(
            headerCells: table.headerCells,
            bodyRows: table.bodyRows,
            columnCount: columnCount
        )

        os_log("TableRenderer: Rendering table with %d columns", log: .tableRenderer, type: .debug, columnCount)

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
                columnWidth: columnWidths[safe: colIndex] ?? 100.0
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
                    columnWidth: columnWidths[safe: colIndex] ?? 100.0
                )
                result.append(cellString)
            }
        }

        let totalCells = table.headerCells.count + table.bodyRows.flatMap { $0 }.count
        os_log("TableRenderer: Render complete, %d cells", log: .tableRenderer, type: .info, totalCells)

        return result
    }

    // MARK: - Private Helpers

    /// Calculates content-aware column widths based on cell content
    /// - Parameters:
    ///   - headerCells: Header row cells
    ///   - bodyRows: Body row cells
    ///   - columnCount: Total number of columns
    /// - Returns: Array of column widths in points
    private func calculateColumnWidths(
        headerCells: [String],
        bodyRows: [[String]],
        columnCount: Int
    ) -> [CGFloat] {
        // Constants for width calculation
        let characterWidth: CGFloat = 8.0  // Approximate width per character for system font
        let cellPadding: CGFloat = 12.0     // 6pt on each side
        let minColumnWidth: CGFloat = 60.0  // Minimum width for very short content
        let maxColumnWidth: CGFloat = 300.0 // Maximum width to prevent extreme cases

        var columnWidths: [CGFloat] = Array(repeating: minColumnWidth, count: columnCount)

        // For each column, find the maximum content length
        for columnIndex in 0..<columnCount {
            var maxLength = 0

            // Check header cell
            if columnIndex < headerCells.count {
                maxLength = max(maxLength, headerCells[columnIndex].count)
            }

            // Check all body row cells
            for row in bodyRows {
                if columnIndex < row.count {
                    maxLength = max(maxLength, row[columnIndex].count)
                }
            }

            // Calculate estimated width: length * characterWidth + padding
            let estimatedWidth = CGFloat(maxLength) * characterWidth + cellPadding

            // Apply min/max constraints
            let finalWidth = min(max(estimatedWidth, minColumnWidth), maxColumnWidth)
            columnWidths[columnIndex] = finalWidth

            os_log("TableRenderer: Column %d maxLength=%d estimatedWidth=%.1f finalWidth=%.1f",
                   log: .tableRenderer, type: .debug,
                   columnIndex, maxLength, estimatedWidth, finalWidth)
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
        columnWidth: CGFloat
    ) -> NSAttributedString {
        // Create NSTextTableBlock for this cell
        let block = NSTextTableBlock(
            table: table,
            startingRow: row,
            rowSpan: 1,
            startingColumn: column,
            columnSpan: 1
        )

        // Set explicit column width to prevent cells from expanding to container width
        // Note: We set width for the block's outer edge (.border) which controls the cell's overall width
        block.setWidth(columnWidth, type: .absoluteValueType, for: .border)
        os_log("TableRenderer: Set cell [%d,%d] width to %.1f pt", log: .tableRenderer, type: .debug, row, column, columnWidth)

        // Configure padding: 6pt on all edges for balanced density/readability
        for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
            block.setWidth(6.0, type: .absoluteValueType, for: .padding, edge: edge)
        }

        // Header separator: bottom border on header cells only
        if isHeader {
            block.setWidth(1.0, type: .absoluteValueType, for: .border, edge: .maxY)
            block.setBorderColor(NSColor.separatorColor)
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

        // Truncate long content with ellipsis for quick scanning
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // Handle empty cells: show middot indicator with subtle color, no background
        let displayText: String
        let foregroundColor: NSColor

        if content.isEmpty {
            displayText = "\u{00B7}"  // middot
            foregroundColor = NSColor.quaternaryLabelColor  // Lighter/more subtle
        } else {
            displayText = content
            foregroundColor = NSColor.textColor
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
