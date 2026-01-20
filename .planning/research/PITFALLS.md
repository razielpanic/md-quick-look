# Domain Pitfalls: Quick Look Extensions for macOS

**Domain:** Quick Look extension development (macOS 12+)
**Researched:** 2026-01-19
**Project Context:** md-spotlighter (markdown rendering with instant performance requirement)

## Critical Pitfalls

### Pitfall 1: Sandbox Prevents Access to Referenced Files

**What goes wrong:**
Sandboxed Quick Look extensions can read the previewed markdown file itself, but the sandbox denies access to files referenced within the markdown (images, CSS, included markdown files). This causes broken image links and cross-file references to silently fail in the preview.

**Why it happens:**
macOS 12+ enforces strict sandbox isolation for all Quick Look extensions. File access is limited to the exact file being previewed; relative file paths or absolute paths to adjacent files are blocked even with proper entitlements. The extension cannot follow `![image.png](./images/image.png)` references.

**Consequences:**
- Markdown files with relative image paths preview incorrectly (missing images)
- CSS imports or @includes silently fail
- Reusable markdown components cannot reference shared assets
- Users see broken previews with no indication why

**Prevention:**
1. **Embed asset data:** Convert referenced images to base64 and embed in HTML (base64-encoded data URIs)
2. **Accept limitation:** Document that md-spotlighter cannot render external references; design around this
3. **Use absolute data:** Only support inline code blocks, embeds, and self-contained markdown
4. **Test carefully:** Create test markdown with various reference types and verify each fails predictably

**Detection:**
- Manual testing: Create markdown with `![](./image.png)` and verify image doesn't render
- Examine console logs for sandbox denial messages during development
- Check if preview renders correctly when all assets are removed

**Phase impact:** Architecture (Phase 1) — must decide on embedded-data approach before rendering pipeline design

---

### Pitfall 2: Instant Rendering Requires Async File Reading Without Blocking Finder

**What goes wrong:**
Blocking the rendering thread to read file contents or perform markdown parsing causes Finder to freeze or become unresponsive. Users experience 2-10 second delays for markdown preview, violating the "instant rendering" constraint. Finder process may appear hung if parsing takes >3-5 seconds.

**Why it happens:**
Quick Look extensions run on the same process thread as Finder. If the extension's `preparePreviewOfFile(at:completionHandler:)` method performs synchronous I/O or heavy parsing on the main thread, it blocks Finder's UI thread. Even small markdown files (100KB+) can cause noticeable lag with naive parsing.

**Consequences:**
- Finder becomes unresponsive while previewing file
- Users perceive extension as "slow" or "broken"
- Cascading delays when scrolling through directories
- Potential timeout and extension crash if rendering exceeds system limits
- System may kill the QuickLookUIService process, disabling Quick Look entirely

**Prevention:**
1. **Always use async completion handler:** Never block in `preparePreviewOfFile()`. Use `DispatchQueue.global(qos: .userInitiated)` for parsing
2. **Profile parsing performance:** Test with large markdown files (500KB+) to establish baseline
3. **Timeout protection:** Implement hard timeout (500ms) for rendering; abort with partial/fallback preview
4. **Lazy render:** For very large files, render incrementally or show first viewport only
5. **Cache aggressively:** Store compiled HTML in memory per file path to avoid re-parsing

**Detection:**
- Use qlmanage CLI: `qlmanage -p -z /path/file.md` measures rendering time
- Monitor in Activity Monitor: Check if process consumes >1 core for >1 second
- Manual testing: Open large markdown files and measure Finder responsiveness

**Phase impact:** Core feature (Phase 1) — rendering performance is foundational; all later features depend on fast rendering

---

### Pitfall 3: Code Signing Breaks After Local Development Changes

**What goes wrong:**
After building and testing locally, the extension suddenly stops being recognized by Finder or System Preferences. The extension appears in System Preferences > Extensions > Quick Look but fails to activate or crashes immediately.

**Why it happens:**
Quick Look extensions require cryptographic code signing with specific entitlements (App Sandbox, file access permissions). Any change to the extension bundle (adding files, modifying resources, changing binaries) invalidates the signature. The system caches extension metadata, so the old broken signature persists until the cache is cleared.

**Consequences:**
- Development build works, test build doesn't
- Unclear error messages from system
- Extension listed in preferences but doesn't work
- App Review rejection if distribution build is improperly signed
- Hours of debugging before recognizing it's a signing issue

**Prevention:**
1. **Clear extension cache during development:** After each build, run:
   ```bash
   qlmanage -r  # Reset Quick Look daemon
   rm ~/Library/Preferences/com.apple.preferences.extensions.QuickLook.plist
   killall Finder
   ```
2. **Verify signing:** Use `codesign -v` on the extension bundle before deployment
3. **Automate in build:** Add "clear cache" script to Xcode build scheme post-action
4. **Test launch:** After moving to /Applications, launch the host app at least once before testing
5. **Verify entitlements:** Cross-check entitlements plist against requirements (App Sandbox must be enabled)

**Detection:**
- Extension listed in System Preferences but doesn't activate → signing issue
- `qlmanage -p` shows "failed to load" → likely signing problem
- Check: `codesign -dv /Applications/md-spotlighter.app/Contents/PlugIns/*.extensionkit`

**Phase impact:** Distribution (Phase 3) — must validate code signing early; late discovery causes release delays

---

### Pitfall 4: Big Sur WebView Crashes Inside Quick Look Preview

**What goes wrong:**
On macOS 11 Big Sur, embedding a WebView (WKWebView) inside a Quick Look preview causes immediate crashes with no stack trace. The extension crashes before rendering anything, leaving a broken preview thumbnail.

**Why it happens:**
There is a known bug in Big Sur's Quick Look engine and WebKit integration. WebViews cannot be safely embedded in Quick Look previews on Big Sur specifically. Attempting to do so triggers memory corruption or sandbox violations that immediately crash the rendering process.

**Consequences:**
- Big Sur users see broken previews with blank thumbnails
- Extension appears non-functional on Big Sur
- May require temporary entitlements that fail App Review
- Users forced to use fallback (generic document icon)

**Prevention:**
1. **Platform detection:** Detect macOS version and use alternative rendering on Big Sur:
   ```swift
   if #available(macOS 12, *) {
       // Use WKWebView for Monterey+
   } else {
       // Use NSAttributedString or alternative for Big Sur
   }
   ```
2. **Workaround with entitlements:** If Web rendering required on Big Sur, request temporary mach-lookup exception (but this triggers App Review scrutiny)
3. **Choose rendering method wisely:** For md-spotlighter, consider NSAttributedString rendering which is stable across all versions
4. **Drop Big Sur support:** Document minimum requirement as macOS 12+ to avoid the issue entirely

**Detection:**
- Test on Big Sur VM or target: launch Finder, preview markdown file, check for crash
- Monitor Console.app for QuickLookUIService errors
- If working on Monterey+ but crashing on Big Sur, this is the issue

**Phase impact:** Feature selection (Phase 1) — choose between WebView (Monterey+) vs NSAttributedString (all versions) early

---

### Pitfall 5: UTI (Uniform Type Identifier) Not Properly Registered

**What goes wrong:**
Even after building and signing the extension, Finder doesn't offer preview for .md files. Extension is installed but never invoked, or competes with default PDF preview for markdown files with conflicting UTI definitions.

**Why it happens:**
Quick Look's discovery mechanism relies entirely on UTI registration in Info.plist. If the extension doesn't declare support for `public.markdown` or `com.md-spotlighter.markdown` with correct priority, Finder won't associate the extension with .md files. Multiple extensions claiming the same UTI causes macOS to choose arbitrarily or ignore all of them.

**Consequences:**
- Extension installed and signed, but never runs
- Users file bugs: "Extension doesn't work"
- Unclear why extension isn't invoked
- May work for some file types but not others

**Prevention:**
1. **Declare correct UTI in Info.plist:**
   ```xml
   <key>NSExtensionActivationRule</key>
   <dict>
       <key>NSExtensionActivationSupportsMarkdown</key>
       <true/>
   </dict>
   <!-- OR explicitly with UTI -->
   <key>NSExtensionAttributes</key>
   <dict>
       <key>QLSupportedContentTypes</key>
       <array>
           <string>public.markdown</string>
       </array>
   </dict>
   ```
2. **Test UTI registration:** Use `mdls` command to verify .md files report correct type:
   ```bash
   mdls -name kMDItemContentType /path/test.md
   # Should output: public.markdown or com.md-spotlighter.markdown
   ```
3. **Check priority:** If multiple extensions claim the same UTI, explicitly set priority in manifest
4. **Verify after install:** After building, check System Preferences > Extensions > Quick Look to see if md-spotlighter is listed

**Detection:**
- `qlmanage -g /path/test.md` shows no provider found
- Extension in System Preferences but marked as "off" or unavailable
- Preview works for some markdown files but not others

**Phase impact:** Core feature (Phase 1) — verify UTI setup before first test build

---

### Pitfall 6: Markdown Parsing Diverges From Target Rendering

**What goes wrong:**
Markdown files render differently in md-spotlighter than in GitHub, Markdown viewers, or the user's expected output. Syntax highlighting colors differ, table formatting varies, code block language detection fails silently, or complex formatting features are ignored.

**Why it happens:**
Different markdown parsing libraries implement different flavors of Markdown. GitHub-flavored Markdown (GFM) is not the same as CommonMark or original Markdown. The library used by md-spotlighter (e.g., cmark-gfm, marked, or custom) may not match the user's expectations or GitHub's actual rendering engine. Syntax highlighters add another layer of divergence.

**Consequences:**
- Users see unexpected preview that doesn't match their mental model
- Complex markdown (tables, task lists, footnotes) may not render
- Code syntax highlighting colors wrong or not applied
- Loss of trust in preview accuracy
- Feature requests for "rendering it like GitHub does"

**Prevention:**
1. **Choose stable markdown library:** Use well-tested library (cmark-gfm or equivalent) rather than custom parser
2. **Document flavor explicitly:** Clarify in help/docs: "md-spotlighter uses CommonMark + GFM extensions"
3. **Limit feature scope:** In Phase 1, support only core features: headings, emphasis, lists, code blocks. Defer tables, footnotes, etc.
4. **Test against reference:** Build test suite comparing output to GitHub or standard markdown specs
5. **Set expectations:** Make clear that preview is "instant" by design and cannot support all markdown features

**Detection:**
- Create test markdown files with various syntax (tables, fenced code, GFM features)
- Compare preview output to GitHub or VS Code
- Monitor user feedback for "renders wrong" reports

**Phase impact:** Feature design (Phase 1) — decide markdown flavor and feature set explicitly

---

### Pitfall 7: Extension Cache or Finder Cache Causes Stale Previews

**What goes wrong:**
After updating the markdown file in Finder, the Quick Look preview still shows old content. Changes made in editor are not reflected in Finder preview without manual refresh.

**Why it happens:**
Multiple caching layers exist: QuickLookUIService caches previews in memory, Finder caches thumbnails, the filesystem caches modified timestamps. If the caching key doesn't include file modification time or content hash, Finder may show stale preview. The extension's completion handler may cache the rendered HTML aggressively.

**Consequences:**
- Users edit markdown, preview still shows old version
- Confusing user experience: "I changed this but it doesn't show"
- Users lose trust in preview accuracy
- May require Finder restart to see changes

**Prevention:**
1. **Include modification time in cache key:** Cache rendered output keyed by `(filePath, modificationTime)` not just filePath
2. **Don't cache preview HTML:** For small files, regenerate on each preview request rather than cache
3. **Respect system cache invalidation:** Listen to file system events if needed; clear cache on file modification
4. **Document refresh behavior:** Users can press spacebar again to force refresh

**Detection:**
- Edit markdown file and immediately preview; check if changes appear
- Modify timestamps manually and test cache behavior
- Monitor memory usage of QuickLookUIService to detect over-caching

**Phase impact:** Core feature (Phase 1) — caching strategy must be decided early

---

## Moderate Pitfalls

### Pitfall 8: Synchronous Image Loading Blocks Preview

**What goes wrong:**
If the extension attempts to load base64-encoded images synchronously (embedding large images), rendering pauses while images are processed. Base64 encoding/decoding becomes a bottleneck for files with multiple images.

**Why it happens:**
To work around sandbox restrictions, images must be converted to base64 data URIs. If this conversion happens synchronously on the main/rendering thread, it delays preview display. Large images (500KB+) can cause 1-2 second delays.

**Prevention:**
- Pre-encode images to base64 during build phase, not at preview time
- For large images, skip embedding and show placeholder
- Use efficient base64 encoder optimized for macOS

**Detection:**
- Profile with Xcode Instruments: check for Time Profiler hotspots in base64 encoding
- Test with markdown containing multiple large images

**Phase impact:** Performance optimization (Phase 2) — address if profiling identifies bottleneck

---

### Pitfall 9: Extension Timeout From System

**What goes wrong:**
Extension rendering takes longer than the system's timeout threshold, and the Quick Look daemon kills the extension process. Preview shows as failed/blank.

**Why it happens:**
macOS enforces rendering timeouts to prevent frozen Finder. If markdown parsing or rendering exceeds ~5-10 seconds, the system terminates the extension process. Developers may not realize timeout exists until large files fail silently.

**Prevention:**
- Implement internal timeout: if rendering takes >500ms, abort and show fallback
- Profile large files to establish performance baseline
- Consider lazy rendering: render visible portion first, rest later
- Add progress logging to understand where time is spent

**Detection:**
- Console.app shows timeout or termination messages
- Test with very large markdown files (>10MB)
- Monitor rendering time with qlmanage

**Phase impact:** Performance (Phase 1) — establish timeout budget early

---

### Pitfall 10: Conflicting Extensions Claim .md UTI

**What goes wrong:**
User has multiple Quick Look extensions installed (e.g., md-spotlighter + third-party markdown viewer). Finder unpredictably chooses one or neither. Preview may fail or show wrong renderer.

**Why it happens:**
If multiple extensions register for the same UTI without priority differences, macOS behavior becomes undefined. System may cache preference, choose alphabetically, or disable all conflicting extensions.

**Prevention:**
- Document compatible UTI scope: what file types md-spotlighter handles
- Set priority in Info.plist if competing with known extensions
- Test with other popular Quick Look extensions installed
- Recommend users disable other markdown Quick Look extensions

**Detection:**
- System Preferences > Extensions > Quick Look: multiple extensions listed for markdown
- Preview behavior is inconsistent
- Check Console.app for extension selection logs

**Phase impact:** Distribution (Phase 3) — address during QA testing

---

### Pitfall 11: NSAttributedString HTML Rendering Limitations

**What goes wrong:**
If using NSAttributedString to render HTML/markdown instead of WebView, HTML rendering is limited. Styling is incomplete, CSS is ignored, layout is unpredictable. Complex markdown looks wrong.

**Why it happens:**
NSAttributedString has limited HTML support. It recognizes basic tags (bold, italic, links) but ignores CSS, layout directives, and advanced styling. Complex markdown rendered via NSAttributedString + HTML looks minimal and unattractive.

**Consequence:**
- Preview looks plain/unformatted compared to modern markdown viewers
- CSS styling ignored
- Layout may break for certain markdown patterns

**Prevention:**
- If using NSAttributedString, limit styling expectations
- Consider WebView for Monterey+ (where it's stable)
- Build custom attributed string styling rather than rely on HTML parsing
- Test NSAttributedString output and document limitations

**Detection:**
- Compare NSAttributedString rendering to WebView rendering
- Test complex markdown with styling and verify output

**Phase impact:** Rendering approach (Phase 1) — choose NSAttributedString vs WebView early

---

### Pitfall 12: Extension Not Launched At Installation

**What goes wrong:**
User installs md-spotlighter app, but Quick Look extension doesn't work until the app is explicitly launched.

**Why it happens:**
macOS requires the host app to be launched at least once so the system can discover and register the bundled Quick Look extension. If user installs but never opens the app, the extension remains unregistered.

**Prevention:**
- Document: "Launch md-spotlighter once after installation for Quick Look support"
- Consider auto-launch on first installation (with user permission)
- Provide setup wizard that launches app automatically
- Check in System Preferences if extension is listed; if not, prompt user to launch app

**Detection:**
- Install app but don't launch; verify Quick Look doesn't work
- After launching app once, Quick Look becomes available

**Phase impact:** Distribution/UX (Phase 3) — document in setup instructions

---

## Minor Pitfalls

### Pitfall 13: qlmanage Command Line Tool Differences

**What goes wrong:**
Extension works in qlmanage testing but fails in actual Finder Quick Look. Debugging is confusing because test results don't match real behavior.

**Why it happens:**
qlmanage runs extensions in nearly the same environment as Finder, but not identical. Permissions, sandbox exceptions, and process isolation may differ slightly. Results in qlmanage are 99% accurate but not 100%.

**Prevention:**
- Always test in actual Finder alongside qlmanage testing
- Document differences between qlmanage and Finder behavior
- Use qlmanage for quick iteration but verify with Finder

**Detection:**
- `qlmanage -p /path/file.md` works, but Finder preview doesn't
- Compare output between both methods

**Phase impact:** Development/testing (Phase 1) — establish both testing methods

---

### Pitfall 14: Very Large Markdown Files Cause Performance Cliff

**What goes wrong:**
Markdown files <100KB render instantly; files >500KB suddenly render slowly or timeout. Performance degradation is non-linear.

**Why it happens:**
Markdown parsing is typically O(n) or worse. Large files exceed Finder's timeout or exceed available memory in QuickLookUIService. No graceful degradation; rendering either completes or crashes.

**Prevention:**
- Establish file size limits: "md-spotlighter works best with files <500KB"
- Implement smart truncation: render only first 100KB, show "(truncated)" notice
- Add file size check: show warning for very large files
- Profile with various file sizes to find performance cliff

**Detection:**
- Create test files of increasing size; measure rendering time
- Find the size threshold where performance degrades

**Phase impact:** Specification (Phase 1) — document size limits and handling

---

### Pitfall 15: Missing Markdown Support for Certain Syntax

**What goes wrong:**
User's markdown uses GitHub-flavored extensions (task lists, strikethrough, tables) that md-spotlighter doesn't support. These render as plain text or break formatting.

**Why it happens:**
If the markdown parsing library doesn't support GFM extensions or if the feature scope is limited, unsupported syntax is silently ignored. Users expect "standard" markdown but different flavors support different features.

**Prevention:**
- Choose markdown library that supports GFM: cmark-gfm or equivalent
- Document supported syntax explicitly in help
- Handle unknown syntax gracefully: ignore or show as plain text
- Test with real-world markdown samples from users

**Detection:**
- Create markdown with task lists, tables, strikethrough
- Verify rendering matches expectations or falls back gracefully

**Phase impact:** Feature design (Phase 1) — decide markdown flavor and coverage early

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Architecture Selection | Pitfall 4: WebView crashes on Big Sur | Decide macOS minimum version and rendering method (WebView vs NSAttributedString) in Phase 1 |
| Markdown Feature Set | Pitfall 6: Parsing divergence | Lock feature scope early; document what markdown syntax is supported |
| Performance Baseline | Pitfall 2: Rendering delays | Establish performance budget (500ms max) in Phase 1; profile constantly |
| Code Signing | Pitfall 3: Signing breaks after changes | Set up automated cache-clearing in build process before Phase 3 distribution |
| File Access | Pitfall 1: Sandbox prevents referenced files | Decide approach (embed data, accept limitation) in Phase 1 architecture |
| Testing Strategy | Pitfall 13: qlmanage vs Finder divergence | Test in both qlmanage and actual Finder during Phase 2 |
| User Documentation | Pitfall 15: Unsupported markdown syntax | Document feature set clearly in help before Phase 3 launch |

---

## Sources

- [Eclectic Light Company: Quick Look Problems Analysis](https://eclecticlight.co/2024/04/05/a-quick-look-at-quicklook-and-its-problems/)
- [Apple Developer Forums: Quick Look Debug & Testing](https://developer.apple.com/forums/thread/114701)
- [GitHub: SourceCodeSyntaxHighlight Project](https://github.com/sbarex/SourceCodeSyntaxHighlight)
- [GitHub: QLMarkdown - Markdown Quick Look Extension](https://github.com/sbarex/QLMarkdown)
- [GitHub: Transmission Quick Look Extension Issue](https://github.com/transmission/transmission/issues/7822)
- [Apple Developer: QLPreviewingController Documentation](https://developer.apple.com/documentation/quicklook/qlpreviewingcontroller)
- [Medium: Debug Your Quick Look Plugin](https://medium.com/@fousa/debug-your-quick-look-plugin-50762525d2c2)
- [Apple Community: QuickLookUIService Performance Issues](https://discussions.apple.com/thread/8506070)
- [Quick Look Plugins List - GitHub](https://github.com/sindresorhus/quick-look-plugins)
