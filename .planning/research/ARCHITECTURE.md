# Quick Look Extension Architecture

**Project:** md-spotlighter (macOS Markdown Quick Look Extension)
**macOS Target:** 14+ (Sonoma and later)
**Researched:** 2026-01-19

## Executive Summary

Quick Look extensions on macOS 14+ are **system-wide app extensions** that integrate with Finder's preview system. The modern architecture (QLPreviewProvider-based) replaces the deprecated qlgenerator approach entirely in macOS Sequoia and later.

For md-spotlighter, the architecture follows this model:

1. **Host Application** - Container for the extension (required by App Store/code signing)
2. **Quick Look Extension Bundle** - The `.appex` that handles markdown files
3. **Rendering Engine** - Processes markdown → HTML/styled content
4. **Optional XPC Service** - Offloads heavy rendering to separate process
5. **Sandbox Boundary** - Strict file access controls

The critical insight: **Quick Look extensions run in a highly sandboxed process** with limited file system access. This directly affects how markdown files are read and how styling is applied.

---

## Extension Anatomy: Modern Architecture (macOS 14+)

### Architecture Overview

```
┌─────────────────────────────────────────┐
│     md-spotlighter Host Application     │
│    (provides App Store presence)        │
├─────────────────────────────────────────┤
│  QLPreviewExtension.appex (Sandboxed)   │
│  ├─ PreviewProvider.swift               │
│  │  └─ QLPreviewProvider subclass        │
│  ├─ Info.plist                          │
│  │  └─ QLSupportedContentTypes = [.md]  │
│  └─ Entitlements.plist                  │
│     └─ com.apple.security.files...      │
├─────────────────────────────────────────┤
│  QLMarkdownRenderXPC.xpc (Optional)     │
│  └─ Heavy rendering offloaded here      │
└─────────────────────────────────────────┘
```

### Two Implementation Approaches

#### Approach 1: Data-Based QLPreviewProvider (Recommended)

**Modern, preferred approach for macOS 14+**

```swift
import QuickLookUI
import SwiftUI

class PreviewProvider: QLPreviewProvider {
    override func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        // 1. Read markdown file (constrained by sandbox)
        guard let data = try? Data(contentsOf: request.fileURL) else {
            throw NSError(domain: "QLMarkdown", code: -1)
        }

        // 2. Parse markdown to HTML
        let markdown = String(data: data, encoding: .utf8) ?? ""
        let html = parseMarkdown(markdown)

        // 3. Return styled HTML reply
        let reply = QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 800, height: 600),
            createDataUsing: { completion in
                completion(html.data(using: .utf8))
            }
        )
        return reply
    }
}
```

**Key characteristics:**
- `QLPreviewProvider` is a protocol/base class you subclass
- Implement single method: `providePreview(for:) async throws -> QLPreviewReply`
- Receives `QLFilePreviewRequest` containing the file URL
- Returns `QLPreviewReply` with content (HTML, PDF, drawing, or file URL)
- **Runs in sandboxed process** with tight file access
- Better performance: asynchronous, resource-aware

**Entry point configuration in Info.plist:**
```xml
<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>
```

#### Approach 2: View-Based QLPreviewingController (Deprecated)

**Older approach, being phased out. NOT recommended for new projects.**

Requires:
- `PreviewViewController` inheriting from `UIViewController` or `NSViewController`
- Implementation of `preparePreviewOfFileAtURL:completionHandler:`
- Storyboard-based UI (`MainInterface.storyboard`)
- View hierarchy management

**Why not for md-spotlighter:**
- Performance overhead from view management
- More complex lifecycle
- Apple is moving away from this pattern
- Not idiomatic for system extensions

### Critical Architectural Decision: Extension Lifecycle

Quick Look extensions do **NOT** stay running. The lifecycle is:

1. **File selected in Finder** → Quicklook panel opens
2. **System activates extension** (launches `.appex` process)
3. **`providePreview` called** with file URL
4. **Response generated** (HTML, PDF, drawing, etc)
5. **System caches result** (may reuse without calling extension)
6. **Process terminates** after timeout (~seconds)

**Implication for md-spotlighter:**
- No persistent state across previews
- No background processing
- Each preview generation is independent
- Must complete rendering **within timeout** (typically 5-10 seconds)
- Heavy computation should be XPC-offloaded

---

## Component Boundaries

### 1. Quick Look Extension (.appex Bundle)

**Location in App Bundle:**
```
md-spotlighter.app/
├─ Contents/Library/Application Support/
│  └─ QLPreviewExtension.appex/
│     ├─ Contents/
│     │  ├─ MacOS/QLPreviewExtension
│     │  ├─ Resources/
│     │  │  └─ Assets.xcassets
│     │  ├─ Info.plist
│     │  └─ _CodeSignature/
│     └─ (code-signed separately)
```

**Responsibilities:**
- Receive file URL from Quick Look coordinator
- Validate file type (markdown extension/UTI)
- Orchestrate markdown rendering
- Build response object (HTML + styling)
- Return within time limit

**Access and Constraints:**
- ✅ Can read: File being previewed (via `fileURL` parameter)
- ✅ Can read: Bundle resources (CSS, fonts, templates)
- ❌ Cannot read: Other user files (sandboxed)
- ❌ Cannot execute: External processes, scripts
- ❌ Cannot use: Network (no remote image fetching)

### 2. Rendering Engine (Core Logic)

**Location:** Inside `.appex` or as standalone framework

**Responsibilities:**
- Parse markdown to AST
- Apply syntax highlighting
- Convert to styled HTML/RTF
- Handle special markdown features (tables, code blocks, etc)

**Key Decision: Rendering Format**

| Format | Rendering | Performance | Compatibility | Notes |
|--------|-----------|-------------|---------------|-------|
| **HTML+CSS** | WKWebView | Medium | macOS 14+ | Modern, flexible styling, some WebKit issues pre-Monterey |
| **RTF** | NSTextView | High | macOS 10.15+ | Reliable, limited styling, no syntax highlighting |
| **PDF** | PDFKit | Medium | All | Static output, good for printing |
| **Drawing** | Core Graphics | High | All | Direct pixel drawing, maximum control |

**Recommendation for md-spotlighter:**
- **Primary: HTML** via WKWebView (modern, matches web markdown rendering)
- Rationale: macOS 14+ has solid WebKit support in Quick Look
- CSS allows instant theme switching (light/dark)
- Syntax highlighting via CSS classes

### 3. XPC Service (Optional but Recommended)

**When to use XPC:**
- ✅ Heavy markdown processing (large files, complex extensions)
- ✅ Syntax highlighting with external libraries
- ✅ Diagram rendering (Mermaid, PlantUML)
- ✅ Image resizing/optimization
- ✅ Remote resource fetching (if needed)

**Why XPC improves md-spotlighter:**
- Extension remains responsive if rendering stalls
- Can exceed sandbox restrictions (with explicit entitlements)
- Can cache results across preview sessions
- Can handle failures without crashing extension

**XPC Communication Pattern:**

```swift
// In extension (sandboxed)
let connection = NSXPCConnection(serviceName: "com.example.md-spotlighter.render")
connection.remoteObjectInterface = NSXPCInterface(with: MarkdownRenderingProtocol.self)
connection.resume()

let proxy = connection.remoteObjectProxyWithErrorHandler { error in
    // Fallback: render locally or return error
}

// Call XPC service
proxy.renderMarkdown(markdown) { html in
    // Receive HTML from XPC service
}
```

**XPC Service Bundle Structure:**
```
QLMarkdownRenderXPC.xpc/
├─ Contents/
│  ├─ MacOS/QLMarkdownRenderXPC
│  ├─ Info.plist
│  └─ _CodeSignature/
```

---

## Data Flow: Markdown File → Styled Preview

### Complete Rendering Pipeline

```
1. FILE SELECTION
   └─> User selects .md file in Finder

2. QUICK LOOK ACTIVATION
   └─> QuickLook framework queries system for compatible extension
   └─> Finds md-spotlighter via QLSupportedContentTypes in Info.plist

3. EXTENSION LAUNCH
   └─> macOS launches QLPreviewExtension.appex process
   └─> Security sandbox applied (minimal file access)

4. PREVIEW REQUEST
   └─> Quick Look coordinator calls:
       PreviewProvider.providePreview(for: QLFilePreviewRequest)
   └─> request.fileURL = /Users/.../document.md

5. FILE READ (Sandboxed)
   └─> Extension reads markdown file from request.fileURL
       (This URL is security-scoped; reading works automatically)
   └─> Convert bytes to String (UTF-8 encoded)

6. PARSING (XPC or Local)
   └─ Option A (Local): Parse markdown using cmark-gfm or similar
   └─ Option B (XPC): Send markdown to XPC service for parsing

7. RENDERING
   └─> Parse markdown AST
   └─> Apply theme (CSS)
   └─> Generate HTML:
       <html>
         <head>
           <style>/* theme CSS */</style>
         </head>
         <body>
           <!-- rendered markdown -->
         </body>
       </html>

8. RESPONSE CREATION
   └─> Create QLPreviewReply with HTML content
   └─> Specify content type: .html (UTType.html)
   └─> Provide content size for layout

9. DELIVERY
   └─> Return QLPreviewReply to Quick Look coordinator

10. DISPLAY
    └─> Quick Look coordinator embeds HTML in WKWebView
    └─> Result displayed in preview panel

11. CLEANUP
    └─> Extension process keeps running (may be reused)
    └─> After timeout, process terminated
    └─> Result cached by Quick Look (may not call extension again)
```

### Performance Checkpoints (Where Delays Occur)

| Checkpoint | Typical Duration | Concern | Mitigation |
|------------|------------------|---------|-----------|
| Extension launch | 100-500ms | Cold start | Preload if possible |
| File read | 10-100ms | I/O bound | Async, buffered I/O |
| Markdown parsing | 50-500ms | Depends on file size | XPC for large files, caching |
| HTML generation | 20-100ms | CPU bound | Template pre-compilation |
| WKWebView render | 100-300ms | DOM parsing | Simple HTML, limit styling |
| **Total (perceived)** | **300-1500ms** | User-facing | Must be < 2 seconds |

**For instant rendering (project requirement):**
1. Keep markdown files < 10MB (parsing takes seconds for huge files)
2. Precompile CSS (don't inline large stylesheets)
3. Avoid external resources (images, fonts must be bundled)
4. Test with representative files and profile

---

## File I/O and Permissions Model

### Sandbox Constraints for Quick Look Extensions

Quick Look extensions run in **macOS App Sandbox** with minimal privileges:

**Default Entitlements:**
```xml
<!-- Enabled for all Quick Look extensions -->
<key>com.apple.security.app-sandbox</key>
<true/>

<!-- Can read file passed by Quick Look -->
<key>com.apple.security.files.user-selected.read-only</key>
<true/>

<!-- Limited debugging (gets disabled in production) -->
<key>com.apple.security.get-task-allow</key>
<true/>
```

**What this means:**
- ✅ Can read: The file URL provided by Quick Look (security-scoped)
- ✅ Can read: Bundle resources (CSS, fonts, templates)
- ✅ Can write: Temporary cache in app container
- ❌ Cannot read: Other files in user's home directory
- ❌ Cannot read: Local images referenced in markdown (without special entitlement)
- ❌ Cannot execute: shell scripts, external processes
- ❌ Cannot make: network requests

### Handling Image Embedding

**Problem:** Markdown often references local images: `![alt](/path/to/image.png)`

**Solutions:**

**Option 1: Disable embedded images (simplest)**
- Parse markdown but strip image tags
- Show `[Image: filename.png]` as placeholder
- Avoids permission issues entirely

**Option 2: Add Read-Only Entitlement (requires user grant)**
```xml
<key>com.apple.security.files.all</key>
<string>read-only</string>
```
- ❌ Requires full-disk read access
- ❌ Triggers security warnings
- ❌ May be rejected by App Store for some categories

**Option 3: XPC Service with Different Entitlements**
- Extension stays sandboxed (minimal entitlements)
- XPC service gets broader file access (configured separately)
- XPC fetches images, returns data to extension
- ✅ More secure, better UX

**Recommendation for md-spotlighter:**
- Start with Option 1 (no image embedding)
- If users request images: implement Option 3 (XPC-based image loading)
- Only resort to Option 2 if other options exhausted

---

## Rendering Pipeline Architecture

### HTML-Based Rendering (Recommended)

**Flow:**
```
Markdown Text
    ↓
[Parse to AST]
    ↓ (using cmark-gfm or similar)
[Syntax Highlight Code Blocks]
    ↓
[Apply Theme CSS]
    ↓
[Generate HTML]
    ↓
[Wrap with head/style tags]
    ↓
QLPreviewReply.init(dataOfContentType: .html, ...)
    ↓
Quick Look displays in WKWebView
```

**Implementation Example:**

```swift
import QuickLookUI

class PreviewProvider: QLPreviewProvider {
    override func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        guard let markdown = try? String(contentsOf: request.fileURL, encoding: .utf8) else {
            throw RenderError.cantReadFile
        }

        // Parse and render to HTML
        let html = MarkdownRenderer.render(markdown)

        return QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 800, height: 600),
            createDataUsing: { completion in
                completion(html.data(using: .utf8)!)
            }
        )
    }
}
```

### CSS Theme Injection

**Pattern:**
```html
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
/* Light theme CSS (changes for dark mode) */
body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  line-height: 1.6;
  color: #333;
  background: white;
  padding: 20px;
}
code {
  background: #f0f0f0;
  border-radius: 4px;
  padding: 2px 6px;
}
/* ... more theme CSS ... */
</style>
</head>
<body>
<!-- rendered markdown HTML -->
<h1>My Document</h1>
<p>Content here...</p>
</body>
</html>
```

**Dark Mode Support:**
- Quick Look respects system appearance
- Detect via CSS media query: `@media (prefers-color-scheme: dark)`
- Two theme sets in HTML or separate stylesheets

---

## Build and Signing Requirements

### Bundle Structure for md-spotlighter

```
md-spotlighter.app/
├─ Contents/
│  ├─ MacOS/
│  │  └─ md-spotlighter (host app executable)
│  ├─ Library/
│  │  └─ Application Support/
│  │     └─ QLPreviewExtension.appex/
│  │        ├─ Contents/
│  │        │  ├─ MacOS/QLPreviewExtension
│  │        │  ├─ Resources/
│  │        │  │  ├─ Assets.xcassets
│  │        │  │  └─ styles.css
│  │        │  ├─ Info.plist
│  │        │  └─ _CodeSignature/
│  ├─ Resources/
│  │  └─ MainWindow.nib
│  ├─ Info.plist
│  ├─ PkgInfo
│  └─ _CodeSignature/
```

### Host Application Info.plist

**Required for App Store distribution:**
```xml
<key>CFBundleIdentifier</key>
<string>com.example.md-spotlighter</string>

<key>CFBundleVersion</key>
<string>1</string>

<key>CFBundleShortVersionString</key>
<string>1.0</string>

<!-- App must have a visible window or UI element -->
<key>LSUIElement</key>
<false/> <!-- Must be false for App Store -->
```

### Extension Info.plist

**Critical for file type association:**
```xml
<key>CFBundleIdentifier</key>
<string>com.example.md-spotlighter.QLPreviewExtension</string>

<key>NSExtensionPrincipalClass</key>
<string>$(PRODUCT_MODULE_NAME).PreviewProvider</string>

<!-- File types supported -->
<key>NSExtensionAttributes</key>
<dict>
  <key>QLSupportedContentTypes</key>
  <array>
    <string>net.daringfireball.markdown</string> <!-- UTType for .md -->
    <string>public.plain-text</string> <!-- Fallback for .md without UTType -->
  </array>

  <!-- Optional: specify supported content types for thumbnails -->
  <key>QLSupportedContentTypesForThumbnail</key>
  <array>
    <string>net.daringfireball.markdown</string>
  </array>
</dict>

<!-- Rendering preferences -->
<key>QLThumbnailMinimumSize</key>
<integer>16</integer> <!-- For list view icons -->

<key>QLPreviewHeight</key>
<integer>600</integer>

<key>QLPreviewWidth</key>
<integer>800</integer>

<!-- Markdown: use data-based preview, not view-based -->
<key>QLIsDataBasedPreview</key>
<true/>
```

### Extension Entitlements

**File: QLPreviewExtension.entitlements**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <!-- Core sandbox (required) -->
  <key>com.apple.security.app-sandbox</key>
  <true/>

  <!-- Can read file passed by Quick Look -->
  <key>com.apple.security.files.user-selected.read-only</key>
  <true/>

  <!-- Debug allowance (remove for production) -->
  <key>com.apple.security.get-task-allow</key>
  <true/>

  <!-- If using XPC service -->
  <key>com.apple.security.application.groups</key>
  <array>
    <string>group.com.example.md-spotlighter</string>
  </array>
</dict>
</plist>
```

### Code Signing Process

**In Xcode:**

1. **Select Extension Target** → Build Settings
2. **Set Team ID** (required for macOS app)
3. **Code Signing Identity** → Mac Developer (development) or 3rd Party Mac (distribution)
4. **Set Provisioning Profile** → Automatic or manual
5. **Provisioning Profile** for extension must match identifier (`com.example.md-spotlighter.QLPreviewExtension`)

**Signing Identity Requirements:**
- ✅ Host app and extension must have matching Team ID
- ✅ Extension identifier must be scoped under host (e.g., `host.identifier.extension-name`)
- ✅ Each target (host, extension, XPC service) gets separate code signature
- ✅ Development: automatic provisioning usually works
- ✅ Release: explicit provisioning profile required for App Store

**Command-line verification:**
```bash
# Check if extension is signed
codesign -v /path/to/md-spotlighter.app/Contents/Library/Application\ Support/QLPreviewExtension.appex

# Verify entitlements
codesign -d --entitlements - /path/to/extension.appex

# Check embedded content types
grep -A 5 "QLSupportedContentTypes" /path/to/extension.appex/Contents/Info.plist
```

---

## Extension Lifecycle and Resource Management

### Activation Timeline

1. **Finder Selection** (0ms)
   - User selects markdown file

2. **Quick Look Panel Open** (10-50ms)
   - Quick Look framework initializes

3. **Extension Discovery** (20-100ms)
   - System queries installed extensions for supported types
   - Checks QLSupportedContentTypes in Info.plist

4. **Process Launch** (100-500ms)
   - macOS launches `.appex` process in sandbox
   - Extension binary loaded, linked, initialized

5. **Preview Generation** (300-1000ms)
   - `PreviewProvider.providePreview(for:)` called
   - Markdown parsing and rendering
   - HTML response generated

6. **Cache Storage** (10-50ms)
   - Quick Look stores result in cache

7. **Display** (100-300ms)
   - HTML rendered in WKWebView
   - Preview shown to user

### Timeout Handling

**If preview generation exceeds timeout (~10 seconds):**
- Extension process terminated
- Quick Look shows error or placeholder
- User experiences: "Could not generate preview"

**Prevention:**
- Profile rendering with large markdown files
- Set realistic timeout expectations (< 5 seconds for 10MB file)
- If timeout is problematic, move parsing to XPC service

### Resource Cleanup

**Process Lifetime:**
- Extension process remains running after preview generated
- Reused if same file previewed again
- Terminated after inactivity (~5-30 seconds)
- All memory and file handles released on termination

**Implications:**
- Don't hold resources across multiple preview requests
- Safe to load libraries on first call (they'll be cached)
- Caching in `.appex` process is ephemeral (lost when process exits)
- For persistent cache, use XPC service or app container

---

## Performance Architecture Decisions

### Markdown Parsing Library Selection

| Library | Performance | Features | Sandbox Compat. | Notes |
|---------|-------------|----------|-----------------|-------|
| **cmark-gfm** | Fast (C impl) | GitHub Flavored | ✅ Yes | Recommended: used by QLMarkdown |
| **commonmark-swift** | Medium | CommonMark spec | ✅ Yes | Pure Swift, no external deps |
| **markdown-swift** | Slow | Limited | ✅ Yes | Lightweight, limited extensions |
| **down** (swift-cmark) | Fast | GFM + extras | ✅ Yes | Good balance |

**Recommendation:** cmark-gfm via Swift wrapper
- Proven in QLMarkdown project
- Fast parsing (C implementation)
- Supports all GitHub markdown features
- Available via CocoaPods/SPM

### Syntax Highlighting Strategy

**For code blocks in markdown:**

**Option 1: Highlight.js (JavaScript in WebView)**
- ❌ Requires JavaScript execution in WKWebView
- ❌ Can impact performance
- ✅ Supports 200+ languages
- ❌ Cannot be loaded from network (sandbox)

**Option 2: Native Swift highlighter (Highlighter library)**
- ✅ Fast (native code)
- ✅ Can be called in sandbox
- ✅ Deterministic results
- ❌ Limited language support
- ❌ Must embed color scheme data

**Option 3: No syntax highlighting (CSS-only)**
- ✅ Instant rendering
- ✅ Simple implementation
- ✅ Works with any WKWebView
- ❌ Less visually appealing for code
- ✅ Still readable (monospace font)

**Recommendation for MVP:** Option 3 (CSS-only)
- Then move to Option 2 if desired (Swift highlighter library)
- Avoid Option 1 (JavaScript adds complexity)

### Large File Handling

**For files > 5MB:**
1. Consider truncating in preview (show first 50KB)
2. Or implement XPC-based streaming rendering
3. Or use lazy rendering (render visible sections only)

**In Initial Implementation:**
- Render entire file (simpler logic)
- Test performance on 10MB file
- If acceptable, leave as-is
- If slow, optimize in Phase 2

---

## Known Architecture Pitfalls

### Pitfall 1: Missing File Type Registration

**What goes wrong:**
- Extension built but Quick Look never calls it
- User selects .md file, no preview appears

**Root cause:**
- Missing or incorrect `QLSupportedContentTypes` in Info.plist
- Using file extension (`.md`) instead of UTI
- Identifier mismatch between extension and registration

**Prevention:**
- Use correct UTI: `net.daringfireball.markdown`
- Test with: `mdls -name kMDItemContentType file.md` to verify UTI
- Verify with: `pluginkit -m plugin -p com.apple.quicklook.extension`

### Pitfall 2: Sandbox Violation on Image Embedding

**What goes wrong:**
- Markdown with local image: `![alt](/Users/me/image.png)`
- Extension crashes with sandbox violation
- Preview fails silently

**Root cause:**
- Extension tries to read file outside passed URL
- Sandbox denies access

**Prevention:**
- Don't parse and load local image paths
- Strip image tags or show placeholder
- Use XPC service for image loading if needed

### Pitfall 3: Timeout on Large Files

**What goes wrong:**
- Selecting 50MB markdown file
- Preview takes 15+ seconds
- Quick Look shows "Could not generate preview"
- User thinks extension is broken

**Root cause:**
- Parsing and rendering in main thread
- Blocking operation exceeds timeout

**Prevention:**
- Profile with test files (5MB, 10MB, 50MB)
- Set file size limit for rendering
- Implement truncation or streaming
- Use XPC service for background parsing

### Pitfall 4: View-Based Controller Instead of QLPreviewProvider

**What goes wrong:**
- Extension works but requires complex storyboard
- Performance is sluggish
- Breaks on macOS future versions

**Root cause:**
- Using deprecated QLPreviewingController pattern
- Not adopting modern QLPreviewProvider

**Prevention:**
- Use QLPreviewProvider from the start (data-based)
- Delete MainInterface.storyboard
- Set `QLIsDataBasedPreview = true` in Info.plist

### Pitfall 5: Hardcoded CSS Theme

**What goes wrong:**
- Extension always shows light theme
- User switches macOS to dark mode
- Preview remains light (jarring, unreadable)

**Root cause:**
- CSS doesn't include media query for system appearance
- No support for `prefers-color-scheme` media query

**Prevention:**
- Always include: `@media (prefers-color-scheme: dark)`
- Test in both light and dark appearance
- Use CSS variables for theme colors

---

## Recommended Architecture Summary

### For md-spotlighter MVP

**Choose this architecture:**

1. **Host App:**
   - Minimal macOS app (required for extension hosting)
   - Single window with "Extension installed" message
   - Settings window for customizing theme

2. **QLPreviewExtension.appex:**
   - QLPreviewProvider subclass (data-based)
   - Async `providePreview()` method
   - No storyboards or view hierarchy
   - Lightweight (< 5MB)

3. **Rendering Engine:**
   - Embed cmark-gfm for parsing
   - Generate HTML with inline CSS theme
   - Support light/dark via CSS media query
   - No image embedding (use placeholders)

4. **No XPC Service (initially):**
   - Simple enough to render in extension process
   - Revisit for Phase 2 if performance issues arise

5. **Content Type:**
   - Return HTML via `QLPreviewReply(dataOfContentType: .html)`
   - WKWebView renders it automatically

6. **Entitlements:**
   - Standard sandbox only
   - `com.apple.security.files.user-selected.read-only`
   - No special file access

This architecture is:
- ✅ Modern (macOS 14+ native pattern)
- ✅ Simple (no complex lifecycle management)
- ✅ Performant (async, timeouts respected)
- ✅ Future-proof (aligns with Apple's direction)
- ✅ Secure (minimal sandbox escape needed)

---

## Sources

- [Apple Quick Look Framework Documentation](https://developer.apple.com/documentation/quicklook/)
- [QLPreviewProvider Apple Documentation](https://developer.apple.com/documentation/quicklookui/qlpreviewprovider)
- [QLPreviewingController Documentation](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [GitHub: sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) - Modern markdown extension reference
- [GitHub: sbarex/SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight) - Advanced rendering patterns
- [Eclectic Light: How QuickLook Creates Thumbnails and Previews](https://eclecticlight.co/2024/11/04/how-does-quicklook-create-thumbnails-and-previews-with-an-update-to-mints/)
- [Apple Documentation: Accessing Files from macOS App Sandbox](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
- [Apple TN3125: Inside Code Signing: Provisioning Profiles](https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles)
- [WWDC 2019 Session 719: What's New in File Management and Quick Look](https://developer.apple.com/videos/play/wwdc2019/719/)
