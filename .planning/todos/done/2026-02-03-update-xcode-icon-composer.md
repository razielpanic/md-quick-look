---
created: 2026-02-03T00:00
title: Update Xcode project to use Icon Composer instead of AppIcon asset catalog
area: tooling
files:
  - MDQuickLook.xcodeproj/project.pbxproj
  - MDQuickLook/Assets.xcassets/AppIcon.appiconset/Contents.json
---

## Problem

The latest version of Xcode has changed how app icons are configured. Instead of using an AppIcon asset catalog entry within Assets.xcassets (the traditional approach), Xcode now prefers an Icon Composer file at the project level.

Current project structure (Phase 7, Plan 07-01) created Assets.xcassets with an AppIcon.appiconset following the old pattern. This may not integrate properly with modern Xcode versions or may cause warnings/issues during build.

## Solution

Update the Xcode project configuration to:
1. Remove or deprecate the Assets.xcassets/AppIcon.appiconset approach
2. Configure the project to use Icon Composer file format instead
3. Verify icon appears correctly in all contexts (Finder, About panel, etc.)

Research the exact Icon Composer format and integration path for current Xcode versions.
