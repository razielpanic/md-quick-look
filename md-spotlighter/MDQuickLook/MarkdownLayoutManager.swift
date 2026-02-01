import Cocoa
import os.log

extension OSLog {
    static let layoutManager = OSLog(subsystem: "com.razielpanic.md-spotlighter", category: "layoutManager")
}

/// Custom NSAttributedString.Key for marking blockquote ranges and code blocks
extension NSAttributedString.Key {
    static let blockquoteMarker = NSAttributedString.Key("com.razielpanic.blockquoteMarker")
    static let codeBlockMarker = NSAttributedString.Key("com.razielpanic.codeBlockMarker")
}

/// Custom layout manager for drawing blockquote decorations
class MarkdownLayoutManager: NSLayoutManager {

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // Draw standard backgrounds first (code block backgrounds, etc.)
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let textStorage = textStorage,
              let textContainer = textContainer(forGlyphAt: glyphsToShow.location, effectiveRange: nil) else {
            return
        }

        // Find blockquote ranges and draw vertical bars
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage.enumerateAttribute(.blockquoteMarker,
                                      in: charRange,
                                      options: []) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            // Track the union of all line rects to create continuous background
            var unionRect = NSRect.null

            // Enumerate each line fragment in this range
            self.enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, usedRect, container, lineGlyphRange, stop in
                if unionRect.isNull {
                    unionRect = lineRect
                } else {
                    unionRect = unionRect.union(lineRect)
                }
            }

            guard !unionRect.isNull else { return }

            // Draw continuous vertical bar
            let barWidth: CGFloat = 4
            let barX = origin.x + 4
            let barRect = NSRect(x: barX,
                                y: origin.y + unionRect.minY,
                                width: barWidth,
                                height: unionRect.height)

            // Use semantic color that adapts to appearance
            NSColor.systemBlue.withAlphaComponent(0.4).setFill()
            barRect.fill()

            os_log("MarkdownLayoutManager: Drew blockquote border at y=%f height=%f",
                   log: .layoutManager, type: .debug,
                   origin.y + unionRect.minY, unionRect.height)
        }

        // Find code block ranges and draw uniform backgrounds
        textStorage.enumerateAttribute(.codeBlockMarker,
                                      in: charRange,
                                      options: []) { value, range, _ in
            guard value != nil else { return }

            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            // Track the union of all line rects to create continuous background
            var unionRect = NSRect.null

            // Enumerate each line fragment in this range
            self.enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, usedRect, container, lineGlyphRange, stop in
                if unionRect.isNull {
                    unionRect = lineRect
                } else {
                    unionRect = unionRect.union(lineRect)
                }
            }

            guard !unionRect.isNull else { return }

            // Draw single unified background
            let bgRect = NSRect(x: origin.x + 8,
                               y: origin.y + unionRect.minY,
                               width: textContainer.containerSize.width - 16,
                               height: unionRect.height)

            NSColor.secondarySystemFill.setFill()
            bgRect.fill()

            os_log("MarkdownLayoutManager: Drew code block background at y=%f height=%f",
                   log: .layoutManager, type: .debug,
                   origin.y + unionRect.minY, unionRect.height)
        }
    }
}
