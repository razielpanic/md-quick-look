# Phase 14: Task List Checkboxes - Research

**Researched:** 2026-02-07
**Domain:** GFM Task Lists with SF Symbol Checkboxes in NSAttributedString
**Confidence:** HIGH

## Summary

Phase 14 requires rendering GitHub-flavored markdown (GFM) task list items (`- [ ]` and `- [x]`) as visual checkboxes using SF Symbols in the Quick Look extension. The project already uses swift-markdown for AST parsing (which supports GFM task lists through its cmark-gfm backend) and NSAttributedString with NSTextView for rendering. Task list items are detected via the `ListItem.checkbox` property in the swift-markdown AST, which is an optional enum with `.checked` and `.unchecked` cases.

The implementation follows the same hybrid architecture pattern established in Phase 13 (Table Rendering): use swift-markdown's MarkupVisitor pattern to detect task list items during AST traversal, then insert SF Symbol checkboxes as NSTextAttachment objects into the attributed string. Checkboxes must align with text baseline and support mixed lists where regular bullet items and task items coexist in the same list structure.

**Key finding:** Task list syntax inside code blocks is automatically handled correctly by swift-markdown's AST—code block content is parsed as literal text nodes without PresentationIntent for list items, so no special exclusion logic is needed. The MarkupVisitor will never encounter ListItem nodes within CodeBlock nodes.

**Primary recommendation:** Extend the existing MarkdownRenderer to detect ListItem nodes with non-nil `checkbox` property during AST traversal, insert SF Symbol NSTextAttachment (`.circle` or `.checkmark.circle.fill`) before the list item text, use NSParagraphStyle hanging indent (firstLineHeadIndent/headIndent) for proper text wrapping alignment, and apply system accent blue color via NSImage.SymbolConfiguration.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Checkbox appearance:**
- Unchecked: `circle` SF Symbol (empty circle)
- Checked: `checkmark.circle.fill` SF Symbol (filled circle with checkmark)
- Both states use system accent blue — only fill/outline distinguishes checked from unchecked
- Checkbox size scales with font size across width tiers (shrinks in narrow contexts like Finder preview pane)

**Checked item styling:**
- No text change on completed items — same font weight, color, and style as unchecked items
- Only the checkbox icon itself changes (empty circle vs filled checkmark)
- Task item text is plain text only — no inline formatting (bold, code, links) within task items
- No visual grouping or background for consecutive task items — they're just list items with checkboxes

**Nested task lists:**
- Same checkbox style at all nesting levels (no size or icon variation by depth)
- Follow GFM spec: each item renders by its own syntax, not determined by parent type
- A regular bullet parent can have task sub-items and vice versa
- Indentation only for hierarchy — no connecting lines or tree-view guides

**Alignment & spacing:**
- Checkboxes baseline-aligned with the text of their list item
- Tight gap (2-3pt) between checkbox and text
- Same vertical spacing between task items as regular list items — uniform list appearance
- Long text wraps with indent, aligning to the first line of text (not to the checkbox)

### Claude's Discretion

- Nesting depth limit (reasonable cap vs unlimited)
- Exact checkbox point size relative to font size
- How `- [ ]` / `- [x]` inside code blocks is excluded from checkbox conversion (implementation detail)

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

</user_constraints>

## Standard Stack

The established libraries/tools for this phase:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| swift-markdown | 0.7.x | Parse GFM task lists in AST | Already in project, cmark-gfm backend, provides `ListItem.checkbox` property |
| NSTextAttachment | macOS 10.0+ | Embed SF Symbol checkboxes in text | Apple's native inline image/object embedding for NSAttributedString |
| NSImage.systemSymbolName | macOS 11.0+ | Load SF Symbols (circle, checkmark.circle.fill) | macOS-native vector symbols that scale with font size |
| NSImage.SymbolConfiguration | macOS 11.0+ | Configure SF Symbol size/color/weight | Ensures symbols match font metrics and use system accent color |
| NSParagraphStyle | Foundation | Hanging indent for wrapped text | firstLineHeadIndent/headIndent align wrapped text to first line, not checkbox |
| MarkupVisitor protocol | swift-markdown | Traverse markdown AST to find task items | Pattern already used in Phase 13 for table extraction |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSAttributedString.Key.baselineOffset | Foundation | Fine-tune vertical alignment of checkbox | Adjust SF Symbol attachment to sit on text baseline |
| NSColor.controlAccentColor | macOS 10.14+ | System accent blue for checkboxes | User's chosen accent color (default blue) for native feel |
| ListItem.checkbox | swift-markdown | Enum with .checked/.unchecked cases | Detect task list items and their completion state |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NSTextAttachment | Unicode checkbox characters (☐ ☑) | Font-dependent rendering, poor scaling, not native feel |
| MarkupVisitor | Regex detection of `- [ ]` syntax | Fragile, doesn't handle nested lists, swift-markdown already parses |
| SF Symbols | Custom PNG/PDF images | No automatic scaling, no dark mode support, larger bundle size |
| System accent blue | Hardcoded blue color | Ignores user preferences, not accessible |

**Installation:**
```swift
// No additional dependencies - swift-markdown already in project
// NSTextAttachment, SF Symbols are native AppKit (macOS 11.0+)
import Markdown  // swift-markdown
import AppKit    // NSTextAttachment, NSImage, NSColor
```

## Architecture Patterns

### Recommended Project Structure
```
MDQuickLook Extension/
├── MarkdownRenderer.swift       # Extend with task list detection
├── TaskListExtractor.swift      # NEW: MarkupVisitor for task items (optional - may inline)
└── TableExtractor.swift         # Existing pattern to follow
```

### Pattern 1: MarkupVisitor for Task List Detection
**What:** Walk swift-markdown AST to find ListItem nodes with non-nil `checkbox` property
**When to use:** Always - task list items require checkbox insertion before text
**Example:**
```swift
// Source: swift-markdown ListItem.checkbox API + HTMLFormatter reference
// https://github.com/swiftlang/swift-markdown/blob/main/Sources/Markdown/Walker/Walkers/HTMLFormatter.swift
import Markdown

struct TaskListExtractor: MarkupVisitor {
    typealias Result = [TaskListItem]

    struct TaskListItem {
        let checkbox: ListItem.Checkbox  // .checked or .unchecked
        let textContent: String
        let ordinal: Int                  // For list item ordering
        let sourceRange: SourceRange?
    }

    mutating func defaultVisit(_ markup: Markup) -> [TaskListItem] {
        var items: [TaskListItem] = []
        for child in markup.children {
            items.append(contentsOf: visit(child))
        }
        return items
    }

    mutating func visitListItem(_ listItem: ListItem) -> [TaskListItem] {
        // Check if this is a task list item (checkbox is optional)
        guard let checkbox = listItem.checkbox else {
            // Regular list item, not a task
            return []
        }

        // Extract text content from list item children
        let textContent = listItem.plainText.trimmingCharacters(in: .whitespacesAndNewlines)

        let item = TaskListItem(
            checkbox: checkbox,
            textContent: textContent,
            ordinal: /* extract ordinal from parent list context */,
            sourceRange: listItem.range
        )

        return [item]
    }
}
```

### Pattern 2: SF Symbol NSTextAttachment with Baseline Alignment
**What:** Create NSTextAttachment with SF Symbol image, sized to match font, aligned to baseline
**When to use:** For every task list item detected in AST
**Example:**
```swift
// Source: NSTextAttachment + SF Symbols best practices
// Baseline alignment: https://petehare.com/inline-nstextattachment-rendering-in-uitextview/
// SF Symbol configuration: https://www.hackingwithswift.com/articles/237/complete-guide-to-sf-symbols

func createCheckboxAttachment(checked: Bool, fontSize: CGFloat) -> NSTextAttachment {
    let attachment = NSTextAttachment()

    // Choose SF Symbol based on checkbox state
    let symbolName = checked ? "checkmark.circle.fill" : "circle"

    // Configure symbol with system accent color and font-matched size
    let config = NSImage.SymbolConfiguration(
        pointSize: fontSize,  // Match current body font size
        weight: .regular
    )
    .applying(.init(hierarchicalColor: .controlAccentColor))

    if let symbolImage = NSImage(systemSymbolName: symbolName, accessibilityDescription: checked ? "Checked" : "Unchecked") {
        attachment.image = symbolImage.withSymbolConfiguration(config)
    }

    // Baseline alignment: negative y offset moves symbol down to sit on baseline
    // Font metrics: calculate offset using font.capHeight and symbol bounds
    let yOffset = (fontSize - fontSize * 0.8) / 2  // Approximate centering on cap height
    attachment.bounds = CGRect(x: 0, y: -yOffset, width: fontSize, height: fontSize)

    return attachment
}
```

### Pattern 3: Hanging Indent for Text Wrapping
**What:** Use NSParagraphStyle to indent wrapped text so it aligns with first line, not checkbox
**When to use:** For all task list items (same as existing list item handling)
**Example:**
```swift
// Source: NSParagraphStyle headIndent pattern from MarkdownRenderer.applyListItemAttributes
// Existing code at line 747-765 of MarkdownRenderer.swift

func applyTaskListItemAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange, widthTier: WidthTier) {
    // Create paragraph style with hanging indent (tier-aware)
    let paragraphStyle = NSMutableParagraphStyle()

    if widthTier == .narrow {
        // Checkbox (10pt) + gap (2pt) = 12pt indent for wrapped lines
        paragraphStyle.firstLineHeadIndent = 10  // Indent for checkbox
        paragraphStyle.headIndent = 22           // Indent for wrapped text (checkbox + gap + space)
        paragraphStyle.paragraphSpacing = 0     // Same as regular list items
        paragraphStyle.lineSpacing = 1          // Small spacing for wrapped lines
    } else {
        // Checkbox (14pt) + gap (3pt) = 17pt indent for wrapped lines
        paragraphStyle.firstLineHeadIndent = 20  // Indent for checkbox
        paragraphStyle.headIndent = 37           // Indent for wrapped text
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.lineSpacing = 2
    }

    nsAttributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
}
```

### Pattern 4: Mixed List Handling
**What:** Render regular bullets for non-task items, checkboxes for task items in same list
**When to use:** Always - GFM allows mixing task and regular items arbitrarily
**Example:**
```swift
// Source: GFM spec allows mixed lists
// Each ListItem renders independently based on checkbox property

func insertListPrefix(from listItem: ListItem, ordinal: Int, isOrdered: Bool) -> NSAttributedString {
    if let checkbox = listItem.checkbox {
        // Task list item - insert checkbox attachment
        let attachment = createCheckboxAttachment(checked: checkbox == .checked, fontSize: currentBodyFontSize)
        let checkboxString = NSMutableAttributedString(attachment: attachment)
        checkboxString.append(NSAttributedString(string: " "))  // 2-3pt gap after checkbox
        return checkboxString
    } else if isOrdered {
        // Regular ordered list item - insert number
        return NSAttributedString(string: "\(ordinal). ")
    } else {
        // Regular unordered list item - insert bullet
        return NSAttributedString(string: "• ")
    }
}
```

### Anti-Patterns to Avoid

- **Modifying text content of checked items:** User decision specifies NO text changes - only checkbox icon changes
- **Using foregroundColor attribute for checkbox:** SF Symbol tint must use SymbolConfiguration with hierarchicalColor, not attributed string color
- **Hardcoding checkbox size:** Must scale with font size across width tiers (narrow mode uses smaller fonts)
- **Center-aligning checkbox to line height:** User specifies baseline alignment, not vertical center
- **Adding checkbox prefix to code block content:** swift-markdown AST prevents this - CodeBlock nodes don't contain ListItem children

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Parse task list syntax | Regex for `- [ ]` and `- [x]` | swift-markdown ListItem.checkbox | Handles edge cases (nested lists, mixed lists, indentation), already in project |
| Checkbox symbols | Unicode ☐/☑ characters | SF Symbols (circle, checkmark.circle.fill) | SF Symbols scale with font, support dark mode, match system design language |
| Baseline alignment calculation | Hardcoded y offset values | Font metrics (capHeight, descender) | Breaks with dynamic type, different fonts, width tiers |
| Exclude code blocks from conversion | Preprocessing regex to protect code blocks | swift-markdown AST structure (CodeBlock nodes) | AST naturally separates code from list items - no special handling needed |
| System accent color | `NSColor.systemBlue` hardcoded | `NSColor.controlAccentColor` | Respects user's accent color preference in System Settings |

**Key insight:** swift-markdown's AST structure already provides everything needed - ListItem.checkbox for detection, AST hierarchy prevents code block conflicts, plainText extraction for content. Don't reparse markdown with regex.

## Common Pitfalls

### Pitfall 1: NSTextAttachment Not Aligned to Baseline
**What goes wrong:** Checkbox appears vertically centered on line height instead of aligned with text baseline, causing visual misalignment
**Why it happens:** NSTextAttachment.bounds defaults to (0,0,0,0) which centers attachment, not aligning to baseline
**How to avoid:** Set attachment.bounds with negative y offset calculated from font metrics (capHeight or descender)
**Warning signs:** Checkbox looks too high or too low relative to adjacent text, especially noticeable with larger font sizes

### Pitfall 2: Checkbox Color Doesn't Respect System Accent
**What goes wrong:** Checkboxes render in default tint (often black) instead of system accent blue
**Why it happens:** Using NSAttributedString.Key.foregroundColor on attachment doesn't affect SF Symbol tint - must use NSImage.SymbolConfiguration
**How to avoid:** Apply `.applying(.init(hierarchicalColor: .controlAccentColor))` to SymbolConfiguration before creating image
**Warning signs:** Checkboxes stay black/gray in light mode, don't change when user switches accent color in System Settings

### Pitfall 3: Wrapped Text Aligns Under Checkbox Instead of First Line
**What goes wrong:** Long task item text wraps to align under the checkbox, not under the first word of text
**Why it happens:** NSParagraphStyle.headIndent not set, or set equal to firstLineHeadIndent
**How to avoid:** Set headIndent > firstLineHeadIndent by (checkbox width + gap width) to create hanging indent
**Warning signs:** Multi-line task items look indented twice, text doesn't form clean left edge after checkbox

### Pitfall 4: Checkbox Size Doesn't Scale with Width Tier
**What goes wrong:** Checkboxes stay large in narrow mode (Finder preview pane) where fonts shrink to 12pt
**Why it happens:** Hardcoding checkbox pointSize instead of using currentBodyFontSize variable
**How to avoid:** Pass currentBodyFontSize (tier-aware) to NSImage.SymbolConfiguration pointSize parameter
**Warning signs:** Checkboxes look oversized in Finder preview pane, don't match adjacent text size

### Pitfall 5: Code Block Task Syntax Converted to Checkboxes
**What goes wrong:** Markdown like `` ```- [ ] task``` `` renders with checkbox instead of literal text
**Why it happens:** Preprocessing markdown with regex before AST parsing, treating all `- [ ]` as task items
**How to avoid:** Use swift-markdown AST exclusively - CodeBlock nodes contain Text children, not ListItem children, so MarkupVisitor never encounters task syntax in code blocks
**Warning signs:** Code examples showing task list syntax render with actual checkboxes

### Pitfall 6: Mixed Lists Break - All Bullets or All Checkboxes
**What goes wrong:** List with both `- item` and `- [ ] task` renders all items with same prefix (all bullets or all checkboxes)
**Why it happens:** Checking list type (ordered/unordered) instead of individual item's checkbox property
**How to avoid:** Check `listItem.checkbox != nil` for EACH item independently, not at list level
**Warning signs:** Regular list items in task list show checkboxes, or task items show bullets

## Code Examples

Verified patterns from swift-markdown and AppKit best practices:

### Detecting Task List Items in AST
```swift
// Source: swift-markdown ListItem.checkbox API
// https://github.com/swiftlang/swift-markdown/blob/main/Sources/Markdown/Walker/Walkers/HTMLFormatter.swift

import Markdown

// Inside MarkupVisitor or render pipeline
for listItem in document.children.compactMap({ $0 as? ListItem }) {
    if let checkbox = listItem.checkbox {
        // This is a task list item
        let isChecked = (checkbox == .checked)  // .checked or .unchecked
        let text = listItem.plainText

        // Insert checkbox attachment before text
        insertCheckbox(checked: isChecked, beforeText: text)
    } else {
        // Regular list item - insert bullet or number
        insertRegularBullet()
    }
}
```

### Creating SF Symbol Checkbox with System Accent Color
```swift
// Source: NSImage.SymbolConfiguration + NSTextAttachment best practices
// Color: https://www.hackingwithswift.com/articles/237/complete-guide-to-sf-symbols
// Baseline: https://petehare.com/inline-nstextattachment-rendering-in-uitextview/

func checkboxAttachment(checked: Bool, fontSize: CGFloat) -> NSTextAttachment {
    let attachment = NSTextAttachment()

    // SF Symbol names per user decision
    let symbolName = checked ? "checkmark.circle.fill" : "circle"

    // Configure symbol: size matches font, color is system accent
    let config = NSImage.SymbolConfiguration(pointSize: fontSize, weight: .regular)
        .applying(.init(hierarchicalColor: .controlAccentColor))  // System accent blue

    if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: checked ? "Completed task" : "Incomplete task") {
        attachment.image = image.withSymbolConfiguration(config)
    }

    // Baseline alignment: y offset positions symbol on text baseline
    // Formula: negative y = (fontSize - symbol visual height) / 2
    let yOffset = fontSize * 0.15  // Approximate for circular symbols
    attachment.bounds = CGRect(x: 0, y: -yOffset, width: fontSize, height: fontSize)

    return attachment
}
```

### Hanging Indent for Wrapped Text
```swift
// Source: Existing MarkdownRenderer.applyListItemAttributes pattern (line 747-765)
// Extended for task list checkbox width

func paragraphStyleForTaskItem(widthTier: WidthTier, checkboxSize: CGFloat) -> NSParagraphStyle {
    let style = NSMutableParagraphStyle()

    if widthTier == .narrow {
        let gap: CGFloat = 2  // Tight gap per user decision
        style.firstLineHeadIndent = 10                    // Checkbox left margin
        style.headIndent = 10 + checkboxSize + gap        // Wrapped text aligns after checkbox
        style.paragraphSpacing = 0                        // Same as regular lists
        style.lineSpacing = 1
    } else {
        let gap: CGFloat = 3
        style.firstLineHeadIndent = 20
        style.headIndent = 20 + checkboxSize + gap
        style.paragraphSpacing = 0
        style.lineSpacing = 2
    }

    return style
}
```

### Mixed List Rendering
```swift
// Source: GFM spec - each ListItem independent
// Example markdown:
// - Regular item
// - [ ] Unchecked task
// - [x] Checked task
// - Another regular item

func renderListItem(_ listItem: ListItem, ordinal: Int, isOrdered: Bool) -> NSAttributedString {
    let result = NSMutableAttributedString()

    // Check for task list checkbox FIRST
    if let checkbox = listItem.checkbox {
        // Task list item - use checkbox
        let attachment = checkboxAttachment(checked: checkbox == .checked, fontSize: currentBodyFontSize)
        result.append(NSAttributedString(attachment: attachment))
        result.append(NSAttributedString(string: " "))  // Gap
    } else if isOrdered {
        // Regular ordered item - use number
        result.append(NSAttributedString(string: "\(ordinal). "))
    } else {
        // Regular unordered item - use bullet
        result.append(NSAttributedString(string: "• "))
    }

    // Append text content (same for all item types)
    result.append(NSAttributedString(string: listItem.plainText))

    return result
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Unicode checkbox chars (☐ ☑) | SF Symbols (circle, checkmark.circle.fill) | macOS 11.0 (2020) | Native look, perfect scaling, dark mode support |
| Hardcoded blue color | `NSColor.controlAccentColor` | macOS 10.14 (2018) | Respects user's accent color preference |
| Regex parsing `- [ ]` syntax | swift-markdown ListItem.checkbox | swift-markdown 0.1.0 (2021) | Handles nested lists, mixed lists, edge cases |
| Manual baseline calculation | Font metrics (capHeight/descender) | Best practice (ongoing) | Scales with dynamic type, different fonts |
| Text rendering for checkboxes | NSTextAttachment with SF Symbols | macOS 11.0+ (2020) | Inline images scale with text, no font dependencies |

**Deprecated/outdated:**
- **Unicode checkboxes (☐ ☑):** Font-dependent rendering, poor scaling, not native macOS design language
- **Custom checkbox images (PNG/PDF):** Don't scale automatically, no dark mode, larger bundle size
- **Regex-based task list detection:** Fragile, doesn't handle nested/mixed lists, swift-markdown AST is authoritative
- **`NSColor.systemBlue` for checkboxes:** Ignores user accent color preference (should use `.controlAccentColor`)

## Open Questions

Things that couldn't be fully resolved:

1. **Nesting depth limit for task lists**
   - What we know: swift-markdown parses unlimited nesting depth, GFM spec doesn't impose limits
   - What's unclear: Whether deeply nested task lists (>5 levels) cause rendering issues or readability problems
   - Recommendation: No artificial limit - render as parsed. If issues arise, cap at 10 levels (same as regular lists in typical markdown renderers)

2. **Exact checkbox point size relative to font size**
   - What we know: SF Symbol pointSize should match font size for baseline alignment, but visual balance may differ
   - What's unclear: Whether checkbox should be exactly fontSize or slightly smaller (0.9x, 0.95x) for better visual weight
   - Recommendation: Start with 1:1 ratio (pointSize = fontSize), adjust down to 0.9x if checkboxes feel too large. User decision says "scales with font size" which supports proportional sizing.

3. **Checkbox accessibility labels**
   - What we know: NSImage.systemSymbolName accepts accessibilityDescription parameter
   - What's unclear: Best practice for task item accessibility (just checkbox state, or include item text?)
   - Recommendation: Use "Checked" / "Unchecked" for checkbox attachment, rely on text content being readable separately

## Sources

### Primary (HIGH confidence)
- [swift-markdown ListItem.checkbox documentation](https://swiftinit.org/docs/swift-markdown/markdown/listitem.checkbox) - Checkbox enum API
- [swift-markdown HTMLFormatter source code](https://github.com/swiftlang/swift-markdown/blob/main/Sources/Markdown/Walker/Walkers/HTMLFormatter.swift) - Reference implementation showing `.checked` / `.unchecked` usage
- [GitHub cmark-gfm task list extension](https://github.com/github/cmark-gfm/issues/23) - Task list parsing specification
- [Apple NSTextAttachment documentation](https://developer.apple.com/documentation/uikit/nstextattachment) - Attachment API
- [Apple SF Symbols guidelines](https://developer.apple.com/design/human-interface-guidelines/sf-symbols) - Symbol usage best practices

### Secondary (MEDIUM confidence)
- [NSTextAttachment baseline alignment techniques](https://petehare.com/inline-nstextattachment-rendering-in-uitextview/) - Practical bounds adjustment patterns
- [SF Symbols complete guide](https://www.hackingwithswift.com/articles/237/complete-guide-to-sf-symbols) - SymbolConfiguration and color application
- [GFM task list specification](https://github.blog/news-insights/product-news/task-lists-in-gfm-issues-pulls-comments/) - Official GitHub blog post on task list syntax
- [NSParagraphStyle headIndent documentation](https://developer.apple.com/documentation/appkit/nsparagraphstyle/firstlineheadindent) - Hanging indent API

### Tertiary (LOW confidence)
- [GFM mixed list examples](https://github.com/syntax-tree/mdast-util-gfm-task-list-item) - Community documentation on mixed task/regular lists (confirms GFM supports mixing)
- [markdown-it task list plugin](https://github.com/hedgedoc/markdown-it-better-task-lists) - Alternative parser showing common patterns (not directly applicable but confirms approach)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - swift-markdown ListItem.checkbox confirmed in source code, NSTextAttachment/SF Symbols are Apple native APIs
- Architecture: HIGH - MarkupVisitor pattern already proven in Phase 13 (TableExtractor), NSTextAttachment baseline alignment well-documented
- Pitfalls: HIGH - Font metrics, SymbolConfiguration color, hanging indent all verified in Apple docs and best practice articles
- Code examples: HIGH - HTMLFormatter source code shows exact ListItem.checkbox usage, NSTextAttachment patterns from Apple docs

**Research date:** 2026-02-07
**Valid until:** ~30 days (stable APIs - swift-markdown 0.7.x, AppKit NSTextAttachment mature since macOS 10.0, SF Symbols stable since macOS 11.0)
