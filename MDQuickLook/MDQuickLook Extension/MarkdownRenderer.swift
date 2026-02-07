import Foundation
import AppKit
import os.log
import Markdown

extension OSLog {
    static let renderer = OSLog(subsystem: "com.rocketpop.MDQuickLook", category: "renderer")
}

/// Width tier for adaptive rendering
enum WidthTier {
    case narrow   // Finder preview pane (~260px)
    case normal   // Quick Look popup, fullscreen
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

    // MARK: - Width Tier Awareness

    private var widthTier: WidthTier = .normal
    private var availableWidth: CGFloat = 640

    private var currentHeadingSizes: [Int: CGFloat] {
        switch widthTier {
        case .narrow:
            return [1: 20.0, 2: 17.0, 3: 15.0, 4: 14.0, 5: 13.0, 6: 12.0]
        case .normal:
            return [1: 32.0, 2: 26.0, 3: 22.0, 4: 18.0, 5: 16.0, 6: 14.0]
        }
    }

    private var currentHeadingSpacing: [Int: CGFloat] {
        switch widthTier {
        case .narrow:
            return [1: 6.0, 2: 5.0, 3: 4.0, 4: 3.0, 5: 2.0, 6: 2.0]
        case .normal:
            return [1: 12.0, 2: 10.0, 3: 8.0, 4: 6.0, 5: 4.0, 6: 4.0]
        }
    }

    private var currentBodyFontSize: CGFloat {
        widthTier == .narrow ? 12.0 : 14.0
    }

    private var currentCodeFontSize: CGFloat {
        widthTier == .narrow ? 11.0 : 13.0
    }

    // MARK: - Public API

    /// Renders markdown string to styled NSAttributedString
    /// - Parameters:
    ///   - markdown: The markdown content to render
    ///   - widthTier: The width tier for adaptive rendering (default: .normal)
    ///   - availableWidth: The available container width in points (default: 640)
    /// - Returns: NSAttributedString with visual styling applied
    func render(markdown: String, widthTier: WidthTier = .normal, availableWidth: CGFloat = 640) -> NSAttributedString {
        self.widthTier = widthTier
        self.availableWidth = availableWidth
        os_log("MarkdownRenderer: Starting render, input length: %d, availableWidth: %.1f", log: .renderer, type: .info, markdown.count, availableWidth)

        // Extract YAML front matter FIRST (before any other preprocessing)
        let (frontMatter, bodyMarkdown) = extractYAMLFrontMatter(from: markdown)

        // Pre-process body markdown to handle images and task lists (convert to placeholders)
        let preprocessedMarkdown = preprocessTaskLists(in: preprocessBlockquoteSoftBreaks(in: preprocessImages(in: bodyMarkdown)))

        // Check if document contains GFM tables
        if hasGFMTables(in: preprocessedMarkdown) {
            os_log("MarkdownRenderer: Document contains tables, using hybrid rendering", log: .renderer, type: .info)
            let bodyContent = renderWithTables(markdown: preprocessedMarkdown)

            // Prepend front matter if present
            if !frontMatter.isEmpty {
                let result = NSMutableAttributedString()
                result.append(renderFrontMatter(frontMatter))
                result.append(bodyContent)
                return result
            }

            return bodyContent
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

        // Apply inline styles BEFORE list prefixes (insertListPrefixes shifts character
        // positions, which would invalidate the ranges from the original AttributedString)
        applyInlineStyles(from: withNewlines, to: nsAttributedString)

        // Insert list prefixes (bullets and numbers) — must come after applyInlineStyles
        // because it inserts characters, and NSMutableAttributedString shifts existing
        // attributes correctly when characters are inserted
        insertListPrefixes(from: withNewlines, to: nsAttributedString)

        // Apply link styling
        applyLinkStyles(to: nsAttributedString)

        // Apply image placeholder styling
        applyImagePlaceholderStyles(to: nsAttributedString)

        // Set base styling
        applyBaseStyles(to: nsAttributedString)

        // Apply task checkbox styles (must be after base styles for font size)
        applyTaskCheckboxStyles(to: nsAttributedString)

        os_log("MarkdownRenderer: Render complete, output length: %d", log: .renderer, type: .info, nsAttributedString.length)

        // Prepend front matter if present
        if !frontMatter.isEmpty {
            let result = NSMutableAttributedString()
            result.append(renderFrontMatter(frontMatter))
            result.append(nsAttributedString)
            return result
        }

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

        let tableRenderer = TableRenderer(widthTier: widthTier, availableWidth: availableWidth)

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
        let tableRenderer = TableRenderer(widthTier: widthTier, availableWidth: availableWidth)

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

        // Preprocess task lists in the segment
        let preprocessed = preprocessTaskLists(in: trimmed)

        // Parse with AttributedString
        guard let attributedString = try? AttributedString(markdown: preprocessed) else {
            os_log("MarkdownRenderer: Failed to parse non-table segment", log: .renderer, type: .error)
            return NSAttributedString(string: trimmed)
        }

        // Apply same processing as standard render
        var withNewlines = insertBlockBoundaryNewlines(in: attributedString)
        withNewlines = ensureIntraBlockNewlines(in: withNewlines)

        let nsAttributedString = NSMutableAttributedString(withNewlines)

        applyBlockStyles(from: withNewlines, to: nsAttributedString)
        applyInlineStyles(from: withNewlines, to: nsAttributedString)
        insertListPrefixes(from: withNewlines, to: nsAttributedString)
        applyLinkStyles(to: nsAttributedString)
        applyImagePlaceholderStyles(to: nsAttributedString)
        applyBaseStyles(to: nsAttributedString)
        applyTaskCheckboxStyles(to: nsAttributedString)

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
                    // Both are list items - insert if different ordinal OR different block identity
                    // (different identity catches nesting transitions where ordinals can match)
                    if differentListItem || differentIdentity {
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
        var lastProcessedKey: String?

        // Scan for list items
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else { continue }

            // Check if this run contains a list item
            // Only capture the FIRST (innermost) ordinal and list identity
            // Components are ordered innermost-to-outermost, so outer list
            // values would overwrite inner ones if we don't guard
            var isOrderedList = false
            var isUnorderedList = false
            var ordinal: Int?
            var listIdentity: Int = 0
            var foundList = false

            for component in intent.components {
                switch component.kind {
                case .orderedList:
                    if !foundList {
                        isOrderedList = true
                        listIdentity = component.identity
                        foundList = true
                    }
                case .unorderedList:
                    if !foundList {
                        isUnorderedList = true
                        listIdentity = component.identity
                        foundList = true
                    }
                case .listItem(ordinal: let itemOrdinal):
                    if ordinal == nil {
                        ordinal = itemOrdinal
                    }
                default:
                    break
                }
            }

            // If we found a list item, determine the prefix
            // Only insert prefix for FIRST run of each list item
            // Use list identity + ordinal as key to distinguish nested lists
            // (nested items can share ordinals with parent items)
            if let ordinal = ordinal {
                let key = "\(listIdentity)-\(ordinal)"
                if key != lastProcessedKey {
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
                    lastProcessedKey = key

                    os_log("MarkdownRenderer: Found list item (ordinal: %d, ordered: %d, prefix: %{public}s)",
                           log: .renderer, type: .debug, ordinal, isOrderedList ? 1 : 0, prefix)
                }
            }
        }

        // Create list paragraph style (same as in applyListItemAttributes, tier-aware)
        let listParagraphStyle = NSMutableParagraphStyle()
        if widthTier == .narrow {
            listParagraphStyle.firstLineHeadIndent = 10
            listParagraphStyle.headIndent = 18
            listParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 18)]
            listParagraphStyle.paragraphSpacing = 0  // CRITICAL: zero spacing to prevent gaps
            listParagraphStyle.lineSpacing = 1
        } else {
            listParagraphStyle.firstLineHeadIndent = 20
            listParagraphStyle.headIndent = 30
            listParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
            listParagraphStyle.paragraphSpacing = 0  // CRITICAL: zero spacing to prevent gaps
            listParagraphStyle.lineSpacing = 2
        }

        // Insert prefixes in reverse order to maintain indices
        for item in listItems.reversed() {
            // Check if this is a task list item (text starts with TASK placeholder)
            let textAtLocation = (nsAttributedString.string as NSString).substring(from: item.range.location)
            if textAtLocation.hasPrefix("TASKUNCHECKEDPLACEHOLDER") || textAtLocation.hasPrefix("TASKCHECKEDPLACEHOLDER") {
                // Skip inserting bullet prefix for task items - the placeholder IS the prefix
                os_log("MarkdownRenderer: Skipped list prefix for task item at location %d", log: .renderer, type: .debug, item.range.location)
                continue
            }

            let prefixString = NSAttributedString(
                string: item.prefix,
                attributes: [
                    .font: NSFont.systemFont(ofSize: currentBodyFontSize),
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

        // Create default paragraph style with spacing (tier-aware)
        let defaultParagraphStyle = NSMutableParagraphStyle()
        defaultParagraphStyle.paragraphSpacing = widthTier == .narrow ? 4 : 8

        // Ensure all text has at least the base font and paragraph spacing
        nsAttributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if value == nil {
                nsAttributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: currentBodyFontSize), range: range)
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
        guard let fontSize = currentHeadingSizes[level],
              let spacing = currentHeadingSpacing[level] else {
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
        // Apply monospace font (SF Mono) with tier-aware sizing
        let font = NSFont.monospacedSystemFont(ofSize: currentCodeFontSize, weight: .regular)
        nsAttributedString.addAttribute(.font, value: font, range: range)

        // Add marker for LayoutManager to draw uniform background
        nsAttributedString.addAttribute(.codeBlockMarker, value: true, range: range)

        // Create paragraph style with indentation and spacing (tier-aware)
        let paragraphStyle = NSMutableParagraphStyle()
        if widthTier == .narrow {
            paragraphStyle.headIndent = 6
            paragraphStyle.firstLineHeadIndent = 6
            paragraphStyle.paragraphSpacing = 4
            paragraphStyle.paragraphSpacingBefore = 4
        } else {
            paragraphStyle.headIndent = 10
            paragraphStyle.firstLineHeadIndent = 10
            paragraphStyle.paragraphSpacing = 8
            paragraphStyle.paragraphSpacingBefore = 8
        }

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyInlineCodeAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Apply monospace font (SF Mono) with tier-aware sizing
        let font = NSFont.monospacedSystemFont(ofSize: currentCodeFontSize, weight: .regular)
        nsAttributedString.addAttribute(.font, value: font, range: range)

        // Apply same background as code blocks for consistent styling
        nsAttributedString.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: range)
    }

    private func applyListItemAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange, ordinal: Int) {
        // Create paragraph style with indentation for lists (tier-aware)
        let paragraphStyle = NSMutableParagraphStyle()
        if widthTier == .narrow {
            paragraphStyle.firstLineHeadIndent = 10  // Indent for bullet/number
            paragraphStyle.headIndent = 18           // Indent for wrapped text
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 18)]
            paragraphStyle.paragraphSpacing = 0
            paragraphStyle.lineSpacing = 1  // Small spacing for wrapped lines within item
        } else {
            paragraphStyle.firstLineHeadIndent = 20  // Indent for bullet/number
            paragraphStyle.headIndent = 30           // Indent for wrapped text
            paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
            paragraphStyle.paragraphSpacing = 0
            paragraphStyle.lineSpacing = 2  // Small spacing for wrapped lines within item
        }

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyBlockQuoteAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Background is now drawn by LayoutManager for uniform appearance

        // Create paragraph style with indentation (tier-aware)
        let paragraphStyle = NSMutableParagraphStyle()
        if widthTier == .narrow {
            paragraphStyle.headIndent = 12
            paragraphStyle.firstLineHeadIndent = 12
            paragraphStyle.paragraphSpacing = 4
            paragraphStyle.paragraphSpacingBefore = 4
        } else {
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 20
            paragraphStyle.paragraphSpacing = 8
            paragraphStyle.paragraphSpacingBefore = 8
        }

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

    // MARK: - YAML Front Matter

    /// Extracts YAML front matter from markdown content
    /// - Parameter markdown: The markdown content to process
    /// - Returns: Tuple of (parsed key-value pairs, body markdown without front matter)
    private func extractYAMLFrontMatter(from markdown: String) -> ([(key: String, value: String)], String) {
        os_log("MarkdownRenderer: Extracting YAML front matter", log: .renderer, type: .debug)

        // Normalize line endings (Windows CRLF -> Unix LF)
        let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")

        // Pattern: ^---\n(.+?)\n---\n(.*)
        // Matches front matter between --- delimiters at start of document
        let pattern = "^---\\n(.+?)\\n---\\n(.*)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            os_log("MarkdownRenderer: Failed to create front matter regex", log: .renderer, type: .error)
            return ([], markdown)
        }

        let nsString = normalized as NSString
        let fullRange = NSRange(location: 0, length: nsString.length)

        guard let match = regex.firstMatch(in: normalized, options: [], range: fullRange),
              match.numberOfRanges >= 3 else {
            os_log("MarkdownRenderer: No front matter found", log: .renderer, type: .debug)
            return ([], markdown)
        }

        // Extract the YAML content (between delimiters)
        let yamlRange = match.range(at: 1)
        let yamlContent = nsString.substring(with: yamlRange)

        // Extract the body markdown (after front matter)
        let bodyRange = match.range(at: 2)
        let bodyMarkdown = nsString.substring(with: bodyRange)

        os_log("MarkdownRenderer: Found front matter block, parsing key-value pairs", log: .renderer, type: .info)

        // Parse key-value pairs
        let keyValues = parseYAMLKeyValues(yamlContent)

        return (keyValues, bodyMarkdown)
    }

    /// Parses YAML key-value pairs from front matter content
    /// - Parameter yaml: The raw YAML content between delimiters
    /// - Returns: Array of (key, value) tuples preserving original order
    private func parseYAMLKeyValues(_ yaml: String) -> [(key: String, value: String)] {
        var result: [(key: String, value: String)] = []

        let lines = yaml.components(separatedBy: "\n")

        for line in lines {
            // Skip empty lines and comments
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }

            // Split on first colon only (values may contain colons)
            guard let colonIndex = line.firstIndex(of: ":") else {
                continue
            }

            let key = String(line[..<colonIndex]).trimmingCharacters(in: .whitespaces)
            var value = String(line[line.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

            // Handle list values: [item1, item2, item3]
            if value.hasPrefix("[") && value.hasSuffix("]") {
                // Remove brackets
                value = String(value.dropFirst().dropLast())

                // Split by comma, trim each item, strip quotes
                let items = value.components(separatedBy: ",").map { item -> String in
                    var trimmed = item.trimmingCharacters(in: .whitespaces)
                    // Strip surrounding quotes (both " and ')
                    if (trimmed.hasPrefix("\"") && trimmed.hasSuffix("\"")) ||
                       (trimmed.hasPrefix("'") && trimmed.hasSuffix("'")) {
                        trimmed = String(trimmed.dropFirst().dropLast())
                    }
                    return trimmed
                }

                // Rejoin with comma-space
                value = items.joined(separator: ", ")
            } else {
                // Strip surrounding quotes from regular values
                if (value.hasPrefix("\"") && value.hasSuffix("\"")) ||
                   (value.hasPrefix("'") && value.hasSuffix("'")) {
                    value = String(value.dropFirst().dropLast())
                }
            }

            result.append((key: key, value: value))
        }

        os_log("MarkdownRenderer: Parsed %d key-value pairs from front matter", log: .renderer, type: .info, result.count)

        return result
    }

    /// Renders YAML front matter as a styled attributed string
    /// - Parameter frontMatter: Array of (key, value) tuples
    /// - Returns: NSAttributedString with styled front matter section
    private func renderFrontMatter(_ frontMatter: [(key: String, value: String)]) -> NSAttributedString {
        guard !frontMatter.isEmpty else {
            return NSAttributedString()
        }

        let result = NSMutableAttributedString()

        // Width tier-aware configuration
        let fontSize: CGFloat = widthTier == .narrow ? 10 : 12
        let maxDisplayedFields = widthTier == .narrow ? 5 : Int.max
        let spacerHeight: CGFloat = widthTier == .narrow ? 4 : 8

        // Add top spacer inside the front matter content for visual padding
        let spacerStyle = NSMutableParagraphStyle()
        spacerStyle.paragraphSpacing = 0
        spacerStyle.paragraphSpacingBefore = 0
        spacerStyle.minimumLineHeight = spacerHeight
        spacerStyle.maximumLineHeight = spacerHeight
        result.append(NSAttributedString(string: "\n", attributes: [
            .font: NSFont.systemFont(ofSize: 1),
            .paragraphStyle: spacerStyle
        ]))

        // Key styling: bold, tier-aware size, primary label color
        let keyFont = NSFont.boldSystemFont(ofSize: fontSize)
        let keyAttributes: [NSAttributedString.Key: Any] = [
            .font: keyFont,
            .foregroundColor: NSColor.labelColor
        ]

        // Value styling: regular, tier-aware size, secondary label color
        let valueFont = NSFont.systemFont(ofSize: fontSize)
        let valueAttributes: [NSAttributedString.Key: Any] = [
            .font: valueFont,
            .foregroundColor: NSColor.secondaryLabelColor
        ]

        // Paragraph style with indentation and tab stops (tier-aware)
        let paragraphStyle = NSMutableParagraphStyle()
        if widthTier == .narrow {
            paragraphStyle.headIndent = 8
            paragraphStyle.firstLineHeadIndent = 8
            paragraphStyle.tailIndent = -8
            paragraphStyle.paragraphSpacing = 2
            paragraphStyle.paragraphSpacingBefore = 2
        } else {
            paragraphStyle.headIndent = 20
            paragraphStyle.firstLineHeadIndent = 20
            paragraphStyle.tailIndent = -20
            paragraphStyle.paragraphSpacing = 4
            paragraphStyle.paragraphSpacingBefore = 4
        }
        paragraphStyle.lineBreakMode = .byTruncatingTail

        // Determine displayed fields (cap at maxDisplayedFields)
        let displayedFields = Array(frontMatter.prefix(maxDisplayedFields))
        let hiddenCount = frontMatter.count - displayedFields.count

        // Multi-column layout for 4+ pairs (but always single-column in narrow mode)
        let useMultiColumn = displayedFields.count >= 4 && widthTier != .narrow

        if useMultiColumn {
            // Two-column layout with tab stops:
            // Tightened to maximize value space — widest key ~85pt at 12pt bold
            paragraphStyle.tabStops = [
                NSTextTab(textAlignment: .left, location: 95),   // First value column
                NSTextTab(textAlignment: .left, location: 235),  // Second key column
                NSTextTab(textAlignment: .left, location: 330)   // Second value column
            ]

            // Process pairs two at a time
            for i in stride(from: 0, to: displayedFields.count, by: 2) {
                let pair1 = displayedFields[i]

                // First column: key \t value
                let keyString1 = NSAttributedString(string: pair1.key, attributes: keyAttributes)
                result.append(keyString1)
                result.append(NSAttributedString(string: "\t"))  // Tab to value column
                let valueString1 = NSAttributedString(string: pair1.value, attributes: valueAttributes)
                result.append(valueString1)

                // Second column: \t key \t value (if exists)
                if i + 1 < displayedFields.count {
                    let pair2 = displayedFields[i + 1]
                    result.append(NSAttributedString(string: "\t"))  // Tab to second key column
                    let keyString2 = NSAttributedString(string: pair2.key, attributes: keyAttributes)
                    result.append(keyString2)
                    result.append(NSAttributedString(string: "\t"))  // Tab to second value column
                    let valueString2 = NSAttributedString(string: pair2.value, attributes: valueAttributes)
                    result.append(valueString2)
                }

                result.append(NSAttributedString(string: "\n"))
            }
        } else {
            // Single-column layout (tier-aware tab stop)
            let tabLocation: CGFloat = widthTier == .narrow ? 80 : 95
            paragraphStyle.tabStops = [
                NSTextTab(textAlignment: .left, location: tabLocation)  // Value column
            ]

            for pair in displayedFields {
                let keyString = NSAttributedString(string: pair.key, attributes: keyAttributes)
                result.append(keyString)
                result.append(NSAttributedString(string: "\t"))  // Tab to value column
                let valueString = NSAttributedString(string: pair.value, attributes: valueAttributes)
                result.append(valueString)
                result.append(NSAttributedString(string: "\n"))
            }
        }

        // Add "+N more" indicator if fields were hidden
        if hiddenCount > 0 {
            let moreText = NSAttributedString(string: "+\(hiddenCount) more\n", attributes: [
                .font: NSFont.systemFont(ofSize: fontSize),
                .foregroundColor: NSColor.tertiaryLabelColor
            ])
            result.append(moreText)
        }

        // Apply paragraph style to entire front matter section
        let fullRange = NSRange(location: 0, length: result.length)
        result.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

        // Apply front matter marker for background drawing (including spacer)
        result.addAttribute(.frontMatterMarker, value: true, range: fullRange)

        // Add separator newline after front matter
        result.append(NSAttributedString(string: "\n"))

        os_log("MarkdownRenderer: Rendered front matter section with %d pairs", log: .renderer, type: .info, frontMatter.count)

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

    // MARK: - Task List Preprocessing

    /// Preprocesses task list markers by converting them to placeholders
    /// - Parameter markdown: The markdown content to process
    /// - Returns: Markdown with task list markers replaced by placeholders
    private func preprocessTaskLists(in markdown: String) -> String {
        // Split into lines to track code fence state
        let lines = markdown.components(separatedBy: "\n")
        var result: [String] = []
        var inCodeFence = false

        for line in lines {
            // Check for code fence delimiters
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            if trimmedLine.hasPrefix("```") || trimmedLine.hasPrefix("~~~") {
                inCodeFence.toggle()
                result.append(line)
                continue
            }

            // Skip replacement if inside code fence
            if inCodeFence {
                result.append(line)
                continue
            }

            // Replace task list markers with placeholders
            var processedLine = line

            // Pattern for unchecked: ^(\s*)-\s*\[\s*\]\s+
            // Matches: optional whitespace, dash, optional space, open bracket, optional space, close bracket, one or more spaces
            let uncheckedPattern = "^(\\s*)-\\s*\\[\\s*\\]\\s+"
            if let uncheckedRegex = try? NSRegularExpression(pattern: uncheckedPattern) {
                let nsString = processedLine as NSString
                let range = NSRange(location: 0, length: nsString.length)
                processedLine = uncheckedRegex.stringByReplacingMatches(
                    in: processedLine,
                    options: [],
                    range: range,
                    withTemplate: "$1- TASKUNCHECKEDPLACEHOLDER "
                )
            }

            // Pattern for checked: ^(\s*)-\s*\[[xX]\]\s+
            // Matches: optional whitespace, dash, optional space, open bracket, x or X, close bracket, one or more spaces
            let checkedPattern = "^(\\s*)-\\s*\\[[xX]\\]\\s+"
            if let checkedRegex = try? NSRegularExpression(pattern: checkedPattern) {
                let nsString = processedLine as NSString
                let range = NSRange(location: 0, length: nsString.length)
                processedLine = checkedRegex.stringByReplacingMatches(
                    in: processedLine,
                    options: [],
                    range: range,
                    withTemplate: "$1- TASKCHECKEDPLACEHOLDER "
                )
            }

            result.append(processedLine)
        }

        let preprocessed = result.joined(separator: "\n")
        os_log("MarkdownRenderer: Preprocessed task lists", log: .renderer, type: .debug)
        return preprocessed
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

            // Create SF Symbol attachment for photo icon (tier-aware size)
            let attachment = NSTextAttachment()
            if let symbolImage = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image") {
                let config = NSImage.SymbolConfiguration(pointSize: currentBodyFontSize, weight: .regular)
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
                .font: NSFont.systemFont(ofSize: currentBodyFontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
            styledString.append(NSAttributedString(string: placeholderText, attributes: textAttributes))

            // Replace the marker in the attributed string
            nsAttributedString.replaceCharacters(in: match.range, with: styledString)

            os_log("MarkdownRenderer: Replaced image placeholder for %{public}s", log: .renderer, type: .debug, filename)
        }
    }

    // MARK: - Task List Checkbox Styling

    /// Creates an NSTextAttachment with SF Symbol checkbox icon
    /// - Parameters:
    ///   - checked: True for checked state, false for unchecked
    ///   - fontSize: Font size to match checkbox size
    /// - Returns: NSTextAttachment with configured SF Symbol
    private func checkboxAttachment(checked: Bool, fontSize: CGFloat) -> NSTextAttachment {
        let attachment = NSTextAttachment()

        // Choose SF Symbol based on checkbox state
        let symbolName = checked ? "checkmark.circle.fill" : "circle"
        let accessibilityDescription = checked ? "Completed task" : "Incomplete task"

        // Configure symbol with system accent color and font-matched size
        let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
            .applying(.init(hierarchicalColor: .controlAccentColor))

        if let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: accessibilityDescription) {
            attachment.image = symbolImage.withSymbolConfiguration(config)
        }

        // Baseline alignment: negative y offset moves symbol down to sit on baseline
        let yOffset = fontSize * 0.15
        attachment.bounds = CGRect(x: 0, y: -yOffset, width: fontSize, height: fontSize)

        return attachment
    }

    /// Applies task checkbox styling by replacing placeholders with SF Symbol attachments
    /// - Parameter nsAttributedString: The NSMutableAttributedString to modify
    private func applyTaskCheckboxStyles(to nsAttributedString: NSMutableAttributedString) {
        // Find TASKUNCHECKEDPLACEHOLDER and TASKCHECKEDPLACEHOLDER patterns
        let pattern = "TASK(UN)?CHECKEDPLACEHOLDER"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }

        let fullRange = NSRange(location: 0, length: nsAttributedString.length)
        let matches = regex.matches(in: nsAttributedString.string, options: [], range: fullRange)

        // Process in reverse order to maintain indices
        for match in matches.reversed() {
            guard match.range.location != NSNotFound else { continue }

            // Determine if checked or unchecked
            let matchText = (nsAttributedString.string as NSString).substring(with: match.range)
            let isChecked = matchText == "TASKCHECKEDPLACEHOLDER"

            // Create checkbox attachment
            let attachment = checkboxAttachment(checked: isChecked, fontSize: currentBodyFontSize)
            let checkboxString = NSMutableAttributedString(attachment: attachment)

            // Build adjusted paragraph style for task items
            // Wider headIndent accounts for checkbox width + gap so wrapped text aligns with text start
            let gap: CGFloat = widthTier == .narrow ? 2 : 3
            let adjustedParagraphStyle = NSMutableParagraphStyle()
            if widthTier == .narrow {
                adjustedParagraphStyle.firstLineHeadIndent = 10
                adjustedParagraphStyle.headIndent = 10 + currentBodyFontSize + gap
                adjustedParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 10 + currentBodyFontSize + gap)]
                adjustedParagraphStyle.paragraphSpacing = 0
                adjustedParagraphStyle.lineSpacing = 1
            } else {
                adjustedParagraphStyle.firstLineHeadIndent = 20
                adjustedParagraphStyle.headIndent = 20 + currentBodyFontSize + gap
                adjustedParagraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 20 + currentBodyFontSize + gap)]
                adjustedParagraphStyle.paragraphSpacing = 0
                adjustedParagraphStyle.lineSpacing = 2
            }

            // Add gap as kern on the attachment character itself (no space character —
            // a space has its own width that would make headIndent calculation inaccurate)
            checkboxString.addAttribute(.kern, value: gap,
                                        range: NSRange(location: 0, length: checkboxString.length))

            // Set paragraph style on the checkbox string so the first character
            // of the paragraph carries the correct headIndent (NSAttributedString uses
            // the paragraph style of the first character for the whole paragraph)
            checkboxString.addAttribute(.paragraphStyle, value: adjustedParagraphStyle,
                                        range: NSRange(location: 0, length: checkboxString.length))

            // Replace the placeholder with checkbox + gap
            nsAttributedString.replaceCharacters(in: match.range, with: checkboxString)

            // Also apply to the full paragraph range for complete coverage
            let paragraphRange = (nsAttributedString.string as NSString).paragraphRange(for: NSRange(location: match.range.location, length: 1))
            nsAttributedString.addAttribute(.paragraphStyle, value: adjustedParagraphStyle, range: paragraphRange)

            os_log("MarkdownRenderer: Replaced task checkbox placeholder (checked: %d)", log: .renderer, type: .debug, isChecked ? 1 : 0)
        }
    }
}
