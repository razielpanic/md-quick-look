import Foundation
import AppKit
import os.log
import Markdown

extension OSLog {
    static let renderer = OSLog(subsystem: "com.rocketpop.MDQuickLook", category: "renderer")
}

/// Custom markdown renderer that transforms PresentationIntent attributes into visual styling
class MarkdownRenderer {

    // MARK: - Font Sizes

    private let headingSizes: [Int: CGFloat] = [
        1: 32.0,  // h1
        2: 26.0,  // h2
        3: 22.0,  // h3
        4: 18.0,  // h4
        5: 16.0,  // h5
        6: 14.0   // h6
    ]

    private let headingSpacing: [Int: CGFloat] = [
        1: 12.0,
        2: 10.0,
        3: 8.0,
        4: 6.0,
        5: 4.0,
        6: 4.0
    ]

    private let bodyFontSize: CGFloat = 14.0

    // MARK: - Public API

    /// Renders markdown string to styled NSAttributedString
    /// - Parameter markdown: The markdown content to render
    /// - Returns: NSAttributedString with visual styling applied
    func render(markdown: String) -> NSAttributedString {
        os_log("MarkdownRenderer: Starting render, input length: %d", log: .renderer, type: .info, markdown.count)

        // Pre-process markdown to handle images (convert to placeholders)
        let preprocessedMarkdown = preprocessBlockquoteSoftBreaks(in: preprocessImages(in: markdown))

        // Check if document contains GFM tables
        if hasGFMTables(in: preprocessedMarkdown) {
            os_log("MarkdownRenderer: Document contains tables, using hybrid rendering", log: .renderer, type: .info)
            return renderWithTables(markdown: preprocessedMarkdown)
        }

        os_log("MarkdownRenderer: No tables found, using standard rendering", log: .renderer, type: .info)

        // Parse markdown using native AttributedString
        guard let attributedString = try? AttributedString(markdown: preprocessedMarkdown) else {
            os_log("MarkdownRenderer: Failed to parse markdown", log: .renderer, type: .error)
            return NSAttributedString(string: markdown)
        }

        os_log("MarkdownRenderer: Parsed successfully, converting to NSAttributedString", log: .renderer, type: .debug)

        // Insert newlines at block boundaries before conversion
        var withNewlines = insertBlockBoundaryNewlines(in: attributedString)

        // Insert newlines within blocks (for list items and blockquote lines)
        withNewlines = ensureIntraBlockNewlines(in: withNewlines)

        // Convert to NSMutableAttributedString
        let nsAttributedString = NSMutableAttributedString(withNewlines)

        // Apply block-level styles by examining PresentationIntent
        applyBlockStyles(from: withNewlines, to: nsAttributedString)

        // Insert list prefixes (bullets and numbers)
        insertListPrefixes(from: withNewlines, to: nsAttributedString)

        // Apply inline styles
        applyInlineStyles(from: withNewlines, to: nsAttributedString)

        // Apply link styling
        applyLinkStyles(to: nsAttributedString)

        // Apply image placeholder styling
        applyImagePlaceholderStyles(to: nsAttributedString)

        // Set base styling
        applyBaseStyles(to: nsAttributedString)

        os_log("MarkdownRenderer: Render complete, output length: %d", log: .renderer, type: .info, nsAttributedString.length)

        return nsAttributedString
    }

    // MARK: - Table Detection and Hybrid Rendering

    /// Checks if the markdown document contains GFM tables
    /// - Parameter markdown: The markdown content to check
    /// - Returns: True if tables are present, false otherwise
    private func hasGFMTables(in markdown: String) -> Bool {
        let document = Document(parsing: markdown, options: [.parseBlockDirectives])
        var extractor = TableExtractor()
        let tables = extractor.visit(document)
        return !tables.isEmpty
    }

    /// Renders markdown containing tables using hybrid approach
    /// - Parameter markdown: The markdown content with tables
    /// - Returns: NSAttributedString with tables rendered via TableRenderer and other content via standard pipeline
    private func renderWithTables(markdown: String) -> NSAttributedString {
        // Parse document to extract tables
        let document = Document(parsing: markdown, options: [.parseBlockDirectives])
        var extractor = TableExtractor()
        let tables = extractor.visit(document)

        guard !tables.isEmpty else {
            os_log("MarkdownRenderer: No tables found in hybrid render, falling back", log: .renderer, type: .error)
            // Fall back to standard rendering
            return render(markdown: markdown)
        }

        os_log("MarkdownRenderer: Found %d tables, building hybrid output", log: .renderer, type: .info, tables.count)

        // Sort tables by source range to process in document order
        let sortedTables = tables.sorted { (table1, table2) -> Bool in
            guard let range1 = table1.sourceRange, let range2 = table2.sourceRange else {
                return false
            }
            return range1.lowerBound.line < range2.lowerBound.line ||
                   (range1.lowerBound.line == range2.lowerBound.line &&
                    range1.lowerBound.column < range2.lowerBound.column)
        }

        // Check if source ranges are available and reliable
        var useSourceRanges = true
        for table in sortedTables {
            if table.sourceRange == nil {
                useSourceRanges = false
                os_log("MarkdownRenderer: Source ranges not available, using placeholder approach", log: .renderer, type: .info)
                break
            }
        }

        if useSourceRanges {
            return renderWithSourceRanges(markdown: markdown, tables: sortedTables)
        } else {
            return renderWithPlaceholders(markdown: markdown, tables: sortedTables)
        }
    }

    /// Renders using source ranges to split document into table and non-table segments
    /// - Parameters:
    ///   - markdown: The markdown content
    ///   - tables: Sorted list of extracted tables with source ranges
    /// - Returns: NSAttributedString with hybrid rendering
    private func renderWithSourceRanges(markdown: String, tables: [ExtractedTable]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.split(separator: "\n", omittingEmptySubsequences: false)
        var currentLine = 1

        let tableRenderer = TableRenderer()

        for table in tables {
            guard let sourceRange = table.sourceRange else { continue }

            let tableStartLine = sourceRange.lowerBound.line

            // Render markdown BEFORE this table (from currentLine to tableStartLine - 1)
            if currentLine < tableStartLine {
                let beforeLines = lines[(currentLine - 1)..<(tableStartLine - 1)]
                let beforeMarkdown = beforeLines.joined(separator: "\n")
                if !beforeMarkdown.isEmpty {
                    let beforeContent = renderNonTableSegment(beforeMarkdown)
                    result.append(beforeContent)

                    // Ensure proper block separation before table
                    ensureBlockSeparation(in: result)
                }
            }

            // Render the table
            let tableContent = tableRenderer.render(table)
            result.append(tableContent)

            // Update current position to after table
            currentLine = sourceRange.upperBound.line + 1
        }

        // Render remaining markdown AFTER last table
        if currentLine <= lines.count {
            let afterLines = lines[(currentLine - 1)..<lines.count]
            let afterMarkdown = afterLines.joined(separator: "\n")
            if !afterMarkdown.isEmpty {
                // Ensure proper block separation after table
                ensureBlockSeparation(in: result)

                let afterContent = renderNonTableSegment(afterMarkdown)
                result.append(afterContent)
            }
        }

        return result
    }

    /// Renders using placeholder substitution when source ranges are unavailable
    /// - Parameters:
    ///   - markdown: The markdown content
    ///   - tables: List of extracted tables
    /// - Returns: NSAttributedString with hybrid rendering
    private func renderWithPlaceholders(markdown: String, tables: [ExtractedTable]) -> NSAttributedString {
        // Replace table markdown with unique placeholders
        var modifiedMarkdown = markdown
        var placeholderMap: [String: ExtractedTable] = [:]

        // Create a regex to match GFM table patterns
        // Pattern: header row, separator row, and body rows
        let tablePattern = """
        (?:^|\\n)(\\|.+\\|)\\n(\\|[-:| ]+\\|)(?:\\n\\|.+\\|)*
        """

        guard let regex = try? NSRegularExpression(pattern: tablePattern, options: .anchorsMatchLines) else {
            os_log("MarkdownRenderer: Failed to create table regex, falling back", log: .renderer, type: .error)
            return NSAttributedString(string: markdown)
        }

        let nsString = modifiedMarkdown as NSString
        let matches = regex.matches(in: modifiedMarkdown, options: [], range: NSRange(location: 0, length: nsString.length))

        // Replace tables with placeholders (in reverse to maintain indices)
        for (index, match) in matches.enumerated().reversed() {
            let placeholder = "TABLEPLACEHOLDER\(index)TABLEPLACEHOLDER"
            if index < tables.count {
                placeholderMap[placeholder] = tables[index]
            }
            modifiedMarkdown = (modifiedMarkdown as NSString).replacingCharacters(in: match.range, with: placeholder) as String
        }

        // Render the modified markdown with placeholders
        let renderedWithPlaceholders = renderNonTableSegment(modifiedMarkdown)

        // Replace placeholders with rendered tables
        let result = NSMutableAttributedString(attributedString: renderedWithPlaceholders)
        let tableRenderer = TableRenderer()

        for (placeholder, table) in placeholderMap {
            let fullRange = NSRange(location: 0, length: result.length)
            let placeholderRange = (result.string as NSString).range(of: placeholder, options: [], range: fullRange)

            if placeholderRange.location != NSNotFound {
                let renderedTable = tableRenderer.render(table)
                result.replaceCharacters(in: placeholderRange, with: renderedTable)
            }
        }

        return result
    }

    /// Ensures proper block separation by adding newlines if needed
    /// - Parameter attributedString: The attributed string to check/modify
    private func ensureBlockSeparation(in attributedString: NSMutableAttributedString) {
        // Check if the string ends with proper block separation (newlines)
        guard attributedString.length > 0 else { return }

        let lastCharacters = attributedString.string.suffix(2)

        // If doesn't end with \n\n, add necessary newlines
        if lastCharacters.hasSuffix("\n\n") {
            // Already has proper separation
            return
        } else if lastCharacters.hasSuffix("\n") {
            // Has one newline, add one more
            attributedString.append(NSAttributedString(string: "\n"))
        } else {
            // No newlines, add two
            attributedString.append(NSAttributedString(string: "\n\n"))
        }
    }

    /// Renders a non-table segment using standard AttributedString pipeline
    /// - Parameter segment: The markdown segment without tables
    /// - Returns: NSAttributedString with standard styling
    private func renderNonTableSegment(_ segment: String) -> NSAttributedString {
        // Trim leading/trailing whitespace
        let trimmed = segment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return NSAttributedString(string: "")
        }

        // Parse with AttributedString
        guard let attributedString = try? AttributedString(markdown: trimmed) else {
            os_log("MarkdownRenderer: Failed to parse non-table segment", log: .renderer, type: .error)
            return NSAttributedString(string: trimmed)
        }

        // Apply same processing as standard render
        var withNewlines = insertBlockBoundaryNewlines(in: attributedString)
        withNewlines = ensureIntraBlockNewlines(in: withNewlines)

        let nsAttributedString = NSMutableAttributedString(withNewlines)

        applyBlockStyles(from: withNewlines, to: nsAttributedString)
        insertListPrefixes(from: withNewlines, to: nsAttributedString)
        applyInlineStyles(from: withNewlines, to: nsAttributedString)
        applyLinkStyles(to: nsAttributedString)
        applyImagePlaceholderStyles(to: nsAttributedString)
        applyBaseStyles(to: nsAttributedString)

        return nsAttributedString
    }

    // MARK: - Block Boundary Processing

    /// Inserts newlines at block boundaries in AttributedString
    /// - Parameter attributedString: The AttributedString to process
    /// - Returns: AttributedString with newlines inserted at block boundaries
    private func insertBlockBoundaryNewlines(in attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        var insertionOffsets: [AttributedString.Index] = []
        var previousBlockComponent: PresentationIntent.Kind?
        var previousBlockIdentity: Int?
        var previousListItemOrdinal: Int?
        var previousRunEndedWithNewline = false
        var isFirstRun = true

        // Collect insertion points in forward pass
        for run in attributedString.runs {
            let runText = String(attributedString[run.range].characters)
            let runEndsWithNewline = runText.hasSuffix("\n")

            guard let intent = run.presentationIntent else {
                // No intent means this is regular paragraph text
                // Insert newline if transitioning from a block element
                if !isFirstRun && previousBlockComponent != nil && !previousRunEndedWithNewline {
                    insertionOffsets.append(run.range.lowerBound)
                }
                previousBlockComponent = .paragraph
                previousBlockIdentity = nil
                previousListItemOrdinal = nil
                previousRunEndedWithNewline = runEndsWithNewline
                isFirstRun = false
                continue
            }

            // Get the top-level block component (first component in the stack)
            let currentBlockComponent = intent.components.first?.kind
            let currentBlockIdentity = intent.components.first?.identity

            // Check if this run is part of a list item and get its ordinal
            var currentListItemOrdinal: Int?
            for component in intent.components {
                if case .listItem(ordinal: let ordinal) = component.kind {
                    currentListItemOrdinal = ordinal
                    break
                }
            }

            // Check if we're transitioning to a new block
            // Insert newline if:
            // 1. Block component type changed, OR
            // 2. Block identity changed (different paragraph/block instance), OR
            // 3. List item ordinal changed (different list item)
            // BUT NOT if we're just moving between runs in the same list item (inline formatting)
            if !isFirstRun && !previousRunEndedWithNewline {
                let differentComponent = currentBlockComponent != previousBlockComponent
                let differentIdentity = currentBlockIdentity != previousBlockIdentity
                let differentListItem = currentListItemOrdinal != previousListItemOrdinal

                // Only insert newline if it's truly a different block
                // If both runs have the same list item ordinal, they're part of the same item
                if currentListItemOrdinal != nil && previousListItemOrdinal != nil {
                    // Both are list items - only insert if different ordinal
                    if differentListItem {
                        insertionOffsets.append(run.range.lowerBound)
                    }
                } else {
                    // At least one is not a list item - use regular block boundary logic
                    if differentComponent || differentIdentity {
                        insertionOffsets.append(run.range.lowerBound)
                    }
                }
            }

            previousBlockComponent = currentBlockComponent
            previousBlockIdentity = currentBlockIdentity
            previousListItemOrdinal = currentListItemOrdinal
            previousRunEndedWithNewline = runEndsWithNewline
            isFirstRun = false
        }

        // Insert newlines in reverse order to maintain indices
        for insertPosition in insertionOffsets.reversed() {
            result.insert(AttributedString("\n"), at: insertPosition)
            os_log("MarkdownRenderer: Inserted newline at block boundary", log: .renderer, type: .debug)
        }

        return result
    }

    /// Ensures blockquotes have proper internal newlines for separation
    /// - Parameter attributedString: The AttributedString to process
    /// - Returns: AttributedString with newlines added within blockquote blocks
    private func ensureIntraBlockNewlines(in attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        var insertionPositions: [AttributedString.Index] = []
        var previousBlockquoteIdentity: Int?

        // Collect positions where newlines need to be inserted
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else { continue }

            // Check if this run contains a blockquote and extract its identity
            var isBlockquote = false
            var currentBlockquoteIdentity: Int?

            for component in intent.components {
                if case .blockQuote = component.kind {
                    isBlockquote = true
                    currentBlockquoteIdentity = component.identity
                    break
                }
            }

            // For blockquotes, only add newline at paragraph boundaries (identity change)
            // Skip for runs within the same blockquote paragraph
            if isBlockquote {
                if previousBlockquoteIdentity != nil && previousBlockquoteIdentity != currentBlockquoteIdentity {
                    let runText = String(attributedString[run.range].characters)
                    if !runText.hasSuffix("\n") {
                        insertionPositions.append(run.range.upperBound)
                        os_log("MarkdownRenderer: Detected blockquote paragraph boundary (identity %d -> %d)",
                               log: .renderer, type: .debug,
                               previousBlockquoteIdentity ?? -1,
                               currentBlockquoteIdentity ?? -1)
                    }
                }
                previousBlockquoteIdentity = currentBlockquoteIdentity
            }
        }

        // Insert newlines in reverse order to maintain indices
        for insertPosition in insertionPositions.reversed() {
            result.insert(AttributedString("\n"), at: insertPosition)
            os_log("MarkdownRenderer: Inserted intra-block newline at paragraph boundary", log: .renderer, type: .debug)
        }

        return result
    }

    // MARK: - List Prefix Insertion

    /// Inserts visual prefixes (bullets or numbers) for list items
    /// - Parameters:
    ///   - attributedString: The source AttributedString with PresentationIntent
    ///   - nsAttributedString: The target NSMutableAttributedString to modify
    private func insertListPrefixes(from attributedString: AttributedString, to nsAttributedString: NSMutableAttributedString) {
        // Collect list item information
        struct ListItemInfo {
            let range: NSRange
            let prefix: String
        }

        var listItems: [ListItemInfo] = []
        var lastProcessedOrdinal: Int?

        // Scan for list items
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else { continue }

            // Check if this run contains a list item
            var isOrderedList = false
            var isUnorderedList = false
            var ordinal: Int?

            for component in intent.components {
                switch component.kind {
                case .orderedList:
                    isOrderedList = true
                case .unorderedList:
                    isUnorderedList = true
                case .listItem(ordinal: let itemOrdinal):
                    ordinal = itemOrdinal
                default:
                    break
                }
            }

            // If we found a list item, determine the prefix
            // Only insert prefix for FIRST run of each list item
            // Subsequent runs with same ordinal are inline formatting within the item
            if let ordinal = ordinal {
                if ordinal != lastProcessedOrdinal {
                    let nsRange = NSRange(run.range, in: attributedString)
                    let prefix: String

                    if isOrderedList {
                        prefix = "\(ordinal). "
                    } else if isUnorderedList {
                        prefix = "• "
                    } else {
                        // Fallback to bullet for ambiguous cases
                        prefix = "• "
                    }

                    listItems.append(ListItemInfo(range: nsRange, prefix: prefix))
                    lastProcessedOrdinal = ordinal

                    os_log("MarkdownRenderer: Found list item (ordinal: %d, ordered: %d, prefix: %{public}s)",
                           log: .renderer, type: .debug, ordinal, isOrderedList ? 1 : 0, prefix)
                }
            }
        }

        // Create list paragraph style (same as in applyListItemAttributes)
        let listParagraphStyle = NSMutableParagraphStyle()
        listParagraphStyle.firstLineHeadIndent = 20
        listParagraphStyle.headIndent = 30
        listParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
        listParagraphStyle.paragraphSpacing = 0  // CRITICAL: zero spacing to prevent gaps
        listParagraphStyle.lineSpacing = 2

        // Insert prefixes in reverse order to maintain indices
        for item in listItems.reversed() {
            let prefixString = NSAttributedString(
                string: item.prefix,
                attributes: [
                    .font: NSFont.systemFont(ofSize: bodyFontSize),
                    .foregroundColor: NSColor.labelColor,
                    .paragraphStyle: listParagraphStyle  // Apply list paragraph style to prevent gaps
                ]
            )

            nsAttributedString.insert(prefixString, at: item.range.location)
            os_log("MarkdownRenderer: Inserted list prefix at location %d", log: .renderer, type: .debug, item.range.location)
        }
    }

    // MARK: - Style Application

    private func applyBaseStyles(to nsAttributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)

        // Set base text color
        nsAttributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        // Create default paragraph style with spacing
        let defaultParagraphStyle = NSMutableParagraphStyle()
        defaultParagraphStyle.paragraphSpacing = 8  // Add spacing between paragraphs

        // Ensure all text has at least the base font and paragraph spacing
        nsAttributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if value == nil {
                nsAttributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: bodyFontSize), range: range)
            }
        }

        // Set default paragraph spacing for all text (can be overridden by specific elements)
        nsAttributedString.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, _ in
            if value == nil {
                nsAttributedString.addAttribute(.paragraphStyle, value: defaultParagraphStyle, range: range)
            }
        }
    }

    private func applyBlockStyles(from attributedString: AttributedString, to nsAttributedString: NSMutableAttributedString) {
        // Iterate through runs to find block-level elements via PresentationIntent
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else { continue }

            // Convert AttributedString range to NSRange
            let nsRange = NSRange(run.range, in: attributedString)

            // Check components for different block types
            for component in intent.components {
                switch component.kind {
                case .header(let level):
                    applyHeadingAttributes(to: nsAttributedString, range: nsRange, level: level)
                    os_log("MarkdownRenderer: Applied h%d style", log: .renderer, type: .debug, level)

                case .codeBlock(languageHint: _):
                    applyCodeBlockAttributes(to: nsAttributedString, range: nsRange)
                    os_log("MarkdownRenderer: Applied code block style", log: .renderer, type: .debug)

                case .listItem(ordinal: let ordinal):
                    applyListItemAttributes(to: nsAttributedString, range: nsRange, ordinal: ordinal)
                    os_log("MarkdownRenderer: Applied list item style (ordinal: %d)", log: .renderer, type: .debug, ordinal)

                case .blockQuote:
                    applyBlockQuoteAttributes(to: nsAttributedString, range: nsRange)
                    os_log("MarkdownRenderer: Applied blockquote style", log: .renderer, type: .debug)

                default:
                    break
                }
            }
        }
    }

    private func applyInlineStyles(from attributedString: AttributedString, to nsAttributedString: NSMutableAttributedString) {
        // Iterate through runs to find inline formatting
        for run in attributedString.runs {
            guard let inlineIntent = run.inlinePresentationIntent else { continue }

            let nsRange = NSRange(run.range, in: attributedString)

            // Check for inline code
            if inlineIntent.contains(.code) {
                applyInlineCodeAttributes(to: nsAttributedString, range: nsRange)
                os_log("MarkdownRenderer: Applied inline code style", log: .renderer, type: .debug)
            }

            // Check for strikethrough
            if inlineIntent.contains(.strikethrough) {
                nsAttributedString.addAttribute(.strikethroughStyle,
                                               value: NSUnderlineStyle.single.rawValue,
                                               range: nsRange)
                os_log("MarkdownRenderer: Applied strikethrough style", log: .renderer, type: .debug)
            }
        }
    }

    private func applyHeadingAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange, level: Int) {
        guard let fontSize = headingSizes[level],
              let spacing = headingSpacing[level] else {
            os_log("MarkdownRenderer: Unknown heading level %d", log: .renderer, type: .error, level)
            return
        }

        // Apply bold font at heading size
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        nsAttributedString.addAttribute(.font, value: font, range: range)

        // Create paragraph style with spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = spacing
        paragraphStyle.paragraphSpacing = spacing

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyCodeBlockAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Apply monospace font (SF Mono)
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        nsAttributedString.addAttribute(.font, value: font, range: range)

        // Add marker for LayoutManager to draw uniform background
        nsAttributedString.addAttribute(.codeBlockMarker, value: true, range: range)

        // Create paragraph style with indentation and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 10
        paragraphStyle.firstLineHeadIndent = 10
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.paragraphSpacingBefore = 8

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyInlineCodeAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Apply monospace font (SF Mono)
        let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        nsAttributedString.addAttribute(.font, value: font, range: range)

        // Apply same background as code blocks for consistent styling
        nsAttributedString.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: range)
    }

    private func applyListItemAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange, ordinal: Int) {
        // Create paragraph style with indentation for lists
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 20  // Indent for bullet/number
        paragraphStyle.headIndent = 30           // Indent for wrapped text
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
        // Use minimal spacing for list items - newlines provide separation
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.lineSpacing = 2  // Small spacing for wrapped lines within item

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyBlockQuoteAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Background is now drawn by LayoutManager for uniform appearance

        // Create paragraph style with indentation
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 20
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.paragraphSpacingBefore = 8

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

        // Add blockquote marker for MarkdownLayoutManager to draw border and background
        nsAttributedString.addAttribute(.blockquoteMarker, value: true, range: range)
    }

    // MARK: - Image Preprocessing

    private func preprocessImages(in markdown: String) -> String {
        // Replace ![alt](url) with marker that survives AttributedString parsing
        // Use alphanumeric-only markers to avoid markdown interpretation
        let pattern = "!\\[([^\\]]*)\\]\\(([^)]+)\\)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return markdown }

        let nsString = markdown as NSString
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))

        var result = markdown
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }
            let urlRange = match.range(at: 2)
            let url = nsString.substring(with: urlRange)
            let filename = (url as NSString).lastPathComponent

            // Use marker without special markdown characters
            let placeholder = "IMAGEPLACEHOLDERSTART\(filename)IMAGEPLACEHOLDEREND"
            result = (result as NSString).replacingCharacters(in: match.range, with: placeholder) as String
        }

        return result
    }

    // MARK: - Blockquote Soft Break Preprocessing

    private func preprocessBlockquoteSoftBreaks(in markdown: String) -> String {
        // Convert soft breaks (single newlines) to hard breaks (double spaces before newline) within blockquotes
        // This preserves line separation in multi-line blockquotes since AttributedString(markdown:)
        // converts soft breaks to spaces in CommonMark-compliant fashion
        // Pattern: (>[^\n]*)\n(>) - captures blockquote line content followed by newline and next blockquote marker
        // Replacement: $1  \n$2 - adds two trailing spaces before newline (hard break in CommonMark)
        let pattern = "(>[^\\n]*)\\n(>)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return markdown }

        let nsString = markdown as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        // Replace all occurrences with hard break version
        let result = regex.stringByReplacingMatches(
            in: markdown,
            options: [],
            range: fullRange,
            withTemplate: "$1  \n$2"
        )

        os_log("MarkdownRenderer: Preprocessed blockquote soft breaks", log: .renderer, type: .debug)
        return result
    }

    // MARK: - Link Styling

    private func applyLinkStyles(to nsAttributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)

        // Find all runs with .link attribute (automatically added by AttributedString for markdown links)
        nsAttributedString.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            guard value != nil else { return }

            // Style as blue and underlined, but don't make clickable
            nsAttributedString.addAttribute(.foregroundColor, value: NSColor.linkColor, range: range)
            nsAttributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)

            os_log("MarkdownRenderer: Applied link style", log: .renderer, type: .debug)
        }
    }

    // MARK: - Image Placeholder Styling

    private func applyImagePlaceholderStyles(to nsAttributedString: NSMutableAttributedString) {
        // Find IMAGEPLACEHOLDERSTART...IMAGEPLACEHOLDEREND patterns and style them
        let pattern = "IMAGEPLACEHOLDERSTART(.+?)IMAGEPLACEHOLDEREND"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let fullRange = NSRange(location: 0, length: nsAttributedString.length)
        let matches = regex.matches(in: nsAttributedString.string, options: [], range: fullRange)

        for match in matches.reversed() {
            guard match.range.location != NSNotFound,
                  match.numberOfRanges >= 2 else { continue }

            // Extract filename from capture group
            let filenameRange = match.range(at: 1)
            let filename = (nsAttributedString.string as NSString).substring(with: filenameRange)

            // Create SF Symbol attachment for photo icon
            let attachment = NSTextAttachment()
            if let symbolImage = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image") {
                let config = NSImage.SymbolConfiguration(pointSize: bodyFontSize, weight: .regular)
                attachment.image = symbolImage.withSymbolConfiguration(config)
            }

            // Create styled replacement: icon + space + [Image: filename]
            let styledString = NSMutableAttributedString()

            // Add icon
            let iconString = NSAttributedString(attachment: attachment)
            styledString.append(iconString)
            styledString.append(NSAttributedString(string: " "))

            // Add placeholder text in gray with [Image: filename] format
            let placeholderText = "[Image: \(filename)]"
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: bodyFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            styledString.append(NSAttributedString(string: placeholderText, attributes: textAttributes))

            // Replace the marker in the attributed string
            nsAttributedString.replaceCharacters(in: match.range, with: styledString)

            os_log("MarkdownRenderer: Replaced image placeholder for %{public}s", log: .renderer, type: .debug, filename)
        }
    }
}
