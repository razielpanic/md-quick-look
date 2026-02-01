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
        guard var attributedString = try? AttributedString(markdown: markdown) else {
            os_log("MarkdownRenderer: Failed to parse markdown", log: .renderer, type: .error)
            return NSAttributedString(string: markdown)
        }

        os_log("MarkdownRenderer: Parsed successfully, applying styles", log: .renderer, type: .debug)

        // Apply styling based on PresentationIntent
        applyStyles(to: &attributedString)

        // Convert to NSAttributedString
        let result = NSAttributedString(attributedString)
        os_log("MarkdownRenderer: Render complete, output length: %d", log: .renderer, type: .info, result.length)

        return result
    }

    // MARK: - Style Application

    private func applyStyles(to attributedString: inout AttributedString) {
        // Process runs in reverse order to handle nested elements correctly
        for run in attributedString.runs.reversed() {
            let range = run.range

            // Check for block-level presentation intent (headings)
            if let intent = run.presentationIntent {
                applyBlockStyles(to: &attributedString, range: range, intent: intent)
            }

            // Ensure base font is set for all text
            if attributedString[range].font == nil {
                attributedString[range].font = NSFont.systemFont(ofSize: bodyFontSize)
            }

            // Ensure text color is set
            if attributedString[range].foregroundColor == nil {
                attributedString[range].foregroundColor = NSColor.textColor
            }
        }
    }

    private func applyBlockStyles(to attributedString: inout AttributedString, range: Range<AttributedString.Index>, intent: AttributeScopes.FoundationAttributes.PresentationIntentAttribute.Value) {
        // Iterate through intent components to find heading levels
        for component in intent.components {
            switch component.kind {
            case .header(let level):
                applyHeadingStyle(to: &attributedString, range: range, level: level)
                os_log("MarkdownRenderer: Applied h%d style", log: .renderer, type: .debug, level)
            default:
                break
            }
        }
    }

    private func applyHeadingStyle(to attributedString: inout AttributedString, range: Range<AttributedString.Index>, level: Int) {
        guard let fontSize = headingSizes[level],
              let spacing = headingSpacing[level] else {
            os_log("MarkdownRenderer: Unknown heading level %d", log: .renderer, type: .error, level)
            return
        }

        // Create bold font for heading
        let font = NSFont.boldSystemFont(ofSize: fontSize)
        attributedString[range].font = font

        // Create paragraph style with spacing
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.paragraphSpacingBefore = spacing
        paragraphStyle.paragraphSpacing = spacing

        // Copy existing paragraph style settings if any
        if let existingStyle = attributedString[range].paragraphStyle as? NSParagraphStyle {
            paragraphStyle = existingStyle.mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.paragraphSpacingBefore = spacing
            paragraphStyle.paragraphSpacing = spacing
        }

        attributedString[range].paragraphStyle = paragraphStyle
    }
}
