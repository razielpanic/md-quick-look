# Phase 6: Naming Cleanup - Research

**Researched:** 2026-02-02
**Domain:** Xcode project renaming, bundle identifiers, GitHub repository management
**Confidence:** HIGH

## Summary

This phase involves a comprehensive codebase rename from legacy "spotlighter" naming to consistent "MD Quick Look" branding. The research identifies specific locations requiring changes, verified best practices for Xcode project renaming, and confirms the bundle identifier nesting requirements for macOS app extensions.

The current codebase has "spotlighter" references in: Swift source files (OSLog subsystems, error domains), project.pbxproj (target names, build settings), Info.plist files (bundle identifiers, display names), Makefile, and 85+ planning documentation files. The extension already uses "MDQuickLook" naming in many places, which aligns with the target naming scheme.

The safest approach is manual file/folder renaming combined with precise text replacements, rather than using Xcode's built-in rename feature (which can be unreliable for complex projects). All changes can be staged and committed atomically as decided.

**Primary recommendation:** Use `git mv` for directory renames to preserve history, then perform surgical text replacements in project.pbxproj, Info.plist files, Swift files, and Makefile before creating a single atomic commit.

## Standard Stack

This phase uses no external libraries - it's a refactoring/renaming task using built-in tools.

### Core Tools
| Tool | Purpose | Why Used |
|------|---------|----------|
| `git mv` | Rename directories | Preserves file history, Git recognizes as move not delete+add |
| `sed` or manual edit | Text replacement in project files | Precise control over .pbxproj and plist edits |
| `gh repo rename` | Rename GitHub repository | CLI is faster and safer than web UI, -y flag for non-interactive |
| Xcode | Validate build | Confirm project still compiles after renames |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `grep -r` | Find remaining references | Verification step after renames |
| `plutil` | Validate plist syntax | After editing Info.plist files |

**No installation required** - all tools are available on the development machine.

## Architecture Patterns

### Current Project Structure
```
md-spotlighter/                      # ROOT - to remain for local folder (repo rename separate)
├── md-spotlighter/                  # PROJECT FOLDER - rename to MDQuickLook/
│   ├── md-spotlighter.xcodeproj/    # XCODE PROJECT - rename to MDQuickLook.xcodeproj/
│   │   └── project.pbxproj          # Contains many spotlighter references
│   ├── md-spotlighter/              # MAIN APP SOURCE - rename to MDQuickLook/
│   │   ├── main.swift               # Clean - no spotlighter refs
│   │   └── Info.plist               # Bundle ID, app name - NEEDS UPDATE
│   └── MDQuickLook/                 # EXTENSION SOURCE - already correct name
│       ├── PreviewViewController.swift  # Has OSLog subsystem refs
│       ├── MarkdownRenderer.swift       # Has OSLog subsystem refs
│       ├── MarkdownLayoutManager.swift  # Has OSLog subsystem refs
│       ├── TableRenderer.swift          # Has OSLog subsystem refs
│       └── Info.plist               # Extension bundle ID - NEEDS UPDATE
├── Makefile                         # References old names - NEEDS UPDATE
├── .planning/                       # 85+ files with spotlighter refs - NEEDS UPDATE
│   └── config.json                  # project_name field - NEEDS UPDATE
└── samples/                         # Clean - no changes needed
```

### Target Structure After Rename
```
md-spotlighter/                      # Local folder stays (user can rename manually)
├── MDQuickLook/                     # PROJECT FOLDER (was md-spotlighter/)
│   ├── MDQuickLook.xcodeproj/       # XCODE PROJECT (was md-spotlighter.xcodeproj/)
│   ├── MDQuickLook/                 # MAIN APP SOURCE (was md-spotlighter/)
│   │   ├── main.swift
│   │   └── Info.plist               # Updated bundle ID and app name
│   └── MDQuickLook/                 # EXTENSION SOURCE (unchanged path)
│       └── Info.plist               # Updated extension bundle ID
├── Makefile                         # Updated references
└── .planning/                       # Updated references
```

### Pattern 1: Bundle Identifier Nesting
**What:** App extension bundle IDs MUST have the containing app's bundle ID as prefix
**When to use:** Always for macOS/iOS app extensions
**Source:** [Apple Developer Forums](https://developer.apple.com/forums/thread/20239)

| Component | Old Bundle ID | New Bundle ID |
|-----------|--------------|---------------|
| Main App | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |
| Extension | `com.razielpanic.md-spotlighter.quicklook` | `com.rocketpop.MDQuickLook.Extension` |

**Validation:** Extension bundle ID must start with `com.rocketpop.MDQuickLook.`

### Pattern 2: Display Name vs Bundle Name
**What:** Separate internal names from user-facing names
**When to use:** User-facing strings should use "MD Quick Look" (with space); internal identifiers use "MDQuickLook" (no space)

| Context | Value |
|---------|-------|
| CFBundleName (main app) | `MD Quick Look` |
| CFBundleDisplayName (extension) | `MD Quick Look` |
| PRODUCT_BUNDLE_IDENTIFIER | `com.rocketpop.MDQuickLook` |
| OSLog subsystem | `com.rocketpop.MDQuickLook` |
| Error domain in code | `MDQuickLook` |
| Swift type prefixes | `MDQuickLook` |

### Anti-Patterns to Avoid
- **Using Xcode's built-in rename:** Can corrupt project files, especially with extensions. Manual rename is safer.
- **Mixing naming conventions:** Don't use "MD-Quick-Look" or "mdquicklook" - stick to decided patterns.
- **Renaming repo before local changes:** Do local Xcode project rename first, commit, THEN rename GitHub repo.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directory rename | Manual `mv` | `git mv` | Preserves history, Git tracks as rename |
| GitHub repo rename | Web UI navigation | `gh repo rename` | Single command, scriptable, -y for non-interactive |
| Find all references | Manual search | `grep -r "spotlighter"` | Comprehensive, catches hidden references |
| plist validation | Visual inspection | `plutil -lint` | Catches syntax errors immediately |

**Key insight:** The single atomic commit requirement means ALL changes must be verified before ANY are committed. Use staging area to accumulate changes.

## Common Pitfalls

### Pitfall 1: Xcode Project Corruption
**What goes wrong:** Using Xcode's "Rename" feature on complex projects with extensions can corrupt the .pbxproj file, breaking builds.
**Why it happens:** Xcode's rename tries to update too many things automatically and can fail partway through.
**How to avoid:** Use `git mv` for directory renames, then manually edit project.pbxproj with precise text replacements.
**Warning signs:** Xcode shows "Missing file" errors, targets disappear, build fails with cryptic errors.
**Source:** [CreateWithSwift - Safely Renaming Your Xcode Project](https://www.createwithswift.com/safely-renaming-your-xcode-project/)

### Pitfall 2: Bundle ID Mismatch Breaking Extension
**What goes wrong:** Extension doesn't load because its bundle ID doesn't have the app's bundle ID as prefix.
**Why it happens:** Apple requires strict nesting: `<app-bundle-id>.<extension-suffix>`.
**How to avoid:** Extension bundle ID MUST be `com.rocketpop.MDQuickLook.Extension` (starts with app's ID).
**Warning signs:** "App extension has invalid bundle identifier" errors, extension doesn't appear in Quick Look.
**Source:** [Apple Developer Forums](https://developer.apple.com/forums/thread/20239)

### Pitfall 3: Stale Build Artifacts
**What goes wrong:** Old "md-spotlighter.app" still installed in /Applications, confusing Quick Look system.
**Why it happens:** `make clean` doesn't remove previously installed app.
**How to avoid:** Run `rm -rf /Applications/md-spotlighter.app` before installing new version. Update Makefile to clean old name too.
**Warning signs:** Quick Look shows old behavior, wrong bundle ID in Activity Monitor.

### Pitfall 4: GitHub Redirect Collisions
**What goes wrong:** If someone later creates a repo named "md-spotlighter", redirects from old links break.
**Why it happens:** GitHub prioritizes existing repos over redirects.
**How to avoid:** Document that redirects exist; don't reuse "md-spotlighter" name. Redirects are indefinite otherwise.
**Warning signs:** Old links suddenly 404.
**Source:** [GitHub Community Discussion](https://github.com/orgs/community/discussions/42814)

### Pitfall 5: Case-Sensitivity Issues on macOS
**What goes wrong:** Renaming "md-spotlighter" to "MDQuickLook" may not register on case-insensitive file systems.
**Why it happens:** macOS default filesystem treats these as "same" folder.
**How to avoid:** Use two-step rename: `git mv md-spotlighter temp && git mv temp MDQuickLook`
**Warning signs:** `git status` doesn't show the rename.
**Source:** [TheLinuxCode - Git Move Files 2026](https://thelinuxcode.com/git-move-files-practical-renames-refactors-and-history-preservation-in-2026/)

### Pitfall 6: Incomplete Planning Docs Update
**What goes wrong:** 428 occurrences of "spotlighter" across 85 planning files remain after code update.
**Why it happens:** Focus on code files, forgetting documentation.
**How to avoid:** Include `.planning/` in grep sweep; decide if historical docs should be updated (recommendation: YES for consistency).
**Warning signs:** Searching repo still finds old name.

## Code Examples

### Verified: OSLog Subsystem Pattern
```swift
// BEFORE (current code)
extension OSLog {
    private static var subsystem = "com.razielpanic.md-spotlighter"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

// AFTER (target state)
extension OSLog {
    private static var subsystem = "com.rocketpop.MDQuickLook"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}
```

### Verified: Error Domain Pattern
```swift
// BEFORE (current code)
handler(NSError(domain: "MDSpotlighter", code: -1, userInfo: [...]))

// AFTER (target state)
handler(NSError(domain: "MDQuickLook", code: -1, userInfo: [...]))
```

### Verified: Info.plist Bundle Configuration
```xml
<!-- Main App Info.plist - AFTER -->
<key>CFBundleIdentifier</key>
<string>com.rocketpop.MDQuickLook</string>
<key>CFBundleName</key>
<string>MD Quick Look</string>

<!-- Extension Info.plist - AFTER -->
<key>CFBundleIdentifier</key>
<string>com.rocketpop.MDQuickLook.Extension</string>
<key>CFBundleDisplayName</key>
<string>MD Quick Look</string>
<key>CFBundleName</key>
<string>MD Quick Look</string>
```

### Verified: git mv Two-Step Rename (for case changes)
```bash
# Safe rename preserving history on case-insensitive filesystems
cd /Users/razielpanic/Projects/md-spotlighter
git mv md-spotlighter/md-spotlighter.xcodeproj md-spotlighter/temp.xcodeproj
git mv md-spotlighter/temp.xcodeproj md-spotlighter/MDQuickLook.xcodeproj
# Repeat for other directories needing case-change renames
```

### Verified: GitHub Repository Rename
```bash
# Rename repository (run from within repo)
gh repo rename md-quick-look -y

# Verify new URL works
git remote -v  # Should show new URL after fetch
```

### Verified: project.pbxproj Key Replacements
```
# These strings need replacement in project.pbxproj:
"md-spotlighter" -> "MDQuickLook"           # Target names, product names
"com.razielpanic.md-spotlighter" -> "com.rocketpop.MDQuickLook"  # Bundle IDs
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Xcode built-in rename | Manual git mv + text edits | Long-standing best practice | Much safer for complex projects |
| GitHub web rename | `gh repo rename` CLI | gh 2.x+ | Faster, scriptable |
| Finder rename | `git mv` | Always for version control | Preserves history tracking |

**Deprecated/outdated:**
- Using Xcode's "Rename" refactoring for projects with embedded extensions (too risky)
- Manually updating build directory paths (now handled by derived data)

## Inventory of Changes Required

### Source Files (4 files, 8 occurrences)
| File | Line | Current | Target |
|------|------|---------|--------|
| PreviewViewController.swift | 7 | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |
| PreviewViewController.swift | 19 | `MD Spotlighter Quick Look` | `MD Quick Look Extension` |
| PreviewViewController.swift | 28,43 | `MDSpotlighter` (error domain) | `MDQuickLook` |
| MarkdownRenderer.swift | 7 | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |
| MarkdownLayoutManager.swift | 5 | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |
| TableRenderer.swift | 7 | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |

### Info.plist Files (2 files)
| File | Key | Current | Target |
|------|-----|---------|--------|
| md-spotlighter/Info.plist | CFBundleIdentifier | `com.razielpanic.md-spotlighter` | `com.rocketpop.MDQuickLook` |
| md-spotlighter/Info.plist | CFBundleName | `MD Spotlighter` | `MD Quick Look` |
| MDQuickLook/Info.plist | CFBundleIdentifier | `com.razielpanic.md-spotlighter.quicklook` | `com.rocketpop.MDQuickLook.Extension` |
| MDQuickLook/Info.plist | CFBundleDisplayName | `.md for QuickLook` | `MD Quick Look` |
| MDQuickLook/Info.plist | CFBundleName | `.md for QuickLook` | `MD Quick Look` |

### project.pbxproj (1 file, many occurrences)
- Target name: `md-spotlighter` -> `MDQuickLook` (or "MD Quick Look" for display)
- Product name: `md-spotlighter.app` -> `MDQuickLook.app` (or "MD Quick Look.app")
- Bundle identifiers: As above
- INFOPLIST_FILE paths: Update after directory rename

### Makefile (1 file)
```makefile
# Current values needing update:
PROJECT_DIR = md-spotlighter
SCHEME = md-spotlighter
APP_NAME = md-spotlighter.app
# References in commands: killall md-spotlighter
```

### Directory Renames (via git mv)
```bash
# In order:
md-spotlighter/md-spotlighter/ -> md-spotlighter/MDQuickLook/      # App source
md-spotlighter/md-spotlighter.xcodeproj/ -> md-spotlighter/MDQuickLook.xcodeproj/
md-spotlighter/ -> MDQuickLook/                                    # Project folder
```

### Planning Documentation
- `.planning/config.json`: Update `project_name`
- All 85+ files: Replace "spotlighter"/"Spotlighter" with appropriate new name

### GitHub Repository
- `gh repo rename md-quick-look -y`

## Open Questions

1. **Planning docs historical accuracy**
   - What we know: 428 occurrences across 85 files reference old name
   - What's unclear: Should historical summaries retain old name for accuracy, or update for searchability?
   - Recommendation: Update all to new name for consistency and grep-ability. Historical context is preserved in git history.

2. **Scheme naming in Xcode**
   - What we know: Scheme name follows target name
   - What's unclear: Whether "MD Quick Look" (with space) or "MDQuickLook" is better for scheme
   - Recommendation: Use "MDQuickLook" (no space) for scheme name to match target, avoiding path issues.

## Sources

### Primary (HIGH confidence)
- [Apple Developer Forums - Extension Bundle ID](https://developer.apple.com/forums/thread/20239) - Bundle ID nesting requirement
- [CreateWithSwift - Safely Renaming Xcode Project](https://www.createwithswift.com/safely-renaming-your-xcode-project/) - Manual rename approach
- [GitHub Docs - Renaming a Repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository) - Redirect behavior
- [TheLinuxCode - Git Move Files 2026](https://thelinuxcode.com/git-move-files-practical-renames-refactors-and-history-preservation-in-2026/) - Case-sensitivity handling

### Secondary (MEDIUM confidence)
- [GitHub Community Discussion](https://github.com/orgs/community/discussions/42814) - Redirect duration
- [GitHub Gist - Xcode Rename](https://gist.github.com/jyshnkr/23cf9c470e129f417940f32924cfb481) - Step-by-step process

### Codebase Analysis (HIGH confidence)
- Direct grep of current codebase for "spotlighter" patterns
- Direct read of project.pbxproj, Info.plist files, Swift source files

## Metadata

**Confidence breakdown:**
- Xcode renaming approach: HIGH - multiple authoritative sources agree, verified with codebase analysis
- Bundle ID requirements: HIGH - Apple documentation explicit
- GitHub redirects: HIGH - official docs confirm indefinite redirects
- Planning docs update: MEDIUM - decision about historical accuracy is judgment call

**Research date:** 2026-02-02
**Valid until:** Indefinitely - renaming practices are stable
