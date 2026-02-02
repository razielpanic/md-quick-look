import Foundation
import Markdown

/// Represents a table extracted from markdown with column alignments and cell contents
struct ExtractedTable {
    let columnAlignments: [Table.ColumnAlignment?]
    let headerCells: [String]
    let bodyRows: [[String]]
    let sourceRange: SourceRange?
}

/// MarkupVisitor implementation that extracts tables from parsed markdown documents
struct TableExtractor: MarkupVisitor {
    typealias Result = [ExtractedTable]

    /// Visit all children recursively to find tables
    mutating func defaultVisit(_ markup: Markup) -> [ExtractedTable] {
        var tables: [ExtractedTable] = []
        for child in markup.children {
            tables.append(contentsOf: visit(child))
        }
        return tables
    }

    /// Extract table data from a Table node
    mutating func visitTable(_ table: Table) -> [ExtractedTable] {
        // Extract column alignments from table
        let alignments = table.columnAlignments

        // Extract header cells using plainText
        let headerCells: [String] = table.head.cells.map { cell in
            cell.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Extract body rows from table.body.rows
        var bodyRows: [[String]] = []
        for row in table.body.rows {
            let cellContents: [String] = row.cells.map { cell in
                cell.plainText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            bodyRows.append(cellContents)
        }

        // Create extracted table with all data
        let extractedTable = ExtractedTable(
            columnAlignments: alignments,
            headerCells: headerCells,
            bodyRows: bodyRows,
            sourceRange: table.range
        )

        return [extractedTable]
    }
}
