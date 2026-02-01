import Cocoa
import os.log

extension OSLog {
    static let layoutManager = OSLog(subsystem: "com.razielpanic.md-spotlighter", category: "layoutManager")
}

/// Custom NSAttributedString.Key for marking blockquote ranges
extension NSAttributedString.Key {
    static let blockquoteMarker = NSAttributedString.Key("com.razielpanic.blockquoteMarker")
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

            // Get glyph range for this character range
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            // Get bounding rect for these glyphs
            let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // Draw vertical bar on left (GitHub-style)
            // Bar positioned before the text indentation (headIndent is 20, so bar at 4-8)
            let barWidth: CGFloat = 4
            let barX = origin.x + 4  // Position before text indentation
            let barRect = NSRect(x: barX,
                               y: origin.y + boundingRect.minY,
                               width: barWidth,
                               height: boundingRect.height)

            // Use semantic color that adapts to appearance
            NSColor.systemBlue.withAlphaComponent(0.4).setFill()
            barRect.fill()

            os_log("MarkdownLayoutManager: Drew blockquote border at y=%f height=%f",
                   log: .layoutManager, type: .debug,
                   origin.y + boundingRect.minY, boundingRect.height)
        }
    }
}
