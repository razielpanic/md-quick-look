# Phase 9: Distribution Packaging - Research

**Researched:** 2026-02-05
**Domain:** macOS app distribution via DMG and GitHub Releases
**Confidence:** HIGH

## Summary

Researched how to create professional DMG distribution packages for macOS apps and publish them on GitHub Releases. The research covered both signed/notarized and unsigned distribution paths, since Code Signing & Notarization was removed as a separate phase.

**Key findings:**
- `create-dmg` (npm package by sindresorhus) is the standard tool for creating professional DMG files with minimal configuration
- GitHub CLI (`gh release create`) handles release creation and asset uploads in a single command
- Unsigned distribution is viable for v1.1 GitHub release with user-friendly Gatekeeper bypass instructions
- Code signing can be deferred - unsigned apps work fine with documented right-click > Open workaround
- Quick Look extensions embedded in host apps require signing both .app and .appex if code signing is pursued

**Primary recommendation:** Use `create-dmg` with `--no-code-sign` flag for v1.1 unsigned distribution, create GitHub release v1.1 with `gh release create`, and provide clear Gatekeeper bypass instructions in release notes.

## Standard Stack

The established tools for macOS DMG distribution:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| create-dmg | Latest (npm) | Create professional DMG files | Industry standard from sindresorhus, minimal config, handles icon composition and layout automatically |
| gh CLI | 2.x+ | Create GitHub releases and upload assets | Official GitHub CLI, handles release creation, tagging, and asset uploads in single command |
| Xcode xcodebuild | System | Build and archive .app bundle | Native Apple toolchain, required for macOS app builds |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| codesign | System | Sign app bundles and DMG | Only if pursuing signed distribution (optional for v1.1) |
| spctl | System | Verify Gatekeeper compatibility | Test that signed builds pass Gatekeeper checks |
| qlmanage | System | Test Quick Look extensions | Verify extension works after packaging |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| create-dmg (npm) | create-dmg (shell script) | Shell version works without Node.js but less actively maintained |
| create-dmg | hdiutil directly | hdiutil is lower-level, requires manual icon/layout/window configuration |
| create-dmg | DropDMG (paid GUI) | GUI app costs money, create-dmg is free and scriptable |
| gh CLI | Manual GitHub web UI | CLI is faster and scriptable for releases |

**Installation:**
```bash
# Install create-dmg globally
npm install --global create-dmg

# gh CLI is likely already installed (common dev tool)
# If not: brew install gh
```

## Architecture Patterns

### Recommended Distribution Workflow

```
Build Phase:
1. Build .app with Xcode (xcodebuild archive or Xcode GUI)
2. Export .app from archive to known location

Package Phase:
3. Create DMG with create-dmg (unsigned or signed)
4. Test DMG installation on clean state

Release Phase:
5. Create GitHub release with gh CLI
6. Attach DMG as release asset
7. Write release notes with installation instructions
```

### Pattern 1: Unsigned Distribution (Recommended for v1.1)

**What:** Create unsigned DMG with clear Gatekeeper bypass instructions
**When to use:** First public release, rapid iteration, GitHub-only distribution
**Why:** Faster iteration, no Apple Developer account required, users comfortable with right-click > Open

**Example workflow:**
```bash
# 1. Build app (archive via Xcode GUI or xcodebuild)
# Produces: ~/Library/Developer/Xcode/Archives/.../MDQuickLook.xcarchive

# 2. Export .app from archive
# Manual: Right-click archive > Show in Finder > Show Package Contents > Products/Applications
# Result: MD Quick Look.app

# 3. Create unsigned DMG
create-dmg 'MD Quick Look.app' --no-code-sign --dmg-title="MD Quick Look v1.1"

# Produces: MD-Quick-Look-1.1.0.dmg (if app has version 1.1.0 in Info.plist)

# 4. Create GitHub release with DMG attached
gh release create v1.1.0 \
  --title "v1.1.0 - First Public Release" \
  --notes-file RELEASE_NOTES.md \
  "MD-Quick-Look-1.1.0.dmg#MD Quick Look v1.1.0 for macOS"
```

### Pattern 2: Signed and Notarized Distribution (Future)

**What:** Code sign app bundle, create signed DMG, submit for notarization, staple ticket
**When to use:** App Store preparation, enterprise distribution, reducing user friction
**Why:** No Gatekeeper warnings, installs seamlessly, professional polish

**Requirements:**
- Apple Developer Program membership ($99/year)
- Developer ID Application certificate
- App-specific password for notarization
- Two-factor authentication enabled

**Example workflow:**
```bash
# 1. Sign app bundle (both .app and embedded .appex)
codesign --deep --force --verify --verbose \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  --options runtime \
  "MD Quick Look.app"

# 2. Verify signing
codesign --verify --deep --strict --verbose=2 "MD Quick Look.app"
spctl --assess --type execute --verbose "MD Quick Look.app"

# 3. Create signed DMG (create-dmg signs by default if cert available)
create-dmg 'MD Quick Look.app' --identity="Developer ID Application: Your Name"

# 4. Notarize DMG
xcrun notarytool submit MD-Quick-Look-1.1.0.dmg \
  --apple-id your@email.com \
  --password app-specific-password \
  --team-id TEAM_ID \
  --wait

# 5. Staple notarization ticket
xcrun stapler staple MD-Quick-Look-1.1.0.dmg

# 6. Verify notarization
spctl --assess --type open --context context:primary-signature -vv MD-Quick-Look-1.1.0.dmg
```

### Pattern 3: Release Notes Structure

**What:** Markdown release notes with installation instructions and Gatekeeper bypass
**Format:**
```markdown
## What's New in v1.1.0

- First public release
- Professional app icon
- SwiftUI host app with About and Settings windows
- [List specific changes from v1.0]

## Installation

1. Download **MD-Quick-Look-1.1.0.dmg**
2. Open the DMG file
3. Drag **MD Quick Look.app** to **/Applications**
4. **Launch the app once** to register the Quick Look extension

## macOS Security Note

macOS Gatekeeper will show a security warning on first launch:
_"MD Quick Look.app cannot be opened because the developer cannot be verified"_

**Solution (recommended):**
1. Right-click on **MD Quick Look.app** in Applications
2. Select **Open**
3. Click **Open** again in the confirmation dialog

**Alternative (command line):**
```bash
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```

After this one-time step, the app will launch normally.

## Requirements

- macOS 26 (Tahoe) or later
```

### Anti-Patterns to Avoid

- **Signing only the .app without the embedded .appex:** Quick Look extensions require both host app and extension to be signed; signing only one breaks the bundle
- **Creating DMG before verifying app works:** Always test the built .app launches and the extension registers before packaging
- **Forgetting version in DMG filename:** Users download multiple versions; include version for clarity
- **Using `--deep` flag when signing:** Apple recommends signing inside-out (extension first, then app), not deep signing
- **Notarizing without stapling:** Stapling embeds the notarization ticket in the DMG; without it, offline Macs can't verify

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DMG creation with custom background/layout | Manual hdiutil commands with AppleScript | create-dmg | Handles icon composition, window sizing, background images, code signing detection automatically |
| GitHub release creation and asset upload | Manual web UI clicks or curl to GitHub API | gh CLI | Handles authentication, release creation, tagging, asset uploads, draft/prerelease flags in single command |
| Gatekeeper testing | Manual clicking through app launches | spctl --assess | Programmatic verification that Gatekeeper will accept your app; catches signing issues early |
| App bundle verification | Visual inspection or codesign alone | codesign --verify --deep --strict + spctl | Both tools needed: codesign checks signature integrity, spctl checks Gatekeeper acceptance |
| Removing quarantine attributes | Manual System Settings navigation | xattr -dr com.apple.quarantine | Single command removes all quarantine flags recursively; faster than GUI |

**Key insight:** macOS distribution involves many low-level details (code signing nested bundles, DMG layout, notarization flow). Using standard tools prevents common pitfalls and ensures professional results.

## Common Pitfalls

### Pitfall 1: Nested Bundle Signing Order

**What goes wrong:** Signing the .app before the embedded .appex causes "invalid signature" errors or Gatekeeper rejection
**Why it happens:** Code signing seals the entire bundle including nested bundles; signing outer bundle first means inner bundle signature isn't included in the seal
**How to avoid:** Sign inside-out: (1) sign .appex extension, (2) sign .app host app. Or use Xcode's automatic signing which handles order correctly
**Warning signs:** `codesign --verify --deep --strict` fails with "bundle format unrecognized" or "code signature invalid"

### Pitfall 2: Unsigned DMG Gatekeeper Path Randomization

**What goes wrong:** Unsigned DMG works initially but app can't update itself or access resources in later launches
**Why it happens:** macOS copies apps from unsigned disk images to random read-only locations before launch (Gatekeeper Path Randomization)
**How to avoid:** Either (1) sign the DMG, or (2) instruct users to copy app to /Applications before launching (which create-dmg's visual layout encourages)
**Warning signs:** App launches but can't write preferences, can't find embedded resources after first launch

### Pitfall 3: Missing App Launch Before Quick Look Works

**What goes wrong:** Users install app, try Quick Look on .md file, nothing happens
**Why it happens:** macOS only discovers Quick Look extensions when the host app launches at least once
**How to avoid:** Document prominently: "Launch the app once to register the extension"
**Warning signs:** Extension shows in System Settings > Extensions > Quick Look but doesn't activate until app is launched

### Pitfall 4: DMG Filename Version Mismatch

**What goes wrong:** DMG is named "v1.1.0" but Info.plist has version "1.0.0", confusing users and breaking automation
**Why it happens:** Manual DMG naming doesn't sync with app bundle version
**How to avoid:** Let create-dmg read version from Info.plist automatically, or use consistent version variables in build scripts
**Warning signs:** GitHub release tag doesn't match DMG filename doesn't match app About window version

### Pitfall 5: Testing Only on Development Mac

**What goes wrong:** DMG works on your Mac but fails on user machines with Gatekeeper errors or extension not discovered
**Why it happens:** Development Mac has Gatekeeper set to less strict mode, or has leftover build artifacts/cached extension state
**How to avoid:** Test DMG installation on clean Mac: fresh user account, VM, or Test Flight / GitHub beta testers
**Warning signs:** Works for you, multiple users report "app won't open" or "extension doesn't work"

### Pitfall 6: Forgetting to Commit Built App Before DMG Creation

**What goes wrong:** Build .app in Xcode, immediately create DMG, but built app isn't in the expected location
**Why it happens:** Xcode archives go to ~/Library/Developer/Xcode/Archives/ by default, not visible in project folder
**How to avoid:** Export .app from archive to known location (like project build/ folder) before running create-dmg
**Warning signs:** create-dmg fails with "cannot find 'MD Quick Look.app'"

### Pitfall 7: GitHub Release Without Installation Instructions

**What goes wrong:** Users download DMG, encounter Gatekeeper warning, give up
**Why it happens:** Unsigned apps require explicit bypass steps; users assume "broken download" without instructions
**How to avoid:** Include Gatekeeper bypass instructions directly in GitHub release notes (not just README)
**Warning signs:** GitHub issues/discussions with "app won't open" or "is this malware?"

## Code Examples

Verified patterns from official sources:

### Create Unsigned DMG
```bash
# Source: https://github.com/sindresorhus/create-dmg
# Minimal command for unsigned distribution
create-dmg 'MD Quick Look.app' --no-code-sign

# With custom title (max 27 characters)
create-dmg 'MD Quick Look.app' --no-code-sign --dmg-title="MD Quick Look v1.1"

# Overwrite existing DMG (useful in build scripts)
create-dmg 'MD Quick Look.app' --no-code-sign --overwrite
```

### Create GitHub Release with Asset
```bash
# Source: https://cli.github.com/manual/gh_release_create
# Create release from current branch HEAD, attach DMG
gh release create v1.1.0 \
  --title "v1.1.0 - First Public Release" \
  --notes "See README for installation and troubleshooting" \
  "MD-Quick-Look-1.1.0.dmg#MD Quick Look v1.1.0 for macOS"

# With release notes from file
gh release create v1.1.0 \
  --title "v1.1.0 - First Public Release" \
  --notes-file RELEASE_NOTES.md \
  "MD-Quick-Look-1.1.0.dmg"

# As prerelease (beta/RC)
gh release create v1.1.0-beta \
  --prerelease \
  --title "v1.1.0-beta - Beta Release" \
  --notes-file RELEASE_NOTES.md \
  "MD-Quick-Look-1.1.0-beta.dmg"
```

### Verify App Bundle Before Packaging
```bash
# Source: https://developer.apple.com/library/archive/technotes/tn2206/_index.html
# Check code signature (if signed)
codesign --verify --deep --strict --verbose=2 "MD Quick Look.app"

# Check Gatekeeper acceptance (if signed)
spctl --assess --type execute --verbose "MD Quick Look.app"

# Test Quick Look extension registration
qlmanage -r
qlmanage -m plugins | grep -i "md quick look"

# Test Quick Look preview on sample markdown file
qlmanage -p test.md
```

### Remove Quarantine Attribute (User Instructions)
```bash
# Source: https://developer.apple.com/forums/thread/666452
# Single command to remove quarantine from installed app
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app

# Verify quarantine removed
xattr -l /Applications/MD\ Quick\ Look.app
# Should NOT show com.apple.quarantine in output

# Alternative: Show quarantine first, then remove
xattr -l /Applications/MD\ Quick\ Look.app | grep quarantine
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual hdiutil commands | create-dmg wrapper tool | 2015+ | Automated icon composition, window layout, codesigning detection |
| Manual GitHub API calls | gh CLI | 2020+ | Single command for release creation + asset upload + notes |
| notarytool vs altool | notarytool only | Xcode 13+ (2021) | altool deprecated, notarytool is faster and has better CLI experience |
| --deep signing | Inside-out signing | 2019+ (Catalina) | Apple recommends signing nested bundles individually, --deep for emergency only |
| Control-click to bypass Gatekeeper | Still works in Sequoia | 2024 | macOS Sequoia changed the flow (now requires Privacy & Security settings) but control-click still available |

**Deprecated/outdated:**
- `altool` for notarization: Replaced by `notarytool` in Xcode 13+, altool removed entirely in Xcode 14+
- `--exportFormat` in xcodebuild: Replaced by `--exportOptionsPlist` for archive exports
- Manual DMG layout with AppleScript: create-dmg handles layout automatically with sensible defaults

## Open Questions

Things that couldn't be fully resolved:

1. **macOS 26 (Tahoe) specific Gatekeeper changes**
   - What we know: macOS 26.2 has a reported issue with code signature invalidation after first launch (Tailscale bug report)
   - What's unclear: Whether this affects Quick Look extensions specifically, or just Network/System Extensions
   - Recommendation: Test unsigned distribution first, monitor for user reports, add signing if Gatekeeper issues emerge

2. **Optimal testing environment for DMG validation**
   - What we know: Clean Mac testing is essential, VMs available (Orka Desktop, QEMU/KVM)
   - What's unclear: Whether user has access to VM infrastructure, or prefers fresh user account on same Mac
   - Recommendation: Start with fresh user account (`Users & Groups > Add User`), escalate to VM if complex Gatekeeper issues arise

3. **Whether to include .app bundle directly in git**
   - What we know: Built .app is typically gitignored, only source code tracked
   - What's unclear: Project's current .gitignore setup, whether pre-release v1.1-beta has .app committed
   - Recommendation: Keep .app gitignored, only commit DMG to GitHub Releases as asset, not repo

## Sources

### Primary (HIGH confidence)
- [sindresorhus/create-dmg GitHub](https://github.com/sindresorhus/create-dmg) - Installation, usage, API
- [gh release create manual](https://cli.github.com/manual/gh_release_create) - Complete syntax, examples
- [Apple Developer: Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) - Official notarization requirements (page had JS error but URL verified)
- [Apple Technical Note TN2206: macOS Code Signing In Depth](https://developer.apple.com/library/archive/technotes/tn2206/_index.html) - Codesign verification, best practices

### Secondary (MEDIUM confidence)
- [idownloadblog: macOS Sequoia Gatekeeper changes](https://www.idownloadblog.com/2024/08/07/apple-macos-sequoia-gatekeeper-change-install-unsigned-apps-mac/) - User-facing Gatekeeper bypass flow
- [Apple Developer Forums: Quick Look extension signing](https://developer.apple.com/forums/thread/718589) - Nested bundle signing order
- [Apple Developer Forums: xcodebuild unsigned export](https://developer.apple.com/forums/thread/75636) - Unsigned archive creation
- [ISSCloud: com.apple.quarantine attribute](https://www.isscloud.io/guides/macos-security-and-com-apple-quarantine-extended-attribute/) - xattr command usage
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) - Release notes best practices
- [Semantic Versioning 2.0.0](https://semver.org/) - Version numbering standards

### Tertiary (LOW confidence)
- WebSearch results on DMG testing via VMs - Multiple sources but none authoritative (MacStadium, VirtualBox wikis)
- WebSearch results on macOS 26.2 signature invalidation bug - Single Tailscale issue report, not officially confirmed by Apple

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - create-dmg and gh CLI are industry standards with official documentation
- Architecture patterns: HIGH - Workflow verified with official Apple docs and tool documentation
- Unsigned distribution: HIGH - Documented user bypass methods stable across macOS versions
- Code signing process: MEDIUM - Requirements well-documented but not tested in this research phase
- Quick Look extension specifics: MEDIUM - General app extension signing rules apply, but QL-specific testing needed
- macOS 26 compatibility: MEDIUM - Based on recent reports but no official Apple documentation for Tahoe-specific changes

**Research date:** 2026-02-05
**Valid until:** 2026-03-07 (30 days - relatively stable domain, but macOS updates can change Gatekeeper behavior)

**Notes:**
- User has pre-release v1.1-beta already published, so GitHub release workflow is partially understood
- README already has Gatekeeper troubleshooting, indicating user expects unsigned distribution for v1.1
- Prior decision: "Manual DMG installation only" confirms v1.1 will not pursue Homebrew cask or App Store
- Code Signing & Notarization phase was removed from roadmap, indicating preference for unsigned v1.1 release
