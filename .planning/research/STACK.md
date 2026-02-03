# Technology Stack: md-quick-look

**Project:** Quick Look extension for markdown rendering on macOS
**Researched:** January 2026 (v1.0), February 2026 (v1.1 additions)
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

### Project Structure

```
md-quick-look/
├── md-quick-look/                    # Main app (installer)
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/        # v1.1: App icon from Icon Composer
│   ├── ContentView.swift              # v1.1: Status indicator UI
│   ├── AboutView.swift                # v1.1: Custom About window
│   ├── SettingsView.swift             # v1.1: Preferences window
│   └── App.swift                      # v1.1: SwiftUI App with Settings + Window scenes
├── MarkdownPreviewExtension/          # Quick Look extension target
│   ├── PreviewProvider.swift          # QLPreviewProvider subclass
│   ├── MarkdownRenderer.swift         # swift-markdown parsing → NSAttributedString
│   ├── SyntaxHighlighter.swift        # Code block highlighting
│   └── Info.plist                     # Extension configuration
└── Shared/                            # Code shared between app and extension
    └── MarkdownParser.swift           # Isolated parsing logic
```

### SwiftUI App Structure (v1.1)

**App.swift:** Main app entry point with Settings and custom About window

```swift
import SwiftUI

@main
struct MDQuickLookApp: App {
    var body: some Scene {
        // Main window with status indicator
        WindowGroup {
            ContentView()
        }

        // Settings window (Preferences)
        Settings {
            SettingsView()
        }

        // Custom About window
        Window("About MD Quick Look", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.enabled)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About MD Quick Look") {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                    if let url = URL(string: "mdquicklook://about") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }
}
```

**SettingsView.swift:** Preferences window with TabView

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 250)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showFileSize") private var showFileSize = true
    @AppStorage("truncateLimit") private var truncateLimit = 500.0

    var body: some View {
        Form {
            Toggle("Show file size in preview", isOn: $showFileSize)

            VStack(alignment: .leading) {
                Text("Truncate files larger than:")
                Slider(value: $truncateLimit, in: 100...1000, step: 100)
                Text("\(Int(truncateLimit)) KB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
```

**AboutView.swift:** Custom About window

```swift
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App icon
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 128, height: 128)

            // App name and version
            Text("MD Quick Look")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Description
            Text("Quick Look extension for markdown files")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // GitHub link
            Link("View on GitHub", destination: URL(string: "https://github.com/yourusername/md-quick-look")!)
                .font(.body)

            // Credits
            Text("Created with ❤️ by Your Name")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(width: 400, height: 400)
        .padding()
    }
}
```

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

### Troubleshooting

**Notarization fails:**
```bash
# Get detailed status
xcrun notarytool log <submission-id> --keychain-profile "notary-profile"

# Common issues:
# - Missing code signature: Re-export from Xcode with "Developer ID" distribution
# - Invalid entitlements: Check both app and extension have matching entitlements
# - Hardened runtime not enabled: Enable in Build Settings > Hardened Runtime
```

**Stapling fails:**
```bash
# Stapling requires successful notarization
# Check notarization status first:
xcrun notarytool info <submission-id> --keychain-profile "notary-profile"

# Status must be "Accepted" before stapling
```

## Icon Design & Integration Workflow

### 1. Design Phase

**Using Figma template:**

1. Open [macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027/macos-icon-design-template) in Figma
2. Design on 1024x1024 canvas
3. Follow Apple HIG:
   - Rounded square shape (system applies rounding)
   - No text (icon should be recognizable at small sizes)
   - Simple, bold design
   - 2-3 colors max
   - Avoid gradients (they can look muddy at small sizes)

**Design tips for markdown app:**
- Use "M" letterform or markdown symbol (#, *, etc.)
- Consider document metaphor (folded corner, page)
- Test at 32x32 to verify recognizability

### 2. Export Phase

**From Figma:**
- File > Export
- Format: PNG
- Size: 1024w × 1024h
- Quality: Best

### 3. Icon Composer Import

1. Open Icon Composer
2. Drag 1024x1024 PNG to Icon Composer
3. Adjust Liquid Glass properties:
   - Specular: 0.5 (subtle shine)
   - Translucency: 0.2 (slight depth)
   - Blur: 0.1 (soft edges)
4. Preview in different sizes and backgrounds
5. File > Export > Save as AppIcon.icns

### 4. Xcode Integration

1. Open Xcode project
2. Navigate to Assets.xcassets
3. Select AppIcon
4. Drag AppIcon.icns to all size categories, OR:
5. Click AppIcon > Attributes Inspector > Single Size
6. Drag 1024x1024 PNG (Xcode generates all sizes)

**Verify:** Build and check Dock for icon appearance

### Fallback: Image2icon

If Icon Composer unavailable:

1. Download Image2icon from img2icnsapp.com
2. Drag 1024x1024 PNG to Image2icon
3. Click "Export" > Save as .icns
4. Add to Xcode Assets.xcassets (same as above)

### Fallback: No design skills

**Placeholder approach for v1.0:**
- Single letter "M" on gradient background
- Use Icon Composer's text template feature
- Ship with simple icon, commission designer for v1.1

**Free design resources:**
- macosicons.com - Free icon inspiration
- SF Symbols app - Browse system icons for ideas (but don't use directly as app icon)

## Distribution Checklist

### Pre-release (one-time)

- [ ] Apple Developer Program membership ($99/year) enrolled
- [ ] Developer ID certificate downloaded in Xcode
- [ ] notarytool credentials stored (`xcrun notarytool store-credentials`)
- [ ] gh CLI installed and authenticated (`brew install gh && gh auth login`)
- [ ] create-dmg installed (`npm install -g create-dmg`)
- [ ] Node.js 20+ installed (`brew install node`)
- [ ] App icon designed and added to Xcode project

### Per Release

- [ ] Version number updated in Xcode (MARKETING_VERSION)
- [ ] Build number incremented (CURRENT_PROJECT_VERSION)
- [ ] Changelog/release notes drafted
- [ ] Archive built (Product > Archive)
- [ ] App exported with Developer ID distribution
- [ ] App zipped and submitted for notarization
- [ ] Notarization succeeded (wait for "Accepted" status)
- [ ] Notarization ticket stapled to app
- [ ] App validated with stapler and spctl
- [ ] DMG created from notarized app (`create-dmg YourApp.app`)
- [ ] Git tag created (`git tag v1.0.0`)
- [ ] Tags pushed to GitHub (`git push --tags`)
- [ ] GitHub release created (`gh release create v1.0.0 YourApp.dmg`)
- [ ] Release notes added to GitHub release
- [ ] README updated with installation instructions

### Post-release

- [ ] Test DMG download and installation on clean Mac
- [ ] Verify Quick Look extension loads after installation
- [ ] Check Gatekeeper doesn't block app (notarization working)
- [ ] Monitor GitHub issues for installation problems

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

### Notarization (2026)

**Issue:** Some reports of notarization submissions stuck "In Progress" for 24-72+ hours (Jan 2026)
**Workaround:** If stuck >1 hour, check Apple Developer system status. May need to retry submission. Notarization usually completes in 5-10 minutes.

**Issue:** Hardened Runtime required for notarization
**Prevention:** Enable in Build Settings > Signing & Capabilities > Hardened Runtime (automatically enabled for Developer ID builds in Xcode 14+)

## Alternatives Considered

### SwiftUI Settings vs AppKit NSPreferencePane

**Recommendation:** SwiftUI Settings scene

**Why:**
- NSPreferencePane deprecated
- SwiftUI is modern standard (macOS 11+)
- Automatic menu item and keyboard shortcut
- Less code, better maintainability

**When to use AppKit:**
- Never for new projects
- Only if targeting macOS 10.15 or earlier (not this project)

### Icon Composer vs Image2icon vs IconGenerator

**Recommendation:** Icon Composer (if available) > Image2icon > IconGenerator

**Why:**
- Icon Composer: Apple's official tool, best quality, Liquid Glass effects
- Image2icon: Simpler, $9.99 pro features, good fallback
- IconGenerator: Free, open-source, basic functionality

**When to use alternatives:**
- Image2icon: If Icon Composer unavailable (requires macOS 15.3+)
- IconGenerator: If budget constraint or prefer open-source

### gh CLI vs GitHub Actions

**Recommendation:** gh CLI for first release, GitHub Actions for mature automation

**Why:**
- gh CLI: Simple, manual control, easier to debug, no YAML config
- GitHub Actions: Automated, runs on every tag push, better for frequent releases

**When to use GitHub Actions:**
- After 3-5 successful manual releases
- When release frequency increases (weekly+)
- When notarization workflow is proven stable

### create-dmg (Node.js) vs create-dmg (Shell Script)

**Recommendation:** Node.js version (sindresorhus/create-dmg)

**Why:**
- Better defaults, simpler CLI
- Active maintenance, larger community
- Easier installation via npm

**When to use shell script version:**
- Node.js unavailable or unwanted dependency
- Need more granular control over DMG layout
- Prefer bash over Node.js ecosystem

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
- [Image2icon](https://img2icnsapp.com/) - Icon converter tool
- [IconGenerator](https://github.com/onmyway133/IconGenerator) - Open-source icon generator

### Figma Resources

- [macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027/macos-icon-design-template) - Community icon template
- [Official macOS App Icon Template](https://www.figma.com/community/file/1040708197994685442/official-macos-app-icon-template) - Apple-style template
- [macOS 26 UI Kit](https://www.figma.com/community/file/1543337041090580818/macos-26) - Official macOS 26 components

## Sources

### v1.0 Sources (Quick Look Extension)

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

### v1.1 Sources (App Polish & GitHub Release)

**HIGH Confidence:**
- [Icon Composer - Apple Developer](https://developer.apple.com/icon-composer/)
- [Custom About Window in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/)
- [Presenting Preferences Window in SwiftUI](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/)
- [SwiftUI on macOS: Settings, Defaults and About](https://eclecticlight.co/2024/04/30/swiftui-on-macos-settings-defaults-and-about/)
- [gh release create - GitHub CLI Manual](https://cli.github.com/manual/gh_release_create)
- [gh release upload - GitHub CLI Manual](https://cli.github.com/manual/gh_release_upload)

**MEDIUM Confidence:**
- [create-dmg by sindresorhus - GitHub](https://github.com/sindresorhus/create-dmg)
- [Image2icon - macOS Icon Converter](https://img2icnsapp.com/)
- [IconGenerator - GitHub](https://github.com/onmyway133/IconGenerator)
- [Figma macOS Icon Design Template](https://www.figma.com/community/file/1203739127660048027/macos-icon-design-template)
- [Official macOS App Icon Template (Figma)](https://www.figma.com/community/file/1040708197994685442/official-macos-app-icon-template)
- [Notarization Process for macOS Installers](https://apptimized.com/en/news/mac-notarization-process/)
- [GitHub Actions for macOS Universal Binary](https://github.com/marketplace/actions/macos-universal-binary-action)

---

*Last updated: 2026-02-02*
*v1.0 stack: Quick Look extension rendering (Jan 2026)*
*v1.1 additions: App polish + GitHub release automation (Feb 2026)*
