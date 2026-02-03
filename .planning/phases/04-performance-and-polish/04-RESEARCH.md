# Phase 4: Performance & Polish - Research

**Researched:** 2026-02-02
**Domain:** Quick Look extension performance optimization and macOS system appearance integration
**Confidence:** HIGH

## Summary

This phase optimizes rendering performance for a working markdown Quick Look extension that currently renders content correctly but may be slow with large files and lacks dark mode support. The standard approach involves file size truncation, system color adoption, and optional background threading with performance measurement using OSLog signposts. The codebase is well-structured (~58KB total Swift code) using native macOS APIs (NSAttributedString, NSTextStorage, NSLayoutManager) without external dependencies beyond Apple's swift-markdown library.

The extension already uses the correct architecture with a custom NSLayoutManager for special rendering (blockquote borders, code block backgrounds) and AttributedString for markdown parsing. Performance optimization will focus on preventing slowness with large files through truncation, measuring actual performance with real-world samples, and adopting system colors for automatic dark mode support.

**Primary recommendation:** Truncate large files before rendering, adopt NSColor semantic colors throughout, measure performance with OSLog signposts during development, and remove instrumentation before release.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| AppKit (NSAttributedString) | macOS 26+ | Rich text rendering | Native macOS text system, used by all AppKit apps |
| AppKit (NSTextStorage/NSLayoutManager) | macOS 26+ | Advanced text layout | Required for custom rendering (blockquotes, code blocks) |
| swift-markdown | Apple's library | Markdown parsing | Official Apple markdown parser, already in use |
| Foundation (AttributedString) | macOS 26+ | Markdown to attributed string | Native markdown support added in macOS 12 |
| os.log (OSLog) | macOS 26+ | Structured logging | Apple's unified logging system, already in use |
| QuickLook (QLPreviewingController) | macOS 26+ | Quick Look preview interface | Required API for Quick Look extensions |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| os.signpost (OSSignposter) | macOS 26+ | Performance measurement | Development only - measure render times |
| Instruments (Time Profiler) | Xcode 15+ | Performance profiling | Development only - identify bottlenecks |
| DispatchQueue | Swift 5.9+ | Background threading | Only if performance testing shows main thread blocking |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| File truncation | Streaming/pagination | Far more complex, unnecessary for preview use case |
| OSLog signposts | Manual timing with Date() | Less precise, no Instruments integration |
| System colors | Custom color schemes | Doesn't adapt to appearance, breaks system integration |
| Main thread rendering | Background thread with DispatchQueue | More complex, may be unnecessary if truncation solves performance |

**Installation:**
No additional dependencies needed - all APIs are part of macOS SDK.

## Architecture Patterns

### Recommended Approach

**Current Architecture (Validated):**
```
PreviewViewController
├── Reads file with String(contentsOf:)
├── MarkdownRenderer.render()
│   ├── Parses with AttributedString(markdown:)
│   ├── Converts to NSMutableAttributedString
│   └── Applies visual styles via NSAttributedString attributes
├── MarkdownLayoutManager (custom)
│   └── drawBackground() for blockquotes and code blocks
└── Displays in NSTextView with NSScrollView
```

This architecture is solid and doesn't need restructuring. Phase 4 enhancements fit into existing structure.

### Pattern 1: File Size Truncation Before Parsing

**What:** Check file size before reading, truncate content at reasonable limit
**When to use:** Always - prevents performance degradation with large files
**Example:**
```swift
func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    // Check file size before reading
    guard let fileSize = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 else {
        handler(NSError(...))
        return
    }

    let maxSize = 500_000 // 500KB - adjust based on performance testing

    let markdownContent: String
    if fileSize > maxSize {
        // Read only first N bytes and add truncation message
        guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
            handler(NSError(...))
            return
        }
        defer { try? fileHandle.close() }

        let data = fileHandle.readData(ofLength: Int(maxSize))
        var content = String(data: data, encoding: .utf8) ?? ""

        // Add truncation message
        let truncationMsg = "\n\n---\n\n⚠️ Content truncated (file is \(formatFileSize(fileSize)))"
        content.append(truncationMsg)
        markdownContent = content
    } else {
        // Read full file for typical sizes
        markdownContent = try String(contentsOf: url, encoding: .utf8)
    }

    // Continue with existing rendering pipeline
    let renderer = MarkdownRenderer()
    let styledContent = renderer.render(markdown: markdownContent)
    // ...
}

func formatFileSize(_ bytes: UInt64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: Int64(bytes))
}
```

### Pattern 2: System Color Adoption

**What:** Replace all hard-coded colors with NSColor semantic colors that adapt to appearance
**When to use:** Always - provides automatic dark mode support
**Example:**
```swift
// Text colors (adapt light/dark automatically)
.foregroundColor: NSColor.labelColor           // Primary text
.foregroundColor: NSColor.secondaryLabelColor  // Dimmed text (image placeholders)
.foregroundColor: NSColor.quaternaryLabelColor // Empty cell indicators

// Background colors (adapt automatically)
.backgroundColor: NSColor.textBackgroundColor      // Main background
.backgroundColor: NSColor.secondarySystemFill      // Code blocks
.backgroundColor: NSColor.tertiarySystemFill       // Inline code
.backgroundColor: NSColor.quaternarySystemFill     // Blockquotes, empty cells

// Border/separator colors (adapt automatically)
NSColor.separatorColor  // Table borders, blockquote borders

// Link colors (adapt automatically)
NSColor.linkColor  // Links (brighter blue in dark mode)

// In MarkdownLayoutManager.drawBackground():
NSColor.separatorColor.setStroke()  // Instead of systemBlue
NSColor.quaternarySystemFill.setFill()  // Instead of lightGray
```

### Pattern 3: Performance Measurement with OSLog Signposts

**What:** Use OSSignposter to measure rendering time intervals for optimization
**When to use:** Development only - remove before release
**Example:**
```swift
import os.signpost

extension OSLog {
    static let performance = OSLog(subsystem: "com.razielpanic.md-quick-look", category: .pointsOfInterest)
}

class MarkdownRenderer {
    private let signposter = OSSignposter(subsystem: "com.razielpanic.md-quick-look", category: .pointsOfInterest)

    func render(markdown: String) -> NSAttributedString {
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval("render", id: signpostID, "Rendering \(markdown.count) bytes")
        defer { signposter.endInterval("render", state) }

        // Existing rendering code...
        return result
    }
}

// View in Instruments: Product > Profile > Points of Interest template
// Shows timing for each render operation with file sizes
```

### Pattern 4: Optional Background Threading

**What:** Render on background thread if performance testing shows UI blocking
**When to use:** Only if profiling shows main thread blocking >100ms
**Example:**
```swift
func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    // Option 1: Keep rendering on main thread (simpler, likely sufficient with truncation)
    do {
        let content = try loadAndTruncateFile(at: url)
        let styled = MarkdownRenderer().render(markdown: content)
        setupTextView(with: styled)
        handler(nil)
    } catch {
        handler(error)
    }

    // Option 2: If profiling shows main thread blocking, move to background
    DispatchQueue.global(qos: .userInitiated).async {
        do {
            let content = try self.loadAndTruncateFile(at: url)
            let styled = MarkdownRenderer().render(markdown: content)

            // Must update UI on main thread
            DispatchQueue.main.async {
                self.setupTextView(with: styled)
                handler(nil)
            }
        } catch {
            DispatchQueue.main.async {
                handler(error)
            }
        }
    }
}
```

### Anti-Patterns to Avoid

- **Premature background threading:** Don't add threading complexity without profiling data showing it's needed. File truncation may be sufficient.
- **Hard-coded colors:** Using fixed colors (NSColor.black, NSColor.white) breaks dark mode adaptation. Always use semantic colors.
- **No truncation limit:** Attempting to render multi-megabyte files will cause slowness and memory pressure. Always truncate.
- **Development instrumentation in release:** Remove OSLog signpost code before shipping - adds overhead and exposes implementation details.
- **Caching between invocations:** Quick Look may render same file multiple times. Don't add caching complexity - re-render is fast with truncation.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Performance measurement | Manual Date() timing | OSLog signposts + Instruments | Integrated with Instruments, more accurate, visualizes call hierarchies |
| File size formatting | Manual byte/KB/MB math | ByteCountFormatter | Handles localization, follows system conventions |
| Dark mode detection | Manual effectiveAppearance checks | NSColor semantic colors | Automatic adaptation, no code needed, handles high contrast mode |
| String truncation | Manual substring logic | String.prefix(_:) + FileHandle.readData(ofLength:) | Efficient for large files, handles UTF-8 boundaries |
| Threading | Manual Thread() or pthread | DispatchQueue | Modern Swift API, quality-of-service support, safer |

**Key insight:** macOS provides extensive APIs specifically for these common needs. Using system APIs ensures correct behavior across OS versions and reduces maintenance burden.

## Common Pitfalls

### Pitfall 1: Reading Entire Large File Into Memory

**What goes wrong:** Using `String(contentsOf: url)` on a 5MB markdown file loads entire file, causing slow parsing and high memory usage.
**Why it happens:** Code written for typical 10-50KB files doesn't anticipate larger documentation files.
**How to avoid:** Check file size first with FileManager, truncate before parsing:
```swift
let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
guard let fileSize = attrs[.size] as? UInt64, fileSize < maxSize else {
    // Truncate and add message
}
```
**Warning signs:** Preview panel shows spinning indicator for >1 second, Console shows memory warnings, Time Profiler shows String.init taking >100ms.

### Pitfall 2: Using Fixed Colors Instead of Semantic Colors

**What goes wrong:** Text is black in both light and dark mode, making it invisible on dark backgrounds.
**Why it happens:** Developer writes `.foregroundColor: NSColor.black` during light mode testing, doesn't test dark mode.
**How to avoid:** Use semantic colors from day one: `NSColor.labelColor` instead of `NSColor.black`. Test in both appearances (System Settings > Appearance > Dark).
**Warning signs:** Text invisible in dark mode, colors don't match other system apps, inconsistent with macOS UI guidelines.

### Pitfall 3: Main Thread Blocking Without Completion Handler Delay

**What goes wrong:** Rendering takes 2 seconds on main thread, Finder UI freezes, user sees beach ball cursor.
**Why it happens:** Quick Look calls preparePreviewOfFile on main thread, synchronous rendering blocks entire process.
**How to avoid:** Either (1) truncate files to ensure <100ms render time, or (2) move rendering to background thread:
```swift
DispatchQueue.global(qos: .userInitiated).async {
    let styled = render(markdown)
    DispatchQueue.main.async {
        self.setupUI(styled)
        handler(nil)  // Call handler on main thread
    }
}
```
**Warning signs:** Finder becomes unresponsive during Quick Look, Instruments shows main thread at 100% for extended period, user complaints about freezing.

### Pitfall 4: Not Testing with Real-World File Sizes

**What goes wrong:** Extension works perfectly with 1KB test files, but fails/slows with user's 200KB technical documentation.
**Why it happens:** Sample files in `/samples/` directory are tiny (140-1100 bytes). Real markdown files are much larger.
**How to avoid:** Create test files at various sizes: 10KB (typical), 50KB (large), 500KB (maximum), 2MB (should truncate). Use actual README files from popular GitHub projects.
**Warning signs:** Works in testing but gets bad reviews, no performance data above 5KB, no truncation message ever appears.

### Pitfall 5: Leaving Development Instrumentation in Release

**What goes wrong:** Shipping code with OSLog signposts adds overhead, exposes implementation details in Console.app logs.
**Why it happens:** Signpost code is scattered throughout renderer, no clear marker for "development only" sections.
**How to avoid:** Wrap instrumentation in `#if DEBUG` or use build configuration:
```swift
#if DEBUG
let signpostID = signposter.makeSignpostID()
let state = signposter.beginInterval("render", id: signpostID)
defer { signposter.endInterval("render", state) }
#endif
```
Or remove entirely before release commit.
**Warning signs:** Release build contains `.pointsOfInterest` category logs, Console shows internal timing data, App Store review questions instrumentation.

## Code Examples

Verified patterns from official sources and codebase analysis:

### File Size Check and Truncation
```swift
// Source: Analyzed from codebase + Swift Forums discussion
// https://forums.swift.org/t/reading-large-files-fast-and-memory-efficient/37704

func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
    do {
        // Check file size before reading
        let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
        guard let fileSize = attrs[.size] as? UInt64 else {
            handler(NSError(domain: "FileSize", code: -1))
            return
        }

        let maxSize: UInt64 = 500_000  // 500KB - adjust based on testing

        let markdownContent: String
        if fileSize > maxSize {
            // Read first N bytes only
            guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
                handler(NSError(domain: "FileRead", code: -1))
                return
            }
            defer { try? fileHandle.close() }

            let data = fileHandle.readData(ofLength: Int(maxSize))
            var truncated = String(data: data, encoding: .utf8) ?? ""

            // Add user-friendly truncation message
            let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            truncated.append("\n\n---\n\n⚠️ Content truncated (file is \(sizeStr))")
            markdownContent = truncated

            os_log("Truncated large file: %@ (%lld bytes)", log: .quicklook, type: .info, url.lastPathComponent, fileSize)
        } else {
            // Read full file for typical sizes
            markdownContent = try String(contentsOf: url, encoding: .utf8)
            os_log("Read full file: %@ (%d bytes)", log: .quicklook, type: .info, url.lastPathComponent, markdownContent.count)
        }

        // Continue with existing rendering pipeline
        let renderer = MarkdownRenderer()
        let styledContent = renderer.render(markdown: markdownContent)
        setupTextView(with: styledContent)
        handler(nil)

    } catch {
        os_log("Error preparing preview: %@", log: .quicklook, type: .error, error.localizedDescription)
        handler(error)
    }
}
```

### System Color Application in Renderer
```swift
// Source: Analyzed from existing MarkdownRenderer.swift + Apple NSColor documentation
// https://developer.apple.com/documentation/appkit/nscolor

// In applyBaseStyles():
func applyBaseStyles(to nsAttributedString: NSMutableAttributedString) {
    let fullRange = NSRange(location: 0, length: nsAttributedString.length)

    // Use semantic color that adapts to light/dark mode
    nsAttributedString.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)
}

// In applyInlineCodeAttributes():
func applyInlineCodeAttributes(to nsAttributedString: NSMutableAttributedString, range: NSRange) {
    let font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
    nsAttributedString.addAttribute(.font, value: font, range: range)

    // Use semantic fill color (same as code blocks for consistency)
    nsAttributedString.addAttribute(.backgroundColor, value: NSColor.secondarySystemFill, range: range)
}

// In applyImagePlaceholderStyles():
func applyImagePlaceholderStyles(to nsAttributedString: NSMutableAttributedString) {
    let textAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: bodyFontSize),
        .foregroundColor: NSColor.secondaryLabelColor  // Dimmed for placeholder
    ]
    // ...
}

// In MarkdownLayoutManager.drawBackground():
override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
    super.drawBackground(forGlyphRange: glyphsToShow, at: origin)

    // Code block backgrounds
    NSColor.secondarySystemFill.setFill()  // Adapts to appearance
    bgRect.fill()

    // Blockquote backgrounds and borders
    NSColor.quaternarySystemFill.setFill()  // Subtle background
    bgRect.fill()

    NSColor.separatorColor.setStroke()  // Standard separator color
    NSBezierPath.stroke(barRect)
}

// In TableRenderer border styling:
if isHeader {
    block.setWidth(2.0, type: .absoluteValueType, for: .border, edge: .maxY)
    block.setBorderColor(NSColor.separatorColor, for: .maxY)  // Adapts automatically
}
```

### Performance Measurement with Signposts
```swift
// Source: WWDC 2018 Session 405 + Swift by Sundell
// https://www.swiftbysundell.com/wwdc2018/getting-started-with-signposts/

import os.signpost

extension OSLog {
    static let performance = OSLog(subsystem: "com.razielpanic.md-quick-look", category: .pointsOfInterest)
}

class MarkdownRenderer {
    private let signposter = OSSignposter(subsystem: "com.razielpanic.md-quick-look", category: .pointsOfInterest)

    func render(markdown: String) -> NSAttributedString {
        #if DEBUG
        let signpostID = signposter.makeSignpostID()
        let state = signposter.beginInterval("MarkdownRender", id: signpostID, "Size: \(markdown.count) bytes")
        defer { signposter.endInterval("MarkdownRender", state) }
        #endif

        // Parse markdown
        guard let attributedString = try? AttributedString(markdown: markdown) else {
            return NSAttributedString(string: markdown)
        }

        // Apply styles
        var result = NSMutableAttributedString(attributedString)
        applyBlockStyles(from: attributedString, to: result)
        applyInlineStyles(from: attributedString, to: result)
        applyLinkStyles(to: result)
        applyBaseStyles(to: result)

        return result
    }
}

// To measure in Instruments:
// 1. Product > Profile (Cmd+I)
// 2. Choose "Blank" template
// 3. Add "Points of Interest" instrument
// 4. Run and interact with Quick Look
// 5. View "MarkdownRender" intervals with sizes in timeline
```

### Testing with Various File Sizes
```swift
// Source: Project analysis + performance testing best practices
// Create test files programmatically for consistent testing

func createTestMarkdownFiles() {
    let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("md-test-files")
    try? FileManager.default.createDirectory(at: testDir, withIntermediateDirectories: true)

    // Small file (10KB) - typical README
    let small = String(repeating: "# Heading\n\nParagraph text with **bold** and *italic*.\n\n", count: 100)
    try? small.write(to: testDir.appendingPathComponent("small-10kb.md"), atomically: true, encoding: .utf8)

    // Medium file (50KB) - large documentation
    let medium = String(repeating: small, count: 5)
    try? medium.write(to: testDir.appendingPathComponent("medium-50kb.md"), atomically: true, encoding: .utf8)

    // Large file (500KB) - at truncation threshold
    let large = String(repeating: medium, count: 10)
    try? large.write(to: testDir.appendingPathComponent("large-500kb.md"), atomically: true, encoding: .utf8)

    // Huge file (2MB) - should be truncated with message
    let huge = String(repeating: large, count: 4)
    try? huge.write(to: testDir.appendingPathComponent("huge-2mb.md"), atomically: true, encoding: .utf8)

    print("Test files created at: \(testDir.path)")
    print("Open in Finder and press Space to test Quick Look performance")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual dark mode detection with effectiveAppearance | NSColor semantic colors (labelColor, etc.) | macOS 10.14+ (Mojave) | Automatic adaptation, no detection code needed |
| Custom timing with Date() | OSLog signposts + Instruments | macOS 10.14+ (Mojave) | Better profiling integration, visualizable timelines |
| AttributedString(markdown:) unavailable | Native AttributedString markdown parsing | macOS 12+ (Monterey) | Simplified parsing, no custom parser needed |
| NSAttributedString only | AttributedString + NSAttributedString hybrid | macOS 12+ (Monterey) | Modern Swift types with AppKit interop |
| Hard-coded UI colors | System fill colors (secondarySystemFill, etc.) | macOS 10.15+ (Catalina) | Semantic backgrounds that adapt to context |

**Deprecated/outdated:**
- **NSColor.controlTextColor**: Use NSColor.labelColor instead (more semantic, better adaptation)
- **Manual appearance observation**: NSColor semantic colors handle this automatically
- **Custom markdown parsers**: AttributedString(markdown:) is now built-in and maintained by Apple
- **CFAbsoluteTimeGetCurrent()**: Use OSLog signposts for performance measurement
- **NSRunLoop**: Use DispatchQueue for threading (modern Swift concurrency)

## Open Questions

1. **Optimal Truncation Threshold**
   - What we know: User decision is "up to 500KB", typical files are 10-50KB
   - What's unclear: Exact point where performance degrades unacceptably (need empirical testing)
   - Recommendation: Start with 500KB as decided, measure with real-world samples, adjust if needed (document reasoning in commit)

2. **Background Thread Necessity**
   - What we know: Quick Look calls preparePreviewOfFile, shows spinner until handler called
   - What's unclear: Whether file truncation alone keeps rendering <100ms, or if background thread needed
   - Recommendation: Measure first with truncation on main thread, add background threading only if profiling shows blocking >100ms

3. **Truncation Strategy Details**
   - What we know: Truncate at byte limit, add message at bottom
   - What's unclear: Whether to truncate mid-line or at last complete line within limit
   - Recommendation: Truncate at byte limit (simpler), markdown parsing handles incomplete elements gracefully, UTF-8 encoding.utf8 ensures valid boundaries

4. **Performance Instrumentation Removal**
   - What we know: OSLog signposts are for development only
   - What's unclear: Whether to use #if DEBUG or remove entirely before release
   - Recommendation: Remove entirely in release commit (cleaner, no runtime overhead even in debug builds of shipped app)

## Sources

### Primary (HIGH confidence)
- [Apple Developer: QLPreviewingController](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller) - Quick Look API reference
- [Apple Developer: NSColor](https://developer.apple.com/documentation/appkit/nscolor) - System color documentation
- [WWDC 2018 Session 237: Quick Look Previews from the Ground Up](https://asciiwwdc.com/2018/sessions/237) - Official performance guidelines
- [WWDC 2018 Session 405: Measuring Performance Using Logging](https://developer.apple.com/videos/play/wwdc2018/405/) - OSLog signposts
- Codebase analysis: PreviewViewController.swift, MarkdownRenderer.swift, MarkdownLayoutManager.swift, TableRenderer.swift

### Secondary (MEDIUM confidence)
- [Swift by Sundell: Getting started with signposts](https://www.swiftbysundell.com/wwdc2018/getting-started-with-signposts/) - Practical signpost usage
- [Donny Wals: Measuring performance with os_signpost](https://www.donnywals.com/measuring-performance-with-os_signpost/) - Performance measurement patterns
- [Swift with Majid: Measuring app performance in Swift](https://swiftwithmajid.com/2022/05/04/measuring-app-performance-in-swift/) - Modern performance techniques
- [SwiftLee: OSLog and Unified logging](https://www.avanderlee.com/debugging/oslog-unified-logging/) - Logging best practices
- [Indie Stack: Supporting Dark Mode: Adapting Colors](https://indiestack.com/2018/10/supporting-dark-mode-adapting-colors/) - Dark mode color adoption
- [Swift Forums: Reading large files fast and memory efficient](https://forums.swift.org/t/reading-large-files-fast-and-memory-efficient/37704) - File handling strategies
- [Swift Forums: Difficulties With Efficient Large File Parsing](https://forums.swift.org/t/difficulties-with-efficient-large-file-parsing/23660) - Performance considerations

### Tertiary (LOW confidence)
- [The Cope: Resolving Slow Performance of NSTextStorage](https://www.thecope.net/2019/09/15/resolving-slow-performance.html) - NSTextStorage optimization (Swift vs Obj-C)
- [objc.io: Getting to Know TextKit](https://www.objc.io/issues/5-ios7/getting-to-know-textkit/) - TextKit architecture background
- [GitHub: StyledTextKit](https://github.com/GitHawkApp/StyledTextKit) - Alternative attributed string library (not needed, informational)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All APIs are official Apple frameworks, already in use in codebase
- Architecture: HIGH - Existing architecture is sound, phase adds enhancements not restructuring
- Pitfalls: HIGH - Based on official Apple documentation, real-world issues from forums, and codebase analysis
- Performance techniques: HIGH - OSLog signposts and file truncation are well-documented official approaches
- Color adaptation: HIGH - NSColor semantic colors are official API with extensive documentation

**Research date:** 2026-02-02
**Valid until:** 90+ days (stable APIs, no fast-moving changes expected in macOS text/color APIs)
