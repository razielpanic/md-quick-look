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

## macOS Security Note

This is an unsigned release. macOS Gatekeeper will show a warning on first launch.

**To open (recommended):**
1. Right-click **MD Quick Look.app** in Applications
2. Select **Open**
3. Click **Open** in the confirmation dialog

**Alternative (Terminal):**
```bash
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```

After this one-time step, the app launches normally.

## Requirements

- macOS 26 (Tahoe) or later
