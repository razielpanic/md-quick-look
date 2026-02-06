# Phase 11: YAML Front Matter - Research

**Researched:** 2026-02-06
**Domain:** YAML front matter parsing and display in markdown previews
**Confidence:** HIGH

## Summary

YAML front matter is a metadata block enclosed by `---` delimiters at the start of markdown files, popularized by Jekyll and used extensively by static site generators (Hugo, Astro, Gatsby), note-taking tools (Obsidian, Logseq), and CMS platforms. The standard approach is to detect and strip the YAML block before markdown parsing, then display the metadata as a visually distinct section above the rendered body.

The research confirms that swift-markdown does NOT natively support YAML front matter (it parses `---` as ThematicBreak and garbled headings). The recommended pattern is manual extraction via regex, followed by lightweight parsing for display purposes. Full YAML parsing libraries like Yams (6.2.1) are available but overkill for display-only use cases, especially given they add LibYAML C dependencies.

For this Quick Look extension, the preprocessing approach fits perfectly into the existing architecture: add a `preprocessYAMLFrontMatter()` function before `preprocessImages()`, extract key-value pairs with basic parsing, render them as styled NSAttributedString above the body, and ensure visual distinction using semantic NSColor values that adapt to light/dark mode.

**Primary recommendation:** Implement manual YAML front matter detection and extraction via regex in preprocessing, parse key-value pairs with basic string operations (no external YAML library), render as styled NSAttributedString section with multi-column layout support, and use semantic NSColor for dark mode compatibility.

## User Constraints (from CONTEXT.md)

### Locked Decisions

**Visual presentation:**
- Separation style between front matter and body: Claude's discretion (bordered card, divider, or other approach)
- Section label (e.g., "Front Matter" header): Claude's discretion
- MUST adapt styling to system appearance (light mode and dark mode) with appropriate background/border colors for each
- Layout should condense intelligently — use multi-column layout for key-value pairs when space allows, so files with many keys don't consume excessive vertical space

**Key-value formatting:**
- List values (e.g., `tags: [a, b, c]`): Claude's discretion on inline comma-separated vs pill/badge style
- Key vs value styling: Claude's discretion on bold keys, muted keys, etc.
- Date values: display as-is from YAML (no conversion to human-readable format)
- Boolean values: plain text (true/false), no color coding or special treatment

### Claude's Discretion

- Exact separation style (bordered card, divider line, background tint, etc.)
- Whether to include a section header/label for the metadata block
- Key styling approach (bold, muted, colored, etc.)
- List value presentation style (comma-separated vs badges)
- Multi-column layout breakpoints and column count
- Edge case handling: empty front matter, missing closing delimiter, malformed YAML

### Specific Ideas from Discussion

- Multi-column layout for front matter keys when space permits — don't force everything into a single column when there are many short key-value pairs
- Values should be shown exactly as authored in the YAML (dates, booleans) — this is a preview, not a reformatter

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope

## Standard Stack

The established approach for YAML front matter in Swift/macOS contexts:

### Core: Manual Detection + Lightweight Parsing

| Approach | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Regex detection | NSRegularExpression | Detect and extract `---` delimited blocks | swift-markdown doesn't support front matter natively; manual extraction is the recommended workaround |
| String parsing | Swift stdlib | Parse key-value pairs for display | Full YAML parser overkill for display-only use case; basic string operations handle 90% of front matter |
| Preprocessing pattern | Current architecture | Strip front matter before markdown parsing | Matches existing `preprocessImages()` and `preprocessBlockquoteSoftBreaks()` pattern |

**Why no Yams library:**
Requirements explicitly exclude full YAML parsing (REQUIREMENTS.md line 72: "Full YAML parser (Yams): Overkill for display-only; adds C dependency"). For display-only rendering, basic key-value extraction via string parsing is sufficient and avoids LibYAML C dependency.

### Supporting: Display Architecture

| Component | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSAttributedString | macOS SDK | Render styled front matter section | All text rendering in this codebase uses NSAttributedString |
| Custom attribute keys | Extension pattern | Mark front matter ranges for special handling | Existing pattern: `.blockquoteMarker`, `.codeBlockMarker` |
| Semantic NSColor | macOS SDK | Dark mode compatible colors | `.secondarySystemFill`, `.tertiarySystemFill`, `.labelColor`, `.secondaryLabelColor` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual regex extraction | Yams library (6.2.1) | Yams is full-featured YAML parser with Codable support, but adds LibYAML C dependency and is overkill for display-only rendering. User requirement explicitly excludes this. |
| Basic string parsing | YAMLDecoder with Codable | Proper parsing but requires defining structs for metadata, unnecessary complexity for display-only |
| Prepend front matter section | Custom rendering in MarkdownLayoutManager | Could use custom drawing, but NSAttributedString composition is simpler and more maintainable |

**Installation (if Yams were needed):**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/jpsim/Yams.git", from: "6.2.1")
]
```

## Architecture Patterns

### Recommended Project Structure

No new files needed — add to existing MarkdownRenderer.swift:

```
MDQuickLook Extension/
├── MarkdownRenderer.swift        # Add preprocessYAMLFrontMatter() method
├── MarkdownLayoutManager.swift   # Potentially add custom drawing if needed
└── PreviewViewController.swift   # No changes (renderer handles everything)
```

### Pattern 1: Preprocessing Pipeline

**What:** Front matter extraction happens in preprocessing phase, before swift-markdown parsing

**When to use:** Always — front matter must be stripped before markdown parsing to prevent `---` being parsed as horizontal rules

**Example:**
```swift
// Source: Existing MarkdownRenderer.swift architecture
func render(markdown: String) -> NSAttributedString {
    os_log("MarkdownRenderer: Starting render, input length: %d", log: .renderer, type: .info, markdown.count)

    // Pre-process markdown (NEW: YAML front matter FIRST)
    let (frontMatter, bodyMarkdown) = extractYAMLFrontMatter(from: markdown)
    let preprocessedBody = preprocessBlockquoteSoftBreaks(in: preprocessImages(in: bodyMarkdown))

    // ... existing rendering logic for body ...

    // If front matter exists, prepend styled section
    if !frontMatter.isEmpty {
        let frontMatterSection = renderFrontMatter(frontMatter)
        result.insert(frontMatterSection, at: 0)
    }

    return result
}
```

**Critical ordering:** YAML front matter must be extracted FIRST, before any other preprocessing. Other preprocessors like `preprocessImages()` operate on the markdown body and shouldn't see the front matter block.

### Pattern 2: Regex Detection with Edge Cases

**What:** Detect `---` delimited blocks at file start with robust edge case handling

**When to use:** For detecting and extracting YAML front matter

**Example:**
```swift
// Pattern based on gray-matter (battle-tested in Gatsby, Netlify, Astro, etc.)
private func extractYAMLFrontMatter(from markdown: String) -> ([String: String], String) {
    // Pattern explanation:
    // ^---\n          : Opening delimiter (must be at start)
    // (.+?)           : Capture group for YAML content (non-greedy)
    // \n---\n         : Closing delimiter (with newlines)
    // (.*)            : Remaining markdown body

    let pattern = "^---\\n(.+?)\\n---\\n(.*)"
    let options: NSRegularExpression.Options = [.dotMatchesLineSeparators]

    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        return ([:], markdown)  // Regex failed, return original
    }

    let nsString = markdown as NSString
    guard let match = regex.firstMatch(in: markdown, range: NSRange(location: 0, length: nsString.length)),
          match.numberOfRanges >= 3 else {
        return ([:], markdown)  // No front matter found
    }

    let yamlRange = match.range(at: 1)
    let bodyRange = match.range(at: 2)

    let yamlContent = nsString.substring(with: yamlRange)
    let bodyContent = nsString.substring(with: bodyRange)

    // Parse YAML content into key-value pairs
    let frontMatter = parseYAMLKeyValues(yamlContent)

    return (frontMatter, bodyContent)
}
```

**Edge cases handled:**
- Empty front matter block (`---\n---`) → Returns empty dictionary, not an error
- Missing closing delimiter → No match, returns original markdown
- Windows line endings (`\r\n`) → Handle by normalizing to `\n` before regex
- Front matter not at file start → No match (pattern requires `^`)

### Pattern 3: Lightweight Key-Value Parsing

**What:** Parse YAML key-value pairs using string operations, not full YAML parser

**When to use:** For display-only rendering where 90% of front matter is simple `key: value` pairs

**Example:**
```swift
private func parseYAMLKeyValues(_ yaml: String) -> [String: String] {
    var result: [String: String] = [:]
    let lines = yaml.components(separatedBy: "\n")

    for line in lines {
        // Match "key: value" pattern
        guard let colonIndex = line.firstIndex(of: ":") else { continue }

        let key = line[..<colonIndex].trimmingCharacters(in: .whitespaces)
        let value = line[line.index(after: colonIndex)...].trimmingCharacters(in: .whitespaces)

        guard !key.isEmpty else { continue }

        // Handle list values: tags: [a, b, c] or tags: ["a", "b", "c"]
        let displayValue: String
        if value.hasPrefix("[") && value.hasSuffix("]") {
            // Remove brackets, split by comma, trim, join
            let listContent = value.dropFirst().dropLast()
            let items = listContent.components(separatedBy: ",").map { item in
                item.trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
            displayValue = items.joined(separator: ", ")
        } else {
            // Regular value: show as-is (dates, booleans, strings)
            displayValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }

        result[key] = displayValue
    }

    return result
}
```

**What this doesn't handle (acceptable for display-only):**
- Nested YAML structures (rare in front matter, show raw text fallback)
- Multi-line string values (unusual in front matter)
- YAML anchors/references (almost never in front matter)

**What this does handle (covers 90% of real-world front matter):**
- Simple key-value pairs: `title: Hello World`
- Dates: `date: 2024-01-15` (shown as-is)
- Booleans: `published: true` (shown as text)
- Lists: `tags: [markdown, yaml, swift]` (shown comma-separated)
- Quoted strings: `description: "A cool thing"` (quotes stripped)

### Pattern 4: Multi-Column Layout with NSTextContainer

**What:** Use multiple NSTextContainer instances for side-by-side key-value rendering

**When to use:** When front matter has many keys and horizontal space permits

**Example:**
```swift
// Based on iOS7 Day-by-Day multi-column TextKit pattern
// Source: https://github.com/ScottLogic/iOS7-day-by-day/blob/master/21-multi-column-textkit/21-multi-column-textkit.md

private func renderFrontMatterMultiColumn(_ frontMatter: [String: String], availableWidth: CGFloat) -> NSAttributedString {
    let columnCount = availableWidth > 600 ? 2 : 1  // Breakpoint: 2 columns if wide enough
    let columnWidth = (availableWidth - 40) / CGFloat(columnCount)  // Account for padding

    // Create text storage with front matter content
    let textStorage = NSTextStorage()
    let layoutManager = NSLayoutManager()
    textStorage.addLayoutManager(layoutManager)

    // Create multiple text containers for columns
    for _ in 0..<columnCount {
        let container = NSTextContainer(size: CGSize(width: columnWidth, height: CGFloat.greatestFiniteMagnitude))
        layoutManager.addTextContainer(container)
    }

    // Build attributed string with key-value pairs
    let result = NSMutableAttributedString()
    for (key, value) in frontMatter.sorted(by: { $0.key < $1.key }) {
        let line = "\(key): \(value)\n"
        let attributed = NSMutableAttributedString(string: line)

        // Style key (bold) vs value (regular)
        let colonRange = (line as NSString).range(of: ":")
        attributed.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: NSRange(location: 0, length: colonRange.location))
        attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 13), range: NSRange(location: colonRange.location, length: line.count - colonRange.location))

        result.append(attributed)
    }

    textStorage.setAttributedString(result)

    // Force layout and extract result
    layoutManager.ensureLayout(for: layoutManager.textContainers[0])
    return textStorage.attributedSubstring(from: NSRange(location: 0, length: textStorage.length))
}
```

**Note:** For Quick Look extension with single NSTextView, multi-column rendering via NSTextContainer may be complex. Simpler alternative is CSS grid-like layout using paragraph styles and tab stops.

**Simpler alternative using tab stops:**
```swift
private func renderFrontMatterColumns(_ frontMatter: [String: String], availableWidth: CGFloat) -> NSAttributedString {
    let result = NSMutableAttributedString()
    let useColumns = availableWidth > 600

    let paragraphStyle = NSMutableParagraphStyle()
    if useColumns {
        paragraphStyle.tabStops = [NSTextTab(textAlignment: .left, location: availableWidth / 2)]
    }
    paragraphStyle.paragraphSpacing = 4

    let sorted = frontMatter.sorted(by: { $0.key < $1.key })
    for (index, (key, value)) in sorted.enumerated() {
        let line: String
        if useColumns && index % 2 == 0 && index + 1 < sorted.count {
            // Two columns: "key1: value1\tkey2: value2\n"
            let nextPair = sorted[index + 1]
            line = "\(key): \(value)\t\(nextPair.key): \(nextPair.value)\n"
        } else if useColumns && index % 2 == 1 {
            // Skip (already processed in previous iteration)
            continue
        } else {
            // Single column: "key: value\n"
            line = "\(key): \(value)\n"
        }

        let attributed = NSMutableAttributedString(string: line)
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: line.count))
        result.append(attributed)
    }

    return result
}
```

### Pattern 5: Visual Separation with Semantic Colors

**What:** Use semantic NSColor values for backgrounds, borders, and text that adapt to light/dark mode

**When to use:** Always — Quick Look must respect system appearance

**Example:**
```swift
// Source: Apple Developer Documentation - UI Element Colors
// https://developer.apple.com/documentation/appkit/nscolor/ui_element_colors

private func renderFrontMatter(_ frontMatter: [String: String]) -> NSAttributedString {
    let result = NSMutableAttributedString()

    // Section header (optional, per user's discretion)
    let header = NSAttributedString(
        string: "Front Matter\n",
        attributes: [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor  // Adapts to dark mode
        ]
    )
    result.append(header)

    // Key-value pairs with styled background
    for (key, value) in frontMatter.sorted(by: { $0.key < $1.key }) {
        let line = "\(key): \(value)\n"
        let attributed = NSMutableAttributedString(string: line)

        // Bold keys, regular values
        let colonIndex = line.firstIndex(of: ":")!
        let colonLocation = line.distance(from: line.startIndex, to: colonIndex)

        attributed.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: NSRange(location: 0, length: colonLocation))
        attributed.addAttribute(.foregroundColor, value: NSColor.labelColor, range: NSRange(location: 0, length: colonLocation))
        attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 13), range: NSRange(location: colonLocation, length: line.count - colonLocation))
        attributed.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSRange(location: colonLocation, length: line.count - colonLocation))

        result.append(attributed)
    }

    // Background for entire front matter section
    let fullRange = NSRange(location: 0, length: result.length)
    result.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: fullRange)  // Light gray in light mode, dark gray in dark mode

    // Paragraph spacing and padding
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 4
    paragraphStyle.headIndent = 10
    paragraphStyle.firstLineHeadIndent = 10
    result.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)

    // Add separator after front matter
    result.append(NSAttributedString(string: "\n\n"))

    return result
}
```

**Semantic colors reference:**
| Color | Purpose | Light Mode | Dark Mode |
|-------|---------|------------|-----------|
| `.labelColor` | Primary text | Black | White |
| `.secondaryLabelColor` | Secondary text (values) | Gray | Light gray |
| `.secondarySystemFill` | Card backgrounds | Light gray | Dark gray |
| `.tertiarySystemFill` | Large backgrounds | Very light gray | Slightly darker gray |
| `.separatorColor` | Divider lines | Light gray | Dark gray |

### Anti-Patterns to Avoid

- **Parsing YAML after markdown parsing:** Front matter delimiters (`---`) will be interpreted as horizontal rules (ThematicBreak), causing garbled output. Always extract front matter BEFORE calling `AttributedString(markdown:)`.

- **Using full YAML parser for display:** Yams and YAMLDecoder are designed for structured data parsing with Codable. For display-only rendering, they add unnecessary complexity and C dependencies. Basic string parsing handles 90% of real-world front matter.

- **Hard-coded colors:** Using `NSColor.gray` or RGB values breaks dark mode. Always use semantic colors like `.secondarySystemFill` that adapt automatically.

- **Assuming all front matter is valid YAML:** Real-world markdown files may have malformed front matter, missing closing delimiters, or no front matter at all. Detection regex must handle these gracefully and fall back to rendering the full file as markdown.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Full YAML parsing | Custom recursive parser | Yams 6.2.1 (if needed) | YAML spec has edge cases (anchors, multi-line strings, references) that are complex to handle. However, for this project, basic parsing is sufficient per requirements. |
| Dark mode color adaptation | Manual light/dark detection | Semantic NSColor (`.secondarySystemFill`, etc.) | macOS handles appearance changes automatically; semantic colors update when system appearance changes. Manual detection is fragile and incomplete. |
| Multi-line value handling | String splitting with state machine | YAML library (if complex values needed) | Multi-line YAML values have multiple syntaxes (`|`, `>`, quotes). For display-only, showing raw text is acceptable fallback. |

**Key insight:** YAML front matter in markdown is usually simple key-value pairs. The 10% of complex cases (nested objects, multi-line values) can gracefully degrade to "show raw text" without impacting the 90% common case. Full YAML parsing is unnecessary overhead for a preview tool.

## Common Pitfalls

### Pitfall 1: Front Matter Detection Regex Missing Edge Cases

**What goes wrong:** Regex matches `---` delimiters in middle of document, or fails on Windows line endings, causing incorrect extraction or crashes.

**Why it happens:** Simple regex like `---\n(.+?)\n---` doesn't anchor to start of file (`^`) and doesn't handle `\r\n`.

**How to avoid:**
- Use `^---\n` to require front matter at file start
- Normalize line endings to `\n` before regex: `markdown.replacingOccurrences(of: "\r\n", with: "\n")`
- Use `.dotMatchesLineSeparators` option for multi-line matching
- Test with edge cases: empty front matter, no closing delimiter, front matter in code block

**Warning signs:**
- Preview shows horizontal rules at top of document (front matter wasn't stripped)
- Crash on files with `---` in markdown body (regex matched wrong block)
- Windows users report broken rendering (line ending issue)

### Pitfall 2: swift-markdown Parsing Front Matter as ThematicBreak

**What goes wrong:** If front matter isn't stripped before `AttributedString(markdown:)`, the opening `---` is parsed as a horizontal rule (ThematicBreak), and keys become malformed headings.

**Why it happens:** swift-markdown follows CommonMark spec, which doesn't include YAML front matter. `---` is a valid horizontal rule in CommonMark.

**How to avoid:**
- Always extract front matter BEFORE calling `AttributedString(markdown:)`
- Verify extraction with test: file with front matter should not contain `---` after preprocessing
- Order matters: `extractYAMLFrontMatter()` must be first preprocessor

**Warning signs:**
- Horizontal rule appears at top of preview
- Keys like `title: Hello` render as weird headings or broken text
- Issue logged: "Expected front matter not shown, instead see lines at top"

### Pitfall 3: Hard-Coded Colors Break Dark Mode

**What goes wrong:** Front matter section uses `NSColor.lightGray` or RGB values that look good in light mode but are invisible or wrong in dark mode.

**Why it happens:** Developers test only in light mode, unaware that NSColor has semantic values that adapt automatically.

**How to avoid:**
- ALWAYS use semantic colors: `.secondarySystemFill`, `.labelColor`, `.secondaryLabelColor`
- Test in both light and dark mode: System Settings → Appearance → Dark
- Never use RGB values or hard-coded colors for backgrounds or text

**Warning signs:**
- User reports: "Can't read front matter in dark mode"
- Background blends with text in one mode
- Section looks great in light mode but wrong in dark mode

### Pitfall 4: Multi-Column Layout Breaks with Narrow Width

**What goes wrong:** Multi-column layout for key-value pairs looks great in full-screen Quick Look but breaks in Finder preview pane (narrow context), causing clipped text or overlapping columns.

**Why it happens:** Column layout uses fixed width or doesn't check `view.bounds.width`.

**How to avoid:**
- Check available width before choosing column count: `availableWidth > 600 ? 2 : 1`
- Use flexible column widths based on container: `columnWidth = availableWidth / columnCount`
- Test in all Quick Look contexts: spacebar popup, Finder preview pane, full-screen
- Degrade gracefully: single column is always safe fallback

**Warning signs:**
- Text clipped in Finder preview pane
- Columns overlap or extend beyond visible area
- Layout perfect in full-screen but broken in narrow contexts

### Pitfall 5: Empty or Malformed Front Matter Causes Rendering Failure

**What goes wrong:** File with empty front matter block (`---\n---`) or missing closing delimiter causes crash or shows raw markdown including delimiters.

**Why it happens:** Parser assumes well-formed YAML, doesn't handle edge cases gracefully.

**How to avoid:**
- Return empty dictionary for empty front matter (not an error)
- If regex doesn't match (malformed/missing), return original markdown unchanged
- Validate ranges before accessing: check `match.numberOfRanges` and range validity
- Edge case test suite: empty block, no closing delimiter, front matter in code block

**Warning signs:**
- Crash on specific files (edge case not handled)
- Files without front matter show wrong output (regression)
- `---` delimiters visible in preview (parsing failed, fallback didn't work)

## Code Examples

Verified patterns from research and existing codebase architecture:

### YAML Front Matter Preprocessing (Complete Flow)

```swift
// Source: Architecture pattern based on existing preprocessImages() in MarkdownRenderer.swift
// Location: Add to MarkdownRenderer.swift

// MARK: - YAML Front Matter Preprocessing

/// Extracts YAML front matter from markdown and returns both components
/// - Parameter markdown: The raw markdown content
/// - Returns: Tuple of (front matter dictionary, body markdown)
private func extractYAMLFrontMatter(from markdown: String) -> ([String: String], String) {
    // Normalize line endings (handle Windows \r\n)
    let normalized = markdown.replacingOccurrences(of: "\r\n", with: "\n")

    // Pattern: opening ---, YAML content, closing ---, remaining body
    // ^---\n: Must start at beginning of file
    // (.+?): Capture YAML content (non-greedy)
    // \n---\n: Closing delimiter with newlines
    // (.*): Remaining markdown body
    let pattern = "^---\\n(.+?)\\n---\\n(.*)"
    let options: NSRegularExpression.Options = [.dotMatchesLineSeparators]

    guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
        os_log("MarkdownRenderer: Failed to create YAML front matter regex", log: .renderer, type: .error)
        return ([:], markdown)
    }

    let nsString = normalized as NSString
    guard let match = regex.firstMatch(in: normalized, range: NSRange(location: 0, length: nsString.length)),
          match.numberOfRanges >= 3 else {
        // No front matter found - this is normal, return original markdown
        return ([:], markdown)
    }

    let yamlRange = match.range(at: 1)
    let bodyRange = match.range(at: 2)

    let yamlContent = nsString.substring(with: yamlRange)
    let bodyContent = nsString.substring(with: bodyRange)

    os_log("MarkdownRenderer: Extracted YAML front matter, %d bytes", log: .renderer, type: .info, yamlContent.count)

    // Parse YAML content into key-value pairs
    let frontMatter = parseYAMLKeyValues(yamlContent)

    return (frontMatter, bodyContent)
}

/// Parses YAML key-value pairs using simple string operations
/// - Parameter yaml: The YAML content (between delimiters)
/// - Returns: Dictionary of key-value pairs
private func parseYAMLKeyValues(_ yaml: String) -> [String: String] {
    var result: [String: String] = [:]
    let lines = yaml.components(separatedBy: "\n")

    for line in lines {
        // Skip empty lines and comments
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty || trimmed.hasPrefix("#") {
            continue
        }

        // Match "key: value" pattern
        guard let colonIndex = trimmed.firstIndex(of: ":") else { continue }

        let key = trimmed[..<colonIndex].trimmingCharacters(in: .whitespaces)
        let valueStart = trimmed.index(after: colonIndex)
        let value = trimmed[valueStart...].trimmingCharacters(in: .whitespaces)

        guard !key.isEmpty else { continue }

        // Handle list values: tags: [a, b, c] or tags: ["a", "b", "c"]
        let displayValue: String
        if value.hasPrefix("[") && value.hasSuffix("]") {
            // Remove brackets, split by comma, trim quotes
            let listContent = value.dropFirst().dropLast()
            let items = listContent.components(separatedBy: ",").map { item in
                item.trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            }
            displayValue = items.joined(separator: ", ")
            os_log("MarkdownRenderer: Parsed list value for key '%{public}s': %{public}s", log: .renderer, type: .debug, key, displayValue)
        } else {
            // Regular value: remove quotes, show as-is (dates, booleans, strings)
            displayValue = value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        }

        result[key] = displayValue
    }

    os_log("MarkdownRenderer: Parsed %d key-value pairs from YAML", log: .renderer, type: .info, result.count)
    return result
}

/// Renders front matter as styled NSAttributedString section
/// - Parameter frontMatter: Dictionary of key-value pairs
/// - Returns: Styled attributed string for front matter section
private func renderFrontMatter(_ frontMatter: [String: String]) -> NSAttributedString {
    guard !frontMatter.isEmpty else {
        return NSAttributedString()
    }

    let result = NSMutableAttributedString()

    // Optional section header (user's discretion - recommend including)
    let header = NSAttributedString(
        string: "Front Matter\n",
        attributes: [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
    )
    result.append(header)

    // Paragraph style for front matter section
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.paragraphSpacing = 4
    paragraphStyle.headIndent = 10
    paragraphStyle.firstLineHeadIndent = 10

    // Render key-value pairs (sorted for consistency)
    for (key, value) in frontMatter.sorted(by: { $0.key < $1.key }) {
        let line = "\(key): \(value)\n"
        let attributed = NSMutableAttributedString(string: line)

        // Style: bold keys, normal values
        let colonRange = (line as NSString).range(of: ":")
        let keyRange = NSRange(location: 0, length: colonRange.location)
        let valueRange = NSRange(location: colonRange.location, length: line.count - colonRange.location)

        attributed.addAttribute(.font, value: NSFont.boldSystemFont(ofSize: 13), range: keyRange)
        attributed.addAttribute(.foregroundColor, value: NSColor.labelColor, range: keyRange)
        attributed.addAttribute(.font, value: NSFont.systemFont(ofSize: 13), range: valueRange)
        attributed.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: valueRange)
        attributed.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: line.count))

        result.append(attributed)
    }

    // Background for entire section (semantic color adapts to dark mode)
    let fullRange = NSRange(location: 0, length: result.length)
    result.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: fullRange)

    // Add separator after front matter
    result.append(NSAttributedString(string: "\n\n"))

    os_log("MarkdownRenderer: Rendered front matter section, length: %d", log: .renderer, type: .info, result.length)
    return result
}
```

### Integration with Existing Render Pipeline

```swift
// Source: Modify existing render() method in MarkdownRenderer.swift
func render(markdown: String) -> NSAttributedString {
    os_log("MarkdownRenderer: Starting render, input length: %d", log: .renderer, type: .info, markdown.count)

    // STEP 1: Extract YAML front matter FIRST (before other preprocessing)
    let (frontMatter, bodyMarkdown) = extractYAMLFrontMatter(from: markdown)

    // STEP 2: Pre-process body markdown (existing pipeline)
    let preprocessedMarkdown = preprocessBlockquoteSoftBreaks(in: preprocessImages(in: bodyMarkdown))

    // STEP 3: Check if document contains GFM tables (existing logic)
    if hasGFMTables(in: preprocessedMarkdown) {
        os_log("MarkdownRenderer: Document contains tables, using hybrid rendering", log: .renderer, type: .info)
        let bodyContent = renderWithTables(markdown: preprocessedMarkdown)

        // Prepend front matter section if present
        if !frontMatter.isEmpty {
            let result = NSMutableAttributedString()
            result.append(renderFrontMatter(frontMatter))
            result.append(bodyContent)
            return result
        }
        return bodyContent
    }

    // STEP 4: Standard rendering (existing logic)
    guard let attributedString = try? AttributedString(markdown: preprocessedMarkdown) else {
        os_log("MarkdownRenderer: Failed to parse markdown", log: .renderer, type: .error)
        return NSAttributedString(string: markdown)
    }

    // ... existing rendering pipeline (insert newlines, apply styles, etc.) ...

    var withNewlines = insertBlockBoundaryNewlines(in: attributedString)
    withNewlines = ensureIntraBlockNewlines(in: withNewlines)
    let nsAttributedString = NSMutableAttributedString(withNewlines)

    applyBlockStyles(from: withNewlines, to: nsAttributedString)
    insertListPrefixes(from: withNewlines, to: nsAttributedString)
    applyInlineStyles(from: withNewlines, to: nsAttributedString)
    applyLinkStyles(to: nsAttributedString)
    applyImagePlaceholderStyles(to: nsAttributedString)
    applyBaseStyles(to: nsAttributedString)

    // STEP 5: Prepend front matter section if present
    if !frontMatter.isEmpty {
        let frontMatterSection = renderFrontMatter(frontMatter)
        nsAttributedString.insert(frontMatterSection, at: 0)
        os_log("MarkdownRenderer: Prepended front matter section", log: .renderer, type: .info)
    }

    os_log("MarkdownRenderer: Render complete, output length: %d", log: .renderer, type: .info, nsAttributedString.length)
    return nsAttributedString
}
```

### Edge Case Test Examples

```swift
// Test case 1: Empty front matter
let emptyFrontMatter = """
---
---
# Heading

Content here.
"""
// Expected: Empty dictionary, body renders normally

// Test case 2: Missing closing delimiter
let noClosingDelimiter = """
---
title: Test
# Heading

Content here.
"""
// Expected: No front matter detected, entire content renders as markdown

// Test case 3: Windows line endings
let windowsLineEndings = "---\r\ntitle: Test\r\n---\r\n# Heading"
// Expected: Front matter detected after normalization

// Test case 4: Front matter in code block (should NOT be detected)
let frontMatterInCode = """
# Documentation

Example front matter:

```yaml
---
title: Example
---
```
"""
// Expected: No front matter detected (not at file start)

// Test case 5: List values
let listValues = """
---
tags: [swift, yaml, markdown]
categories: ["tutorial", "reference"]
---
"""
// Expected: tags → "swift, yaml, markdown", categories → "tutorial, reference"
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Full YAML parser for display | Lightweight key-value extraction | 2020+ (gray-matter, Jekyll patterns) | Display-only use cases don't need full YAML spec compliance. Basic parsing handles 90% of real front matter. |
| Hard-coded light mode colors | Semantic NSColor (`.secondarySystemFill`, etc.) | macOS 10.14 (Mojave) introduced dark mode | Automatic adaptation to system appearance without manual detection. |
| Manual color switching on appearance change | Semantic colors update automatically | macOS 10.14+ | No observer pattern needed, colors update when system appearance changes. |
| Parsing YAML with swift-markdown | Manual extraction before markdown parsing | Never changed (swift-markdown doesn't support front matter) | swift-markdown follows CommonMark spec; front matter is extension. Manual preprocessing is required workaround. |

**Deprecated/outdated:**
- **Full YAML parser for display-only rendering:** Yams is excellent for structured data parsing, but overkill for showing metadata in a preview. Requirements explicitly exclude this approach.
- **Separate appearance observers for dark mode:** Pre-Mojave pattern. Semantic NSColor values handle appearance changes automatically.
- **Parsing front matter within markdown:** Never worked with swift-markdown (not in CommonMark spec). Must be stripped before parsing.

## Open Questions

Things that couldn't be fully resolved:

1. **Multi-column layout implementation complexity**
   - What we know: NSTextContainer supports multiple containers for column layouts (iOS7 Day-by-Day pattern), but Quick Look extension uses single NSTextView architecture
   - What's unclear: Whether multiple NSTextContainer approach works in Quick Look NSScrollView context, or if simpler tab-stop approach is more reliable
   - Recommendation: Start with tab-stop approach (simpler, proven pattern in existing renderer), defer full NSTextContainer multi-column to later if needed

2. **Front matter section visual style preference**
   - What we know: User gave Claude discretion on exact separation style (bordered card vs divider vs background tint)
   - What's unclear: Which style best fits Quick Look aesthetic and existing renderer patterns
   - Recommendation: Use background tint with `.secondarySystemFill` (matches code block pattern), add divider line below, skip "Front Matter" label if looks redundant

3. **Handling deeply nested YAML (rare edge case)**
   - What we know: Real-world front matter is 90% simple key-value pairs; nested objects are rare
   - What's unclear: Best fallback for nested YAML when basic parser can't handle it
   - Recommendation: Show raw text for nested values (e.g., `nested: { key: value }` displayed as-is). Users can open file in editor for complex metadata.

## Sources

### Primary (HIGH confidence)

- [Yams GitHub Repository](https://github.com/jpsim/Yams) - Current version 6.2.1, Swift Package Manager installation, Codable support, LibYAML dependency
- [swift-markdown Issue #73](https://github.com/swiftlang/swift-markdown/issues/73) - Official confirmation that YAML front matter is not supported, recommended workaround is manual extraction
- [Apple Developer Documentation: UI Element Colors](https://developer.apple.com/documentation/appkit/nscolor/ui_element_colors) - Semantic NSColor values for dark mode
- [Apple Developer Documentation: secondarySystemFill](https://developer.apple.com/documentation/appkit/nscolor/4236444-secondarysystemfill) - Official color for medium-size shape backgrounds
- [Apple Developer Documentation: addAttribute](https://developer.apple.com/documentation/foundation/nsmutableattributedstring/1417080-addattribute) - NSMutableAttributedString attribute application

### Secondary (MEDIUM confidence)

- [gray-matter GitHub Repository](https://github.com/jonschlinkert/gray-matter) - Battle-tested YAML front matter parser (JavaScript), edge case handling patterns
- [Jekyll Front Matter Documentation](https://jekyllrb.com/docs/front-matter/) - Standard front matter format and requirements
- [Hugo Front Matter Documentation](https://gohugo.io/content-management/front-matter/) - Delimiter detection and format specification
- [iOS7 Day-by-Day: Multi-column TextKit](https://github.com/ScottLogic/iOS7-day-by-day/blob/master/21-multi-column-textkit/21-multi-column-textkit.md) - NSTextContainer multi-column layout pattern
- [Augmented Code: Custom NSAttributedString Attributes](https://augmentedcode.io/2019/11/10/adding-custom-attribute-to-nsattributedstring-on-ios/) - Defining custom attribute keys

### Tertiary (LOW confidence)

- [MacDown Issue #469](https://github.com/MacDownApp/macdown/issues/469) - YAML front matter regex pattern discussion (old, but pattern still relevant)
- [Obsidian Linter YAML Rules](https://platers.github.io/obsidian-linter/settings/yaml-rules/) - YAML front matter validation patterns
- [Parsing Front Matter in Obsidian Plugins](https://www.bramadams.dev/202303061543/) - Practical front matter extraction examples

## Metadata

**Confidence breakdown:**
- Standard stack (manual extraction + semantic colors): HIGH - Verified with official docs, existing codebase patterns, and swift-markdown maintainer recommendations
- Architecture (preprocessing pipeline): HIGH - Matches existing `preprocessImages()` pattern in MarkdownRenderer.swift
- Lightweight parsing approach: MEDIUM - Based on gray-matter patterns (JavaScript) and requirements document, not verified in Swift specifically
- Multi-column layout: MEDIUM - NSTextContainer pattern verified for iOS, unclear if works in Quick Look NSScrollView context
- Pitfalls: HIGH - Based on CommonMark spec knowledge, swift-markdown issue tracker, and macOS dark mode documentation

**Research date:** 2026-02-06
**Valid until:** 30 days (stable domain - YAML front matter format hasn't changed since Jekyll popularized it ~2010, semantic NSColor stable since macOS 10.14)
