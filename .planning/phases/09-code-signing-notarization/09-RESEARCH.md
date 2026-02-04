# Phase 9: Code Signing & Notarization - Research

**Researched:** 2026-02-03
**Domain:** macOS code signing, notarization, and Gatekeeper compliance
**Confidence:** MEDIUM

## Summary

Code signing and notarization for macOS apps distributed outside the App Store requires a paid Apple Developer Program membership ($99/year), Developer ID certificates, hardened runtime enablement, and submission to Apple's notary service. The process follows a specific workflow: sign all components inside-out (frameworks and extensions first, then the main app), submit to notarization, wait for approval, and staple the ticket to the app bundle.

For Quick Look extensions specifically, this means signing the .appex bundle before signing the containing .app bundle. The signing must include hardened runtime flags and appropriate entitlements. Notarization is performed using the `xcrun notarytool` command-line tool (the old `altool` is deprecated as of November 2023). Once notarized, the ticket must be stapled using `xcrun stapler` to allow offline verification.

The primary technical challenge is getting the signing order and entitlements correct. Common pitfalls include using `--deep` flag (deprecated and unreliable), signing in wrong order (outside-in instead of inside-out), missing hardened runtime flags, and incorrect or missing entitlements.

**Primary recommendation:** Use Xcode's automatic code signing for development and testing, but understand the manual `codesign` workflow for troubleshooting and CI/CD. Sign components inside-out (.appex before .app), enable hardened runtime, submit with `notarytool --wait`, and staple the ticket before distribution.

## Standard Stack

The established tools for macOS code signing and notarization:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| codesign | Built into macOS | Command-line tool for signing code | Apple's official signing tool, part of Xcode Command Line Tools |
| xcrun notarytool | Xcode 13+ | Submit apps for notarization | Replaced deprecated altool, only accepted method since Nov 2023 |
| xcrun stapler | Built into macOS | Attach notarization ticket to app | Enables offline Gatekeeper verification |
| Xcode | 14+ | IDE with integrated signing | Automatic certificate management, GUI for entitlements |
| security | Built into macOS | Keychain access for certificates | Manage signing identities and credentials |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| spctl | Built into macOS | Gatekeeper assessment tool | Verify that signed app passes Gatekeeper checks |
| codesign --verify | Built into macOS | Verify code signatures | Check signature validity independent of Gatekeeper |
| codesign --display | Built into macOS | Inspect signature details | View entitlements, runtime flags, signing identity |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| xcrun notarytool | Third-party notarization tools | Third-party tools may simplify workflow but add dependency and lag behind Apple's updates |
| Xcode automatic signing | Manual codesign scripts | Manual signing gives full control but requires deeper understanding and more maintenance |

**Installation:**
```bash
# Install Xcode from Mac App Store
# https://apps.apple.com/us/app/xcode/id497799835

# Verify Xcode Command Line Tools
xcode-select --install

# Verify tools are available
which codesign
which xcrun
which stapler
```

## Architecture Patterns

### Recommended Signing Workflow

```
1. Join Apple Developer Program ($99/year)
   └── Create Developer ID Application certificate

2. Configure Xcode Project
   ├── Enable "Hardened Runtime" capability
   ├── Add required entitlements
   └── Set "Developer ID Application" as signing identity

3. Sign Components (Inside-Out Order)
   ├── Sign frameworks/dylibs (deepest first)
   ├── Sign .appex extension
   └── Sign .app bundle (last)

4. Package for Notarization
   ├── Option A: ZIP the .app bundle
   ├── Option B: Create DMG disk image
   └── Option C: Create PKG installer

5. Submit to Apple Notary Service
   └── xcrun notarytool submit --wait

6. Staple Notarization Ticket
   └── xcrun stapler staple MyApp.app

7. Verify
   ├── codesign --verify --deep --strict
   └── spctl --assess --type execute
```

### Pattern 1: Inside-Out Signing Order

**What:** Sign nested code components from deepest to outermost in the bundle hierarchy

**When to use:** Always, for any app bundle containing frameworks, plugins, or app extensions

**Why:** The outer bundle's signature must seal and reference the inner signatures. Changing inner components after outer signing breaks the seal.

**Example:**
```bash
# For MDQuickLook.app with Extension.appex inside

# 1. Sign any frameworks first (if present)
codesign --force --timestamp --options runtime \
  --sign "Developer ID Application: YourName (TeamID)" \
  "MDQuickLook.app/Contents/Frameworks/SomeFramework.framework"

# 2. Sign the Quick Look extension (.appex)
codesign --force --timestamp --options runtime \
  --entitlements Extension.entitlements \
  --sign "Developer ID Application: YourName (TeamID)" \
  "MDQuickLook.app/Contents/PlugIns/Extension.appex"

# 3. Sign the main app bundle (LAST)
codesign --force --timestamp --options runtime \
  --entitlements MDQuickLook.entitlements \
  --sign "Developer ID Application: YourName (TeamID)" \
  "MDQuickLook.app"
```

### Pattern 2: Notarization Workflow with Keychain Profile

**What:** Store Apple ID credentials securely in keychain, submit app for notarization, wait for result, staple ticket

**When to use:** For every release build distributed outside the App Store

**Example:**
```bash
# One-time setup: Store credentials in keychain
xcrun notarytool store-credentials "NotaryProfile" \
  --apple-id "you@example.com" \
  --team-id "ABCD123456" \
  --password "app-specific-password"

# Submit app for notarization (with --wait to block until complete)
xcrun notarytool submit MDQuickLook.zip \
  --keychain-profile "NotaryProfile" \
  --wait

# If submission succeeds, staple the ticket
xcrun stapler staple MDQuickLook.app

# Verify stapling succeeded
xcrun stapler validate MDQuickLook.app
```

### Pattern 3: Verification Workflow

**What:** Multi-level verification to ensure code signing and notarization are correct

**When to use:** Before distributing any build, and when troubleshooting signing issues

**Example:**
```bash
# 1. Verify code signature is valid
codesign --verify --deep --strict --verbose=2 MDQuickLook.app

# 2. Display signature details
codesign --display --verbose=4 MDQuickLook.app

# 3. Check hardened runtime is enabled (look for "runtime" flag)
codesign --display --verbose MDQuickLook.app | grep runtime

# 4. View entitlements
codesign --display --entitlements - MDQuickLook.app

# 5. Test Gatekeeper assessment (what users will experience)
spctl --assess --type execute --verbose MDQuickLook.app

# 6. Verify notarization ticket is stapled
xcrun stapler validate MDQuickLook.app
```

### Pattern 4: Entitlements Configuration

**What:** Create entitlements plist files for app and extension with required capabilities

**When to use:** When hardened runtime prevents needed functionality (debugging, dynamic loading, etc.)

**Example MDQuickLook.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for hardened runtime -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Allow reading user-selected files (Quick Look requirement) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>

    <!-- Network access if needed for future features -->
    <key>com.apple.security.network.client</key>
    <false/>
</dict>
</plist>
```

**Example Extension.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Quick Look extensions must be sandboxed -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- Read access to previewed files -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

### Anti-Patterns to Avoid

- **Using --deep flag:** Deprecated since macOS 13, unreliable for complex bundles, applies all options to nested code which may not be appropriate
- **Signing outside-in:** Signing the .app before the .appex breaks the seal when you later sign the extension
- **Missing --timestamp:** Required for Developer ID, ensures signature remains valid even after certificate expires
- **Omitting --options runtime:** Hardened runtime is required for notarization; without it, submission will fail
- **Using --force blindly:** While sometimes necessary, it can hide underlying issues; prefer fixing the root cause
- **Not verifying before distribution:** Always run verification commands to catch issues before users encounter them

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Storing Apple ID credentials | Shell scripts with passwords | `xcrun notarytool store-credentials` | Secure keychain storage, prevents credential exposure in scripts |
| Checking notarization status | Custom polling scripts | `xcrun notarytool submit --wait` | Built-in polling with proper timeouts and error handling |
| Finding signing identities | Parsing security output | `security find-identity -v -p codesigning` | Official command provides clean, parseable output |
| Determining what to sign | Manually listing files | Let Xcode handle it or use `codesign` on bundles | Apple's tools understand bundle structure and signing requirements |
| Creating DMGs for distribution | Shell scripts with hdiutil | Use create-dmg tool or Xcode's Archive & Export | Handles code signing of disk images, notarization-ready formats |
| Entitlements management | Editing raw XML | Xcode's Signing & Capabilities UI | Validates entitlements, prevents typos, provides autocomplete |

**Key insight:** Apple provides specific, maintained tools for each step of the code signing and notarization workflow. Using them ensures compatibility with current and future macOS versions, proper error messages, and adherence to Apple's security requirements.

## Common Pitfalls

### Pitfall 1: Wrong Signing Order (Outside-In Instead of Inside-Out)

**What goes wrong:** Developer signs the main .app bundle first, then realizes the .appex extension inside also needs signing. When they sign the .appex, it invalidates the outer .app signature.

**Why it happens:** Intuition suggests signing the "main" thing first. The bundle hierarchy isn't visually obvious until you explore the .app package contents.

**How to avoid:** Always sign from innermost to outermost. Use this command to find all nested code:
```bash
find MDQuickLook.app -name "*.appex" -o -name "*.framework" -o -name "*.dylib"
```
Sign each result, then sign the main bundle last.

**Warning signs:**
- `codesign --verify` fails with "resource envelope is obsolete"
- Gatekeeper warns "App is damaged" even though you just signed it
- Notarization fails with "invalid signature" for nested code

### Pitfall 2: Missing Hardened Runtime Flag

**What goes wrong:** Notarization submission fails with error: "The executable does not have the hardened runtime enabled"

**Why it happens:** The `--options runtime` flag is not included in the codesign command, or Xcode project doesn't have "Hardened Runtime" capability enabled.

**How to avoid:**
- In Xcode: Enable "Hardened Runtime" under Signing & Capabilities tab
- Command line: Always include `--options runtime` when signing with Developer ID
- Verify with: `codesign --display --verbose MDQuickLook.app | grep "flags=.*runtime"`

**Warning signs:**
- Notarization fails immediately with hardened runtime error
- `codesign --display` output doesn't show "runtime" in flags
- App launches locally but Gatekeeper blocks it on other Macs

### Pitfall 3: Certificate Has Expired

**What goes wrong:** Developer ID Application certificate expires, and new builds fail to sign.

**Why it happens:** Certificates expire after 5 years. Apple sends renewal reminders but they can be missed.

**How to avoid:**
- Set calendar reminders for 30 days before expiration
- Check certificate validity: `security find-identity -v -p codesigning`
- Renew certificate through Apple Developer portal before expiration

**Important:** Code signed BEFORE expiration remains valid indefinitely due to trusted timestamp. Only new signing attempts will fail.

**Warning signs:**
- `codesign` fails with "certificate has expired"
- Xcode shows "No signing certificate found" even though you have one
- `security find-identity` shows certificate with expiration date in the past

### Pitfall 4: Using App-Specific Password Instead of App Store Connect API Key

**What goes wrong:** Notarization works for individual developers but fails in CI/CD pipelines or when 2FA is required.

**Why it happens:** App-specific passwords require interactive setup and don't work well in automated environments.

**How to avoid:** For CI/CD, use App Store Connect API keys instead:
```bash
xcrun notarytool submit MyApp.zip \
  --key AuthKey_KEYID.p8 \
  --key-id KEYID \
  --issuer ISSUER_ID \
  --wait
```

**Warning signs:**
- Notarization works locally but fails in CI/CD
- Authentication errors when running non-interactively
- Need to re-authenticate frequently

### Pitfall 5: Not Waiting for Notarization to Complete

**What goes wrong:** Developer submits app for notarization, assumes it succeeded immediately, and distributes the app without stapling the ticket.

**Why it happens:** Notarization is asynchronous and can take from seconds to several minutes. Without `--wait` flag, the command returns immediately with a submission ID.

**How to avoid:**
- Always use `--wait` flag: `xcrun notarytool submit --wait`
- If not using --wait, check status: `xcrun notarytool wait SUBMISSION_ID`
- Only staple after receiving "Accepted" status

**Warning signs:**
- Users report Gatekeeper warnings even though "you notarized it"
- `stapler validate` fails with "does not have a ticket stapled"
- Stapling command fails with "could not find a valid ticket"

### Pitfall 6: Incorrect Bundle Identifier

**What goes wrong:** Notarization fails with "The binary uses an SDK older than the 10.9 SDK" or "Invalid Code Signing Entitlements"

**Why it happens:** Bundle identifier in Info.plist doesn't match certificate or entitlements, or contains invalid characters.

**How to avoid:**
- Use reverse-DNS format: `com.yourcompany.appname`
- Ensure consistency across Info.plist, entitlements, and Xcode project
- Extension bundle ID should be main bundle ID + suffix: `com.yourcompany.appname.Extension`

**Warning signs:**
- Notarization log shows bundle ID mismatches
- Entitlements validation fails
- Extension doesn't load even though app is signed correctly

### Pitfall 7: Modifying App After Signing

**What goes wrong:** Developer signs the app, then modifies a file inside the bundle (like updating version in Info.plist), which invalidates the signature.

**Why it happens:** Code signature seals the entire bundle. Any modification breaks the seal.

**How to avoid:**
- Make ALL changes before signing
- Signing should be the absolute last step
- If you must modify, re-sign completely

**Warning signs:**
- `codesign --verify` fails with "code object is not signed at all"
- Gatekeeper treats the app as unsigned
- Notarization works but distributed app is rejected by Gatekeeper

### Pitfall 8: Stapling to Wrong Location

**What goes wrong:** Developer staples the ticket to a ZIP file or DMG instead of the .app bundle inside it.

**Why it happens:** Misunderstanding of what "stapling" means and where the ticket should be attached.

**How to avoid:**
- Staple to the .app bundle: `xcrun stapler staple MDQuickLook.app`
- If distributing via DMG: staple to both the .app AND the .dmg
- Verify stapling: `xcrun stapler validate MDQuickLook.app`

**Warning signs:**
- `stapler validate` fails even though notarization succeeded
- Extracting app from DMG and running shows Gatekeeper warning
- App works when internet connected but fails offline

## Code Examples

Verified patterns from official sources and community best practices:

### Complete Signing and Notarization Script

```bash
#!/bin/bash
# Source: Combined from Apple Developer Documentation and community practices
# https://developer.apple.com/developer-id/

set -e  # Exit on error

APP_NAME="MDQuickLook"
APP_PATH="build/${APP_NAME}.app"
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAM123)"
KEYCHAIN_PROFILE="NotaryProfile"

echo "=== Code Signing and Notarization ==="

# Step 1: Sign the Quick Look extension (inside-out order)
echo "Signing extension..."
codesign --force --timestamp --options runtime \
  --entitlements "${APP_NAME}/Extension.entitlements" \
  --sign "$SIGNING_IDENTITY" \
  "${APP_PATH}/Contents/PlugIns/Extension.appex"

# Step 2: Sign the main app bundle
echo "Signing main app..."
codesign --force --timestamp --options runtime \
  --entitlements "${APP_NAME}/${APP_NAME}.entitlements" \
  --sign "$SIGNING_IDENTITY" \
  "${APP_PATH}"

# Step 3: Verify signatures
echo "Verifying signatures..."
codesign --verify --deep --strict --verbose=2 "${APP_PATH}"
echo "✓ Code signature valid"

# Step 4: Create ZIP for notarization
echo "Creating ZIP for notarization..."
ditto -c -k --keepParent "${APP_PATH}" "${APP_NAME}.zip"

# Step 5: Submit to notary service (wait for completion)
echo "Submitting to Apple notary service..."
xcrun notarytool submit "${APP_NAME}.zip" \
  --keychain-profile "$KEYCHAIN_PROFILE" \
  --wait

# Step 6: Staple the ticket
echo "Stapling notarization ticket..."
xcrun stapler staple "${APP_PATH}"

# Step 7: Verify stapling
echo "Verifying staple..."
xcrun stapler validate "${APP_PATH}"

# Step 8: Test Gatekeeper
echo "Testing Gatekeeper assessment..."
spctl --assess --type execute --verbose "${APP_PATH}"

echo "✓ Complete! App is signed, notarized, and stapled."
```

### One-Time Setup: Store Notarization Credentials

```bash
# Source: https://keith.github.io/xcode-man-pages/notarytool.1.html

# First, generate an app-specific password at appleid.apple.com
# Settings → Sign-In and Security → App-Specific Passwords

# Store credentials in keychain with a profile name
xcrun notarytool store-credentials "NotaryProfile" \
  --apple-id "you@example.com" \
  --team-id "ABCD123456" \
  --password "xxxx-xxxx-xxxx-xxxx"

# The password is your app-specific password, NOT your Apple ID password
# Team ID can be found at: https://developer.apple.com/account/
```

### Check Notarization Status (If Not Using --wait)

```bash
# Source: https://keith.github.io/xcode-man-pages/notarytool.1.html

# Submit without waiting
SUBMISSION_ID=$(xcrun notarytool submit MyApp.zip \
  --keychain-profile "NotaryProfile" \
  | grep "id:" | awk '{print $2}')

echo "Submission ID: $SUBMISSION_ID"

# Check status
xcrun notarytool info "$SUBMISSION_ID" \
  --keychain-profile "NotaryProfile"

# Get detailed logs if it failed
xcrun notarytool log "$SUBMISSION_ID" \
  --keychain-profile "NotaryProfile"
```

### Inspect Existing Signatures

```bash
# Source: https://developer.apple.com/library/archive/technotes/tn2206/

# View signature details
codesign --display --verbose=4 MDQuickLook.app

# Check if hardened runtime is enabled
codesign --display --verbose MDQuickLook.app | grep runtime

# View entitlements
codesign --display --entitlements - --xml MDQuickLook.app

# Verify deep signature (including nested code)
codesign --verify --deep --strict --verbose=2 MDQuickLook.app

# Find all code in a bundle that can be signed
find MDQuickLook.app -type f -perm +111 -print
```

### Xcode Build Settings for Code Signing

```bash
# Source: Apple Developer Forums and Xcode documentation

# In Xcode project.pbxproj or xcconfig file:

CODE_SIGN_IDENTITY = "Developer ID Application"
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = TEAM123  // Your Team ID
ENABLE_HARDENED_RUNTIME = YES
CODE_SIGN_ENTITLEMENTS = MDQuickLook/MDQuickLook.entitlements

# For the extension target:
CODE_SIGN_IDENTITY = "Developer ID Application"
CODE_SIGN_STYLE = Automatic
DEVELOPMENT_TEAM = TEAM123
ENABLE_HARDENED_RUNTIME = YES
CODE_SIGN_ENTITLEMENTS = MDQuickLook/Extension.entitlements
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| altool for notarization | xcrun notarytool | November 2023 | Old altool no longer accepted; must use notarytool |
| Xcode 13 or earlier for notarization | Xcode 14+ | November 2023 | Must upgrade Xcode to submit for notarization |
| Optional hardened runtime | Mandatory hardened runtime | macOS 10.14 (Mojave) | All notarized apps must have hardened runtime enabled |
| --deep flag for signing | Sign components individually | macOS 13 (Ventura) | --deep deprecated, unreliable for complex bundles |
| Gatekeeper can be disabled by users | Gatekeeper read-only (macOS 15+) | macOS 15 (Sequoia) | Users can no longer disable Gatekeeper via spctl |
| Developer ID Installer required for expiration | Trusted timestamp preserves validity | Ongoing | Apps signed with valid cert remain valid even after expiration |

**Deprecated/outdated:**
- **altool:** Deprecated November 2023, replaced by notarytool. No longer accepts submissions.
- **--deep flag:** Deprecated in macOS 13, unreliable for apps with complex nested structures. Sign components individually instead.
- **Xcode 13 notarization:** No longer supported as of November 2023. Must use Xcode 14 or later.
- **Optional notarization:** While technically not required for all distribution, user expectations and Gatekeeper warnings make it effectively mandatory for 2026.
- **spctl --master-disable:** Removed in macOS 15 Sequoia. Users can no longer globally disable Gatekeeper from command line.

## Open Questions

Things that couldn't be fully resolved:

1. **Sandbox Entitlements for Quick Look Extensions**
   - What we know: Quick Look extensions must be sandboxed (`com.apple.security.app-sandbox = true`). Some extensions use temporary exception entitlements like `com.apple.security.temporary-exception.mach-lookup.global-name` for specific functionality.
   - What's unclear: The exact set of entitlements required for MDQuickLook extension. Whether read-only file access entitlement is sufficient or if additional permissions are needed.
   - Recommendation: Start with minimal entitlements (sandbox + read-only file access). Test thoroughly. Add exceptions only if specific features fail with clear errors.

2. **Notarization Service Delays (Early 2026)**
   - What we know: Some developers reported submissions stuck in "In Progress" for 24-72+ hours starting January 2026, though Apple Developer System Status shows "Operational"
   - What's unclear: Whether this is resolved, ongoing, or affects specific submission types
   - Recommendation: Use `--wait` flag with generous timeout (e.g., `--timeout 1h`). If submission hangs beyond reasonable time, check Apple Developer forums and system status. Have fallback plan for release timing.

3. **Xcode Automatic vs Manual Signing for Extensions**
   - What we know: Xcode supports automatic signing for both apps and extensions. Manual signing gives full control.
   - What's unclear: Whether Xcode automatic signing correctly handles inside-out order for nested extensions, or if manual intervention is needed
   - Recommendation: Try Xcode automatic signing first. If verification fails, switch to manual codesign workflow with explicit inside-out order.

4. **DMG vs ZIP vs PKG for Distribution**
   - What we know: All three formats (DMG, ZIP, PKG) are supported for notarization. DMGs can also be signed and stapled.
   - What's unclear: Best practice for GitHub distribution of Quick Look extensions (which require installation to ~/Library/QuickLook/ or /Library/QuickLook/)
   - Recommendation: Start with DMG containing the .app with installation instructions. Consider PKG installer for future versions if user feedback indicates installation friction.

5. **Certificate Renewal Impact on Already-Distributed Apps**
   - What we know: Apps signed with valid certificate remain valid after expiration due to trusted timestamp. Developer ID Installer certificates require validity at installation time.
   - What's unclear: Whether users experience any warnings or issues when launching apps signed with expired certificates, even with timestamp
   - Recommendation: Set renewal reminder for 60 days before expiration. Test with expired dev certificate in VM to understand user experience.

## Sources

### Primary (HIGH confidence)
- [Signing Mac Software with Developer ID - Apple Developer](https://developer.apple.com/developer-id/) - Official Apple workflow documentation
- [notarytool man page](https://keith.github.io/xcode-man-pages/notarytool.1.html) - Command reference for notarization
- [Developer ID certificates - Apple Developer](https://developer.apple.com/help/account/certificates/create-developer-id-certificates/) - Certificate creation guide
- [Certificates - Apple Developer](https://developer.apple.com/support/certificates/) - Certificate management overview

### Secondary (MEDIUM confidence)
- [Technical Note TN2206: macOS Code Signing In Depth](https://developer.apple.com/library/archive/technotes/tn2206/) - Apple's technical deep-dive (archived but still accurate)
- [Code Signing Tasks](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/Procedures/Procedures.html) - Apple's code signing procedures (archived)
- [Scripting OS X: Notarize a Command Line Tool with notarytool](https://scriptingosx.com/2021/07/notarize-a-command-line-tool-with-notarytool/) - Community tutorial verified with official docs
- [macOS distribution gist by rsms](https://gist.github.com/rsms/929c9c2fec231f0cf843a1a746a416f5) - Community best practices compilation
- [Eclectic Light: The Hardened Runtime Explained](https://eclecticlight.co/2019/08/10/the-hardened-runtime-explained/) - Detailed hardened runtime explanation
- [Eclectic Light: What's Happening with Code Signing (Jan 2026)](https://eclecticlight.co/2026/01/17/whats-happening-with-code-signing-and-future-macos/) - Recent state of code signing

### Tertiary (LOW confidence - flag for validation)
- Apple Developer Forums threads (2023-2026) - Community troubleshooting, not authoritative
- GitHub repositories with example signing scripts - Useful patterns but not official
- Third-party blog posts about notarization - May be outdated or incomplete

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Apple provides official tools (codesign, notarytool, stapler) with stable APIs
- Architecture patterns: MEDIUM - Inside-out signing is documented but examples vary; notarization workflow well-established
- Pitfalls: MEDIUM - Based on developer forum discussions and community experience, verified against official docs where possible
- Quick Look specific entitlements: LOW - Limited official documentation specific to Quick Look extensions; requires testing

**Research date:** 2026-02-03
**Valid until:** 2026-03-03 (30 days - Apple's code signing requirements are stable but notarization service may have updates)

**Notes:**
- Hardened runtime and notarytool are current state of the art and unlikely to change soon
- Apple's transition away from altool is complete (Nov 2023), so these patterns are stable
- Main unknowns are Quick Look extension-specific entitlements and optimal distribution format for GitHub
- Recommend testing signing workflow early in phase to identify issues before packaging
