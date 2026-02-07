import Foundation
import AppKit
import os.log
import Markdown

extension OSLog {
    static let tableRenderer = OSLog(subsystem: "com.rocketpop.MDQuickLook", category: "tableRenderer")
}

/// Renders ExtractedTable to NSAttributedString using NSTextTable and NSTextTableBlock
class TableRenderer {

    var widthTier: WidthTier = .normal
    var availableWidth: CGFloat = 640

    private var bodyFontSize: CGFloat {
        widthTier == .narrow ? 11.0 : 14.0  // Compact mode: 11pt for max data density
    }

    /// Initializes TableRenderer with width tier and available width
    /// - Parameters:
    ///   - widthTier: The width tier for adaptive rendering (default: .normal)
    ///   - availableWidth: The available container width in points (default: 640)
    init(widthTier: WidthTier = .normal, availableWidth: CGFloat = 640) {
        self.widthTier = widthTier
        self.availableWidth = availableWidth
    }

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

        // Set total table width based on measured column widths, capped to max table width
        let totalWidth = columnWidths.reduce(0, +)
        let maxTableWidth = widthTier == .narrow ? availableWidth : min(availableWidth, 640.0)
        let cappedWidth = min(totalWidth, maxTableWidth)
        nsTable.setContentWidth(cappedWidth, type: .absoluteValueType)

        os_log("TableRenderer: Rendering table with %d columns (measured widths: %@, total: %.1fpt)", log: .tableRenderer, type: .debug, columnCount, columnWidths.map { String(format: "%.1f", $0) }.joined(separator: ", "), totalWidth)

        // Render header row (row 0) - headers always truncate
        for (colIndex, headerContent) in table.headerCells.enumerated() {
            let alignment = table.columnAlignments[safe: colIndex] ?? nil
            let cellString = renderCell(
                table: nsTable,
                row: 0,
                column: colIndex,
                content: headerContent,
                isHeader: true,
                alignment: alignment,
                columnWidths: columnWidths,
                shouldWrap: false
            )
            result.append(cellString)
        }

        // Render body rows starting at row 1 with smart wrap/truncate decision per row
        for (rowIndex, rowCells) in table.bodyRows.enumerated() {
            let rowFont = NSFont.systemFont(ofSize: bodyFontSize)
            let wrap = shouldWrapRow(cells: rowCells, columnWidths: columnWidths, font: rowFont)

            for (colIndex, cellContent) in rowCells.enumerated() {
                let alignment = table.columnAlignments[safe: colIndex] ?? nil
                let cellString = renderCell(
                    table: nsTable,
                    row: rowIndex + 1,  // +1 because row 0 is header
                    column: colIndex,
                    content: cellContent,
                    isHeader: false,
                    alignment: alignment,
                    columnWidths: columnWidths,
                    shouldWrap: wrap
                )
                result.append(cellString)
            }
        }

        let totalCells = table.headerCells.count + table.bodyRows.flatMap { $0 }.count
        os_log("TableRenderer: Render complete, %d cells", log: .tableRenderer, type: .info, totalCells)

        // Add spacing after table to separate from subsequent content
        let spacingStyle = NSMutableParagraphStyle()
        spacingStyle.paragraphSpacing = widthTier == .narrow ? 6 : 12
        spacingStyle.paragraphSpacingBefore = 0
        result.append(NSAttributedString(string: "\n", attributes: [
            .paragraphStyle: spacingStyle,
            .font: NSFont.systemFont(ofSize: 1)
        ]))

        return result
    }

    // MARK: - Private Helpers

    /// Determines if a row should use wrapping instead of truncation.
    /// Wrapping activates only when >50% of cells in the row would overflow their column width.
    private func shouldWrapRow(cells: [String], columnWidths: [CGFloat], font: NSFont) -> Bool {
        guard cells.count > 1 else { return false }

        var overflowCount = 0
        for (index, content) in cells.enumerated() {
            guard index < columnWidths.count else { continue }
            let cellWidth = columnWidths[index]
            let padding = widthTier == .narrow ? 4.0 : 12.0
            let availableTextWidth = cellWidth - padding

            let textWidth = (content as NSString).size(withAttributes: [.font: font]).width
            if textWidth > availableTextWidth {
                overflowCount += 1
            }
        }

        let shouldWrap = Double(overflowCount) / Double(cells.count) > 0.5
        os_log("TableRenderer: Row wrap decision: %{public}s (%d/%d cells overflow)", log: .tableRenderer, type: .debug, shouldWrap ? "wrap" : "truncate", overflowCount, cells.count)
        return shouldWrap
    }

    /// Checks if a string is likely an unbreakable token (URL, file path, long identifier).
    private func isUnbreakableString(_ content: String) -> Bool {
        let trimmed = content.trimmingCharacters(in: .whitespaces)
        if trimmed.contains("://") || trimmed.hasPrefix("/") || trimmed.hasPrefix("~") {
            return true
        }
        if trimmed.count > 20 && !trimmed.contains(" ") {
            return true
        }
        return false
    }

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

        // STEP 1: Measure raw content width per column
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

        // STEP 2: Add padding and breathing room (tier-aware compact mode)
        let cellPadding: CGFloat
        let breathingRoom: CGFloat
        if widthTier == .narrow {
            cellPadding = 4.0   // 2pt each side (compact mode)
            breathingRoom = 6.0
        } else {
            cellPadding = 12.0  // 6pt each side (normal mode)
            breathingRoom = 16.0
        }

        for i in 0..<columnCount {
            columnWidths[i] += cellPadding + breathingRoom
        }

        // STEP 3: Apply min/max column constraints (tier-aware compact mode)
        let minColumnWidth: CGFloat
        var maxColumnWidth: CGFloat
        if widthTier == .narrow {
            minColumnWidth = 30.0   // Compact mode minimum
            maxColumnWidth = 120.0  // Compact mode maximum
        } else {
            minColumnWidth = 50.0   // Normal mode minimum
            maxColumnWidth = 280.0  // Normal mode maximum
        }

        // STEP 4: High column count handling (5+ columns)
        if columnCount >= 5 {
            // Reduce max column width to prevent any single column from dominating
            // Max column can be at most 1.5x the equal-share width
            let maxTableWidth = widthTier == .narrow ? availableWidth : min(availableWidth, 640.0)
            let equalShare = maxTableWidth / CGFloat(columnCount)
            maxColumnWidth = min(maxColumnWidth, equalShare * 1.5)
        }

        for i in 0..<columnCount {
            columnWidths[i] = min(max(columnWidths[i], minColumnWidth), maxColumnWidth)
        }

        // STEP 5: Determine max table width
        // Normal mode: cap at 640pt (body content max width)
        // Narrow mode: use full available width (already constrained)
        let maxTableWidth: CGFloat = widthTier == .narrow ? availableWidth : min(availableWidth, 640.0)

        // STEP 6: Calculate total measured width
        let totalMeasuredWidth = columnWidths.reduce(0, +)

        // STEP 7: Content-fitted logic
        if totalMeasuredWidth <= maxTableWidth {
            // Table fits comfortably - use measured widths as-is (content-fitted)
            os_log("TableRenderer: Content-fitted table (%.1fpt of %.1fpt available)", log: .tableRenderer, type: .debug, totalMeasuredWidth, maxTableWidth)
            return columnWidths
        } else {
            // Table exceeds max width - scale proportionally
            os_log("TableRenderer: Scaling table from %.1fpt to %.1fpt", log: .tableRenderer, type: .debug, totalMeasuredWidth, maxTableWidth)

            let scale = maxTableWidth / totalMeasuredWidth
            for i in 0..<columnCount {
                columnWidths[i] *= scale
            }

            // Re-enforce minimum column width after scaling
            var needsRedistribution = false
            for i in 0..<columnCount {
                if columnWidths[i] < minColumnWidth {
                    columnWidths[i] = minColumnWidth
                    needsRedistribution = true
                }
            }

            // If any column fell below minimum, redistribute remaining space
            if needsRedistribution {
                let usedWidth = columnWidths.reduce(0, +)
                let remainingWidth = maxTableWidth - usedWidth

                if remainingWidth > 0 {
                    // Count columns that are above minimum (can absorb extra space)
                    let flexibleColumns = columnWidths.filter { $0 > minColumnWidth }.count

                    if flexibleColumns > 0 {
                        let extraPerColumn = remainingWidth / CGFloat(flexibleColumns)
                        for i in 0..<columnCount {
                            if columnWidths[i] > minColumnWidth {
                                columnWidths[i] += extraPerColumn
                            }
                        }
                    }
                }
            }

            return columnWidths
        }
    }

    private func renderCell(
        table: NSTextTable,
        row: Int,
        column: Int,
        content: String,
        isHeader: Bool,
        alignment: Table.ColumnAlignment?,
        columnWidths: [CGFloat],
        shouldWrap: Bool = false
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

        // Configure padding (tier-aware compact mode): 2pt in narrow mode, 6pt in normal mode
        let cellPadding: CGFloat = widthTier == .narrow ? 2.0 : 6.0
        for edge: NSRectEdge in [.minX, .minY, .maxX, .maxY] {
            block.setWidth(cellPadding, type: .absoluteValueType, for: .padding, edge: edge)
        }

        // Header separator: bottom border on header cells only (tier-aware thickness)
        if isHeader {
            let headerBorderWidth: CGFloat = widthTier == .narrow ? 1.0 : 2.0
            block.setWidth(headerBorderWidth, type: .absoluteValueType, for: .border, edge: .maxY)
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

        // Smart wrap/truncate decision
        // Headers always truncate, unbreakable strings always truncate, otherwise use row-level decision
        if isHeader || !shouldWrap || isUnbreakableString(content) {
            paragraphStyle.lineBreakMode = .byTruncatingTail
        } else {
            paragraphStyle.lineBreakMode = .byWordWrapping
        }

        // Handle empty cells: show middot indicator with subtle color, no background
        var displayText: String
        let foregroundColor: NSColor

        if content.isEmpty {
            displayText = "\u{00B7}"  // middot
            foregroundColor = NSColor.quaternaryLabelColor  // Lighter/more subtle
        } else {
            displayText = content
            foregroundColor = NSColor.labelColor
        }

        // Apply 3-line cap for wrapped cells
        // Manual content truncation ensures no cell exceeds 3 lines
        if shouldWrap && !isHeader && !isUnbreakableString(content) && !content.isEmpty {
            let availableTextWidth = (columnWidths[safe: column] ?? 100) - (widthTier == .narrow ? 4.0 : 12.0)
            let font = isHeader ? NSFont.boldSystemFont(ofSize: bodyFontSize) : NSFont.systemFont(ofSize: bodyFontSize)
            let avgCharWidth = ("M" as NSString).size(withAttributes: [.font: font]).width
            let charsPerLine = max(1, Int(availableTextWidth / avgCharWidth))
            let maxChars = charsPerLine * 3

            if content.count > maxChars {
                displayText = String(content.prefix(maxChars)) + "\u{2026}"
            }
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
