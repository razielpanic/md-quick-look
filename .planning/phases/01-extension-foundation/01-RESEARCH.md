# Phase 1: Extension Foundation - Research

**Researched:** 2026-01-31
**Domain:** macOS Quick Look Extension Development
**Confidence:** MEDIUM

## Summary

Quick Look extensions on macOS 26+ (Tahoe) use the modern App Extension architecture, replacing deprecated `.qlgenerator` plugins. Extensions are sandboxed bundles that integrate with Finder's Quick Look feature through the `QLPreviewingController` protocol. The extension registers via UTI (Uniform Type Identifier) rather than file extension matching.

For markdown rendering, the standard approach is parsing with `swift-markdown` (Apple's official library powered by cmark-gfm) and rendering to either HTML in WKWebView or RTF in NSTextView. However, WKWebView has documented performance issues in Quick Look contexts on macOS Big Sur and earlier, making NSTextView with AttributedString the recommended approach for immediate, smooth rendering.

The development workflow requires building the extension as an embedded target within a host app, installing to `~/Library/QuickLook/`, and running `qlmanage -r` to reload the Quick Look system. Testing is manual through Finder with debug logging for key milestones.

**Primary recommendation:** Use App Extension template with `QLPreviewingController` protocol, parse markdown with `swift-markdown`, render to NSAttributedString for NSTextView display (avoiding WKWebView issues), and automate build/install/reload workflow with Makefile.

## Standard Stack

The established libraries/tools for macOS Quick Look extension development:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| QuickLook framework | macOS 26+ | Extension infrastructure | Apple's official framework for preview extensions |
| swift-markdown | 0.7.3+ | Markdown parsing | Official Swift.org library, powered by cmark-gfm, used by DocC |
| Foundation AttributedString | iOS 15+/macOS 12+ | Styled text rendering | Native markdown support, thread-safe, copy-on-write |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSTextView | AppKit | Display rendered content | Recommended over WKWebView for Quick Look (avoids WebKit bugs) |
| qlmanage CLI | Built-in | Testing and reloading | Essential for development workflow (`qlmanage -r`, `qlmanage -p`) |
| Xcode App Extension template | Xcode 16+ | Project scaffolding | Provides boilerplate PreviewViewController |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| swift-markdown | Ink (John Sundell) | Ink is faster (O(N) complexity) but lacks official Apple support |
| swift-markdown | SwiftyMarkdown | Better for custom AttributedString styling, lacks GFM extensions |
| NSTextView | WKWebView | WKWebView renders HTML perfectly but has known bugs in Quick Look sandbox |
| Makefile | Shell script | Shell scripts simpler but lack dependency tracking and incremental builds |

**Installation:**
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main")
]
```

## Architecture Patterns

### Recommended Project Structure
```
md-quick-look/
├── md-quick-look/              # Host application (minimal, just to launch extension)
│   ├── Info.plist
│   └── main.swift
├── MDQuickLook/                 # Quick Look extension target
│   ├── PreviewViewController.swift
│   ├── Info.plist               # QLSupportedContentTypes configuration
│   └── Resources/
│       └── styles.css           # Optional: HTML styles if using WKWebView path
├── Makefile                     # Build/install/clean automation
└── samples/                     # Test markdown files
    ├── basic.md
    └── empty.md
```

### Pattern 1: App Extension Integration
**What:** Quick Look extension embedded within host app bundle
**When to use:** Always (required architecture for macOS 10.15+)
**Implementation:**
1. Create host app target (even if minimal)
2. Add Quick Look Preview Extension target
3. Embed extension in host app's `Contents/Library/QuickLook/`
4. Launch host app once to register extension with system

### Pattern 2: UTI-Based File Type Registration
**What:** Register supported file types via Uniform Type Identifiers in Info.plist
**When to use:** Always (UTI matching is required, extension matching insufficient)
**Example:**
```xml
<!-- MDQuickLook/Info.plist -->
<key>NSExtension</key>
<dict>
    <key>NSExtensionAttributes</key>
    <dict>
        <key>QLSupportedContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
            <string>public.plain-text</string>
        </array>
    </dict>
    <key>NSExtensionPointIdentifier</key>
    <string>com.apple.quicklook.preview</string>
    <key>NSExtensionPrincipalClass</key>
    <string>$(PRODUCT_MODULE_NAME).PreviewViewController</string>
</dict>
```

### Pattern 3: QLPreviewingController Protocol Implementation
**What:** Implement `preparePreviewOfFile(at:completionHandler:)` to generate preview
**When to use:** Always (core protocol requirement)
**Example:**
```swift
// Source: Apple Developer Documentation + community patterns
import Cocoa
import QuickLookUI
import Markdown

class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        // 1. Load file content
        guard let markdownContent = try? String(contentsOf: url, encoding: .utf8) else {
            handler(NSError(domain: "MarkdownError", code: 1))
            return
        }

        // 2. Parse markdown with swift-markdown
        let document = Document(parsing: markdownContent)

        // 3. Render to AttributedString (native Markdown support in macOS 12+)
        let attributedString = try? AttributedString(markdown: markdownContent)

        // 4. Display in NSTextView
        let textView = NSTextView(frame: self.view.bounds)
        textView.isEditable = false
        textView.textStorage?.setAttributedString(NSAttributedString(attributedString ?? ""))
        self.view.addSubview(textView)

        // 5. Signal completion
        handler(nil)
    }
}
```

### Pattern 4: Progressive Rendering Strategy
**What:** Render first paragraph immediately, stream remaining content asynchronously
**When to use:** Large markdown files where parsing/rendering takes >100ms
**Implementation approach:**
1. Split markdown into first paragraph and remainder
2. Parse and render first paragraph synchronously
3. Call completion handler immediately
4. Parse/render remainder on background queue
5. Update view on main queue as sections complete

**Note:** This pattern requires careful AttributedString mutation on main thread.

### Anti-Patterns to Avoid
- **Using WKWebView for HTML rendering:** WebKit has known bugs in Quick Look sandbox (scrolling lag, network client failures, first responder issues) especially pre-macOS 12. Use NSTextView with AttributedString instead.
- **Matching files by extension only:** System uses UTI matching, not extension matching. Must declare UTIs in QLSupportedContentTypes.
- **Manual installation without qlmanage -r:** Extensions won't activate without reloading Quick Look system daemon.
- **Assuming synchronous completion:** Must call completion handler even for sync rendering to signal preview ready.
- **Rendering raw markdown then updating:** Creates jarring visual transition. Render styled content before first display.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Markdown parsing | Custom regex-based parser | swift-markdown (Apple) | GFM spec compliance, handles edge cases (nested lists, code blocks, escaping), maintained by Swift.org |
| Markdown to AttributedString | Manual NSAttributedString construction | AttributedString(markdown:) initializer | Native iOS 15+/macOS 12+ support, handles bold/italic/code/links automatically |
| HTML generation from Markdown | String concatenation | swift-markdown + cmark-gfm visitor | Escaping, nesting, GFM extensions (tables, strikethrough, task lists) |
| Extension installation | Manual copy to ~/Library/QuickLook | Build phase + qlmanage -r script | Ensures clean install, rebuilds cache, handles code signing |
| UTI discovery for .md files | Hardcode file extensions | Declare standard UTIs | System reserves some extensions (.txt, .html), UTI more reliable |

**Key insight:** Markdown parsing complexity explodes with edge cases. GFM spec is 50+ pages. cmark-gfm is battle-tested C implementation with Swift wrapper. Don't reimplement.

## Common Pitfalls

### Pitfall 1: Extension Not Appearing in System Settings
**What goes wrong:** Extension builds successfully but doesn't show in System Settings > Extensions > Quick Look
**Why it happens:** Extension not registered with system; Quick Look daemon cache not updated
**How to avoid:**
1. Launch host app at least once (registers extension)
2. Run `qlmanage -r` to reload Quick Look daemon
3. Check extension enabled in System Settings > Extensions > Quick Look
**Warning signs:** `qlmanage -m` doesn't list your extension's bundle identifier

### Pitfall 2: UTI Conflicts with System Handlers
**What goes wrong:** Extension registered but system ignores it for certain file types
**Why it happens:** macOS reserves specific UTIs for system handlers (.txt, .plist pre-Monterey, .json on Apple Silicon Ventura+)
**How to avoid:**
- Check [https://github.com/sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) for list of reserved extensions per macOS version
- Test on target macOS version (26+ for this project)
- Use `mdls filename.md` to verify actual UTI assigned by system
**Warning signs:** `qlmanage -p sample.md` shows generic text preview instead of your extension

### Pitfall 3: Sandbox Permission Denials
**What goes wrong:** Extension crashes with "Sandbox: deny(1) file-read-data" errors
**Why it happens:** Extensions run in tight sandbox, inherit host app's entitlements, limited file access
**How to avoid:**
1. Use only `com.apple.security.files.user-selected.read-only` entitlement
2. Don't attempt network access (com.apple.security.network.client ignored in QL extensions)
3. Don't spawn external processes (blocked in Catalina+ sandboxed extensions)
4. Read only the file passed to `preparePreviewOfFile(at:)` URL
**Warning signs:** Console shows sandbox denial logs, extension fails silently

### Pitfall 4: WKWebView Performance Issues in Quick Look
**What goes wrong:** HTML rendering via WKWebView shows scrolling lag, delayed link navigation, or crashes
**Why it happens:** WebKit integration bugs in Quick Look sandbox (documented in Big Sur, partially fixed Monterey+)
**How to avoid:** Use NSTextView with AttributedString rendering instead of WKWebView with HTML
**Warning signs:**
- Scrollbar dragging moves window instead of content
- Internal links have 1-2 second delay
- Console shows "Quick Look Preview not allowing first responder"
- Network client failures despite entitlements

### Pitfall 5: Forgetting to Call Completion Handler
**What goes wrong:** Preview never displays, Finder shows indefinite spinner
**Why it happens:** `preparePreviewOfFile(at:completionHandler:)` requires calling handler to signal ready
**How to avoid:**
- Always call handler, even if rendering synchronous
- Call handler with error if preview generation fails
- Use `defer { handler(error) }` pattern to guarantee call
**Warning signs:** Finder Quick Look overlay hangs, never shows content or error

### Pitfall 6: Dynamic UTI Assignment Issues
**What goes wrong:** Files with same extension preview inconsistently
**Why it happens:** If file has dynamic UTI (no app claims it), Quick Look may fail to match
**How to avoid:**
- Declare exported UTI in host app Info.plist
- Include all common markdown UTIs in QLSupportedContentTypes
- Test with files created by different apps
**Warning signs:** Works for files created in one app, fails for others

## Code Examples

Verified patterns from official sources:

### Minimal QLPreviewingController Implementation
```swift
// Source: Apple Developer Documentation + SourceCodeSyntaxHighlight example
import Cocoa
import QuickLookUI
import Markdown

class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        self.view = NSView()
        self.view.autoresizingMask = [.width, .height]
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        do {
            // Load markdown content
            let content = try String(contentsOf: url, encoding: .utf8)

            // Parse and render to AttributedString (macOS 12+)
            let attributedString = try AttributedString(markdown: content)

            // Create NSTextView for display
            let textView = NSTextView(frame: self.view.bounds)
            textView.autoresizingMask = [.width, .height]
            textView.isEditable = false
            textView.textStorage?.setAttributedString(NSAttributedString(attributedString))

            self.view.addSubview(textView)
            handler(nil)
        } catch {
            handler(error)
        }
    }
}
```

### Info.plist UTI Configuration
```xml
<!-- Source: Apple Developer Documentation -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.razielpanic.md-quick-look.quicklook</string>
    <key>CFBundleName</key>
    <string>.md for QuickLook</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionAttributes</key>
        <dict>
            <key>QLSupportedContentTypes</key>
            <array>
                <string>net.daringfireball.markdown</string>
                <string>public.plain-text</string>
            </array>
        </dict>
        <key>NSExtensionPointIdentifier</key>
        <string>com.apple.quicklook.preview</string>
        <key>NSExtensionPrincipalClass</key>
        <string>$(PRODUCT_MODULE_NAME).PreviewViewController</string>
    </dict>
</dict>
</plist>
```

### Makefile Build Automation
```makefile
# Source: Community best practices (SourceCodeSyntaxHighlight, Makefiles for Mobile CI)
.PHONY: build install clean reload

QLEXT_NAME = md-quick-look.qlgenerator
INSTALL_DIR = $(HOME)/Library/QuickLook

build:
	xcodebuild -scheme "md-quick-look" -configuration Release

install: build
	rm -rf "$(INSTALL_DIR)/$(QLEXT_NAME)"
	cp -R "build/Release/$(QLEXT_NAME)" "$(INSTALL_DIR)/"

reload:
	qlmanage -r
	qlmanage -r cache

clean:
	rm -rf build/
	rm -rf "$(INSTALL_DIR)/$(QLEXT_NAME)"

test: install reload
	qlmanage -p samples/basic.md
```

### Debug Logging Pattern
```swift
// Source: Common practice across Quick Look extensions
import os.log

extension OSLog {
    private static var subsystem = "com.razielpanic.md-quick-look"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

class PreviewViewController: NSViewController, QLPreviewingController {
    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, url.path)

        // ... generate preview ...

        os_log("Rendering complete", log: .quicklook, type: .info)
        handler(nil)
    }
}

// View logs: log stream --predicate 'subsystem == "com.razielpanic.md-quick-look"' --level info
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .qlgenerator plugins in ~/Library/QuickLook | App Extension embedded in host app | macOS 10.15 (2019) | Extensions sandboxed, can't run external processes without XPC service |
| File extension matching | UTI-based matching | Always (QL design) | More reliable but requires UTI declaration, some extensions reserved |
| Objective-C QLPreviewPanel | Swift QLPreviewingController | macOS 10.15 | Modern Swift APIs, better async handling |
| HTML in WKWebView | RTF in NSTextView or AttributedString | Recommended since Big Sur bugs | Better performance in QL sandbox context |
| Manual HTML generation | swift-markdown + AttributedString(markdown:) | macOS 12+ native support | Simpler implementation, native styling |

**Deprecated/outdated:**
- **QLGenerator plugins:** Deprecated macOS 10.15, removed macOS 15 (Sequoia). Use App Extensions.
- **QLPreviewPanel (AppKit):** Legacy API for in-app previews. Use QLPreviewingController for extensions.
- **NSAttributedString(HTML:):** Deprecated for markdown. Use AttributedString(markdown:) on macOS 12+.
- **com.apple.security.temporary-exception.* entitlements:** App Review rejects these. Use proper entitlements or XPC service.

## Open Questions

Things that couldn't be fully resolved:

1. **Progressive rendering implementation details**
   - What we know: AttributedString is copy-on-write, thread-safe for reads
   - What's unclear: Best pattern for streaming updates to NSTextView without flicker
   - Recommendation: Start with synchronous rendering. Add progressive rendering only if >500ms for typical files. Test with 100KB+ markdown files.

2. **Exact markdown UTI priorities on macOS 26**
   - What we know: .md files typically map to "net.daringfireball.markdown" or "public.plain-text"
   - What's unclear: Whether macOS 26 Tahoe changed any UTI reservations vs. Sequoia
   - Recommendation: Declare both UTIs, test with `mdls` on actual macOS 26 system, monitor Console for conflicts.

3. **AttributedString markdown rendering limitations**
   - What we know: AttributedString(markdown:) supports bold, italic, code, links, strikethrough
   - What's unclear: Whether tables are rendered (user requirement says "include tables")
   - Recommendation: Test AttributedString(markdown:) with table syntax. If unsupported, fall back to swift-markdown AST traversal with custom AttributedString builder or HTML rendering.

4. **Build script preference: Makefile vs shell script**
   - What we know: Makefile better for dependency tracking, shell script simpler
   - What's unclear: User's team familiarity/preference (marked Claude's discretion)
   - Recommendation: Use Makefile. Provides idiomatic `make build`, `make install`, `make clean` commands. Prevents unnecessary rebuilds. Standard in open-source Quick Look extensions.

## Sources

### Primary (HIGH confidence)
- [Quick Look framework - Apple Developer Documentation](https://developer.apple.com/documentation/QuickLook) - Official framework documentation
- [QLPreviewingController - Apple Developer Documentation](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller) - Protocol specification
- [swift-markdown GitHub repository](https://github.com/swiftlang/swift-markdown) - Official Swift.org markdown parser (v0.7.3)
- [AttributedString with Markdown - Apple Developer Documentation](https://developer.apple.com/documentation/foundation/instantiating-attributed-strings-with-markdown-syntax) - Native markdown rendering

### Secondary (MEDIUM confidence)
- [QLMarkdown GitHub repository](https://github.com/sbarex/QLMarkdown) - Production Quick Look markdown extension, verified architecture patterns
- [SourceCodeSyntaxHighlight GitHub repository](https://github.com/sbarex/SourceCodeSyntaxHighlight) - XPC service pattern for unsandboxed processing
- [Creating file previews in macOS Catalina](https://blog.smittytone.net/2019/11/07/create_previews_macos_catalina/) - Step-by-step implementation guide
- [Creating and Configuring a Quick Look Project - Apple Developer Archive](https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/Quicklook_Programming_Guide/Articles/QLProjectConfig.html) - Legacy but still relevant configuration
- [Debug your Quick Look plugin - Medium](https://medium.com/@fousa/debug-your-quick-look-plugin-50762525d2c2) - Testing workflow (MEDIUM - verified against other sources)

### Tertiary (LOW confidence)
- [WebSearch: Quick Look extension development best practices 2026] - Ecosystem discovery, flagged WKWebView issues and deprecated APIs
- [WebSearch: Markdown parser comparison] - Library options survey
- [macOS Hints: Enable QuickLook](https://www.projectwizards.net/en/blog/2025/01/quicklook) - User-facing extension management
- [A quick look at QuickLook and its problems](https://eclecticlight.co/2024/04/05/a-quick-look-at-quicklook-and-its-problems/) - Community-identified issues

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - swift-markdown official, AttributedString native to macOS 12+, QuickLook framework is authoritative
- Architecture: HIGH - App Extension pattern verified in Apple docs and multiple production extensions
- Pitfalls: MEDIUM - WKWebView issues documented in community sources, sandbox constraints verified in Apple forums
- Progressive rendering: LOW - Pattern inferred from requirements but not verified in Quick Look context

**Research date:** 2026-01-31
**Valid until:** 2026-03-01 (30 days - macOS Quick Look API is stable)

**Notes:**
- User decisions constrain: Must use styled rendering from start (no raw markdown), manual Finder testing, build script automation, bundle identifier com.razielpanic.md-quick-look
- Claude's discretion areas: Build script format (recommended Makefile), logging control (recommended OSLog with subsystem), styling depth (recommended AttributedString defaults), version numbering (recommended semantic 0.1.0)
- Phase scope: Foundation only - get extension loading and displaying basic styled markdown. Advanced features (syntax highlighting, image handling) deferred to later phases per project decisions.
