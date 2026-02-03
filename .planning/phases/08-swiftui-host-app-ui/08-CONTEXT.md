# Phase 8: SwiftUI Host App UI - Context

**Gathered:** 2026-02-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Professional app UI with About window, Preferences, and extension status indicator. This phase delivers the user-facing app experience when MD Quick Look is launched directly (not the Quick Look extension itself). We're building windows and UI elements that make the app feel polished and complete for v1.1 public release.

</domain>

<decisions>
## Implementation Decisions

### About Window Layout & Content
- **Visual style:** Standard macOS About window (simple, centered) - not custom branded
- **Information displayed:**
  - App icon from Phase 7 (53KB purple gradient icon)
  - App name & version number (e.g., "MD Quick Look v1.1.0")
  - Clickable GitHub repository link (formatted as actual URL, not button)
  - Credits/attribution: Copyright + brief one-line description of what the app does
- **Layout:** Icon at top, app name, version, copyright - clean and minimal like system About windows

### First-Launch & Status Communication
- **First launch behavior:** Show status window displaying extension state
- **Status window appears:** First launch only (not on subsequent launches)
- **Status window content:**
  - Extension enabled/disabled state
  - Link to System Settings (if extension is disabled, show how to enable it)
  - "Don't show again" checkbox/dismiss option
  - ~~Quick usage instruction~~ (not included - focused on status only)
- **After first launch:** Status information accessible via Preferences window (not separate menu item, not in About)
- **Subsequent launches:** Show Preferences window by default when app is launched

### Menu Bar & App Lifecycle
- **Menu items:**
  - About MD Quick Look
  - Preferences (⌘,)
  - Help/Documentation (links to GitHub README)
  - Quit (⌘Q)
- **Help destination:** GitHub README (opens in browser)
- **Dock behavior:** Claude's discretion (see below)
- **Window behavior:** Preferences window shows by default on launch (after first-launch status dismissed)

### Preferences Window
- **Content for v1.1:** Extension status display (enabled/disabled state, link to System Settings)
- **Structure:** Minimal placeholder - ready for future settings in later versions
- **Note:** This is where users go to check extension status after dismissing first-launch window

### Claude's Discretion
- Exact About window dimensions and spacing
- Preferences window layout and organization
- Dock behavior (stay in Dock vs menu bar only vs quit when windows close) - choose what's appropriate for a Quick Look extension host app
- Loading states and transitions
- Window positioning and management
- Dark mode implementation details (all UI must work in light and dark modes per success criteria)

</decisions>

<specifics>
## Specific Ideas

- "Very Mac-assed" philosophy - feature complete, beautiful, polished, simple. Native feel, follows Apple design guidelines.
- About window should feel like standard macOS About windows (similar to other system utilities)
- This is a utility app, not a productivity app - keep it simple and unobtrusive
- Extension status is the main thing users need to check - make it easy to verify the extension is working

</specifics>

<deferred>
## Deferred Ideas

None - discussion stayed within phase scope

</deferred>

---

*Phase: 08-swiftui-host-app-ui*
*Context gathered: 2026-02-03*
