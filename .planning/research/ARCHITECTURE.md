# Architecture Research: Host App UI for Quick Look Extension

**Domain:** macOS Quick Look Extension Host App UI (About, Preferences, Status)
**Milestone:** v1.1 - Public Release (GitHub)
**Researched:** 2026-02-02
**Confidence:** HIGH

## Executive Summary

This research focuses on adding user-facing UI to the existing MD Quick Look host app for v1.1. The extension (MDQuickLook.appex) already works and renders markdown previews. Now we need to add:

1. **About window** - Shown when app launches
2. **Preferences window** - Accessible via menu (Cmd+,)
3. **Status indicator** - Shows extension is active

**Architecture decision:** Pure SwiftUI using App scenes (Window, Settings) targeting macOS 13+. No AppKit unless absolutely necessary. This matches the "very Mac-assed" aesthetic and is appropriate for macOS 26+ target.

**Key insight:** Host app and extension are **independent**. The app doesn't control the extension at runtime. It just contains it and provides user-facing UI for settings/information.

---

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MD Quick Look v1.1                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Host Application (md-spotlighter.app)         │  │
│  │                  SwiftUI App Lifecycle                 │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │                                                         │  │
│  │  Scene 1: About Window (Window scene)                  │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  AboutWindow.swift (SwiftUI View)               │   │  │
│  │  │  - App icon, version, description                │   │  │
│  │  │  - GitHub link                                    │   │  │
│  │  │  - Extension status indicator (optional)          │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  │  Scene 2: Settings (Settings scene)                    │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  SettingsView.swift (SwiftUI View)              │   │  │
│  │  │  - Placeholder content for v1.1                  │   │  │
│  │  │  - Future: theme, font size, etc.                │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  │  Optional: Extension Status Check                      │  │
│  │  ┌─────────────────────────────────────────────────┐   │  │
│  │  │  ExtensionStatus.swift (ObservableObject)       │   │  │
│  │  │  - Runs: qlmanage -m                             │   │  │
│  │  │  - Parses: looks for bundle ID in output         │   │  │
│  │  │  - Returns: enabled/disabled/unknown             │   │  │
│  │  └─────────────────────────────────────────────────┘   │  │
│  │                                                         │  │
│  └───────────────────────────────────────────────────────┘  │
│                          │                                   │
│                          │ (contains)                        │
│                          ↓                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │    Quick Look Extension (MDQuickLook.appex)           │  │
│  │    - PreviewViewController.swift (existing)            │  │
│  │    - MarkdownRenderer.swift (existing)                 │  │
│  │    - TableRenderer.swift (existing)                    │  │
│  │    - MarkdownLayoutManager.swift (existing)            │  │
│  │    [UNCHANGED - already working]                       │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
├─────────────────────────────────────────────────────────────┤
│                     macOS System Layer                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐   │
│  │   Finder     │  │  Quick Look  │  │ System Settings │   │
│  │   (user)     │→ │    Server    │  │   Extensions    │   │
│  │              │  │ (quicklookd) │  │                 │   │
│  └──────────────┘  └──────────────┘  └─────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| **App.swift** | App lifecycle, scene configuration | SwiftUI @main App struct |
| **AboutWindow.swift** | Display app info, version, GitHub link | SwiftUI View in Window scene |
| **SettingsView.swift** | Preferences UI (placeholder for v1.1) | SwiftUI View in Settings scene |
| **ExtensionStatus.swift** | Check if extension is enabled | ObservableObject running qlmanage -m |
| **MDQuickLook.appex** | Markdown preview rendering | Existing implementation (UNCHANGED) |

---

## Recommended Project Structure

```
md-spotlighter/
├── md-spotlighter/                    # Host app target
│   ├── App.swift                      # NEW: @main SwiftUI App entry
│   ├── Views/
│   │   ├── AboutWindow.swift          # NEW: About window content
│   │   └── SettingsView.swift         # NEW: Settings/Preferences
│   ├── Models/
│   │   └── ExtensionStatus.swift      # NEW (optional): Status checker
│   ├── Resources/
│   │   ├── Assets.xcassets            # App icon (update)
│   │   └── Credits.rtf                # Optional: simple About credits
│   ├── Info.plist                     # Update: ensure regular activation policy
│   └── main.swift                     # REMOVE: replace with App.swift
│
├── MDQuickLook/                       # Extension target
│   ├── PreviewViewController.swift    # EXISTING - no changes
│   ├── MarkdownRenderer.swift         # EXISTING - no changes
│   ├── TableRenderer.swift            # EXISTING - no changes
│   ├── MarkdownLayoutManager.swift    # EXISTING - no changes
│   ├── TableExtractor.swift           # EXISTING - no changes
│   └── Info.plist                     # EXISTING - no changes
│
└── Shared/ (optional)                 # Only if settings need sharing
    └── Constants.swift                # Shared bundle IDs, app group
```

### Structure Rationale

- **App.swift:** Modern SwiftUI lifecycle replaces `main.swift` with `NSApplication.shared.run()`. Declares Window and Settings scenes.
- **Views/:** SwiftUI views separated from app logic. Easy to preview, test, and iterate.
- **Models/:** Business logic for checking extension status. Separation of concerns.
- **Resources/:** Assets like app icon. Credits.rtf is optional alternative to custom About window.
- **main.swift removal:** Pure SwiftUI apps use @main on App struct, not standalone main.swift.
- **Extension unchanged:** v1.1 doesn't modify rendering logic. UI is purely host app.

---

## Architectural Patterns

### Pattern 1: SwiftUI App with Multiple Scenes (RECOMMENDED)

**What:** Modern macOS 13+ pattern using declarative scenes. Define Window scene for About, Settings scene for Preferences.

**When to use:** Always for macOS 13+ apps. Native menu integration, window management, minimal code.

**Trade-offs:**
- **Pros:** Automatic "Settings..." menu item (Cmd+,), native window behavior, less boilerplate
- **Cons:** Requires macOS 13+ (not an issue - targeting macOS 26+)

**Example:**
```swift
import SwiftUI

@main
struct MDQuickLookApp: App {
    var body: some Scene {
        // About window - shown when app launches
        Window("About MD Quick Look", id: "about") {
            AboutWindow()
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        .defaultPosition(.center)
        .commands {
            // Replace default About menu item
            CommandGroup(replacing: .appInfo) {
                Button("About MD Quick Look") {
                    NSApp.sendAction(Selector(("showAboutWindow:")), to: nil, from: nil)
                }
            }
        }

        // Settings window - automatic Cmd+, handling
        Settings {
            SettingsView()
        }
    }
}
```

**File location:** `md-spotlighter/App.swift`
**Lines of code:** ~30-50

### Pattern 2: Extension Status Detection via qlmanage

**What:** Run `qlmanage -m` command to check if extension is registered with Quick Look server. Parse output for bundle identifier.

**When to use:** To show accurate status in About window ("Extension active ✓" vs "Enable in System Settings").

**Trade-offs:**
- **Pros:** Accurate real-time status, no private APIs
- **Cons:** Requires shell command execution, parsing text output

**Example:**
```swift
import Foundation

@MainActor
class ExtensionStatus: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isChecking: Bool = false

    private let bundleID = "com.yourdomain.md-spotlighter.MDQuickLook"

    func check() async {
        isChecking = true
        defer { isChecking = false }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/qlmanage")
        process.arguments = ["-m"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for bundle identifier in qlmanage output
                isEnabled = output.contains(bundleID)
            } else {
                isEnabled = false
            }
        } catch {
            isEnabled = false
        }
    }
}
```

**File location:** `md-spotlighter/Models/ExtensionStatus.swift`
**Lines of code:** ~40-60

**Alternative:** Skip status checking for v1.1 MVP. Just show "Launch app once to register extension" message. Status checking can be added in v1.2.

### Pattern 3: Custom About Window (Full Control)

**What:** Create custom SwiftUI view for About window with app icon, version, description, GitHub link.

**When to use:** When you need interactive elements (clickable GitHub link) or custom layout beyond Credits.rtf.

**Trade-offs:**
- **Custom Window Pros:** Full design control, buttons/links, dynamic content
- **Credits.rtf Pros:** Zero code, automatic system About panel (but no interactivity)

**Example:**
```swift
import SwiftUI

struct AboutWindow: View {
    @StateObject private var extensionStatus = ExtensionStatus()

    var body: some View {
        VStack(spacing: 20) {
            // App icon
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                .resizable()
                .frame(width: 128, height: 128)

            // App name
            Text("MD Quick Look")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Version
            Text("Version \(appVersion)")
                .foregroundStyle(.secondary)

            // Description
            Text("Beautiful markdown previews in Finder")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Extension status (optional)
            HStack {
                Image(systemName: extensionStatus.isEnabled ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(extensionStatus.isEnabled ? .green : .orange)
                Text(extensionStatus.isEnabled ? "Extension Active" : "Enable in System Settings")
                    .foregroundStyle(.secondary)
            }
            .task {
                await extensionStatus.check()
            }

            // GitHub link
            Link("View on GitHub", destination: URL(string: "https://github.com/user/md-quick-look")!)
                .buttonStyle(.link)
        }
        .padding(40)
        .frame(width: 400)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}
```

**File location:** `md-spotlighter/Views/AboutWindow.swift`
**Lines of code:** ~60-80

### Pattern 4: Settings Scene with Placeholder

**What:** Use SwiftUI Settings scene for automatic Preferences integration. Start with placeholder, expand in future versions.

**When to use:** Always for macOS apps. System adds "Settings..." menu item automatically.

**Trade-offs:**
- **Pros:** Zero boilerplate, native menu integration, standard keyboard shortcut (Cmd+,)
- **Cons:** Settings window has specific behavior (singleton, can't programmatically close)

**Example:**
```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preferences coming in a future update")
                        .foregroundStyle(.secondary)

                    Text("Planned settings:")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Label("Theme customization", systemImage: "paintpalette")
                        Label("Font size options", systemImage: "textformat.size")
                        Label("Code block styling", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                }
            } header: {
                Text("General")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
    }
}
```

**File location:** `md-spotlighter/Views/SettingsView.swift`
**Lines of code:** ~30-40 (placeholder)

**Future expansion (v1.2+):** Add real settings with @AppStorage for theme selection, font size, etc. Extension reads via UserDefaults.

---

## Data Flow

### App Launch Flow

```
User double-clicks md-spotlighter.app
    ↓
App.swift @main struct initializes
    ↓
SwiftUI creates Window scene for About
    ↓
About window appears centered on screen
    ↓
(Optional) ExtensionStatus.check() runs async
    ↓
Status displayed: "Extension Active ✓" or "Enable in System Settings"
    ↓
User clicks GitHub link or closes window
    ↓
App remains running (can reopen via Dock)
    OR
App quits if applicationShouldTerminateAfterLastWindowClosed = true
```

### Extension Registration Flow (macOS System)

```
User launches app first time
    ↓
macOS scans app bundle
    ↓
Discovers MDQuickLook.appex in PlugIns/
    ↓
Reads Info.plist → QLSupportedContentTypes
    ↓
Registers with Quick Look server (quicklookd)
    ↓
Extension appears in System Settings > Extensions > Quick Look
    ↓
User enables extension (may be automatic)
    ↓
Extension active for .md files in Finder
```

**Key insight:** Extension registration is **automatic**. Host app doesn't need code to "install" extension. Just launching the app once triggers macOS discovery.

### Settings Access Flow (When User Presses Cmd+,)

```
User presses Cmd+, (or selects "Settings..." from menu)
    ↓
SwiftUI Settings scene activates
    ↓
SettingsView appears in singleton window
    ↓
User views placeholder content
    ↓
User closes window (Settings scene remains available)
```

### Extension Preview Flow (EXISTING - UNCHANGED)

```
User selects .md file in Finder
    ↓
User presses Spacebar
    ↓
Finder requests preview from quicklookd
    ↓
quicklookd loads MDQuickLook.appex
    ↓
PreviewViewController.preparePreviewOfFile() called
    ↓
MarkdownRenderer generates preview
    ↓
Preview displayed in Quick Look window
```

**No interaction with host app during preview.** Extension runs independently.

---

## Integration Points

### Host App ↔ Extension Communication

| Integration Type | Pattern | Notes |
|------------------|---------|-------|
| **No direct communication** | Standard approach | Extension runs in separate process managed by quicklookd |
| **Shared settings (future)** | UserDefaults with app group | Requires app group entitlement, not needed for v1.1 |
| **Version sync** | Bundle.main.infoDictionary | Extension can read host app version if needed |

**Critical:** Host app and extension are **decoupled**. App can't send messages to running extension. For v1.1, there's no shared state.

### Host App ↔ macOS System

| Integration Point | Pattern | Notes |
|-------------------|---------|-------|
| **Extension registration** | Automatic on first launch | macOS scans .app/Contents/PlugIns/ |
| **System Settings UI** | Automatic | macOS generates Extensions pane |
| **Status detection** | `qlmanage -m` command | Parse output for bundle ID |
| **About panel** | Custom Window scene or Credits.rtf | SwiftUI or system About |
| **Settings menu** | Settings scene | SwiftUI adds menu item automatically |

### Extension ↔ Quick Look Server (EXISTING)

| Integration Point | Pattern | Notes |
|-------------------|---------|-------|
| **Preview requests** | QLPreviewingController protocol | Existing implementation in PreviewViewController |
| **File access** | Sandbox with user-selected file access | Extension reads .md file passed by quicklookd |

---

## UI Architecture Details

### SwiftUI vs AppKit Decision

**Recommendation:** Pure SwiftUI for host app UI

| Aspect | SwiftUI | AppKit | Chosen |
|--------|---------|--------|--------|
| About window | Window scene | NSWindow + NSWindowController | **SwiftUI** |
| Settings window | Settings scene | NSPreferencePane or custom | **SwiftUI** |
| Status checking | @Published + Process | NSTask | **SwiftUI** |
| Complexity | Low (declarative) | High (imperative) | **SwiftUI** |
| macOS 26 support | Native, modern | Native, legacy | **SwiftUI** |
| Learning curve | Lower for first-timer | Higher | **SwiftUI** |

**Rationale:**
- No AppKit APIs needed for About/Settings UI
- SwiftUI provides automatic menu integration
- Simpler codebase, easier to maintain
- Modern, declarative approach
- Matches macOS 26+ target (no legacy support needed)

**When to use AppKit:**
- Only if specific AppKit API is required (none for v1.1)
- Example: Custom NSView subclass for advanced drawing (not needed)

### Window Activation Policy

**Recommendation:** NSApplicationActivationPolicyRegular (default)

| Policy | Dock Icon | Menu Bar | Use Case |
|--------|-----------|----------|----------|
| **Regular** | ✓ Yes | ✓ Yes | Standard apps (CHOOSE THIS) |
| Accessory | ✗ No | ✗ No | Background/menu bar apps |
| Prohibited | ✗ No | ✗ No | Daemons only |

**Why Regular:**
- User expects to see app in Dock when launched
- About/Settings windows are user-facing
- Can quit via Cmd+Q or app menu
- Standard behavior for Quick Look host apps

**How to ensure Regular policy:**
- Don't set LSUIElement in Info.plist (or set to false)
- Don't set LSBackgroundOnly
- Default is Regular

### Launch Behavior Options

**Option A: Show About window, stay open**
```swift
@main
struct MDQuickLookApp: App {
    var body: some Scene {
        Window("About MD Quick Look", id: "about") {
            AboutWindow()
        }
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }
}

// No applicationShouldTerminateAfterLastWindowClosed
// App stays running when window closes
```

**Option B: Show About window, quit when closed**
```swift
@main
struct MDQuickLookApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window("About MD Quick Look", id: "about") {
            AboutWindow()
        }

        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true  // Quit when About window closes
    }
}
```

**Recommendation for v1.1:** Option A (stay open). Simpler, allows reopening About from Dock without relaunching.

---

## Anti-Patterns

### Anti-Pattern 1: Trying to Control Extension from Host App

**What people do:** Add "Start Extension" or "Stop Extension" buttons in host app. Try to send messages to running extension.

**Why it's wrong:**
- Extension runs in separate process controlled by quicklookd, not host app
- No IPC channel between app and extension
- Extension lifecycle is system-managed

**Do this instead:**
- Host app only provides UI and settings storage
- Extension reads settings independently when it runs
- Direct users to System Settings for enable/disable

### Anti-Pattern 2: Using LSUIElement to Hide from Dock

**What people do:** Set `LSUIElement=true` in Info.plist thinking extension is "background only."

**Why it's wrong:**
- User can't find app to open Settings/About
- No menu bar when LSUIElement=true
- Confusing UX ("where did I install this?")

**Do this instead:**
- Use Regular activation policy (default)
- App appears in Dock normally
- User launches to see About/Settings
- Extension works whether app is running or not

### Anti-Pattern 3: Complex Extension Status Detection

**What people do:** Poll System Settings state continuously, use private APIs, create extension-to-app communication channel.

**Why it's wrong:**
- Private APIs = App Store rejection
- Polling wastes CPU/battery
- Over-engineered for simple status check

**Do this instead:**
- Run `qlmanage -m` once when About window appears
- Parse output for bundle ID (simple string search)
- Show enabled/disabled state
- Link to System Settings if disabled

### Anti-Pattern 4: Mixing AppKit Without Reason

**What people do:** Use NSHostingController to embed SwiftUI in AppKit windows when pure SwiftUI works.

**Why it's wrong:**
- Unnecessary complexity
- More code to maintain
- Bridge layer can have bugs

**Do this instead:**
- Pure SwiftUI for macOS 13+ apps
- Only use AppKit if specific API is unavailable in SwiftUI

### Anti-Pattern 5: View-Based Extension Controller (Not Relevant for v1.1 but Worth Noting)

**What people do:** Use old QLPreviewingController pattern with storyboards for extension.

**Why it's wrong:**
- Extension already uses modern approach (QLPreviewingController with programmatic UI)
- v1.1 doesn't touch extension code

**Already avoided:** Extension uses PreviewViewController programmatically, no storyboards.

---

## File-by-File Implementation Guide

### 1. App.swift (NEW)

**Purpose:** SwiftUI app entry point, scene configuration

**Responsibilities:**
- Define Window scene for About
- Define Settings scene for Preferences
- Configure window appearance
- Optional: AppDelegate for lifecycle hooks

**Code structure:**
```swift
import SwiftUI

@main
struct MDQuickLookApp: App {
    // Optional: for advanced lifecycle control
    // @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        Window("About MD Quick Look", id: "about") {
            AboutWindow()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        Settings {
            SettingsView()
        }
    }
}
```

**Lines of code:** ~20-30 (basic), ~40-50 (with AppDelegate)

### 2. AboutWindow.swift (NEW)

**Purpose:** About window UI

**Responsibilities:**
- Display app icon
- Show app name and version
- Show description
- GitHub link
- Optional: extension status

**Code structure:**
```swift
import SwiftUI

struct AboutWindow: View {
    var body: some View {
        VStack(spacing: 20) {
            // Icon, name, version, description, link
        }
        .padding(40)
        .frame(width: 400)
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

#Preview {
    AboutWindow()
}
```

**Lines of code:** ~40-60 (without status), ~80-100 (with status)

### 3. SettingsView.swift (NEW)

**Purpose:** Settings/Preferences UI

**Responsibilities:**
- Show placeholder content for v1.1
- Future: theme selection, font size, etc.

**Code structure:**
```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Form {
            Section("General") {
                Text("Preferences coming soon")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 200)
    }
}

#Preview {
    SettingsView()
}
```

**Lines of code:** ~20-30 (placeholder)

### 4. ExtensionStatus.swift (NEW - OPTIONAL)

**Purpose:** Check extension activation status

**Responsibilities:**
- Run `qlmanage -m`
- Parse output for bundle ID
- Publish status (enabled/disabled)

**Code structure:**
```swift
import Foundation

@MainActor
class ExtensionStatus: ObservableObject {
    @Published var isEnabled: Bool = false
    @Published var isChecking: Bool = false

    func check() async {
        // Run qlmanage, parse output
    }
}
```

**Lines of code:** ~40-60

**For v1.1 MVP:** This is optional. Can skip and add in v1.2 if desired.

### 5. main.swift (REMOVE)

**Current content:**
```swift
import AppKit
NSApplication.shared.run()
```

**Action:** Delete this file. SwiftUI App struct with @main replaces it.

### 6. Info.plist (UPDATE)

**Ensure these keys:**
```xml
<key>CFBundleIdentifier</key>
<string>com.yourdomain.md-spotlighter</string>

<key>CFBundleName</key>
<string>MD Quick Look</string>

<!-- Don't set LSUIElement - let it default to false (Regular policy) -->
```

**Lines to change:** 1-2 (update app name if needed)

### 7. Assets.xcassets (UPDATE)

**Add/update:** AppIcon with 1024x1024 image for About window display.

---

## Build Configuration

### Xcode Target Structure (v1.1)

```
Project: md-spotlighter
├── Target: md-spotlighter (Application)
│   ├── Product: md-spotlighter.app
│   ├── Bundle ID: com.yourdomain.md-spotlighter
│   ├── Deployment: macOS 26.0+
│   ├── Sources:
│   │   ├── App.swift (NEW)
│   │   ├── Views/AboutWindow.swift (NEW)
│   │   ├── Views/SettingsView.swift (NEW)
│   │   └── Models/ExtensionStatus.swift (NEW - optional)
│   ├── Resources:
│   │   ├── Assets.xcassets (UPDATE)
│   │   └── Info.plist (UPDATE)
│   └── Embedded Content:
│       └── MDQuickLook.appex
│
└── Target: MDQuickLook (App Extension)
    ├── Product: MDQuickLook.appex
    ├── Bundle ID: com.yourdomain.md-spotlighter.MDQuickLook
    └── [UNCHANGED - no modifications for v1.1]
```

### Build Order

1. **Extension builds** (dependency)
2. **Extension embedded** in app PlugIns/
3. **App builds** with new SwiftUI files
4. **Signing** (both targets)

No changes to extension build process for v1.1.

---

## Phase-Specific Recommendations for v1.1

### Recommended Implementation Order

**Phase 1: SwiftUI App Foundation**
- Remove main.swift
- Create App.swift with Window scene
- Create minimal AboutWindow.swift
- Build and verify app launches showing About window

**Phase 2: About Window Content**
- Add app icon to AboutWindow
- Format version string from Bundle
- Add description text
- Test appearance in light/dark mode

**Phase 3: Settings Scene**
- Add Settings scene to App.swift
- Create SettingsView.swift with placeholder
- Verify "Settings..." menu item appears
- Test Cmd+, keyboard shortcut

**Phase 4: Polish (Optional)**
- Add GitHub link to AboutWindow
- Add extension status check (ExtensionStatus.swift)
- Test status indicator updates
- Link to System Settings if disabled

**Phase 5: Integration Testing**
- Build and run
- Verify extension still works (preview .md file)
- Verify About window appears on launch
- Verify Settings accessible via menu
- Test in light and dark mode

**Rationale:** Build foundation first, add features incrementally, test integration last.

---

## Known Pitfalls (Host App Specific)

### Pitfall 1: Forgetting to Remove main.swift

**What goes wrong:**
- Both main.swift and App.swift with @main exist
- Build error: "Multiple @main entry points"

**Prevention:**
- Delete main.swift when creating App.swift
- Or remove NSApplication.shared.run() and use @NSApplicationMain

### Pitfall 2: LSUIElement Confusion

**What goes wrong:**
- Set LSUIElement=true thinking it makes app lightweight
- App has no Dock icon, no menu bar
- User can't access Settings

**Prevention:**
- Don't set LSUIElement in Info.plist
- Use default Regular activation policy

### Pitfall 3: Hardcoded Version String

**What goes wrong:**
- Show "Version 1.0" hardcoded in AboutWindow
- Forget to update when releasing v1.1, v1.2

**Prevention:**
- Read from Bundle: `Bundle.main.infoDictionary?["CFBundleShortVersionString"]`
- Single source of truth in Info.plist

### Pitfall 4: Blocking Main Thread with qlmanage

**What goes wrong:**
- Run `qlmanage -m` synchronously in view body
- UI freezes while command executes

**Prevention:**
- Use async/await with `.task { await extensionStatus.check() }`
- Or run in background DispatchQueue

### Pitfall 5: Assuming Extension and App Share State

**What goes wrong:**
- Try to communicate between app and extension
- Expect extension to respond to app UI changes in real-time

**Prevention:**
- Remember: extension runs in separate process
- No direct communication channel
- Settings changes only apply to next preview request

---

## Alternatives Considered

### Alternative 1: Credits.rtf Instead of Custom About Window

**What:** Add Credits.rtf file to Resources, use system About panel.

**Pros:**
- Zero code
- Standard macOS appearance
- Automatic dark mode

**Cons:**
- Can't add interactive elements (GitHub link button)
- Limited layout control
- Static content only

**Decision:** Use custom About window for GitHub link and extension status.

### Alternative 2: AppKit-Based UI

**What:** Use NSWindow, NSViewController for About/Settings.

**Pros:**
- More control over window behavior
- Access to all AppKit APIs

**Cons:**
- More code (window controllers, view controllers)
- Imperative instead of declarative
- Higher learning curve

**Decision:** Use SwiftUI for simpler, modern approach.

### Alternative 3: No Status Indicator

**What:** Skip extension status checking entirely.

**Pros:**
- Simpler implementation
- No shell command execution
- Less code to maintain

**Cons:**
- User might think extension isn't working
- No feedback on activation state

**Decision:** Include basic status indicator or defer to v1.2.

---

## Sources

**SwiftUI Architecture:**
- [Create a fully custom About window for a Mac app in SwiftUI](https://nilcoalescing.com/blog/FullyCustomAboutWindowForAMacAppInSwiftUI/)
- [Presenting The Preferences Window On macOS Using SwiftUI](https://serialcoder.dev/text-tutorials/macos-tutorials/presenting-the-preferences-window-on-macos-using-swiftui/)
- [SwiftUI on macOS: Settings, defaults and About](https://eclecticlight.co/2024/04/30/swiftui-on-macos-settings-defaults-and-about/)
- [Apple Developer Documentation: Settings Scene](https://developer.apple.com/documentation/swiftui/settings)
- [Scenes types in a SwiftUI Mac app](https://nilcoalescing.com/blog/ScenesTypesInASwiftUIMacApp/)

**SwiftUI + AppKit Integration:**
- [Use SwiftUI with AppKit - WWDC22](https://developer.apple.com/videos/play/wwdc2022/10075/)
- [NSHostingController | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/nshostingcontroller)
- [macOS Apprentice, Chapter 18: Using SwiftUI in AppKit](https://www.kodeco.com/books/macos-apprentice/v1.0/chapters/18-using-swiftui-in-appkit)

**Quick Look Extension Structure:**
- [PeekX: Quick Look Extension for Folder Preview on macOS](https://github.com/altic-dev/PeekX)
- [QLMarkdown: macOS Quick Look extension for Markdown files](https://github.com/sbarex/QLMarkdown)
- [An overview of app extensions and plugins in macOS Sequoia](https://eclecticlight.co/2025/04/23/an-overview-of-app-extensions-and-plugins-in-macos-sequoia/)

**Extension Status Detection:**
- [qlmanage Man Page - macOS](https://ss64.com/mac/qlmanage.html)
- [Inside QuickLook previews with qlmanage](https://eclecticlight.co/2018/04/05/inside-quicklook-previews-with-qlmanage/)
- [macOS Hints: Enable QuickLook in macOS Sonoma and macOS Sequoia](https://www.projectwizards.net/en/blog/2025/01/quicklook)

**macOS App Lifecycle:**
- [SwiftUI on macOS: Life Cycle and App Delegate](https://eclecticlight.co/2024/04/17/swiftui-on-macos-life-cycle-and-appdelegate/)
- [NSApplicationDelegateAdaptor | Apple Developer Documentation](https://developer.apple.com/documentation/swiftui/nsapplicationdelegateadaptor)
- [LSUIElement | Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/lsuielement)
- [A menu bar only macOS app using AppKit](https://www.polpiella.dev/a-menu-bar-only-macos-app-using-appkit/)

**About Panel Customization:**
- [Customizing the macOS About Panel in SwiftUI](https://danielsaidi.com/blog/2023/11/28/customizing-the-macos-about-panel-in-swiftui/)
- [Credits - Swift macOS](https://gavinw.me/swift-macos/swiftui/credits.html)
- [Apple Developer Documentation: NSApplication credits](https://developer.apple.com/documentation/appkit/nsapplication/aboutpaneloptionkey/credits)
- [Customize About panel on macOS in SwiftUI](https://nilcoalescing.com/blog/CustomiseAboutPanelOnMacOSInSwiftUI/)

---
*Architecture research for: macOS Quick Look Extension Host App UI*
*Researched: 2026-02-02*
*Milestone: v1.1 - Public Release (GitHub)*
