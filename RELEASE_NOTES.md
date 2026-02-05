## What's New in v1.1.0

**First public release of MD Quick Look** — a macOS Quick Look extension for beautifully rendered Markdown previews.

### Highlights
- Professional purple gradient app icon with markdown motif
- SwiftUI host application with About window and Settings
- Extension status indicator with direct link to System Settings
- Comprehensive documentation with installation guide, troubleshooting, and demo GIF
- Consistent "MD Quick Look" naming throughout all surfaces
- MIT License (open source)

### Full Changelog

**v1.1.0 (February 2026) - First Public Release**
- Renamed from development name to "MD Quick Look" across all project files, documentation, and UI
- Added professional app icon: purple gradient (#6B46C1 to #553C9A) with carved-out # symbol effect
- Built SwiftUI host application with About, Preferences, and first-launch guidance
- Added extension enable/disable guidance via System Settings deep link (com.apple.ExtensionsPreferences)
- Created comprehensive README with installation guide, troubleshooting steps, feature highlights, and screenshots
- Added LICENSE file (MIT License, copyright 2026 Raziel Panic)
- Added demo GIF showing Quick Look in action
- Repository published at github.com/razielpanic/md-quick-look

**v1.0.0 (February 2026) - Core Feature Set**
- Headings (H1-H6), bold, italic, strikethrough
- Unordered and ordered lists
- Blockquotes
- Code blocks with monospaced font
- GitHub-flavored tables with borders and padding
- Horizontal rules
- Automatic dark mode support matching macOS system appearance
- Instant rendering (under 1 second for typical markdown files)

## Installation

1. Download **MD Quick Look 1.1.0.dmg** below
2. Open the DMG file
3. Drag **MD Quick Look.app** to **Applications**
4. **Launch the app once** to register the Quick Look extension
5. Select any `.md` file in Finder and press **Space** to preview

## Important: First Launch Setup

This is an unsigned release. **The app will not open normally on first launch** — macOS Gatekeeper blocks unsigned apps by default. You must do one of the following before the app will run:

### Option A: Right-click to Open (recommended)

1. Open **Finder** and navigate to **Applications**
2. **Right-click** (or Control-click) on **MD Quick Look.app**
3. Select **Open** from the context menu
4. Click **Open** in the confirmation dialog that appears

### Option B: Remove quarantine via Terminal

```bash
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```

After either step, the app will open normally from now on.

### Enable the Quick Look Extension

After the app launches for the first time, you need to enable the extension:

1. Open **System Settings**
2. Go to **Extensions** → **Quick Look**
3. Toggle **MD Quick Look** to **on**
4. Open a new Finder window, select any `.md` file, and press **Space**

> **Tip:** The app includes a direct link to the Extensions settings pane — click "Open System Settings" in the app window.

## Requirements

- macOS 26 (Tahoe) or later
