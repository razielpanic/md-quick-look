# Technology Stack: md-spotlighter

**Project:** Quick Look extension for markdown rendering on macOS
**Researched:** January 2026
**Recommendation Confidence:** HIGH

## Recommended Stack

### Core Framework & Extension Architecture

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Swift** | 5.9+ (6.0 compatible) | Primary language | Modern, safe language; native macOS support; best DX for Quick Look extensions |
| **Xcode** | 16+ | Build and development | Required for app extensions; full Quick Look debugging support; SPM integration |
| **macOS Deployment Target** | 14.0 (Sonoma) | Minimum supported | Project constraint (no legacy); aligns with modern API availability; broad user base |
| **QuickLook Framework** | App Extension API | Extension host | Modern replacement for deprecated QLGenerator (deprecated in macOS 15 Sequoia) |

### Markdown Processing

| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| **swift-markdown** | 0.3+ | Parse markdown to AST | Official Apple library; CommonMark + GitHub Flavored Markdown (GFM) support; thread-safe; immutable data structures |
| **Alternative: Down** | 0.11+ | Parse/render markdown | Faster markdown parsing via cmark; simpler API; more output formats (HTML, RTF); consider if performance critical |

**Recommendation:** Start with `swift-markdown`. It's maintained by Apple, provides excellent AST support for custom rendering control, and includes both CommonMark and GFM. If profiling shows performance issues with large files or complex rendering, consider Down for its cmark-based speed.

### Rendering Approach

| Component | Technology | Purpose | Why |
|-----------|-----------|---------|-----|
| **Text rendering** | NSAttributedString + Core Text | Styled text output | Native macOS, performant, no external dependencies for rendering; direct markdown → NSAttributedString conversion avoids WebKit overhead |
| **Code block syntax highlighting** | *Highlighter library TBD* | Syntax coloring | Quick Look extensions have strict sandboxing; avoid Highlight external tool. Consider lightweight alternatives or build custom for supported languages |
| **UI framework** | SwiftUI | Extension UI | Modern, native, integrates well with NSAttributedString via NSAttributedString(markdown:) initializer; cleaner than UIKit for Quick Look |

**Critical note:** WebKit in Quick Look extensions has documented issues on macOS Sequoia (map tiles not rendering, performance problems). Avoid WebKit rendering if possible. Direct NSAttributedString rendering is more reliable and performant.

### Code Syntax Highlighting

**Recommendation:** Custom lightweight syntax highlighting for code blocks

**Why:**
- Quick Look extensions run in a sandboxed process; external tools (like Highlight) are difficult to embed
- Project scope: "minimal scope: headings, bold, italic, lists, code blocks"
- For MVP: Basic syntax highlighting (language detection, simple colorization)
- For future: Integrate highlighter library after verifying sandbox compatibility

**Candidate libraries (post-MVP):**
- **Splash** (github.com/JohnSundell/Splash): Fast, lightweight, specifically for Swift; no external dependencies
- **SwiftUI HighlightedTextEditor**: Provides syntax highlighting for SwiftUI TextEditor; may not work in Quick Look sandbox
- **Custom regex-based**: Simple keyword/pattern matching for common languages

Start with manual keyword highlighting for common languages (JavaScript, Python, Swift, Shell). This avoids dependencies and works reliably in the sandbox.

## Extension Target Configuration

### Info.plist Requirements

```xml
<!-- Quick Look Extension Configuration -->
<key>NSExtensionPointIdentifier</key>
<string>com.apple.quicklook.thumbnail</string>

<!-- Data-based preview (not file URL-based) -->
<key>QLIsDataBasedPreview</key>
<true/>

<!-- Supported UTI types -->
<key>QLSupportedContentTypes</key>
<array>
  <string>net.daringfireball.markdown</string>
  <string>com.markdowntable</string>
  <string>io.github.quarto.qmd</string>
</array>

<!-- Principal class for preview provider -->
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
```

### Build Settings

- **Minimum Deployment:** macOS 14.0
- **Swift Language Version:** Swift 5.9 or later
- **Code Signing Requirement:** Must be signed (system requirement for extensions)
- **Sandbox:** Enabled (required for all app extensions)

### Code Signing & Entitlements

**Required entitlements:**
```xml
<key>com.apple.security.app-sandbox</key>
<true/>

<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```

## Dependency Management

### Swift Package Dependencies

Use Swift Package Manager (SPM). Add to Package.swift or via Xcode:

```bash
# swift-markdown (official Apple library)
.package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.3.0")

# Alternative: Down (if performance testing shows need)
.package(url: "https://github.com/johnxnguyen/Down.git", from: "0.11.0")
```

**Xcode 16 considerations:**
- SPM integration is stable; no issues reported with Quick Look extensions
- Can mix Swift Package dependencies with Objective-C C libraries if needed (e.g., cmark)
- Build performance: Minimal impact for markdown parsing libraries

## What NOT to Use (Anti-Stack)

| Technology | Why Not | Impact |
|-----------|---------|--------|
| **WebKit / WKWebView** | Documented rendering bugs in macOS Sequoia; heavy memory footprint; slower than native rendering; Quick Look sandbox restrictions | Preview failures, poor performance, maintenance burden |
| **QLGenerator bundles** | Deprecated, no longer supported in macOS 15+ | Will not work; user base running Sequoia cannot use |
| **UIKit (instead of SwiftUI)** | Requires NSViewControllerRepresentable wrapper; added complexity | Code duplication, harder to maintain |
| **External rendering tools (Pandoc, etc.)** | Sandbox restrictions prevent process execution; XPC workaround creates architectural complexity | Very difficult to debug, unreliable |
| **Realm, Core Data** | Unnecessary complexity for read-only preview; extension runs in isolated process | Setup overhead, sync complexity, not needed |
| **SwiftUI Text(markdown:) alone** | Limited formatting support; ignores images and block elements | Cannot display headings, lists, code blocks properly |

## Installation & Setup

### Project Structure

```
md-spotlighter/
├── md-spotlighter/                    # Main app (installer)
│   └── Assets, UI, etc.
├── MarkdownPreviewExtension/          # Quick Look extension target
│   ├── PreviewProvider.swift          # QLPreviewProvider subclass
│   ├── MarkdownRenderer.swift         # swift-markdown parsing → NSAttributedString
│   ├── SyntaxHighlighter.swift        # Code block highlighting
│   └── Info.plist                     # Extension configuration
└── Shared/                            # Code shared between app and extension
    └── MarkdownParser.swift           # Isolated parsing logic
```

### Initial Setup

```bash
# 1. Create Xcode project with macOS > App template
# 2. Add Quick Look extension target
#    File > New > Target > Quick Look Preview Extension
# 3. Add SPM dependency
#    File > Add Packages > https://github.com/swiftlang/swift-markdown.git
# 4. Configure deployment target to macOS 14.0
# 5. Enable App Sandbox in entitlements
```

## Performance Targets

For instant rendering (Quick Look requirement):

| Scenario | Target | Approach |
|----------|--------|----------|
| 1KB markdown file | <100ms | Direct parsing + rendering |
| 50KB markdown file | <500ms | Parse on background thread, render to Main |
| 500KB markdown file | <2s | Consider pagination or truncation |

**Key optimization:** Avoid parsing entire file if > 100KB. Implement truncation with "file too large" message. Quick Look previews should feel instant.

## Known Issues & Workarounds

### macOS Sequoia (15.0+)

**Issue:** QLGenerator plugins no longer work
**Solution:** Use app extension API (this stack uses it)

**Issue:** Quick Look extensions with MapKit show beige background
**Workaround:** Avoid MapKit; not relevant for markdown rendering

### Sandbox Restrictions

**Issue:** Cannot shell out to external tools (Highlight, Pandoc)
**Workaround:** Embed syntax highlighting or use pure Swift libraries

**Issue:** Limited file system access
**Workaround:** Use provided file URL; read-only access only

### Code Signing

**Issue:** Extension fails to load if not properly signed
**Prevention:** Ensure team ID matches main app; entitlements must be identical between app and extension; use automatic signing in Xcode

## Documentation & References

### Official Apple Resources
- [Quick Look Framework Documentation](https://developer.apple.com/documentation/quicklook/)
- [QLPreviewingController API](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [QLPreviewProvider Documentation](https://developer.apple.com/documentation/quicklookui/qlpreviewprovider)
- [App Extension Security Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInPractice/AppSandboxInPractice.html)

### Community References
- [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) - Reference implementation using cmark-gfm
- [smittytone/PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) - Reference using NSAttributedString rendering
- [sbarex/SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight) - Reference with XPC for highlighting

## Sources

- [Quick Look Framework - Apple Developer Documentation](https://developer.apple.com/documentation/quicklook/)
- [QLPreviewingController - Apple Developer Documentation](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [swift-markdown - GitHub](https://github.com/swiftlang/swift-markdown)
- [Down - Markdown/CommonMark rendering in Swift - GitHub](https://github.com/johnxnguyen/Down)
- [Sequoia No Longer Supports QuickLook Generator Plug-ins](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)
- [How Sequoia has changed QuickLook and its thumbnails - The Eclectic Light Company](https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/)
- [QLMarkdown - Quick Look extension for Markdown on GitHub](https://github.com/sbarex/QLMarkdown)
- [PreviewMarkdown - Quick Look Markdown preview on GitHub](https://github.com/smittytone/PreviewMarkdown)
- [SourceCodeSyntaxHighlight - Quick Look extension on GitHub](https://github.com/sbarex/SourceCodeSyntaxHighlight)
- [Adding Swift package dependencies in Xcode - Hacking with Swift](https://www.hackingwithswift.com/books/ios-swiftui/adding-swift-package-dependencies-in-xcode)
- [Swift Markdown UI - GitHub](https://github.com/gonzalezreal/swift-markdown-ui)
- [Using QuickLook in SwiftUI - Daniel Saidi](https://danielsaidi.com/blog/2022/06/27/using-quicklook-with-swiftui)
- [Splash - Swift syntax highlighter - GitHub](https://github.com/JohnSundell/Splash)
