import Foundation
import AppKit
import os.log

extension OSLog {
    static let renderer = OSLog(subsystem: "com.razielpanic.md-spotlighter", category: "renderer")
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
        let preprocessedMarkdown = preprocessImages(in: markdown)

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

    // MARK: - Block Boundary Processing

    /// Inserts newlines at block boundaries in AttributedString
    /// - Parameter attributedString: The AttributedString to process
    /// - Returns: AttributedString with newlines inserted at block boundaries
    private func insertBlockBoundaryNewlines(in attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        var insertionOffsets: [AttributedString.Index] = []
        var previousBlockComponent: PresentationIntent.Kind?
        var isFirstRun = true

        // Collect insertion points in forward pass
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else {
                // No intent means this is regular paragraph text
                // Treat it as a paragraph block
                if !isFirstRun && previousBlockComponent != nil {
                    insertionOffsets.append(run.range.lowerBound)
                }
                previousBlockComponent = .paragraph
                isFirstRun = false
                continue
            }

            // Get the top-level block component (first component in the stack)
            let currentBlockComponent = intent.components.first?.kind

            // Check if we're transitioning to a new block
            if !isFirstRun && currentBlockComponent != previousBlockComponent {
                insertionOffsets.append(run.range.lowerBound)
            }

            previousBlockComponent = currentBlockComponent
            isFirstRun = false
        }

        // Insert newlines in reverse order to maintain indices
        for insertPosition in insertionOffsets.reversed() {
            result.insert(AttributedString("\n"), at: insertPosition)
            os_log("MarkdownRenderer: Inserted newline at block boundary", log: .renderer, type: .debug)
        }

        return result
    }

    /// Ensures list items and blockquote lines end with newlines for proper separation
    /// - Parameter attributedString: The AttributedString to process
    /// - Returns: AttributedString with newlines added at the end of list items and blockquote lines
    private func ensureIntraBlockNewlines(in attributedString: AttributedString) -> AttributedString {
        var result = attributedString
        var insertionPositions: [AttributedString.Index] = []

        // Collect positions where newlines need to be inserted
        for run in attributedString.runs {
            guard let intent = run.presentationIntent else { continue }

            // Check if this run contains a list item or blockquote
            var needsNewline = false
            for component in intent.components {
                switch component.kind {
                case .listItem(ordinal: _):
                    needsNewline = true
                case .blockQuote:
                    needsNewline = true
                default:
                    break
                }
            }

            // If this run needs a newline, append it at the end of the run
            if needsNewline {
                let runEndIndex = run.range.upperBound
                insertionPositions.append(runEndIndex)
            }
        }

        // Insert newlines in reverse order to maintain indices
        for insertPosition in insertionPositions.reversed() {
            result.insert(AttributedString("\n"), at: insertPosition)
            os_log("MarkdownRenderer: Inserted intra-block newline", log: .renderer, type: .debug)
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
            if let ordinal = ordinal {
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
                os_log("MarkdownRenderer: Found list item (ordinal: %d, ordered: %d, prefix: %{public}s)",
                       log: .renderer, type: .debug, ordinal, isOrderedList ? 1 : 0, prefix)
            }
        }

        // Insert prefixes in reverse order to maintain indices
        for item in listItems.reversed() {
            let prefixString = NSAttributedString(
                string: item.prefix,
                attributes: [
                    .font: NSFont.systemFont(ofSize: bodyFontSize),
                    .foregroundColor: NSColor.textColor
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
        nsAttributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

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

        // Apply background color (adapts to Dark Mode)
        nsAttributedString.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: range)

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

        // Apply lighter background than code blocks
        nsAttributedString.addAttribute(.backgroundColor, value: NSColor.quaternarySystemFill, range: range)
    }

    private func applyListItemAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange, ordinal: Int) {
        // Create paragraph style with indentation for lists
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = 20  // Indent for bullet/number
        paragraphStyle.headIndent = 30           // Indent for wrapped text
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
        paragraphStyle.paragraphSpacing = 4

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
    }

    private func applyBlockQuoteAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
        // Apply subtle background
        nsAttributedString.addAttribute(.backgroundColor, value: NSColor.quaternarySystemFill, range: range)

        // Create paragraph style with indentation
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.headIndent = 20
        paragraphStyle.firstLineHeadIndent = 20
        paragraphStyle.paragraphSpacing = 8
        paragraphStyle.paragraphSpacingBefore = 8

        nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)

        // Add blockquote marker for MarkdownLayoutManager to draw border
        nsAttributedString.addAttribute(.blockquoteMarker, value: true, range: range)
    }

    // MARK: - Image Preprocessing

    private func preprocessImages(in markdown: String) -> String {
        // Replace markdown image syntax ![alt](url) with placeholder text
        // Pattern matches: ![any text](any url)
        let pattern = "!\\[([^\\]]*)\\]\\(([^)]+)\\)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return markdown
        }

        let nsString = markdown as NSString
        let matches = regex.matches(in: markdown, options: [], range: NSRange(location: 0, length: nsString.length))

        var result = markdown
        // Process in reverse to maintain string indices
        for match in matches.reversed() {
            guard match.numberOfRanges >= 3 else { continue }

            // Extract the URL/path from the image reference
            let urlRange = match.range(at: 2)
            let url = nsString.substring(with: urlRange)

            // Extract filename from URL/path
            let filename = (url as NSString).lastPathComponent

            // Create placeholder text with special marker
            let placeholder = "<<IMAGE:\(filename)>>"

            // Replace the full image markdown with placeholder
            result = (result as NSString).replacingCharacters(in: match.range, with: placeholder) as String
        }

        return result
    }

    // MARK: - Link Styling

    private func applyLinkStyles(to nsAttributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)

        // Find all runs with .link attribute (automatically added by AttributedString for markdown links)
        nsAttributedString.enumerateAttribute(.link, in: fullRange, options: []) { value, range, _ in
            guard value != nil else { return }

            // Style as blue and underlined, but don't make clickable
            nsAttributedString.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: range)
            nsAttributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)

            os_log("MarkdownRenderer: Applied link style", log: .renderer, type: .debug)
        }
    }

    // MARK: - Image Placeholder Styling

    private func applyImagePlaceholderStyles(to nsAttributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)
        let text = nsAttributedString.string as NSString

        // Find placeholder markers inserted during preprocessing
        let pattern = "<<IMAGE:([^>]+)>>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return }

        let matches = regex.matches(in: text as String, options: [], range: fullRange)

        // Process in reverse to maintain indices
        for match in matches.reversed() {
            guard match.numberOfRanges >= 2 else { continue }

            let matchRange = match.range
            let filenameRange = match.range(at: 1)
            let filename = text.substring(with: filenameRange)

            // Create image placeholder with SF Symbol
            let placeholder = createImagePlaceholder(filename: filename)

            // Replace the marker text with styled placeholder
            nsAttributedString.replaceCharacters(in: matchRange, with: placeholder)

            // Remove link attribute from the replacement range (prevents blue link styling)
            let newRange = NSRange(location: matchRange.location, length: placeholder.length)
            nsAttributedString.removeAttribute(.link, range: newRange)

            os_log("MarkdownRenderer: Applied image placeholder for %{public}s", log: .renderer, type: .debug, filename)
        }
    }

    private func createImagePlaceholder(filename: String) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Create SF Symbol attachment
        let attachment = NSTextAttachment()
        attachment.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image")
        attachment.bounds = CGRect(x: 0, y: -4, width: 16, height: 16)

        // Add the icon
        result.append(NSAttributedString(attachment: attachment))

        // Add the placeholder text
        result.append(NSAttributedString(
            string: " [Image: \(filename)]",
            attributes: [
                .foregroundColor: NSColor.secondaryLabelColor,
                .font: NSFont.systemFont(ofSize: 14)
            ]
        ))

        return result
    }
}
