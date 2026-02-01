# Phase 2: Core Markdown Rendering - Research

**Researched:** 2026-02-01
**Domain:** AttributedString Markdown Customization and NSTextView Styling
**Confidence:** MEDIUM

## Summary

Phase 1 established basic markdown rendering using `AttributedString(markdown:)`, which provides automatic parsing but limited styling control. Phase 2 requires enhanced visual hierarchy, custom fonts (SF Mono for code), and element-specific styling (blockquote borders, image placeholders with SF Symbols).

The native `AttributedString(markdown:)` initializer supports basic markdown elements (bold, italic, code, strikethrough, links) but applies minimal default styling. To customize appearance, developers can access **PresentationIntent** attributes on AttributedString runs, which identify markdown element types (.header(level), .codeBlock, .listItem, .blockQuote) without visual styling. Custom styling requires either: (1) transforming PresentationIntents into visual attributes after parsing, or (2) using swift-markdown's Visitor pattern to build AttributedString with custom attributes during parsing.

For Phase 2 requirements, the **PresentationIntent transformation approach** is recommended: parse with `AttributedString(markdown:)`, then iterate through `.runs` to detect intents and apply custom fonts, colors, paragraph styles, and spacing. Blockquote borders require custom NSLayoutManager subclass to draw vertical bars. Image placeholders use NSTextAttachment with SF Symbol icons.

**Primary recommendation:** Use `AttributedString(markdown:)` for parsing, then transform PresentationIntents to apply custom styling (heading hierarchy, SF Mono code blocks, list indentation). Subclass NSLayoutManager for blockquote border drawing. Use NSTextAttachment with SF Symbols for image placeholders.

## Standard Stack

The established libraries/tools for customizing AttributedString markdown rendering:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Foundation AttributedString | macOS 12+ | Markdown parsing with PresentationIntents | Native Apple API, built on swift-markdown/cmark-gfm |
| NSMutableParagraphStyle | AppKit | Paragraph spacing, indentation, line height | Standard for text layout customization |
| NSLayoutManager | AppKit | Custom text decorations (borders, backgrounds) | Required for drawing beyond attribute capabilities |
| NSTextAttachment | AppKit | Inline images/symbols in attributed text | Standard for embedding non-text content |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSImage(systemSymbolName:) | macOS 11+ | SF Symbol image creation | Image placeholders (per user requirements) |
| swift-markdown (already in Phase 1) | 0.7.3+ | Alternative: Visitor pattern for custom rendering | Only if PresentationIntent transformation insufficient |
| NSFont.monospacedSystemFont | macOS 10.15+ | SF Mono font access | Code blocks (user requirement) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| PresentationIntent transformation | swift-markdown Visitor pattern (e.g., Markdownosaur) | Visitor pattern gives more control but requires custom AST traversal (100+ lines), unnecessary for this phase's needs |
| Custom NSLayoutManager | Third-party library (SwiftyMarkdown) | Third-party libs easier but less control, Phase 1 already uses native approach |
| NSTextAttachment for images | Plain text "[Image: ...]" | User specified SF Symbol if available, plain text fallback acceptable |

**Installation:**
```swift
// No additional dependencies - all native AppKit/Foundation APIs
// swift-markdown already added in Phase 1 (not needed for PresentationIntent approach)
```

## Architecture Patterns

### Pattern 1: PresentationIntent-Based Styling
**What:** Parse markdown with `AttributedString(markdown:)`, then transform PresentationIntent attributes into visual styling
**When to use:** Always (recommended approach for Phase 2)
**How it works:**
1. Parse markdown: `let attrString = try AttributedString(markdown: content)`
2. Iterate through `attrString.runs` to find PresentationIntent attributes
3. Detect element types (header level, code block, list, blockquote)
4. Apply styling via `replaceAttributes(_:with:)` or `transformingAttributes(_:_:)`
5. Convert to NSAttributedString for NSTextView display

**Example:**
```swift
// Source: frankrausch/AttributedStringStyledMarkdown pattern + Apple Foundation docs
var attributedString = try AttributedString(markdown: markdownContent)

// Transform headers
for run in attributedString.runs {
    if let intent = run.presentationIntent {
        for component in intent.components {
            switch component.kind {
            case .header(let level):
                // Apply larger font for h1-h6
                let size: CGFloat = [32, 24, 20, 18, 16, 14][level - 1]
                attributedString[run.range].font = .systemFont(ofSize: size, weight: .bold)

            case .codeBlock(languageHint: _):
                // SF Mono for code blocks
                attributedString[run.range].font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                attributedString[run.range].backgroundColor = NSColor.secondarySystemFill

            default:
                break
            }
        }
    }
}
```

### Pattern 2: Inline Intent Transformation
**What:** Handle inline markdown (bold, italic, code, strikethrough) separately from block elements
**When to use:** After block-level styling applied
**Implementation:**
```swift
// Source: AttributedStringStyledMarkdown pattern
for run in attributedString.runs {
    if let inlineIntent = run.inlinePresentationIntent {
        if inlineIntent.contains(.code) {
            attributedString[run.range].font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            attributedString[run.range].backgroundColor = NSColor.quaternarySystemFill // Lighter than code blocks
        }
        if inlineIntent.contains(.stronglyEmphasized) {
            attributedString[run.range].font = .systemFont(ofSize: 14, weight: .bold)
        }
        if inlineIntent.contains(.emphasized) {
            // Italic handled automatically by AttributedString markdown parser
        }
        if inlineIntent.contains(.strikethrough) {
            // Strikethrough handled automatically
        }
    }
}
```

### Pattern 3: Custom NSLayoutManager for Blockquote Borders
**What:** Subclass NSLayoutManager to draw vertical bar on left of blockquote paragraphs
**When to use:** User requirement for GitHub-style blockquote borders
**Implementation approach:**
```swift
// Source: Pattern from NSLayoutManager documentation + community examples
class MarkdownLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        // Find ranges with blockquote presentation intent
        textStorage?.enumerateAttribute(.presentationIntent,
                                       in: glyphsToShow,
                                       options: []) { value, range, _ in
            guard let intent = value as? PresentationIntent,
                  intent.components.contains(where: { $0.kind == .blockQuote }) else { return }

            // Draw vertical bar on left
            let rect = boundingRect(forGlyphRange: range, in: textContainer(forGlyphAt: range.location, effectiveRange: nil)!)
            let barRect = NSRect(x: rect.minX - 10, y: rect.minY, width: 4, height: rect.height)
            NSColor.systemBlue.withAlphaComponent(0.3).setFill()
            barRect.fill()
        }
    }
}
```

### Pattern 4: Image Placeholder with SF Symbols
**What:** Replace markdown images with `[Image: filename]` text + SF Symbol icon
**When to use:** Markdown image syntax detected (handled by swift-markdown but not rendered by AttributedString)
**Implementation:**
```swift
// Source: WWDC 2021 SF Symbols in AppKit + NSTextAttachment docs
func createImagePlaceholder(filename: String) -> NSAttributedString {
    // SF Symbol icon
    let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
    let photoImage = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image")
        .withSymbolConfiguration(config)

    let attachment = NSTextAttachment()
    attachment.image = photoImage

    let symbolString = NSAttributedString(attachment: attachment)
    let textString = NSAttributedString(string: " [Image: \(filename)]",
                                       attributes: [.foregroundColor: NSColor.secondaryLabelColor])

    let combined = NSMutableAttributedString()
    combined.append(symbolString)
    combined.append(textString)
    return combined
}
```

### Pattern 5: List Indentation with Tab Stops
**What:** Use NSParagraphStyle with headIndent and firstLineHeadIndent for nested lists
**When to use:** Ordered and unordered lists
**Implementation:**
```swift
// Source: NSParagraphStyle examples + AttributedStringStyledMarkdown
let paragraphStyle = NSMutableParagraphStyle()
paragraphStyle.firstLineHeadIndent = CGFloat(level * 20) // Indent bullet/number
paragraphStyle.headIndent = CGFloat(level * 20 + 10)     // Indent text
paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: CGFloat(level * 20 + 10))]
paragraphStyle.paragraphSpacing = 4

attributedString[run.range].paragraphStyle = paragraphStyle
```

### Anti-Patterns to Avoid
- **Building NSAttributedString manually:** Don't parse markdown yourself. Use `AttributedString(markdown:)` for parsing, which handles edge cases (nested lists, escaping, GFM extensions).
- **Ignoring PresentationIntent:** Don't apply styling based on regex/text matching. PresentationIntent provides semantic structure from the parser.
- **Modifying AttributedString during iteration:** Don't mutate the string while iterating `.runs`. Collect ranges first, then apply transformations, or use `.transformingAttributes()`.
- **Using WKWebView for styled rendering:** Phase 1 research identified WKWebView issues in Quick Look sandbox. Continue using NSTextView approach.
- **Custom border drawing in drawGlyphs:** Use `drawBackground(forGlyphRange:)` for decorations like blockquote borders, not `drawGlyphs` (which is for glyph drawing only).

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown parsing | Regex-based markdown parser | `AttributedString(markdown:)` initializer | Already using in Phase 1, handles GFM spec edge cases (nested formatting, escaping, code fences) |
| Detecting markdown elements | String pattern matching | PresentationIntent attributes on AttributedString runs | Parser provides semantic structure (.header, .codeBlock, .listItem) accurately |
| Monospace font access | Hardcode font name "SF Mono" | `NSFont.monospacedSystemFont(ofSize:weight:)` | Respects system font settings, supports different macOS versions |
| SF Symbol images | PNG image assets | `NSImage(systemSymbolName:)` | Adapts to Dark Mode, scales with text, respects accessibility settings |
| Paragraph indentation calculation | Manual pixel math | NSParagraphStyle properties (headIndent, firstLineHeadIndent, tabStops) | Handles RTL text, respects text container width, works with line wrapping |
| Custom text background colors | NSLayoutManager drawing | `.backgroundColor` attribute on AttributedString/NSAttributedString | System handles color, respects Dark Mode, integrates with selection |

**Key insight:** AttributedString markdown parsing provides semantic structure (PresentationIntent) without visual styling. Don't re-parse or re-detect elements. Transform intents into visual attributes.

## Common Pitfalls

### Pitfall 1: AttributedString Markdown Limitations
**What goes wrong:** Expecting `AttributedString(markdown:)` to render all markdown elements with full styling
**Why it happens:** Apple's markdown initializer parses markdown into PresentationIntents (semantic markup) but applies minimal visual styling. Advanced elements like tables, headings (beyond basic detection), and images are not visually rendered.
**How to avoid:**
- Understand that `AttributedString(markdown:)` = parser + minimal styling
- Custom styling requires post-processing PresentationIntents
- Tables: Not in Phase 2 scope (deferred per requirements)
- Images: Use NSTextAttachment placeholders (user requirement)
**Warning signs:** Markdown displays but all text looks same size/style, code blocks not monospace

### Pitfall 2: Iterating and Mutating AttributedString Runs
**What goes wrong:** Modifying AttributedString while iterating through `.runs` causes crashes or incorrect ranges
**Why it happens:** Mutation during iteration invalidates run ranges
**How to avoid:**
1. Collect all ranges needing transformation first
2. Apply transformations after iteration completes
3. Or use `.transformingAttributes(_:_:)` which handles this safely
**Warning signs:** "Range out of bounds" crashes, styling applied to wrong text ranges
**Example safe pattern:**
```swift
// SAFE: Collect then transform
var modifications: [(Range<AttributedString.Index>, AttributeContainer)] = []
for run in attributedString.runs {
    // Collect modifications
    if shouldModify(run) {
        modifications.append((run.range, newAttributes))
    }
}
for (range, attrs) in modifications {
    attributedString[range].mergeAttributes(attrs)
}

// SAFER: Use transformingAttributes
attributedString.transformingAttributes(\.presentationIntent) { intent in
    // Apply transformations based on intent
}
```

### Pitfall 3: Blockquote Styling with Attributes Alone
**What goes wrong:** Attempting to add left border to blockquotes using only NSAttributedString attributes
**Why it happens:** NSAttributedString doesn't have a "border" attribute. Borders require custom drawing.
**How to avoid:**
- Use custom NSLayoutManager subclass
- Override `drawBackground(forGlyphRange:at:)`
- Draw vertical bar based on PresentationIntent detection
- Alternative: Use increased left indentation + background color (simpler but no border)
**Warning signs:** No way to add border via NSAttributedString attributes, searching for non-existent APIs

### Pitfall 4: Dark Mode and System Appearance
**What goes wrong:** Hardcoded colors look wrong in Dark Mode (white background in dark UI)
**Why it happens:** Using `.white` or `.black` instead of semantic colors
**How to avoid:**
- Use semantic colors: `.textColor`, `.backgroundColor`, `.secondarySystemFill`, `.secondaryLabelColor`
- SF Symbols automatically adapt to appearance
- Test in both Light and Dark Mode
**Warning signs:** Extension looks good in Light Mode but unreadable in Dark Mode

### Pitfall 5: PresentationIntent Component Structure
**What goes wrong:** Checking `intent == .header(1)` fails even for H1 elements
**Why it happens:** PresentationIntent contains **components array**, not single value
**How to avoid:**
```swift
// WRONG
if run.presentationIntent == .header(1) { } // Doesn't work

// RIGHT
if let intent = run.presentationIntent {
    for component in intent.components {
        if case .header(let level) = component.kind {
            // Process header with level
        }
    }
}
```
**Warning signs:** PresentationIntent checks never match, styling not applied

### Pitfall 6: Converting Between AttributedString and NSAttributedString
**What goes wrong:** Losing attributes or causing crashes when converting
**Why it happens:** Not all AttributedString attributes bridge to NSAttributedString (PresentationIntent doesn't)
**How to avoid:**
- Apply visual styling (fonts, colors, paragraph styles) in AttributedString before converting
- Convert once: `let nsAttrString = NSAttributedString(attributedString)`
- Don't convert back and forth multiple times
**Warning signs:** Attributes missing after conversion, crashes on `NSAttributedString(attributedString)`

## Code Examples

Verified patterns from official sources and community best practices:

### Complete Styling Pipeline
```swift
// Source: Synthesized from AttributedStringStyledMarkdown, Apple docs, research findings
func styledMarkdown(from content: String) throws -> NSAttributedString {
    // 1. Parse markdown
    var attributedString = try AttributedString(markdown: content)

    // 2. Apply block-level styling (in reverse to handle nested elements)
    for run in attributedString.runs.reversed() {
        guard let intent = run.presentationIntent else { continue }

        for component in intent.components {
            let range = run.range

            switch component.kind {
            case .header(let level):
                let sizes: [CGFloat] = [32, 26, 22, 18, 16, 14]
                let size = sizes[min(level - 1, 5)]
                attributedString[range].font = .systemFont(ofSize: size, weight: .bold)

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.paragraphSpacing = 8
                paragraphStyle.paragraphSpacingBefore = 4
                attributedString[range].paragraphStyle = paragraphStyle

            case .codeBlock(languageHint: _):
                attributedString[range].font = .monospacedSystemFont(ofSize: 13, weight: .regular)
                attributedString[range].backgroundColor = NSColor.secondarySystemFill

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = 10
                paragraphStyle.firstLineHeadIndent = 10
                paragraphStyle.paragraphSpacing = 8
                attributedString[range].paragraphStyle = paragraphStyle

            case .listItem(ordinal: let number):
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.firstLineHeadIndent = 20
                paragraphStyle.headIndent = 30
                paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: 30)]
                attributedString[range].paragraphStyle = paragraphStyle

            case .blockQuote:
                attributedString[range].backgroundColor = NSColor.quaternarySystemFill

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.headIndent = 20
                paragraphStyle.firstLineHeadIndent = 20
                attributedString[range].paragraphStyle = paragraphStyle

            default:
                break
            }
        }
    }

    // 3. Apply inline styling
    for run in attributedString.runs {
        guard let inlineIntent = run.inlinePresentationIntent else { continue }

        if inlineIntent.contains(.code) {
            attributedString[run.range].font = .monospacedSystemFont(ofSize: 13, weight: .regular)
            attributedString[run.range].backgroundColor = NSColor.quaternarySystemFill
        }
    }

    // 4. Convert to NSAttributedString
    return NSAttributedString(attributedString)
}
```

### NSLayoutManager Subclass for Blockquote Borders
```swift
// Source: NSLayoutManager documentation + custom drawing patterns
class MarkdownLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // Draw standard backgrounds first
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

        guard let textStorage = textStorage,
              let textContainer = textContainer(forGlyphAt: glyphsToShow.location, effectiveRange: nil) else {
            return
        }

        // Find blockquote ranges
        textStorage.enumerateAttribute(.presentationIntent,
                                      in: glyphsToShow,
                                      options: []) { value, charRange, _ in
            guard let intent = value as? PresentationIntent,
                  intent.components.contains(where: { $0.kind == .blockQuote }) else {
                return
            }

            let glyphRange = self.glyphRange(forCharacterRange: charRange, actualCharacterRange: nil)
            let boundingRect = self.boundingRect(forGlyphRange: glyphRange, in: textContainer)

            // Draw vertical bar (GitHub-style)
            let barWidth: CGFloat = 4
            let barX = origin.x + boundingRect.minX - 15
            let barRect = NSRect(x: barX,
                               y: origin.y + boundingRect.minY,
                               width: barWidth,
                               height: boundingRect.height)

            NSColor.systemBlue.withAlphaComponent(0.4).setFill()
            barRect.fill()
        }
    }
}
```

### Setting Up NSTextView with Custom Layout Manager
```swift
// Source: AppKit NSTextView documentation + Phase 1 implementation
func setupTextView() -> NSTextView {
    let textStorage = NSTextStorage()
    let layoutManager = MarkdownLayoutManager() // Custom subclass
    let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))

    layoutManager.addTextContainer(textContainer)
    textStorage.addLayoutManager(layoutManager)

    let textView = NSTextView(frame: .zero, textContainer: textContainer)
    textView.isEditable = false
    textView.isSelectable = true
    textView.backgroundColor = NSColor.textBackgroundColor // Adapts to appearance

    return textView
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual HTML generation + WKWebView | AttributedString(markdown:) + PresentationIntent transformation | macOS 12 (2021) | Simpler implementation, avoids WKWebView Quick Look issues (Phase 1 finding) |
| Regex-based markdown parsing | swift-markdown (cmark-gfm) via AttributedString | iOS 15/macOS 12 | GFM spec compliance, handles edge cases |
| Custom markdown parsers (Ink, SwiftyMarkdown) | Native AttributedString markdown support | iOS 15/macOS 12 | Built-in, maintained by Apple, no dependencies |
| Hardcoded font names | NSFont.monospacedSystemFont | macOS 10.15+ | Respects user font settings, adapts across OS versions |
| PNG icon assets | SF Symbols via NSImage(systemSymbolName:) | macOS 11+ | Dark Mode adaptation, accessibility, no asset management |

**Deprecated/outdated:**
- **NSAttributedString(HTML:):** Still works but not recommended for markdown. Use `AttributedString(markdown:)` instead.
- **Third-party markdown to HTML converters:** Unnecessary with native markdown support.
- **Manual paragraph style calculations:** NSParagraphStyle properties handle complexity (RTL, line wrapping, accessibility).

## Open Questions

Things that couldn't be fully resolved:

1. **Table rendering support in AttributedString**
   - What we know: `AttributedString(markdown:)` parses tables (swift-markdown supports GFM tables) but may not apply table-specific PresentationIntents or visual formatting
   - What's unclear: Whether PresentationIntent includes table-specific components (.table, .tableCell) in current macOS 26
   - Recommendation: Tables deferred to later phase per requirements. If needed, use swift-markdown Visitor pattern to build custom NSAttributedString with table layout (complex, 200+ lines).

2. **PresentationIntent.Component.Kind exhaustive list**
   - What we know: Documented kinds include .header(level), .codeBlock(languageHint), .listItem(ordinal), .blockQuote, .paragraph
   - What's unclear: Complete list not in Apple documentation; source code inspection needed for all cases
   - Recommendation: Handle known cases from requirements (headings, code, lists, blockquotes). Log unhandled cases for debugging.

3. **Optimal heading size hierarchy**
   - What we know: User marked as Claude's discretion
   - What's unclear: User's visual preference for h1-h6 sizes
   - Recommendation: Use sizes [32, 26, 22, 18, 16, 14] for h1-h6 (inspired by GitHub markdown styling). Can be tuned in verification.

4. **Inline code vs block code background differentiation**
   - What we know: User marked as Claude's discretion
   - What's unclear: User preference for visual distinction
   - Recommendation: Use lighter background for inline code (.quaternarySystemFill) vs code blocks (.secondarySystemFill). Provides subtle visual distinction.

5. **Code block line wrapping vs horizontal scroll**
   - What we know: User marked as Claude's discretion
   - What's unclear: User preference for long code lines
   - Recommendation: Start with wrapping (NSTextView default with `textContainer.widthTracksTextView = true`). Horizontal scroll requires custom NSScrollView configuration. Wrapping simpler and more common in Quick Look context.

## Sources

### Primary (HIGH confidence)
- [Instantiating Attributed Strings with Markdown Syntax - Apple Developer Documentation](https://developer.apple.com/documentation/foundation/instantiating-attributed-strings-with-markdown-syntax) - Official AttributedString markdown API (attempted fetch, JavaScript-blocked but confirmed existence)
- [NSLayoutManager - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/nslayoutmanager) - Custom text decorations and background drawing
- [NSParagraphStyle - Apple Developer Documentation](https://developer.apple.com/documentation/uikit/nsparagraphstyle) - Paragraph indentation and spacing
- [SF Symbols in UIKit and AppKit - WWDC21](https://developer.apple.com/videos/play/wwdc2021/10251/) - Official SF Symbols usage in AppKit
- [NSImage.SymbolConfiguration - Apple Developer Documentation](https://developer.apple.com/documentation/appkit/nsimage/symbolconfiguration) - SF Symbol configuration API

### Secondary (MEDIUM confidence)
- [AttributedStringStyledMarkdown GitHub](https://github.com/frankrausch/AttributedStringStyledMarkdown/blob/main/AttributedStringStyledMarkdown/AttributedString+StyledMarkdown.swift) - Working implementation of PresentationIntent transformation pattern
- [MarkdownToAttributedString GitHub](https://github.com/madebywindmill/MarkdownToAttributedString) - Built on swift-markdown, demonstrates styling approach
- [Markdownosaur GitHub](https://github.com/christianselig/Markdownosaur) - swift-markdown Visitor pattern example
- [PresentationIntents Discussion - Swift Forums](https://forums.swift.org/t/presentationintents-on-attributedstring-containers/61952) - Community discussion on PresentationIntent structure
- [How to render markdown block quotes with NSAttributedString - Swift Forums](https://forums.swift.org/t/how-to-render-markdown-block-quotes-with-nsattributedstring/74600) - Blockquote rendering challenges
- [AttributedString Tutorial - Kodeco](https://www.kodeco.com/29501177-attributedstring-tutorial-for-swift-getting-started) - AttributedString fundamentals
- [A Deep Dive into SwiftUI Rich Text Layout - FatBobMan](https://fatbobman.com/en/posts/a-deep-dive-into-swiftui-rich-text-layout/) - PresentationIntent explanation (Feb 2025)
- [AttributedString - Making Text More Beautiful Than Ever - FatBobMan](https://fatbobman.com/en/posts/attributedstring/) - AttributedString architecture

### Tertiary (LOW confidence - WebSearch findings)
- [Markdown with AttributedString - Design+Code](https://designcode.io/swiftui-handbook-markdown-attributed-string/) - Basic markdown support overview
- [Using Markdown in SwiftUI - AppCoda](https://www.appcoda.com/swiftui-markdown/) - Markdown limitations discussion
- [3 surprises when using Markdown in SwiftUI - Marco Eidinger](https://blog.eidinger.info/3-surprises-when-using-markdown-in-swiftui) - Strikethrough syntax confirmed (~~text~~)
- [NSParagraphStyle Explained Visually - Medium](https://medium.com/@at_underscore/nsparagraphstyle-explained-visually-a8659d1fbd6f) - Visual guide to paragraph properties
- [The Complete Guide to SF Symbols - Hacking with Swift](https://www.hackingwithswift.com/articles/237/complete-guide-to-sf-symbols) - SF Symbols overview

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All native Apple APIs (AttributedString, NSLayoutManager, NSParagraphStyle, SF Symbols), documented and stable
- Architecture: MEDIUM - PresentationIntent transformation pattern verified in multiple sources (AttributedStringStyledMarkdown, MarkdownToAttributedString) but not exhaustively documented by Apple
- Pitfalls: MEDIUM - AttributedString limitations well-documented in community (tables/images not rendered), conversion pitfalls from experience, blockquote border requires custom drawing (confirmed via NSLayoutManager docs)
- Code examples: MEDIUM - Synthesized from multiple sources (AttributedStringStyledMarkdown implementation, Apple docs, WWDC sessions), not tested in this project yet

**Research date:** 2026-02-01
**Valid until:** 2026-03-01 (30 days - AttributedString API stable since macOS 12, no major changes expected)

**Notes:**
- User decisions constrain: SF Mono for code, links not clickable (styled text only), SF Symbol for image placeholders, GitHub-style blockquote borders, no large file optimization (deferred to Phase 4)
- Claude's discretion areas: Heading sizes (recommended 32-14pt hierarchy), inline vs block code background distinction (recommended lighter for inline), code line wrapping (recommended wrap, not scroll), spacing between elements (recommended via NSParagraphStyle spacing properties)
- Phase boundary: Core markdown elements only (headings, formatting, lists, code, blockquotes, links, images as placeholders). Tables explicitly not in requirements. Syntax highlighting deferred to Phase 3 per project plan.
- Foundation from Phase 1: Already using `AttributedString(markdown:)` for basic rendering. Phase 2 adds custom styling via PresentationIntent transformation.
