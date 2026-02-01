import Cocoa
import os.log

extension OSLog {
    static let layoutManager = OSLog(subsystem: "com.razielpanic.md-spotlighter", category: "layoutManager")
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

        textStorage.enumerateAttribute(.presentationIntent,
                                      in: charRange,
                                      options: []) { value, range, _ in
            guard let intent = value as? PresentationIntent else { return }

            // Check if this is a blockquote
            let isBlockquote = intent.components.contains { component in
                if case .blockQuote = component.kind { return true }
                return false
            }

            guard isBlockquote else { return }

            // Get glyph range for this character range
            let glyphRange = self.glyphRange(forCharacterRange: range, actualCharacterRange: nil)

            // Get bounding rect for these glyphs
            let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // Draw vertical bar on left (GitHub-style)
            let barWidth: CGFloat = 4
            let barX = origin.x + 8  // Fixed position from left edge
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
