import Cocoa
import os.log

extension OSLog {
    static let layoutManager = OSLog(subsystem: "com.rocketpop.MDQuickLook", category: "layoutManager")
}

/// Custom NSAttributedString.Key for marking blockquote ranges and code blocks
extension NSAttributedString.Key {
    static let blockquoteMarker = NSAttributedString.Key("com.rocketpop.blockquoteMarker")
    static let codeBlockMarker = NSAttributedString.Key("com.rocketpop.codeBlockMarker")
    static let frontMatterMarker = NSAttributedString.Key("com.rocketpop.frontMatterMarker")
}

/// Custom layout manager for drawing blockquote decorations
class MarkdownLayoutManager: NSLayoutManager {

    // MARK: - Helper Methods

    /// Merges adjacent or overlapping ranges
    /// - Parameter ranges: Array of NSRanges to merge
    /// - Returns: Array of merged NSRanges
    private func mergeAdjacentRanges(_ ranges: [NSRange]) -> [NSRange] {
        guard !ranges.isEmpty else { return [] }

        let sorted = ranges.sorted { $0.location < $1.location }
        var merged: [NSRange] = [sorted[0]]

        for range in sorted.dropFirst() {
            let last = merged.last!
            // If adjacent (within 2 characters for newlines) or overlapping
            if range.location <= last.location + last.length + 2 {
                // Extend the last range
                let newLength = max(last.length, range.location + range.length - last.location)
                merged[merged.count - 1] = NSRange(location: last.location, length: newLength)
            } else {
                merged.append(range)
            }
        }

        return merged
    }

    // MARK: - Drawing

    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // Draw standard backgrounds first (code block backgrounds, etc.)
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let textStorage = textStorage,
              let textContainer = textContainer(forGlyphAt: glyphsToShow.location, effectiveRange: nil) else {
            return
        }

        // Find blockquote ranges and draw vertical bars
        let charRange = characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        // Collect all blockquote ranges first
        var allBlockquoteRanges: [NSRange] = []
        textStorage.enumerateAttribute(.blockquoteMarker,
                                      in: charRange,
                                      options: []) { value, range, _ in
            guard value != nil else { return }
            allBlockquoteRanges.append(range)
            os_log("MarkdownLayoutManager: Found blockquote range %d-%d",
                   log: .layoutManager, type: .debug,
                   range.location, range.location + range.length)
        }

        // Merge adjacent/overlapping blockquote ranges
        let mergedRanges = mergeAdjacentRanges(allBlockquoteRanges)

        // Draw for each merged range
        for range in mergedRanges {
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

            guard !unionRect.isNull else { continue }

            // Draw full-width background first (behind border)
            let bgRect = NSRect(x: origin.x + 12,  // Start after border
                               y: origin.y + unionRect.minY,
                               width: textContainer.containerSize.width - 24,
                               height: unionRect.height)

            NSColor.quaternarySystemFill.setFill()
            bgRect.fill()

            // Draw continuous vertical bar on top
            let barWidth: CGFloat = 4
            let barX = origin.x + 4
            let barRect = NSRect(x: barX,
                                y: origin.y + unionRect.minY,
                                width: barWidth,
                                height: unionRect.height)

            // Use semantic color that adapts to appearance
            NSColor.separatorColor.setFill()
            barRect.fill()

            os_log("MarkdownLayoutManager: Drew blockquote border at y=%f height=%f for merged range %d-%d",
                   log: .layoutManager, type: .debug,
                   origin.y + unionRect.minY, unionRect.height, range.location, range.location + range.length)
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

        // Find front matter ranges and draw rounded background with separator
        textStorage.enumerateAttribute(.frontMatterMarker,
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

            // Draw rounded background with insets and vertical padding
            let verticalPadding: CGFloat = 12
            let bgRect = NSRect(x: origin.x + 6,
                               y: origin.y + unionRect.minY - verticalPadding,
                               width: textContainer.containerSize.width - 12,
                               height: unionRect.height + verticalPadding * 2)

            let path = NSBezierPath(roundedRect: bgRect, xRadius: 6, yRadius: 6)
            NSColor.tertiarySystemFill.setFill()
            path.fill()

            // Draw bottom separator line (below the padded background)
            let separatorY = origin.y + unionRect.maxY + verticalPadding
            let separatorPath = NSBezierPath()
            separatorPath.move(to: NSPoint(x: origin.x + 6, y: separatorY))
            separatorPath.line(to: NSPoint(x: origin.x + textContainer.containerSize.width - 6, y: separatorY))
            separatorPath.lineWidth = 1.0
            NSColor.separatorColor.setStroke()
            separatorPath.stroke()

            os_log("MarkdownLayoutManager: Drew front matter background at y=%f height=%f",
                   log: .layoutManager, type: .debug,
                   origin.y + unionRect.minY, unionRect.height)
        }
    }
}
