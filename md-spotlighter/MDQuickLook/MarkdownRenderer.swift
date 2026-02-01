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

        // Parse markdown using native AttributedString
        guard let attributedString = try? AttributedString(markdown: markdown) else {
            os_log("MarkdownRenderer: Failed to parse markdown", log: .renderer, type: .error)
            return NSAttributedString(string: markdown)
        }

        os_log("MarkdownRenderer: Parsed successfully, converting to NSAttributedString", log: .renderer, type: .debug)

        // Convert to NSMutableAttributedString
        let nsAttributedString = NSMutableAttributedString(attributedString)

        // Apply block-level styles by examining PresentationIntent
        applyBlockStyles(from: attributedString, to: nsAttributedString)

        // Apply inline styles
        applyInlineStyles(from: attributedString, to: nsAttributedString)

        // Set base styling
        applyBaseStyles(to: nsAttributedString)

        os_log("MarkdownRenderer: Render complete, output length: %d", log: .renderer, type: .info, nsAttributedString.length)

        return nsAttributedString
    }

    // MARK: - Style Application

    private func applyBaseStyles(to nsAttributedString: NSMutableAttributedString) {
        let fullRange = NSRange(location: 0, length: nsAttributedString.length)

        // Set base text color
        nsAttributedString.addAttribute(.foregroundColor, value: NSColor.textColor, range: fullRange)

        // Ensure all text has at least the base font (if not overridden by headings)
        nsAttributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, _ in
            if value == nil {
                nsAttributedString.addAttribute(.font, value: NSFont.systemFont(ofSize: bodyFontSize), range: range)
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
    }
}
