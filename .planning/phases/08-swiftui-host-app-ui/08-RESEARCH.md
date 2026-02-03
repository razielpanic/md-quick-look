# Phase 8: SwiftUI Host App UI - Research

**Researched:** 2026-02-03
**Domain:** SwiftUI macOS application lifecycle, window management, and utility app UI patterns
**Confidence:** HIGH

## Summary

SwiftUI for macOS (as of macOS 13+) provides native APIs for building professional host app UIs using the App protocol, WindowGroup/Window scenes, Settings scene, and modern window customization modifiers. The standard stack is pure SwiftUI with minimal AppKit bridging.

For this Quick Look extension host app, the architecture follows established patterns: SwiftUI @main entry point with App conformance, Settings scene for preferences, Window scene for custom About window, and @AppStorage for first-launch detection. The app should adopt standard macOS utility app behavior (normal Dock presence, standard menu bar) rather than background-only modes (LSUIElement/LSBackgroundOnly) which create window management frustrations.

Key findings: (1) SwiftUI's Window scene with modifiers like `.windowResizability()`, `.containerBackground()`, and `.restorationBehavior()` provides complete About window customization without AppKit; (2) Extension status checking requires either executing `pluginkit -m` via Process or directing users to System Settings (no direct programmatic API); (3) UserDefaults with @AppStorage is the standard for first-launch detection; (4) Dark mode support is automatic through SwiftUI's semantic colors and @Environment(\.colorScheme).

**Primary recommendation:** Use pure SwiftUI with App/Scene API (macOS 13+ target), Settings scene for preferences, Window scene for About, @AppStorage for first-launch flag, and direct users to System Settings for extension management rather than attempting programmatic status checks.

## Standard Stack

The established libraries/tools for this domain:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftUI | Built-in (macOS 13+) | UI framework and app lifecycle | Native Apple framework, first-class macOS support since macOS 13 |
| Foundation | Built-in | Bundle info, UserDefaults, URL handling | Standard library for app metadata and preferences |
| AppKit | Built-in (minimal) | NSWorkspace for opening URLs | Only needed for specific system integrations SwiftUI doesn't cover |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| NSWorkspace | Built-in | Opening System Settings URLs | When providing "Open System Settings" links from the app |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Pure SwiftUI | AppDelegate + AppKit | AppDelegate provides more system hooks but SwiftUI's App protocol is cleaner and Apple's recommended path for new apps |
| Settings scene | Custom Preferences window | Settings scene automatically creates menu item and uses system styling, custom requires more code |
| @AppStorage | Manual UserDefaults | @AppStorage provides automatic SwiftUI view updates, manual requires more boilerplate |

**Installation:**
No external dependencies required - all native frameworks.

## Architecture Patterns

### Recommended Project Structure
```
MDQuickLook/
├── MDQuickLookApp.swift     # @main App entry point
├── Views/
│   ├── AboutView.swift       # Custom About window content
│   ├── SettingsView.swift    # Preferences window content
│   └── FirstLaunchView.swift # First-launch status window
├── Models/
│   └── AppState.swift        # @AppStorage properties, first-launch logic
└── Resources/
    └── Assets.xcassets       # App icon, color sets for dark mode
```

### Pattern 1: SwiftUI App Lifecycle
**What:** Using @main with App protocol conformance and Scene-based architecture
**When to use:** All new macOS apps targeting macOS 13+

**Example:**
```swift
// Source: https://developer.apple.com/documentation/swiftui/app
@main
struct MDQuickLookApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false

    var body: some Scene {
        // Main windows (hidden by default for utility app)
        WindowGroup {
            EmptyView() // Or minimal status view
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)

        // About window
        Window("About MD Quick Look", id: "about") {
            AboutView()
                .frame(width: 400, height: 300)
        }
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.enabled)
        .restorationBehavior(.disabled)

        // Preferences/Settings
        Settings {
            SettingsView()
        }

        // First launch window
        Window("Welcome", id: "firstLaunch") {
            FirstLaunchView()
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
    }
}
```

### Pattern 2: Custom About Window
**What:** Using Window scene with customization modifiers for standard macOS About window feel
**When to use:** When you need custom About window layout beyond NSApp.orderFrontStandardAboutPanel

**Example:**
```swift
// Source: https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/
Window("About MD Quick Look", id: "about") {
    VStack(spacing: 16) {
        // App icon
        Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
            .resizable()
            .frame(width: 128, height: 128)

        // App name and version
        Text("MD Quick Look")
            .font(.title)
        Text("Version \(Bundle.main.releaseVersionNumber ?? "Unknown")")
            .font(.subheadline)
            .foregroundColor(.secondary)

        // GitHub link
        Link("github.com/user/repo",
             destination: URL(string: "https://github.com/user/repo")!)
            .font(.body)

        // Copyright
        Text("© 2026 Your Name")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    .padding()
    .frame(width: 400, height: 300)
    .containerBackground(.regularMaterial, for: .window)
}
.windowResizability(.contentSize)
.windowBackgroundDragBehavior(.enabled)
.restorationBehavior(.disabled)
.windowMinimizeBehavior(.disabled)
```

### Pattern 3: Settings Scene
**What:** Using Settings scene for preferences window with automatic menu integration
**When to use:** All macOS apps with user preferences

**Example:**
```swift
// Source: https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/
Settings {
    TabView {
        GeneralSettingsView()
            .tabItem {
                Label("General", systemImage: "gear")
            }
    }
    .padding()
    .frame(width: 450, height: 300)
}
```

### Pattern 4: First-Launch Detection
**What:** Using @AppStorage with UserDefaults key to track first launch
**When to use:** When app needs to show welcome/onboarding only once

**Example:**
```swift
// Source: https://betterprogramming.pub/checking-for-the-users-first-launch-in-swift-df02a1feb472
@main
struct MDQuickLookApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onAppear {
            if !hasLaunchedBefore {
                openWindow(id: "firstLaunch")
                hasLaunchedBefore = true
            }
        }

        Window("Welcome", id: "firstLaunch") {
            FirstLaunchView()
        }
    }
}
```

### Pattern 5: Opening URLs
**What:** Using Link view or @Environment(\.openURL) to open external URLs in browser
**When to use:** GitHub links, documentation links, System Settings links

**Example:**
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-open-web-links-in-safari
// Using Link view (simpler)
Link("View on GitHub", destination: URL(string: "https://github.com/user/repo")!)

// Using openURL (more control)
@Environment(\.openURL) var openURL
Button("Open System Settings") {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.extensions") {
        openURL(url)
    }
}
```

### Pattern 6: Bundle Version Access
**What:** Accessing CFBundleShortVersionString programmatically for version display
**When to use:** About windows, app metadata display

**Example:**
```swift
// Source: https://blog.rampatra.com/how-to-display-the-app-version-in-a-macos-ios-swiftui-app
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }
    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

// Usage in SwiftUI
Text("Version \(Bundle.main.releaseVersionNumber ?? "Unknown")")
```

### Anti-Patterns to Avoid
- **Using LSUIElement or LSBackgroundOnly for utility apps:** Creates window management issues where app windows get stuck behind other windows. Better to use normal Dock presence for apps with UI.
- **Manual UserDefaults instead of @AppStorage:** Loses automatic SwiftUI view updates and requires more boilerplate code.
- **Trying to programmatically enable/disable extensions:** No public API exists; users must use System Settings.
- **Overusing AppDelegate in SwiftUI apps:** SwiftUI's App protocol handles most needs; only bridge to AppKit when absolutely necessary.
- **Storing sensitive data in UserDefaults/@AppStorage:** Not secure storage; use Keychain for credentials/secrets.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Preferences window | Custom window management | Settings scene | Automatically creates menu item (⌘,), handles window lifecycle, applies system styling |
| First-launch tracking | Custom file-based flags | @AppStorage with UserDefaults | Automatic persistence, type-safe, integrates with SwiftUI updates |
| Dark mode support | Manual color switching | SwiftUI semantic colors + @Environment(\.colorScheme) | Automatic system integration, asset catalog color sets |
| About window | NSApp.orderFrontStandardAboutPanel | Window scene with custom layout | More control while maintaining native feel, modern SwiftUI approach |
| Opening System Settings | Shell scripts, AppleScript | NSWorkspace.shared.open() with x-apple.systempreferences URL | Native API, proper error handling, security sandboxing compatible |
| Extension status checking | Custom PlugInKit wrapper | Direct user to System Settings | No public API for status checking; PlugInKit is private framework |

**Key insight:** SwiftUI for macOS has matured significantly since macOS 13. Most UI needs can be satisfied with pure SwiftUI APIs without AppKit bridging. The ecosystem has established patterns for common utility app requirements.

## Common Pitfalls

### Pitfall 1: Window Restoration for Utility Windows
**What goes wrong:** About windows and first-launch windows restore on app launch, showing stale UI from previous session
**Why it happens:** macOS automatically saves and restores window state by default
**How to avoid:** Apply `.restorationBehavior(.disabled)` to About and first-launch Window scenes
**Warning signs:** About window appears on app launch without user action; window state persists between launches

### Pitfall 2: Extension Status False Assumptions
**What goes wrong:** Attempting to programmatically check if Quick Look extension is enabled using private APIs or incorrect assumptions
**Why it happens:** No public API exists for checking extension enabled status from host app
**How to avoid:** Direct users to System Settings > General > Login Items & Extensions, or use `pluginkit -m` via Process (but note it requires specific entitlements)
**Warning signs:** App crashes when trying to access PlugInKit private framework; sandboxing violations

### Pitfall 3: LSUIElement for Apps With UI
**What goes wrong:** Using LSUIElement = true makes app windows get stuck behind other windows, frustrating users who need to interact with preferences/about windows
**Why it happens:** Developers assume utility apps should be "invisible" in Dock
**How to avoid:** For apps with UI windows (About, Preferences), use normal Dock presence. LSUIElement is only appropriate for menu bar-only apps with no windows.
**Warning signs:** Users report windows disappearing behind other apps; can't bring app to front easily

### Pitfall 4: @State vs @AppStorage Confusion
**What goes wrong:** Using @State for first-launch flag causes flag to reset every app launch
**Why it happens:** @State is ephemeral view state, not persistent storage
**How to avoid:** Use @AppStorage for data that must persist between app launches; use @State only for temporary UI state within a session
**Warning signs:** First-launch window shows every time app opens; settings don't persist

### Pitfall 5: Hardcoded Colors Breaking Dark Mode
**What goes wrong:** UI looks broken in dark mode because colors are hardcoded for light mode
**Why it happens:** Using Color(.sRGB, red:green:blue:) or similar instead of semantic colors
**How to avoid:** Use SwiftUI semantic colors (.primary, .secondary, .background) or asset catalog color sets with light/dark variants
**Warning signs:** Text disappears in dark mode; poor contrast; colors don't adapt to system appearance

### Pitfall 6: Window Size Constraints Not Matching
**What goes wrong:** Window resizability setting doesn't work, or window behaves unexpectedly
**Why it happens:** Using `.windowResizability(.contentSize)` without setting matching min/max frame constraints, or setting opposite constraints
**How to avoid:** When using `.contentSize`, ensure view frame matches desired fixed size; when allowing resize, provide sensible min/max constraints
**Warning signs:** Window still resizable despite `.contentSize`; window refuses to resize in expected direction

### Pitfall 7: UserDefaults Size Bloat
**What goes wrong:** App performance degrades over time; preferences corrupted
**Why it happens:** Storing large data (images, large JSON) in UserDefaults
**How to avoid:** Keep UserDefaults under ~512KB total; use for simple preferences only; store large data in Application Support directory
**Warning signs:** Slow app launch; preferences don't save reliably

## Code Examples

Verified patterns from official sources:

### Accessing Bundle Version
```swift
// Source: https://blog.rampatra.com/how-to-display-the-app-version-in-a-macos-ios-swiftui-app
extension Bundle {
    var releaseVersionNumber: String? {
        return infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        return infoDictionary?["CFBundleVersion"] as? String
    }
}

// Usage
let version = Bundle.main.releaseVersionNumber ?? "Unknown"
let build = Bundle.main.buildVersionNumber ?? "Unknown"
Text("Version \(version) (\(build))")
```

### Opening GitHub Repository Link
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-open-web-links-in-safari
Link("github.com/username/md-quick-look",
     destination: URL(string: "https://github.com/username/md-quick-look")!)
    .font(.body)
```

### Opening System Settings
```swift
// Source: https://blog.rampatra.com/how-to-open-macos-system-settings-or-a-specific-pane-programmatically-with-swift
@Environment(\.openURL) var openURL

Button("Open Login Items & Extensions") {
    // Note: Specific pane URLs are undocumented and may change
    if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
        openURL(url)
    }
}
```

### Detecting Color Scheme
```swift
// Source: https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-dark-mode
struct MyView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack {
            if colorScheme == .dark {
                Text("Dark mode active")
                    .foregroundColor(.white)
            } else {
                Text("Light mode active")
                    .foregroundColor(.black)
            }
        }
    }
}
```

### Window Customization
```swift
// Source: https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/
Window("About MD Quick Look", id: "about") {
    AboutView()
        .frame(width: 400, height: 300)
        .containerBackground(.regularMaterial, for: .window)
}
.windowResizability(.contentSize)
.windowBackgroundDragBehavior(.enabled)
.restorationBehavior(.disabled)
.windowMinimizeBehavior(.disabled)
```

### First Launch Detection
```swift
// Source: https://betterprogramming.pub/checking-for-the-users-first-launch-in-swift-df02a1feb472
@main
struct MDQuickLookApp: App {
    @AppStorage("hasLaunchedBefore") private var hasLaunchedBefore = false
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .task {
            if !hasLaunchedBefore {
                openWindow(id: "firstLaunch")
                hasLaunchedBefore = true
            }
        }

        Window("Welcome", id: "firstLaunch") {
            FirstLaunchView()
        }
        .windowResizability(.contentSize)
        .restorationBehavior(.disabled)
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| AppDelegate + SceneDelegate | @main App protocol | macOS 11 (2020), matured macOS 13 | Cleaner declarative lifecycle, less boilerplate |
| NSUserDefaultsController bindings | @AppStorage property wrapper | macOS 11 (2020) | Automatic SwiftUI view updates, simpler code |
| NSAboutPanelController | Window scene with custom layout | macOS 13 (2022) | Full customization while maintaining native feel |
| .qlgenerator plugins | .appex Quick Look extensions | macOS 10.15 (2019), enforced Sequoia (2024) | Modern extension architecture, sandboxed |
| Manual NSWindowController | Window scene + modifiers | macOS 13 (2022), enhanced WWDC24 | Declarative window management, better integration |

**Deprecated/outdated:**
- **LSBackgroundOnly for utility apps:** Still works but creates UX problems with window management; prefer normal Dock presence for apps with windows
- **NSUserDefaults manual observation:** Use @AppStorage for automatic SwiftUI integration
- **Xcode Preferences panes (PreferencePane framework):** Removed in macOS 13; use Settings scene in-app preferences

## Open Questions

Things that couldn't be fully resolved:

1. **Extension Enabled Status Checking**
   - What we know: No public API for checking Quick Look extension enabled status; PlugInKit is private framework; `pluginkit -m` command exists but requires entitlements
   - What's unclear: Whether sandboxed apps can execute `pluginkit` via Process; reliability of System Settings URL schemes
   - Recommendation: Direct users to System Settings manually via instructions/button; don't attempt programmatic status checking. Display instructions like "Open System Settings > General > Login Items & Extensions > Quick Look to enable"

2. **Exact System Settings URL for Quick Look Extensions**
   - What we know: `x-apple.systempreferences:` URL scheme exists; specific pane identifiers are undocumented
   - What's unclear: Correct URL to deep-link directly to Quick Look extensions section (not just Login Items)
   - Recommendation: Use general Login Items URL or open root System Settings, include clear textual instructions

3. **Default Window Behavior After First Launch**
   - What we know: After dismissing first-launch window, subsequent launches should show Preferences (per CONTEXT.md)
   - What's unclear: Best UX pattern (auto-show Preferences vs no window vs menu bar only)
   - Recommendation: Test with users; typical utility apps either show nothing (menu bar interaction only) or show Preferences. Since this is extension host, likely better to show nothing and rely on menu bar.

## Sources

### Primary (HIGH confidence)
- [Hacking with Swift: SwiftUI App Lifecycle](https://www.hackingwithswift.com/articles/224/common-swiftui-mistakes-and-how-to-fix-them)
- [Nil Coalescing: Fully Custom About Window for Mac App in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/)
- [SerialCoder: Presenting Preferences Window on macOS using SwiftUI](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/)
- [Better Programming: Checking for User's First Launch in Swift](https://betterprogramming.pub/checking-for-the-users-first-launch-in-swift-df02a1feb472)
- [Rampatra: Display App Version in macOS/iOS SwiftUI App](https://blog.rampatra.com/how-to-display-the-app-version-in-a-macos-ios-swiftui-app)
- [Hacking with Swift: How to Open Web Links in Safari](https://www.hackingwithswift.com/quick-start/swiftui/how-to-open-web-links-in-safari)
- [Rampatra: Open macOS System Settings Programmatically](https://blog.rampatra.com/how-to-open-macos-system-settings-or-a-specific-pane-programmatically-with-swift)

### Secondary (MEDIUM confidence)
- [TrozWare: SwiftUI for Mac 2025](https://troz.net/post/2025/swiftui-mac-2025/)
- [Hacking with Swift: Common SwiftUI Mistakes](https://www.hackingwithswift.com/articles/224/common-swiftui-mistakes-and-how-to-fix-them)
- [SwiftLee: User Defaults Reading and Writing in Swift](https://www.avanderlee.com/swift/user-defaults-preferences/)
- [Medium: Mastering SwiftUI @AppStorage Best Practices](https://medium.com/@ramdhas/mastering-swiftui-best-practices-for-efficient-user-preference-management-with-appstorage-cf088f4ca90c)
- [R0uter's Blog: Three Operating Modes of macOS Application](https://www.logcg.com/en/archives/3531.html)
- [The Eclectic Light Company: How PlugInKit Enables App Extensions](https://eclecticlight.co/2025/04/16/how-pluginkit-enables-app-extensions/)

### Tertiary (LOW confidence)
- WebSearch results about pluginkit commands (no official documentation found)
- System Settings URL schemes (undocumented, may change)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - SwiftUI App protocol and Settings scene are documented Apple APIs with extensive community usage
- Architecture: HIGH - Patterns verified from multiple authoritative sources, well-established since macOS 13
- Pitfalls: MEDIUM - Based on community experience and forum discussions; some edge cases may exist

**Research date:** 2026-02-03
**Valid until:** ~30 days (2026-03-03) - SwiftUI APIs are stable, but macOS Sequoia/15+ updates may introduce changes. Revalidate if targeting macOS 16+.
