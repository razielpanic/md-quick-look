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

        // Create NSTextTable with percentage-based width for side margins
        let nsTable = NSTextTable()
        nsTable.numberOfColumns = columnCount
        nsTable.collapsesBorders = true
        nsTable.hidesEmptyCells = false

        // Set table width to 75% of container width to prevent edge-to-edge display
        // This provides breathing room on both sides without truncating content
        nsTable.setContentWidth(75.0, type: .percentageValueType)

        os_log("TableRenderer: Rendering table with %d columns at 75%% width", log: .tableRenderer, type: .debug, columnCount)

        // Render header row (row 0)
        for (colIndex, headerContent) in table.headerCells.enumerated() {
            let alignment = table.columnAlignments[safe: colIndex] ?? nil
            let cellString = renderCell(
                table: nsTable,
                row: 0,
                column: colIndex,
                content: headerContent,
                isHeader: true,
                alignment: alignment
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
                    alignment: alignment
                )
                result.append(cellString)
            }
        }

        let totalCells = table.headerCells.count + table.bodyRows.flatMap { $0 }.count
        os_log("TableRenderer: Render complete, %d cells", log: .tableRenderer, type: .info, totalCells)

        return result
    }

    // MARK: - Private Helpers

    private func renderCell(
        table: NSTextTable,
        row: Int,
        column: Int,
        content: String,
        isHeader: Bool,
        alignment: Table.ColumnAlignment?
    ) -> NSAttributedString {
        // Create NSTextTableBlock for this cell
        let block = NSTextTableBlock(
            table: table,
            startingRow: row,
            rowSpan: 1,
            startingColumn: column,
            columnSpan: 1
        )

        // No explicit column width - let NSTextTable distribute columns naturally within the 75% table width

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
