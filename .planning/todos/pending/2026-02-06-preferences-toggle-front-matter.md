---
created: 2026-02-06T12:05
title: Add Preferences toggle for YAML front matter display
area: ui
files:
  - MDQuickLook/MDQuickLook Extension/MarkdownRenderer.swift
  - MDQuickLook/MDQuickLook/SettingsView.swift
---

## Problem

YAML front matter is primarily machine-targeted metadata (used by Jekyll, Hugo, Obsidian, etc.). Some users may prefer to hide it entirely since it's not part of the document content they're scanning. This is a natural candidate for the first Preferences toggle — "Show YAML front matter" on/off.

Requires the front matter feature to be complete first (Phase 11). The Preferences window already exists (SwiftUI Settings scene from v1.1) but currently only shows extension status. Adding a toggle means establishing:
- UserDefaults storage for the preference
- App Group sharing between host app and extension (extension needs to read the preference)
- UI toggle in SettingsView

## Solution

TBD — candidate for a future phase or inclusion in an existing phase. Key considerations:
- App Group container needed for host app ↔ extension preference sharing
- UserDefaults.init(suiteName:) with shared App Group ID
- Default should be "show" (front matter visible by default)
- Could expand to other toggles later (image placeholders, etc.)
