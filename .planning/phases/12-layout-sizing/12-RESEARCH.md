# Phase 12: Layout & Sizing - Research

**Researched:** 2026-02-06
**Domain:** Responsive layout and font scaling in macOS Quick Look extensions
**Confidence:** MEDIUM-HIGH

## Summary

This research investigates how to detect available width in Quick Look contexts and adapt font sizes, padding, and text layout to produce readable output in narrow (Finder preview pane ~260px), normal (Quick Look popup), and fullscreen contexts.

The standard approach is to detect width via `view.bounds.width` in `viewDidLayout()`, then pass width constraints to the renderer to generate appropriately scaled `NSAttributedString` content. Quick Look window sizing should remain system-managed (no `preferredContentSize`) to preserve native resize behavior. Font scaling uses a modular scale approach with disproportionate shrinking (headings shrink more than body text), while spacing adapts via `textContainerInset` and paragraph styles.

Typography best practices recommend 16px body text minimum, 11pt absolute floor for accessibility, and max content width of 65-80 characters per line. Font scaling ratios of 1.2-1.5x between heading levels create clear hierarchy without excessive contrast.

**Primary recommendation:** Implement width detection in `viewDidLayout()`, pass available width to renderer, generate width-adapted `NSAttributedString` with scaled fonts and spacing, apply via `textContainerInset` adjustment.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Width breakpoints:**
- Two discrete tiers: narrow and normal (no smooth scaling)
- Narrow tier threshold: Claude's discretion based on actual Quick Look contexts (Finder preview pane is ~260px)
- Window sizing stays system-managed (no preferredContentSize) — current autoresizing mask approach is correct
- Extension adapts content to whatever width macOS provides

**Font scaling:**
- Scaled shrink approach: headings shrink more aggressively than body text (headings eat the most space)
- Minimum font size floor enforced — nothing goes below a readable minimum (~9-10pt range)
- Code blocks (inline and fenced) scale at the same rate as body text
- Heading hierarchy flattens in narrow mode — H1/H2/H3 sizes converge closer together to save vertical space
- In normal mode, heading hierarchy stays as-is with distinct size steps

**Spacing & density:**
- Narrow mode: minimal margins (~5-8pt), almost edge-to-edge content to maximize the ~260px
- Narrow mode: paragraph spacing and vertical gaps shrink proportionally
- Narrow mode: decorative element inner padding (code blocks, blockquotes, YAML) also shrinks
- Normal mode: add a max content width cap to prevent uncomfortably long lines in fullscreen (typographic best practice, ~65-80 chars per line)
- Normal mode: otherwise stays as-is

**YAML front matter at narrow widths:**
- Shrink the YAML section (smaller font, tighter spacing) — not hidden, not collapsed
- Truncate long values with ellipsis to keep the section compact
- Keep the background styling (rounded colored container) even in narrow mode
- Cap displayed fields at ~4-5 in narrow mode, with a "+N more" indicator for additional fields
- Future: Preferences toggle for YAML display is a separate todo (already captured)

### Claude's Discretion

- Exact narrow breakpoint threshold (likely around 300px but test to confirm)
- Specific font size ratios for narrow mode
- Exact minimum font size floor
- Max content width value for normal mode
- Heading size convergence ratios in narrow mode

### Deferred Ideas (OUT OF SCOPE)

- Preferences toggle for YAML front matter display (show/hide) — already captured as pending todo

</user_constraints>

## Standard Stack

The established approach for adaptive text layout in macOS Quick Look extensions:

### Core
| Library/API | Version | Purpose | Why Standard |
|------------|---------|---------|--------------|
| NSTextView | AppKit | Text rendering container | Native macOS text display with built-in scrolling |
| NSTextContainer | AppKit | Text layout geometry | Manages text wrapping and container sizing |
| NSAttributedString | Foundation | Styled text content | Declarative text styling with attributes |
| NSLayoutManager | AppKit | Text layout engine | Handles glyph generation and layout |
| view.bounds | NSView | Width detection | Standard property for view geometry |

### Supporting
| API | Version | Purpose | When to Use |
|-----|---------|---------|-------------|
| textContainerInset | NSTextView | Dynamic padding | Adjust margins based on available width |
| NSParagraphStyle | Foundation | Spacing control | Paragraph-level spacing, indentation |
| viewDidLayout() | NSViewController | Layout notification | Detect when view bounds change |
| NSView.boundsDidChangeNotification | AppKit | Bounds change detection | Alternative to viewDidLayout for fine-grained control |
| NSFont.systemFont(ofSize:) | AppKit | Dynamic font sizing | Generate fonts at runtime based on width tier |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Discrete breakpoints | Smooth scaling (CSS clamp-like) | Discrete tiers simpler to implement, test, debug; smooth scaling requires continuous calculation |
| Width-adapted NSAttributedString | CSS + WKWebView | NSAttributedString approach stays native, no web tech dependency, better performance |
| viewDidLayout() | Bounds change notification | viewDidLayout is simpler for view controller context, notification more granular but requires setup |

**Installation:**
No external dependencies — all AppKit/Foundation APIs.

## Architecture Patterns

### Recommended Component Structure

```
PreviewViewController.swift         # Width detection, view lifecycle
├── viewDidLayout()                 # Detect bounds.width changes
├── updateLayoutForWidth()          # Dispatch to renderer with width tier
└── applyStyledContent()            # Apply NSAttributedString to text view

MarkdownRenderer.swift              # Content generation with width awareness
├── render(markdown:width:)         # NEW: Accept width parameter
├── fontSizesForWidth()             # NEW: Return scaled font sizes
├── spacingForWidth()               # NEW: Return scaled spacing values
└── renderFrontMatter(width:)       # NEW: Width-aware YAML rendering

MarkdownLayoutManager.swift         # Background drawing (no changes needed)
```

### Pattern 1: Width Detection in View Controller

**What:** Detect available width in `viewDidLayout()`, determine tier (narrow/normal), pass to renderer.

**When to use:** Every time view bounds change (user resizes window, enters fullscreen, changes Finder pane width).

**Example:**
```swift
// Source: Research synthesis from Apple NSViewController docs
override func viewDidLayout() {
    super.viewDidLayout()

    let availableWidth = view.bounds.width

    // Determine width tier (exact threshold from testing)
    let widthTier: WidthTier = availableWidth < 320 ? .narrow : .normal

    // If tier changed, re-render content with new constraints
    if widthTier != currentWidthTier {
        currentWidthTier = widthTier
        updateContentForWidth(widthTier)
    }
}
```

### Pattern 2: Width-Aware Renderer

**What:** Renderer accepts width tier parameter, returns NSAttributedString with scaled fonts and spacing.

**When to use:** During initial render and whenever width tier changes.

**Example:**
```swift
// Source: Research synthesis
class MarkdownRenderer {
    func render(markdown: String, widthTier: WidthTier) -> NSAttributedString {
        let fontSizes = self.fontSizesForWidthTier(widthTier)
        let spacing = self.spacingForWidthTier(widthTier)

        // Generate styled content using tier-specific values
        let content = generateContent(markdown, fonts: fontSizes, spacing: spacing)
        return content
    }

    private func fontSizesForWidthTier(_ tier: WidthTier) -> FontSizes {
        switch tier {
        case .narrow:
            // Headings shrink aggressively, body text shrinks moderately
            return FontSizes(
                h1: 20,  // Was 32 → 37.5% reduction
                h2: 17,  // Was 26 → 34.6% reduction
                h3: 15,  // Was 22 → 31.8% reduction
                body: 12,  // Was 14 → 14.3% reduction
                code: 11   // Was 13 → 15.4% reduction
            )
        case .normal:
            return FontSizes(
                h1: 32, h2: 26, h3: 22,
                body: 14, code: 13
            )
        }
    }
}
```

### Pattern 3: Dynamic Text Container Insets

**What:** Adjust `textContainerInset` based on width tier to control horizontal padding.

**When to use:** After determining width tier, before applying NSAttributedString to text view.

**Example:**
```swift
// Source: Apple "Setting Text Margins" documentation
func applyStyledContent(_ content: NSAttributedString, widthTier: WidthTier) {
    // Set tier-specific insets
    let insets: NSSize = widthTier == .narrow
        ? NSSize(width: 6, height: 6)    // Minimal in narrow mode
        : NSSize(width: 20, height: 20)  // Standard in normal mode

    textView.textContainerInset = insets

    // Apply content
    textStorage.setAttributedString(content)
}
```

### Pattern 4: Max Content Width in Normal Mode

**What:** In normal mode (wide contexts), limit line length to 65-80 characters for readability.

**When to use:** When available width exceeds optimal reading width (~800-1000px).

**Example:**
```swift
// Source: Typography readability research
func updateTextContainer(for widthTier: WidthTier) {
    guard widthTier == .normal else { return }

    // Calculate max content width based on body font
    let avgCharWidth: CGFloat = 8.5  // Approximate for 14pt system font
    let maxChars: CGFloat = 75       // Target 75 chars per line
    let maxContentWidth = avgCharWidth * maxChars  // ~638pt

    // Center content if window wider than max
    if view.bounds.width > maxContentWidth {
        let excessWidth = view.bounds.width - maxContentWidth
        let horizontalInset = excessWidth / 2
        textView.textContainerInset = NSSize(width: horizontalInset, height: 20)
    }
}
```

### Anti-Patterns to Avoid

- **Setting preferredContentSize:** Breaks system-managed resizing. Quick Look window should resize freely; content adapts to whatever size macOS provides. (Source: Apple Developer Forums - setting preferredContentSize breaks autoresizing)

- **Smooth/continuous scaling:** Adds complexity, harder to test. Discrete tiers (narrow/normal) are easier to validate and debug.

- **Uniform font scaling:** Shrinking all fonts by same percentage wastes space. Headings should shrink more aggressively since they consume more vertical space and don't need to be as large for quick scanning.

- **Using view.frame instead of view.bounds:** Bounds is in view's own coordinate system; frame is in superview's. Bounds is correct for layout decisions within the view.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Font size calculation | Custom scaling formulas | Discrete tier lookup table | Two tiers means two sets of values; lookup is simpler, more maintainable than formulas |
| Width breakpoint detection | Complex responsive logic | Simple if/switch on bounds.width | Only two tiers (narrow/normal), one threshold check is sufficient |
| Line length limiting | Custom text wrapping | textContainerInset centering | AppKit handles wrapping automatically; just adjust insets |
| Bounds change detection | Manual frame tracking | viewDidLayout() lifecycle method | Built-in lifecycle method handles all resize scenarios |

**Key insight:** AppKit's text system is designed for this. NSTextView + NSTextContainer already handle wrapping, scrolling, and sizing. The extension just needs to provide appropriately styled NSAttributedString and adjust insets.

## Common Pitfalls

### Pitfall 1: Setting preferredContentSize in QLPreviewingController

**What goes wrong:** Quick Look window stops resizing properly. User drags corner to resize → content doesn't adapt, or window size is fixed.

**Why it happens:** Setting preferredContentSize tells the system "this is my ideal size" which conflicts with user-driven resizing and fullscreen transitions.

**How to avoid:** Never set preferredContentSize. Use autoresizingMask on subviews (already correct in current implementation: `scrollView.autoresizingMask = [.width, .height]`).

**Warning signs:** Window doesn't resize when dragging corners, fullscreen mode has wrong dimensions, Finder preview pane shows clipped content.

**Source:** [Apple Developer Forums - Setting preferredContentSize](https://developer.apple.com/forums/thread/673369)

### Pitfall 2: Regenerating NSAttributedString on Every Bounds Change

**What goes wrong:** Performance degrades, UI feels sluggish during window resize.

**Why it happens:** Markdown parsing and NSAttributedString generation is expensive. Running on every pixel of resize causes janky UI.

**How to avoid:** Only regenerate when width tier changes (narrow ↔ normal transition), not on every bounds change. Cache current tier, compare before regenerating.

**Warning signs:** Visible lag when resizing window, high CPU usage during resize, dropped frames.

### Pitfall 3: Font Sizes Below Readable Minimum

**What goes wrong:** Text becomes illegible in narrow mode, accessibility failure.

**Why it happens:** Aggressive scaling formula drops fonts below ~9pt, too small to read comfortably.

**How to avoid:** Set absolute floor on font sizes. Apple recommends minimum 11pt for accessibility; 9-10pt is absolute limit.

**Warning signs:** User complaints about readability, text too small in Finder preview pane.

**Source:** [Font Size Requirements - WCAG 2.1](https://font-converters.com/accessibility/font-size-requirements)

### Pitfall 4: Inconsistent Width Tracking Setup

**What goes wrong:** Infinite loop, text view doesn't resize, or content overflows container.

**Why it happens:** Setting both `widthTracksTextView: true` on NSTextContainer AND `isHorizontallyResizable: true` on NSTextView creates circular dependency.

**How to avoid:** Use `widthTracksTextView: true` (container follows view) with `isHorizontallyResizable: false`. Let container width track view, but keep view width fixed by autoresizing mask.

**Warning signs:** Infinite loop crash, console spam about layout inconsistency, horizontal scrollbar appears unexpectedly.

**Source:** [Apple Developer Documentation - Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html)

### Pitfall 5: Calculating Max Content Width Without Testing

**What goes wrong:** Line length calculation produces wrong results; text too narrow or too wide in normal mode.

**Why it happens:** Average character width varies by font, weight, and content mix (code vs prose). Fixed formula doesn't account for variation.

**How to avoid:** Test with real markdown files containing various content types. Measure actual rendered line lengths. Adjust maxChars target based on observed results.

**Warning signs:** Lines appear uncomfortably long (>90 chars) or wastefully narrow (<50 chars) in fullscreen mode.

## Code Examples

Verified patterns from research and official sources:

### Detecting Width Tier Changes

```swift
// Source: Research synthesis from NSViewController lifecycle docs
class PreviewViewController: NSViewController, QLPreviewingController {

    enum WidthTier {
        case narrow   // < 320pt (Finder preview pane)
        case normal   // >= 320pt (Quick Look popup, fullscreen)
    }

    private var currentWidthTier: WidthTier?

    override func viewDidLayout() {
        super.viewDidLayout()

        let availableWidth = view.bounds.width
        let newTier: WidthTier = availableWidth < 320 ? .narrow : .normal

        // Only regenerate if tier changed
        guard newTier != currentWidthTier else { return }

        currentWidthTier = newTier
        regenerateContentForWidthTier(newTier)
    }
}
```

### Width-Aware Font Sizing

```swift
// Source: Typography modular scale research + accessibility minimums
struct FontSizes {
    let h1: CGFloat
    let h2: CGFloat
    let h3: CGFloat
    let h4: CGFloat
    let body: CGFloat
    let code: CGFloat

    static let normal = FontSizes(
        h1: 32, h2: 26, h3: 22, h4: 18,
        body: 14, code: 13
    )

    static let narrow = FontSizes(
        // Headings shrink 30-40%, body/code shrink 10-15%
        // Floor enforced at 10pt minimum
        h1: max(20, 10),   // 37.5% reduction
        h2: max(17, 10),   // 34.6% reduction
        h3: max(15, 10),   // 31.8% reduction
        h4: max(14, 10),   // 22.2% reduction
        body: max(12, 10), // 14.3% reduction
        code: max(11, 10)  // 15.4% reduction
    )
}
```

### Width-Aware Spacing

```swift
// Source: Research synthesis
struct SpacingValues {
    let textContainerInset: NSSize
    let paragraphSpacing: CGFloat
    let headingSpacing: CGFloat
    let codeBlockPadding: CGFloat
    let blockquotePadding: CGFloat

    static let normal = SpacingValues(
        textContainerInset: NSSize(width: 20, height: 20),
        paragraphSpacing: 8,
        headingSpacing: 10,
        codeBlockPadding: 10,
        blockquotePadding: 20
    )

    static let narrow = SpacingValues(
        // Shrink all spacing ~60-75% to maximize content visibility
        textContainerInset: NSSize(width: 6, height: 6),
        paragraphSpacing: 4,
        headingSpacing: 4,
        codeBlockPadding: 6,
        blockquotePadding: 12
    )
}
```

### Max Content Width (Normal Mode)

```swift
// Source: Readability research - optimal line length 65-80 chars
func applyMaxContentWidth(textView: NSTextView, bodyFontSize: CGFloat) {
    let availableWidth = view.bounds.width

    // Calculate max width for 75 characters at current body font
    // Approximate: monospace = fontSize * 0.6, system font = fontSize * 0.55
    let avgCharWidth = bodyFontSize * 0.55
    let targetChars: CGFloat = 75
    let maxContentWidth = avgCharWidth * targetChars

    if availableWidth > maxContentWidth + 40 {  // +40 for insets
        // Center content by increasing horizontal inset
        let excessWidth = availableWidth - maxContentWidth
        let horizontalInset = excessWidth / 2
        textView.textContainerInset = NSSize(
            width: horizontalInset,
            height: 20
        )
    } else {
        // Use standard insets
        textView.textContainerInset = NSSize(width: 20, height: 20)
    }
}
```

### YAML Front Matter Width Adaptation

```swift
// Source: Research synthesis + user constraints
func renderFrontMatter(_ frontMatter: [(String, String)], widthTier: WidthTier) -> NSAttributedString {

    let result = NSMutableAttributedString()

    // Determine display limits and styling based on width tier
    let (fontSize, maxFields, truncateAt): (CGFloat, Int, Int) = {
        switch widthTier {
        case .narrow:
            return (10, 5, 30)  // Smaller font, show max 5 fields, truncate values at 30 chars
        case .normal:
            return (12, Int.max, Int.max)  // Standard font, show all, no truncation
        }
    }()

    // Determine which fields to display
    let displayedFields = frontMatter.prefix(maxFields)
    let hiddenCount = frontMatter.count - displayedFields.count

    for (key, value) in displayedFields {
        // Truncate long values in narrow mode
        let displayValue = value.count > truncateAt
            ? String(value.prefix(truncateAt)) + "…"
            : value

        // Apply key: value styling (implementation details...)
    }

    // Add "+N more" indicator if fields hidden
    if hiddenCount > 0 {
        let indicator = NSAttributedString(
            string: "\n+\(hiddenCount) more",
            attributes: [
                .font: NSFont.systemFont(ofSize: fontSize),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        result.append(indicator)
    }

    return result
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Fixed preferredContentSize | System-managed sizing with autoresizing | macOS 10.15+ | Quick Look windows now resize freely; extensions must adapt content |
| CSS @media queries (web) | Container-based breakpoints | 2023-2024 | Focus on container width, not viewport; better for reusable components |
| Uniform scaling | Proportional scaling by element type | Ongoing | Headings shrink more than body text for better space utilization |
| Smooth/continuous scaling | Discrete breakpoint tiers | Ongoing | Simpler implementation, easier testing, fewer edge cases |

**Deprecated/outdated:**
- Setting `preferredContentSize` in QLPreviewingController: Breaks resize behavior on modern macOS. Use autoresizing masks instead.
- Viewport-based breakpoints without min/max: CSS clamp() and container queries replaced pure viewport units for better control.

## Open Questions

Things that couldn't be fully resolved:

1. **Exact Finder preview pane width**
   - What we know: User constraint mentions ~260px, community reports vary 250-300px depending on macOS version
   - What's unclear: Does width vary by macOS version, display resolution, or user customization?
   - Recommendation: Test on multiple macOS versions (Monterey, Ventura, Sonoma, Tahoe) with different display densities. Measure actual bounds.width in Finder preview pane. Choose threshold that works across all tested scenarios (~300-320px likely safe).

2. **Optimal heading convergence in narrow mode**
   - What we know: Headings should flatten (H1/H2/H3 closer in size) to save space
   - What's unclear: Exact ratios that maintain hierarchy while maximizing space savings
   - Recommendation: Start with research-derived values (H1: 20pt, H2: 17pt, H3: 15pt), test with real markdown files containing all heading levels. Verify visual hierarchy still clear in narrow context.

3. **Performance of viewDidLayout() regeneration**
   - What we know: Should only regenerate when tier changes, not every bounds change
   - What's unclear: Is tier-change detection sufficient, or do resize animations still cause jank?
   - Recommendation: Profile with Instruments during window resize. If still seeing performance issues, consider debouncing regeneration (wait until resize completes) using a short timer.

4. **Max content width character count**
   - What we know: Typography research suggests 65-80 chars/line optimal
   - What's unclear: Does this apply equally to markdown with code blocks, lists, headings?
   - Recommendation: Test with diverse markdown files. Measure actual readability comfort with prose paragraphs vs code blocks. May need different maxChars for different content types.

## Sources

### Primary (HIGH confidence)

- [Apple Developer Documentation - Setting Text Margins](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextUILayer/Tasks/SetTextMargins.html) - Official textContainerInset patterns
- [Apple Developer Documentation - Tracking the Size of a Text View](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html) - NSTextContainer sizing behavior
- [Apple Developer Documentation - viewDidLayout()](https://developer.apple.com/documentation/appkit/nsviewcontroller/1434451-viewdidlayout) - View lifecycle methods
- [Apple Developer Documentation - NSViewFrameDidChangeNotification](https://developer.apple.com/documentation/appkit/nsviewframedidchangenotification) - Bounds change notifications
- [Font Size Requirements - WCAG 2.1 AA/AAA Compliance](https://font-converters.com/accessibility/font-size-requirements) - Accessibility minimum font sizes

### Secondary (MEDIUM confidence)

- [Readability: The Optimal Line Length - Baymard](https://baymard.com/blog/line-length-readability) - 50-75 character line length research
- [Typography in UX Best Practices Guide](https://developerux.com/2025/02/12/typography-in-ux-best-practices-guide/) - 16px body text, 1.3-1.6x heading scale
- [Modular Scale Typography](https://www.modularscale.com/) - Type scale ratios (1.2-1.5x between levels)
- [Font Size Guidelines for Responsive Websites](https://www.learnui.design/blog/mobile-desktop-website-font-size-guidelines.html) - 16px body baseline, heading size ranges
- [Apple Developer Forums - Setting preferredContentSize](https://developer.apple.com/forums/thread/673369) - preferredContentSize breaks autoresizing (verified by community)
- [Responsive Design Breakpoints 2025](https://www.browserstack.com/guide/responsive-design-breakpoints) - Modern breakpoint patterns (content-driven vs device-driven)
- [Container Queries - MDN](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Containment/Container_queries) - Container-based responsive design (conceptual parallel to NSView bounds-based adaptation)

### Tertiary (LOW confidence - needs validation)

- [QLMarkdown GitHub Repository](https://github.com/sbarex/QLMarkdown) - Example Quick Look extension (uses custom sizing, warns about compatibility issues)
- Typography scaling ratios and exact thresholds - WebSearch results from multiple sources with varying recommendations; needs testing with actual content

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - AppKit/Foundation APIs are well-documented and stable
- Architecture patterns: MEDIUM-HIGH - Based on official Apple docs, needs validation through testing
- Font scaling specifics: MEDIUM - Research-derived ratios are well-established in typography, but exact values for narrow mode need testing
- Performance considerations: MEDIUM - viewDidLayout() approach is standard, but tier-change optimization needs profiling to confirm
- Pitfalls: HIGH - preferredContentSize issue verified by Apple forums; NSTextContainer width tracking documented by Apple

**Research date:** 2026-02-06
**Valid until:** 30 days (stable macOS APIs, typography best practices change slowly)
