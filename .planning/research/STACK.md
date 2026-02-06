# Technology Stack: md-quick-look

**Project:** Quick Look extension for markdown rendering on macOS
**Researched:** January 2026 (v1.0), February 2026 (v1.1 additions, v1.2 additions)
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
| **Text rendering** | NSAttributedString + Core Text | Styled text output | Native macOS, performant, no external dependencies for rendering; direct markdown to NSAttributedString conversion avoids WebKit overhead |
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

---

## v1.1 Public Release Stack Additions

**Added:** February 2026 for v1.1 milestone
**Focus:** App polish (About, Preferences, Status, Icon) + GitHub release automation

### macOS App UI (Host App)

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **SwiftUI Settings scene** | Built-in (macOS 11+) | Preferences window | Native SwiftUI scene. Automatic Preferences menu item + Cmd+, shortcut. Uses TabView for multi-page settings. Zero external dependencies. Standard macOS behavior. |
| **SwiftUI Window scene** | Built-in (macOS 13+) | Custom About window | Replace default Credits.rtf with fully custom About UI. Full control over layout, links, version display. Supports `.windowResizability(.contentSize)` for fixed size. |
| **@AppStorage** | Built-in SwiftUI | Settings persistence | Property wrapper auto-saves to UserDefaults. Zero boilerplate vs manual NSUserDefaults. Use for toggles, text fields, selections in Settings. |
| **SF Symbols 7** | Built-in (macOS 26) | UI icons (tabs, buttons) | 6,900+ system icons. Use `systemImage:` in SwiftUI Labels. **NOT for app icon** - only for UI elements. Free, matches system design language. |

### App Icon Design & Integration

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Icon Composer** | Beta (macOS 15.3+) | App icon creation | Apple's official icon tool. Multi-layer icons with Liquid Glass effects. Exports to Xcode-compatible format. Supports Mac, iPhone, iPad, Watch. Native integration, professional results. |
| **Figma** | Web/Desktop | Icon design source | Free templates available ([macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027), [Official macOS App Icon Template](https://www.figma.com/community/file/1040708197994685442)). Export 1024x1024 PNG, import to Icon Composer. |
| **Alternative: Image2icon** | $9.99 (Pro) | Icon conversion | Fallback if Icon Composer unavailable. Drag PNG to app, export .icns. Simpler than Icon Composer but less polish. |
| **Alternative: IconGenerator** | Free (open-source) | Icon generation | GitHub: onmyway133/IconGenerator. macOS app, drag PNG to generate .icns. Third option if others unavailable. |

**Recommendation:** Icon Composer (Apple's official tool) > Image2icon (simple, polished) > IconGenerator (free fallback). All three work fine - pick based on availability.

### GitHub Release Automation

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **gh CLI** | Latest | GitHub release creation | Official GitHub CLI. Simple workflow: `gh release create v1.0 ./app.dmg`. Supports asset upload, release notes, draft releases. Installed via Homebrew. No CI/CD complexity for first release. |
| **create-dmg** | Latest (Node.js) | DMG installer generation | Generates professional DMG with background images, proper layout. Minimal config, good defaults. Handles code signing integration. Node.js-based (requires Node 20+). Industry standard for macOS releases. |
| **Alternative: create-dmg (shell)** | Latest | DMG generation | Bash-based version. More manual config vs Node.js version. Use if Node.js unavailable. Both create same quality DMG. |

### Code Signing & Notarization

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **xcrun notarytool** | Built-in (Xcode 14+) | App notarization | Required for macOS apps distributed outside App Store. Submit to Apple's malware scanning. Replaced altool (deprecated Nov 2023). Only tool supported as of 2026. Command-line, ships with Xcode. |
| **xcrun stapler** | Built-in (Xcode) | Notarization ticket stapling | Attaches notarization ticket to .app bundle. Required after notarization. One command: `xcrun stapler staple YourApp.app`. Built into Xcode. |
| **Developer ID certificate** | Apple Developer Program | Code signing | Required for distribution outside App Store. $99/year Apple Developer membership. Download in Xcode > Preferences > Accounts > Manage Certificates. |

### Development & Build Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Xcode 14+** | Build, sign, archive | Product > Archive for release builds. Required for notarytool. Build for "Any Mac" (Apple Silicon + Intel universal binary). |
| **Homebrew** | Package management | Install gh CLI: `brew install gh`. Install Node.js: `brew install node`. Standard macOS package manager. |
| **Git** | Version control | Tag releases: `git tag v1.0 && git push --tags`. gh CLI uses tags to create GitHub releases. Already installed on macOS. |
| **Node.js** | JavaScript runtime | Required for create-dmg (Node.js version). Version 20+. Install via Homebrew or nodejs.org. |

---

## v1.2 Rendering Polish Stack Additions

**Added:** February 2026 for v1.2 milestone
**Focus:** Quick Look window sizing, preview pane optimization, table improvements, YAML front matter, GFM task list checkboxes

### Feature 1: Quick Look Window Sizing and Content Layout

**No new dependencies required.** Uses existing AppKit APIs.

| API / Component | Source | Purpose | Integration Point |
|----------------|--------|---------|-------------------|
| **NSViewController.preferredContentSize** | AppKit (built-in) | Set initial Quick Look window dimensions | Set in `PreviewViewController` before calling completion handler |
| **NSView.autoresizingMask** | AppKit (built-in) | Ensure content resizes with window | Already in use (`.width`, `.height` on scrollView) |
| **NSTextContainer.widthTracksTextView** | AppKit (built-in) | Text reflows on window resize | Already in use (`true`) |

**How it works:** `PreviewViewController` subclasses `NSViewController`, which inherits `preferredContentSize` from NSViewController. Setting this property tells the Quick Look host what initial window size is preferred. The Quick Look host may or may not honor it depending on context (spacebar preview vs preview pane).

**Key findings:**
- `preferredContentSize` sets the initial window dimensions. It is advisory -- the host can ignore it.
- On macOS Catalina, setting `preferredContentSize` could break autoresizing of subviews. This bug was fixed in Big Sur. Since this project targets macOS 14.0+, this is not a concern. (Source: [Apple Developer Forums thread 673369](https://developer.apple.com/forums/thread/673369))
- The current code already uses `autoresizingMask = [.width, .height]` on the scroll view, which handles resize correctly.
- **Recommendation:** Set `preferredContentSize` to a sensible default (e.g., `NSSize(width: 800, height: 600)`) in `loadView()` or early in `preparePreviewOfFile`. The current code already creates the view at 800x600 but does not explicitly set `preferredContentSize`.

**Confidence:** MEDIUM -- preferredContentSize behavior is documented for NSViewController, but Quick Look-specific behavior is poorly documented. Testing on target macOS versions is essential.

### Feature 2: Preview Pane Rendering Optimization

**No new dependencies required.** Uses standard AppKit view lifecycle.

| API / Component | Source | Purpose | Integration Point |
|----------------|--------|---------|-------------------|
| **view.bounds.size.width** | AppKit (built-in) | Detect available width at render time | Check in `preparePreviewOfFile` to adjust layout |
| **NSView.viewDidLayout()** | AppKit (built-in) | React to layout changes after display | Override in `PreviewViewController` for dynamic adjustment |
| **NSTextContainer.containerSize** | AppKit (built-in) | Control text wrap width | Already in use; adjust based on detected width |

**How it works:** There is NO explicit API to distinguish "Finder preview pane" from "spacebar Quick Look window." Both contexts invoke the same `QLPreviewingController.preparePreviewOfFile(at:completionHandler:)` method. The difference is only the view size the host provides.

**Detection strategy:** Use `view.bounds.size.width` at render time to detect narrow contexts. When width is below a threshold (approximately 300-400pt), apply compact layout adjustments:
- Reduce `textContainerInset` (e.g., from 20pt to 10pt)
- Scale down heading font sizes
- Switch tables to a more compact mode or horizontal scroll
- Reduce paragraph spacing

**Reactive resizing:** Override `viewDidLayout()` on PreviewViewController to detect if the view is resized after initial render (e.g., user resizes Finder column). This would allow re-adjusting layout dynamically, though for v1.2 a one-time check at render time is likely sufficient.

**Confidence:** HIGH -- This approach is pure standard AppKit. No Quick Look-specific API is needed; the width check is straightforward.

### Feature 3: Table Rendering Improvements for Narrow Spaces

**No new dependencies required.** Enhances existing `TableRenderer` and `NSTextTable` usage.

| API / Component | Source | Purpose | Integration Point |
|----------------|--------|---------|-------------------|
| **NSTextTable.layoutAlgorithm** | AppKit (built-in) | Switch between fixed and automatic table layout | Currently uses `.fixedLayoutAlgorithm`; consider `.automaticLayoutAlgorithm` |
| **NSTextBlock.setContentWidth(_:type:)** | AppKit (built-in) | Set column widths as percentage or absolute | Currently uses `.absoluteValueType`; add `.percentageValueType` option |
| **NSTextTableBlock padding/border** | AppKit (built-in) | Cell styling | Already in use |

**Current state:** The `TableRenderer` uses `.fixedLayoutAlgorithm` with measured absolute column widths. It has a `maxTableWidth` of 800pt and scales columns proportionally if they exceed it.

**Improvements for narrow spaces:**
1. **Percentage-based column widths:** Instead of absolute widths, use `.percentageValueType` with `NSTextBlock.setContentWidth()`. This makes tables responsive to container width. Divide 100% across columns based on content measurement ratios.
2. **Automatic layout algorithm:** Switch from `.fixedLayoutAlgorithm` to `.automaticLayoutAlgorithm` when the available width is narrow. The automatic algorithm lets NSTextTable size columns based on content, similar to CSS `table-layout: auto`. Note: automatic layout may be slower for large tables.
3. **Line wrapping in cells:** Currently using `.byTruncatingTail` line break mode. For narrow views, switch to `.byWordWrapping` so cell content wraps instead of being truncated.
4. **Container width awareness:** Pass the available container width to `TableRenderer` so it can adapt column sizing strategy.

**Confidence:** HIGH -- NSTextTable's percentage-based widths and layout algorithms are stable AppKit APIs available since macOS 10.4. The main engineering work is plumbing the container width through to the renderer.

### Feature 4: YAML Front Matter Detection and Display

**No new library required for v1.2 scope.** Use simple regex/string parsing.

| Approach | Dependency | Complexity | Recommendation |
|----------|-----------|------------|----------------|
| **Regex stripping + key-value display** | None (Swift stdlib) | Low | **Recommended for v1.2** |
| **Yams library (full YAML parser)** | jpsim/Yams 6.2.1 | Medium | Defer unless structured parsing needed |
| **swift-markdown front matter** | Not supported | N/A | Not available (confirmed: [Issue #73](https://github.com/swiftlang/swift-markdown/issues/73)) |

**Why regex, not Yams:**
- YAML front matter in markdown files is almost always simple key-value pairs (title, date, author, tags)
- The project only needs to *detect and display* front matter, not parse it into typed objects
- Adding Yams (which embeds LibYAML, a C library) increases bundle size and complexity for a feature that needs only string extraction
- If future requirements need structured YAML parsing (e.g., conditional rendering based on metadata), Yams can be added later

**Implementation approach:**
1. **Detection:** Check if file content starts with `---\n`. If so, find the closing `---\n` (or `...\n`).
2. **Extraction:** Split content into front matter string and markdown body.
3. **Parsing for display:** Split front matter lines on first `:` to get key-value pairs. This handles 95%+ of real-world front matter.
4. **Rendering:** Display as a styled header block (light background, key-value table or formatted list) above the markdown content.
5. **Stripping:** Pass only the markdown body (without front matter) to the existing `MarkdownRenderer.render()` pipeline.

**Regex pattern:**
```swift
// Match front matter block at start of document
// ^---\n captures opening delimiter
// ([\s\S]*?) captures content (non-greedy)
// \n---$ captures closing delimiter
let pattern = "\\A---\\n([\\s\\S]*?)\\n---\\n"
```

**What this means for the stack:**
- No new SPM dependency
- One new preprocessing step before the existing markdown pipeline
- One new rendering component for the front matter display block
- Integration point: Add to `PreviewViewController.preparePreviewOfFile()` before calling `MarkdownRenderer.render()`

**About Yams (if needed later):**
- Latest version: 6.2.1 (released February 5, 2026)
- Swift 5.7+ / Xcode 14+ required
- Codable-based API: `YAMLDecoder().decode(FrontMatter.self, from: yamlString)`
- Platform support: macOS, iOS, Linux
- Source: [github.com/jpsim/Yams](https://github.com/jpsim/Yams)

**Confidence:** HIGH for regex approach (standard Swift string processing). LOW for knowing all edge cases of YAML front matter in the wild (nested values, multiline strings, TOML front matter variants).

### Feature 5: GFM Task List Checkboxes

**No new dependencies required.** Uses existing swift-markdown `ListItem.checkbox` API.

| API / Component | Source | Purpose | Integration Point |
|----------------|--------|---------|-------------------|
| **ListItem.checkbox** | swift-markdown (already a dependency) | Detect checked/unchecked state | Extend `TableExtractor` pattern (MarkupVisitor) |
| **Checkbox enum** | swift-markdown (`.checked`, `.unchecked`) | State representation | Map to visual checkbox characters |
| **NSTextAttachment** | AppKit (built-in) | Render checkbox icons | Use SF Symbols for checkbox appearance |
| **SF Symbols** | Built-in (macOS 11+) | Checkbox icons | `checkmark.square` and `square` system images |

**How swift-markdown handles task lists (verified from source code):**
- The cmark-gfm parser always attaches the `tasklist` extension (line 626 of CommonMarkConverter.swift)
- When parsing `- [x] item`, it creates a `ListItem` node with `.checkbox = .checked`
- When parsing `- [ ] item`, it creates a `ListItem` node with `.checkbox = .unchecked`
- Regular list items have `.checkbox = nil`
- No special parse options are required -- task list support is enabled by default

**Critical detail -- two parsing paths:**
The current codebase has TWO markdown parsing paths:

1. **`AttributedString(markdown:)`** -- Used for the primary rendering pipeline. This is Apple's Foundation-level parser. It does NOT expose checkbox state through `PresentationIntent`. When it encounters `- [ ] text`, it likely strips the checkbox markers and treats the item as a regular list item. This parser does not support GFM task lists.

2. **`Document(parsing:)`** from swift-markdown -- Used currently only for table detection in `hasGFMTables()` and `renderWithTables()`. This parser DOES support task lists via `ListItem.checkbox`.

**Implementation approach:**
Since `AttributedString(markdown:)` does not expose task list state, the implementation must detect task lists via the swift-markdown `Document` parser and handle them in the rendering pipeline. Two options:

**Option A (Recommended): Preprocessing approach**
1. Parse with `Document(parsing:)` to find list items with checkboxes
2. Replace `- [ ]` / `- [x]` markers in the raw markdown with visual Unicode characters before passing to `AttributedString(markdown:)`
3. Use checkbox characters: unchecked = "\u{2610}" (ballot box), checked = "\u{2611}" (ballot box with check)
4. These survive the `AttributedString(markdown:)` pipeline as regular text in list items

**Option B: Post-processing approach**
1. After `AttributedString(markdown:)` renders, scan the output for residual `[ ]` / `[x]` text patterns
2. Replace with styled checkboxes (NSTextAttachment with SF Symbols)
3. Risk: `AttributedString(markdown:)` may mangle the checkbox syntax unpredictably

**Option C: Full hybrid rendering (like tables)**
1. Detect task lists via `Document(parsing:)` and split the document
2. Render task list sections separately with custom checkbox rendering
3. Most complex, but most control over appearance

**Recommendation:** Option A (preprocessing) because:
- Minimal code change (one preprocessing function, similar to existing `preprocessImages()`)
- Works with the existing `AttributedString(markdown:)` pipeline
- Unicode ballot box characters render correctly in NSTextView
- Can be enhanced later with SF Symbol attachments if Unicode rendering is insufficient

**What this means for the stack:**
- No new SPM dependency
- Leverages existing swift-markdown dependency (already used for table extraction)
- One new preprocessing function in `MarkdownRenderer`
- Uses `Document(parsing:)` which is already imported and used

**Confidence:** HIGH -- `ListItem.checkbox` API verified directly from swift-markdown source code in the project's own build cache. The `tasklist` cmark extension is always enabled. Unicode ballot box characters are well-supported in macOS text rendering.

---

## v1.2 Stack Summary: What to Add, What NOT to Add

### Add Nothing to Dependencies

All five v1.2 features can be implemented with **zero new dependencies**. The existing stack (Swift, AppKit, swift-markdown) provides everything needed:

| Feature | Stack Required | New Dependencies |
|---------|---------------|-----------------|
| Window sizing | NSViewController.preferredContentSize | None |
| Preview pane | view.bounds.size.width check | None |
| Table improvements | NSTextTable percentage widths, automatic layout | None |
| YAML front matter | Swift String/Regex processing | None |
| Task list checkboxes | swift-markdown ListItem.checkbox + Unicode | None |

### What NOT to Add and Why

| Library/Tool | Why Tempting | Why NOT to Add |
|-------------|-------------|----------------|
| **Yams** (YAML parser) | Full YAML parsing for front matter | Overkill for display-only key-value extraction. Adds LibYAML C dependency. Defer unless structured parsing is needed. |
| **swift-markdown-ui** (gonzalezreal) | Full GFM rendering including task lists | Targets SwiftUI Text, not NSAttributedString. Incompatible with existing NSTextView rendering pipeline. Now in maintenance mode. |
| **MarkdownToAttributedString** (madebywindmill) | Claims task list support | Would replace the existing rendering pipeline. Too invasive for a polish milestone. |
| **WKWebView** | Easy responsive tables via HTML/CSS | Documented Quick Look issues on Sequoia. Heavy memory footprint. Contradicts existing NSAttributedString architecture. |
| **SwiftUI for extension** | Modern layout for responsive content | Quick Look preview extensions use NSViewController, not SwiftUI views. Would require NSHostingView bridge. Current NSTextView approach is more performant for text-heavy content. |

---

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
# swift-markdown (official Apple library) -- ONLY dependency for extension
.package(url: "https://github.com/swiftlang/swift-markdown.git", from: "0.3.0")
```

**v1.2 note:** No additional package dependencies needed. All five features use built-in AppKit APIs and the existing swift-markdown dependency.

## Installation & Setup

### v1.1 Tools Installation

```bash
# GitHub CLI (release creation)
brew install gh
gh auth login

# Node.js (required for create-dmg)
brew install node

# create-dmg (DMG generation)
npm install --global create-dmg

# Verify installations
gh --version           # Should show gh version X.X.X
node --version         # Should show v20.X.X or later
create-dmg --version   # Should show create-dmg version
```

**Icon Composer:** Download from [developer.apple.com/icon-composer](https://developer.apple.com/icon-composer/) (requires macOS 15.3+)

**Xcode:** Already installed (required for project). Verify Xcode 14+ for notarytool support.

### v1.2 Setup

No additional tools or installations required. All APIs are available in the existing development environment.

## What NOT to Use (Anti-Stack)

| Technology | Why Not | Impact |
|-----------|---------|--------|
| **WebKit / WKWebView** | Documented rendering bugs in macOS Sequoia; heavy memory footprint; slower than native rendering; Quick Look sandbox restrictions | Preview failures, poor performance, maintenance burden |
| **QLGenerator bundles** | Deprecated, no longer supported in macOS 15+ | Will not work; user base running Sequoia cannot use |
| **UIKit (instead of SwiftUI)** | Requires NSViewControllerRepresentable wrapper; added complexity | Code duplication, harder to maintain |
| **External rendering tools (Pandoc, etc.)** | Sandbox restrictions prevent process execution; XPC workaround creates architectural complexity | Very difficult to debug, unreliable |
| **Realm, Core Data** | Unnecessary complexity for read-only preview; extension runs in isolated process | Setup overhead, sync complexity, not needed |
| **SwiftUI Text(markdown:) alone** | Limited formatting support; ignores images and block elements | Cannot display headings, lists, code blocks properly |
| **SF Symbols for app icon** | SF Symbols are UI elements (toolbar icons, buttons), not app icons. Wrong format, wrong design language. Won't look right in Dock/Finder. | Unprofessional appearance, violates Apple HIG |
| **altool for notarization** | Deprecated Nov 2023. Apple no longer accepts uploads from altool or Xcode 13. | Notarization will fail. Must use notarytool. |
| **Third-party Settings libraries** | sindresorhus/Settings adds dependency for built-in SwiftUI Settings scene functionality (available since macOS 11). | Unnecessary complexity, external dependency when native solution exists |
| **GitHub Actions (v1.1)** | For first-time releaser, CI/CD setup adds complexity. Manual gh CLI workflow is simpler to understand and debug. | Longer setup time, harder to troubleshoot first release |
| **release-it / semantic-release** | Node.js automation tools designed for npm packages. Overkill for macOS app with manual versioning. Complex config. | Setup overhead, npm ecosystem assumptions don't fit macOS apps |
| **manual DMG creation (hdiutil)** | Requires extensive scripting for background images, icon positioning, window sizing. Error-prone, time-consuming. | Brittle, hard to maintain, inconsistent results |
| **Yams for v1.2** | Full YAML parser is overkill for front matter display. Adds C library dependency. | Bundle size increase, dependency maintenance, unnecessary complexity |
| **swift-markdown-ui** | Maintenance mode. Targets SwiftUI, not NSTextView. Would require rewriting the renderer. | Architecture mismatch, maintenance risk |

## Code Signing & Notarization Workflow

### One-time Setup

1. **Apple Developer Program membership** - $99/year, required for Developer ID certificate
2. **Download Developer ID certificate** - Xcode > Settings > Accounts > Manage Certificates > "Developer ID Application"
3. **Store notarytool credentials:**

```bash
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "your-email@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "app-specific-password"
```

**Note:** Generate app-specific password at appleid.apple.com > Sign-In and Security > App-Specific Passwords

### Per-Release Workflow

**Estimated time:** 15-20 minutes per release

```bash
# 1. Archive in Xcode (5 min)
# Product > Archive
# Automatically code signs with Developer ID

# 2. Export app bundle (2 min)
# Organizer > Distribute App > Developer ID > Export
# Exports to ~/Desktop/YourApp/

# 3. Zip for notarization (30 sec)
cd ~/Desktop/YourApp/
ditto -c -k --keepParent YourApp.app YourApp.zip

# 4. Submit for notarization (5-10 min wait time)
xcrun notarytool submit YourApp.zip \
  --keychain-profile "notary-profile" \
  --wait

# 5. Staple notarization ticket (30 sec)
xcrun stapler staple YourApp.app

# 6. Verify notarization (10 sec)
xcrun stapler validate YourApp.app
spctl -a -vvv -t install YourApp.app

# 7. Create DMG (1 min)
create-dmg YourApp.app

# Output: YourApp 1.0.0.dmg (in current directory)

# 8. Create GitHub release (1 min)
git tag v1.0.0
git push --tags
gh release create v1.0.0 "YourApp 1.0.0.dmg" \
  --title "v1.0.0 - Initial Release" \
  --notes "First public release of MD Quick Look"
```

## Performance Targets

For instant rendering (Quick Look requirement):

| Scenario | Target | Approach |
|----------|--------|----------|
| 1KB markdown file | <100ms | Direct parsing + rendering |
| 50KB markdown file | <500ms | Parse on background thread, render to Main |
| 500KB markdown file | <2s | Consider pagination or truncation |

**v1.2 performance considerations:**
- YAML front matter stripping adds negligible overhead (single regex match at file start)
- Task list checkbox preprocessing adds one `Document(parsing:)` call -- already done for table detection, can be combined
- Table percentage-width calculation is simpler than current absolute measurement (less string size computation)
- Preview pane width detection is a single property read, zero cost

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

### Notarization (2026)

**Issue:** Some reports of notarization submissions stuck "In Progress" for 24-72+ hours (Jan 2026)
**Workaround:** If stuck >1 hour, check Apple Developer system status. May need to retry submission. Notarization usually completes in 5-10 minutes.

**Issue:** Hardened Runtime required for notarization
**Prevention:** Enable in Build Settings > Signing & Capabilities > Hardened Runtime (automatically enabled for Developer ID builds in Xcode 14+)

### v1.2 Specific

**Issue:** `preferredContentSize` behavior is not well-documented for Quick Look extensions
**Mitigation:** Test on macOS 14, 15, and 26. The property is advisory; the host controls the actual window size. Do not assume a specific initial size.

**Issue:** `AttributedString(markdown:)` does not support GFM task list checkboxes
**Mitigation:** Use preprocessing to replace `- [ ]`/`- [x]` with Unicode ballot box characters before passing to `AttributedString(markdown:)`. Verify that `AttributedString(markdown:)` does not strip or mangle these characters.

**Issue:** NSTextTable percentage widths with automatic layout may behave differently than fixed layout
**Mitigation:** Test with both layout algorithms. Keep fixed layout as fallback for spacebar Quick Look (wide view) and use automatic/percentage for narrow preview pane.

## Alternatives Considered

### SwiftUI Settings vs AppKit NSPreferencePane

**Recommendation:** SwiftUI Settings scene

**Why:**
- NSPreferencePane deprecated
- SwiftUI is modern standard (macOS 11+)
- Automatic menu item and keyboard shortcut
- Less code, better maintainability

### YAML Parsing: Regex vs Yams

**Recommendation:** Regex for v1.2, Yams if requirements grow

| Criterion | Regex | Yams |
|-----------|-------|------|
| Complexity | Low | Medium |
| Dependencies | None | jpsim/Yams 6.2.1 (LibYAML) |
| Handles nested YAML | No | Yes |
| Handles multiline values | Partial | Yes |
| Sufficient for display | Yes (95%+ of real files) | Yes (100%) |
| Bundle size impact | None | ~500KB |

**When to switch to Yams:**
- If users report front matter display issues with nested/complex YAML
- If the project needs to conditionally render based on metadata values
- If front matter parsing becomes a feature differentiator

### Task List Rendering: Preprocessing vs Post-processing vs Hybrid

**Recommendation:** Preprocessing (Option A)

| Approach | Complexity | Risk | Visual Quality |
|----------|-----------|------|---------------|
| Preprocessing (Unicode chars) | Low | Low | Good (standard ballot boxes) |
| Post-processing (scan output) | Medium | Medium (fragile) | Better (SF Symbol attachments) |
| Hybrid rendering (like tables) | High | Low | Best (full control) |

**When to upgrade to hybrid:**
- If Unicode ballot boxes look inconsistent across font sizes
- If users want styled (colored) checkboxes
- If task list nesting becomes a requirement

## Version Compatibility Matrix

| Tool | Minimum Version | Our Version | Notes |
|------|----------------|-------------|-------|
| macOS (development) | 15.3 | 26.2 | Icon Composer requires 15.3+. Everything else works on older macOS. |
| Xcode | 14.0 | 16+ | Xcode 14 required for notarytool. Xcode 16 recommended for latest features. |
| Swift | 5.9 | 6.0 compatible | Project uses Swift 5.9+, compatible with Swift 6.0. |
| SwiftUI Settings | macOS 11+ | 26+ | Settings scene available since Big Sur. Project targets Sonoma (14.0). |
| SwiftUI Window | macOS 13+ | 26+ | Custom Window scene requires Ventura. Project exceeds requirement. |
| Icon Composer | macOS 15.3+ | 26.2 | Our dev machine meets requirement. Falls back to Image2icon if unavailable. |
| Node.js | 20+ | Latest | Required for create-dmg. Check with `node --version`. |
| gh CLI | Any recent | Latest | Works on all modern macOS. No compatibility concerns. |
| notarytool | Xcode 14+ | Xcode 16 | Ships with Xcode. altool deprecated Nov 2023. |
| swift-markdown | 0.3+ | main branch | Task list checkbox support verified in source. No version bump needed. |

**Deployment target:** macOS 14.0 (Sonoma)
**App runs on:** macOS 14.0+
**Development requires:** macOS 15.3+ (for Icon Composer), but 14.0+ works with Image2icon fallback

## Documentation & References

### Official Apple Resources

**v1.0 (Quick Look Extension):**
- [Quick Look Framework Documentation](https://developer.apple.com/documentation/quicklook/)
- [QLPreviewingController API](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [QLPreviewProvider Documentation](https://developer.apple.com/documentation/quicklookui/qlpreviewprovider)
- [App Extension Security Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/AppSandboxDesignGuide/AppSandboxInPractice/AppSandboxInPractice.html)

**v1.1 (App Polish & Release):**
- [Icon Composer](https://developer.apple.com/icon-composer/) - Official icon design tool
- [Apple Design Resources - macOS](https://developer.apple.com/design/resources/) - Official templates and guidelines
- [SF Symbols](https://developer.apple.com/sf-symbols/) - System icon library
- [SwiftUI Settings Documentation](https://developer.apple.com/documentation/swiftui/settings) - Settings scene API
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) - Notarization guide
- [Signing Mac Software with Developer ID](https://developer.apple.com/developer-id/) - Code signing overview

**v1.2 (Rendering Polish):**
- [NSViewController.preferredContentSize](https://developer.apple.com/documentation/appkit/nsviewcontroller/preferredcontentsize) - Window sizing
- [NSTextTable](https://developer.apple.com/documentation/appkit/nstexttable) - Table layout
- [NSTextTable.LayoutAlgorithm](https://developer.apple.com/documentation/appkit/nstexttable/layoutalgorithm) - Layout algorithm options
- [NSTextBlock.setContentWidth(_:type:)](https://developer.apple.com/documentation/appkit/nstextblock/setcontentwidth(_:type:)) - Width types (absolute/percentage)
- [Using Text Tables](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html) - Apple archive guide

### Community References

**v1.0 (Quick Look Extension):**
- [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) - Reference implementation using cmark-gfm
- [smittytone/PreviewMarkdown](https://github.com/smittytone/PreviewMarkdown) - Reference using NSAttributedString rendering
- [sbarex/SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight) - Reference with XPC for highlighting

**v1.1 (App Polish & Release):**
- [Custom About Window in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/) - Detailed implementation guide
- [Presenting Preferences Window](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/) - Settings scene tutorial
- [SwiftUI on macOS: Settings and About](https://eclecticlight.co/2024/04/30/swiftui-on-macos-settings-defaults-and-about/) - Comprehensive guide
- [create-dmg by sindresorhus](https://github.com/sindresorhus/create-dmg) - DMG creation tool

**v1.2 (Rendering Polish):**
- [swift-markdown ListItem.checkbox source](https://github.com/swiftlang/swift-markdown/blob/main/Sources/Markdown/Block%20Nodes/Block%20Container%20Blocks/ListItem.swift) - Task list API
- [YAML Front Matter in swift-markdown (Issue #73)](https://github.com/swiftlang/swift-markdown/issues/73) - Confirmed not supported; DIY recommended
- [Yams YAML Parser](https://github.com/jpsim/Yams) - If full YAML parsing needed later (v6.2.1)
- [Setting preferredContentSize in QL extension](https://developer.apple.com/forums/thread/673369) - Known Catalina bug (fixed in Big Sur+)

## Sources

### v1.0 Sources (Quick Look Extension)

- [Quick Look Framework - Apple Developer Documentation](https://developer.apple.com/documentation/quicklook/)
- [QLPreviewingController - Apple Developer Documentation](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [swift-markdown - GitHub](https://github.com/swiftlang/swift-markdown)
- [Down - Markdown/CommonMark rendering in Swift - GitHub](https://github.com/johnxnguyen/Down)
- [Sequoia No Longer Supports QuickLook Generator Plug-ins](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)
- [How Sequoia has changed QuickLook and its thumbnails - The Eclectic Light Company](https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/)

### v1.1 Sources (App Polish & GitHub Release)

**HIGH Confidence:**
- [Icon Composer - Apple Developer](https://developer.apple.com/icon-composer/)
- [Custom About Window in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/)
- [Presenting Preferences Window in SwiftUI](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/)
- [gh release create - GitHub CLI Manual](https://cli.github.com/manual/gh_release_create)

**MEDIUM Confidence:**
- [create-dmg by sindresorhus - GitHub](https://github.com/sindresorhus/create-dmg)
- [Figma macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027/macos-icon-design-template)

### v1.2 Sources (Rendering Polish)

**HIGH Confidence (verified from source code):**
- swift-markdown `ListItem.checkbox` API -- verified in local build cache (`build/SourcePackages/checkouts/swift-markdown/Sources/Markdown/Block Nodes/Block Container Blocks/ListItem.swift`)
- swift-markdown `tasklist` cmark extension always enabled -- verified in `CommonMarkConverter.swift` line 626
- `Checkbox` enum with `.checked` / `.unchecked` cases -- verified in source
- NSTextTable layout algorithms and percentage width types -- stable AppKit APIs since macOS 10.4

**MEDIUM Confidence (documented but not Quick Look-specific):**
- `NSViewController.preferredContentSize` -- documented for NSViewController, behavior in Quick Look host not fully documented
- NSTextTable `.automaticLayoutAlgorithm` vs `.fixedLayoutAlgorithm` -- documented but specific behavior differences not well explained in Apple docs

**LOW Confidence (needs validation during implementation):**
- `AttributedString(markdown:)` handling of `- [ ]` / `- [x]` syntax -- not documented whether it strips, passes through, or mangles checkbox markers. Needs empirical testing.
- Preview pane width thresholds -- no documentation on typical Finder preview pane widths. Needs testing on different screen sizes and Finder configurations.

---

*Last updated: 2026-02-05*
*v1.0 stack: Quick Look extension rendering (Jan 2026)*
*v1.1 additions: App polish + GitHub release automation (Feb 2026)*
*v1.2 additions: Rendering polish + new markdown features (Feb 2026)*
