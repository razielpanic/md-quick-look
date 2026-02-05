---
created: 2026-02-04T12:00
title: Ensure MIT license attribution in app UI
area: ui
files:
  - LICENSE
  - "MD Quick Look/MDQuickLookApp.swift"
---

## Problem

The project uses MIT License (created in Phase 11-01). MIT requires the license notice to be included in "all copies or substantial portions of the Software." Need to verify the About window and any other relevant UI surfaces include proper MIT attribution/license notice — not just the LICENSE file in the repo.

Common locations: About window credits, Settings/Preferences acknowledgements, any bundled third-party notices.

## Solution

TBD — research what MIT actually requires for binary distribution vs source distribution. At minimum, ensure the About window references the license. May need a "License" or "Acknowledgements" section in the app UI.
