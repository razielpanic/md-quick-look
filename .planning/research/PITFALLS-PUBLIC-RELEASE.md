# Pitfalls Research: First-Time Public Release

**Domain:** First-time macOS app public release (GitHub distribution)
**Researched:** 2026-02-02
**Confidence:** MEDIUM to HIGH
**Context:** MD Quick Look extension - developer has never released software publicly before

## Critical Pitfalls

### Pitfall 1: Unsigned/Unnotarized App Creates Scary User Experience

**What goes wrong:**
Without code signing and notarization, users see "a giant scary pop-up that warns them that macOS can't verify your app." In macOS Sequoia and later, even the traditional right-click workaround to force-open unsigned apps has been removed or restricted. Users may give up before ever launching your app.

**Why it happens:**
First-time developers don't realize that macOS requires notarization for all apps distributed outside the App Store. The notarization process seems complex (certificates, hardened runtime, stapling) and easy to skip during initial development.

**How to avoid:**
1. Obtain a Developer ID Application certificate from Apple Developer account
2. Sign with hardened runtime enabled: `codesign --options=runtime`
3. Submit to Apple's notarization service using `notarytool`
4. **Staple** the notarization result to your app: this attaches notarization to the software so users don't need to be online for verification
5. Test on a clean Mac to verify the signature works

**Warning signs:**
- You haven't run `codesign` or `notarytool` commands before creating your release
- Testing only on your development Mac (where you have developer tools installed)
- Getting "damaged and can't be opened" messages when downloading your own release
- Seeing quarantine attributes on your distributed app

**Phase to address:**
Phase addressing code signing and distribution preparation (before first GitHub release)

---

### Pitfall 2: Wrong Release Asset Format (ZIP vs DMG Choice)

**What goes wrong:**
Distributing only source code instead of compiled binaries, or choosing the wrong archive format. ZIP files work but may silently fail to grant necessary permissions. DMG files provide better UX but require more setup. Using both without explaining which users should download creates confusion.

**Why it happens:**
GitHub makes it easy to release source code, so first-timers often forget to attach compiled binaries. The ZIP vs DMG decision isn't obvious - ZIP is simpler to create, DMG provides better installer UX and permission handling.

**How to avoid:**
For Quick Look extensions specifically:
- **Use DMG for primary distribution** - macOS is more willing to grant file access permissions to apps from DMG vs ZIP
- Include the complete `.app` bundle (not just the extension)
- Name following semantic versioning: `AppName-1.0.0.dmg`
- Optionally provide ZIP for auto-updaters (Sparkle framework)
- Sign and notarize the DMG itself, not just the app inside

**Warning signs:**
- GitHub release only shows "Source code (zip)" and "Source code (tar.gz)" assets
- Release notes say "download and build from source" with no binary option
- Users report permission dialogs appearing but not working
- Bug reports about "app won't install" from non-technical users

**Phase to address:**
Phase addressing distribution packaging and release preparation

---

### Pitfall 3: App Icon Missing or Wrong Format

**What goes wrong:**
App displays with generic blank document icon. Or icon appears in Finder but not in About window. Or icon looks wrong on Retina displays. Or Xcode rejects the icon during archive/notarization with cryptic errors about missing sizes.

**Why it happens:**
macOS requires icons in multiple sizes, and as of macOS 26, Apple introduced a new layered icon approach with the Icon Composer tool. First-timers often:
- Add only a 1024x1024 PNG without using Xcode's asset catalog
- Add effects like drop shadows or rounded corners (Apple applies these automatically)
- Use wrong transparent areas or cutouts
- For macOS, don't provide all required sizes (macOS doesn't auto-generate from 1024x1024 like iOS does)

**How to avoid:**
1. Use Xcode's asset catalog (Assets.xcassets) with AppIcon entry
2. For macOS 26+, use Icon Composer app (included with Xcode 26) for layered icons
3. Provide all required sizes manually for macOS (512x512, 256x256, 128x128, 64x64, 32x32, 16x16 at 1x and 2x)
4. Don't add drop shadows, rounded corners, or gloss - Apple adds these automatically
5. Fill the entire square with no transparent borders or cutouts
6. Test icon at all sizes, especially 16x16 (menu bar size)

**Warning signs:**
- Icon looks good in Finder but generic elsewhere
- Icon appears jagged or blurry at small sizes
- Xcode shows warnings about missing icon sizes during build
- App Store Connect rejects icon during submission

**Phase to address:**
Phase addressing app polish and branding (icon creation phase)

---

### Pitfall 4: Bundle Identifier Mistakes

**What goes wrong:**
Using placeholder identifiers like `com.yourcompany.app`, forgetting to update from "spotlighter" to actual app name, or incorrectly naming extension bundle IDs. Xcode may reject builds or notarization may fail with cryptic errors. Worse, you can't change bundle ID after App Store submission without creating a new app listing.

**Why it happens:**
Bundle IDs are set early in development using Xcode templates and easy to forget. The reverse-DNS format (`com.company.app`) feels arbitrary. Extension bundle IDs must be prefixed with parent app bundle ID, which isn't obvious.

**How to avoid:**
1. Choose your bundle ID carefully before first release: `com.yourdomain.MDQuickLook` (use actual domain or reverse email)
2. For extensions, prefix with parent app: if app is `com.example.MyApp`, extension should be `com.example.MyApp.QuickLookExtension`
3. Avoid uppercase letters (use all lowercase)
4. Search and replace all references to old name ("spotlighter") across project
5. Don't use `com.apple.*` or `com.example.*` in production (example IDs are fine for local testing only)

**Warning signs:**
- Bundle ID still contains "spotlighter" or placeholder text
- Extension doesn't appear in System Settings > Extensions
- Notarization succeeds but extension doesn't load
- Multiple bundle ID variants across Info.plist files

**Phase to address:**
Phase addressing naming consistency and cleanup (before public release)

---

### Pitfall 5: Installation Instructions Assume Technical Knowledge

**What goes wrong:**
README says "build from source" or "install the Quick Look generator" without explaining what that means. Non-developer users don't know:
- What Quick Look is or how to verify it's working
- Where to find System Settings > Extensions
- What "quarantine attribute" means
- Why they need to "launch the app once" before the extension works
- How to troubleshoot when spacebar preview doesn't show formatted markdown

**Why it happens:**
Developer creates instructions they understand, forgetting that end users (the target for GitHub release) may not be technical. Quick Look extensions have a particularly confusing installation flow: download app → launch app once → enable in System Settings → test with spacebar in Finder.

**How to avoid:**
For Quick Look extension specifically:
1. **Installation section with screenshots**: show System Settings > Extensions > Quick Look
2. **Step-by-step numbered list**:
   - Download MDQuickLook-1.0.0.dmg
   - Open DMG and drag app to Applications
   - Launch the app once (important: system won't discover extension until app launches)
   - Open System Settings > Extensions > Quick Look
   - Enable "MD Quick Look"
   - Test: Select a .md file in Finder and press spacebar
3. **Troubleshooting section**: Common issues like extension not appearing, permission dialogs, quarantine warnings
4. **Video or GIF**: 30-second screen recording showing installation and first use
5. **What Quick Look is**: One sentence explaining "Quick Look is the spacebar preview feature in Finder"

**Warning signs:**
- README jumps straight to features without installation steps
- Installation instructions are one sentence: "Install the extension"
- No troubleshooting section
- No screenshots or visual aids
- Using technical terms without definitions (daemon, notarization, entitlements, sandboxing)

**Phase to address:**
Phase addressing documentation and README creation (before GitHub release)

---

### Pitfall 6: Screenshot Mistakes in README and GitHub Release

**What goes wrong:**
No screenshots at all (users can't tell what the app does). Or screenshots show developer tools/Xcode instead of user-facing UI. Or images are too large (slow to load) or too small (can't see details). Or first screenshot shows login screen instead of main value proposition.

**Why it happens:**
Developers focus on code and forget that GitHub README is marketing. First-timers don't realize the first screenshot is critical - it's what shows in search results and social media previews. Screenshots often show the developer's workflow (terminal, Xcode) instead of end-user experience.

**How to avoid:**
1. **First screenshot = hero shot**: Show the main value - formatted markdown preview in Finder Quick Look, not the app icon or About window
2. **Show before/after**: Raw markdown (before) vs. formatted preview (after) to demonstrate value instantly
3. **Highlight key features**: Use callouts or annotations to point out formatting, dark mode, tables
4. **Optimize images**:
   - Use PNG for screenshots (not JPEG which has artifacts)
   - Retina quality but compress for web (use ImageOptim or similar)
   - Max width ~1200px for README images
5. **Order by importance**: Lead with Quick Look preview, not app icon or preferences
6. **Include UI screenshots**: Show About window and Preferences if they're polished, but after the main value screenshot

**Warning signs:**
- No screenshots in README
- First image is app icon or About window instead of main functionality
- Screenshots show terminal commands or Xcode project
- Images take 5+ seconds to load
- Can't read text in screenshots (too small or blurry)

**Phase to address:**
Phase addressing documentation and marketing materials (before GitHub release)

---

### Pitfall 7: Version Numbering Confusion (CFBundleVersion vs CFBundleShortVersionString)

**What goes wrong:**
Setting CFBundleVersion to "1.0.0-latest.20210705" instead of an integer. Or reusing build numbers across versions. Or GitHub release tag doesn't match app version. Updates and auto-updaters break because version comparison fails.

**Why it happens:**
macOS has two version fields that serve different purposes:
- **CFBundleShortVersionString**: User-facing semantic version (1.0.0, 1.1.0) - can be string
- **CFBundleVersion**: Build number that must be monotonically increasing integer - many first-timers don't know this

**How to avoid:**
1. **CFBundleShortVersionString**: Use semantic versioning (1.0.0) for user-facing version
2. **CFBundleVersion**: Use incremental integers (1, 2, 3, 4...) that always increase, even across major versions
3. **Build numbers never decrease**: Version 2.0.0 might have build 15, version 1.9.0 had build 14
4. **Git tags match semantic version**: Tag release as `v1.0.0` matching CFBundleShortVersionString
5. **Release asset naming**: Use semantic version in filename: `MDQuickLook-1.0.0.dmg`

**Warning signs:**
- CFBundleVersion contains semantic version string instead of integer
- Build numbers decrease between versions
- GitHub release tag is `v1.0` but app shows `1.0.0`
- Xcode warnings about build number format

**Phase to address:**
Phase addressing release preparation and version management

---

### Pitfall 8: Forgetting to Launch App Once (Quick Look Extension Specific)

**What goes wrong:**
User downloads app, tries to preview .md file with spacebar, nothing happens. Extension doesn't appear in System Settings > Extensions > Quick Look. User concludes app is broken and leaves bad review or GitHub issue.

**Why it happens:**
macOS Quick Look extensions are bundled inside a parent app. The system only discovers the extension **after the parent app launches for the first time**. This is not documented clearly by Apple and completely non-obvious to users.

**How to avoid:**
1. **Make this step #1 in installation instructions**: "Launch the MD Quick Look app once (the app doesn't need to stay open)"
2. **App first-launch UI explains this**: On first launch, show alert or window explaining "The Quick Look extension is now installed. You can close this app and use spacebar in Finder to preview .md files."
3. **Include in troubleshooting**: "Extension not appearing? Make sure you've launched the app at least once."
4. **Consider automated solution**: App could detect first launch and show helpful UI automatically
5. **README includes video/GIF**: Visual demonstration showing app launch → enable in settings → test in Finder

**Warning signs:**
- Installation instructions skip the "launch app once" step
- No first-launch explanation in app UI
- Troubleshooting section doesn't mention this requirement
- GitHub issues from users saying "extension doesn't work" or "not appearing in settings"

**Phase to address:**
Phase addressing first-launch experience and documentation

---

### Pitfall 9: .qlgenerator Plugin Format (Deprecated Technology)

**What goes wrong:**
Building a `.qlgenerator` plugin instead of a Quick Look App Extension. Works on developer's Mac (macOS 14 or earlier) but completely non-functional for users on macOS 15 Sequoia and later. Extension never appears in System Settings.

**Why it happens:**
Many Quick Look tutorials and Stack Overflow answers reference the old `.qlgenerator` format. This worked fine until macOS 15 Sequoia removed support entirely. The old API was deprecated in macOS 10.15 Catalina (2019) but continued working until 2024.

**How to avoid:**
1. **Verify you're building Quick Look App Extension**: Project should have a target type "Quick Look Extension" in Xcode
2. **Not** using legacy `.qlgenerator` bundle
3. **Extension lives inside parent .app bundle**: `MDQuickLook.app/Contents/PlugIns/MDQuickLookExtension.appex`
4. **Test on macOS 15+**: If targeting public release in 2026, test on Sequoia (15.0) or later
5. **Check bundle extension**: Should be `.appex` not `.qlgenerator`

**Warning signs:**
- Following tutorials from 2018 or earlier
- Project creates `.qlgenerator` bundle
- Extension works on macOS 14 but not 15
- System Settings > Extensions > Quick Look shows no entry for your extension
- Console logs show "qlgenerator no longer supported"

**Phase to address:**
Early architecture phase (before building extension) - this is a foundational technology choice

---

### Pitfall 10: No Hardened Runtime = Notarization Fails

**What goes wrong:**
Notarization submission fails with cryptic error: "The binary is not signed with a hardened runtime." Or notarization succeeds but users get security warnings on launch. App can't access certain system resources.

**Why it happens:**
Hardened Runtime is a security feature required for notarization. It restricts what the app can do (no JIT compilation, no debugger attachment, etc.). First-timers often:
- Sign the app without `--options=runtime` flag
- Enable Hardened Runtime but need entitlements for certain features (file access, network)
- Sign in wrong order (must sign "bottom up": frameworks first, then app bundle)

**How to avoid:**
1. **Enable in Xcode**: Build Settings > Signing > Enable Hardened Runtime = YES
2. **Command-line signing**: Use `--options=runtime` flag: `codesign --sign "Developer ID" --options=runtime MyApp.app`
3. **Sign bottom-up in hierarchy**:
   - Sign embedded frameworks first
   - Sign executables
   - Sign app bundle last
4. **Don't use `--deep` flag**: Doesn't work reliably, sign each component separately
5. **Add required entitlements**: If app needs network/file access, add entitlements file with specific permissions

**Warning signs:**
- Notarization fails with "not signed with hardened runtime" error
- Signing works but notarization rejects
- App launches but can't access files or network despite having code to do so
- Using `codesign --deep` (this often causes subtle issues)

**Phase to address:**
Phase addressing code signing and notarization setup

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip notarization "for now" | Faster to release, no Apple account needed | Every user sees scary security warning, can't distribute widely | Never - notarization is required for credible macOS distribution |
| ZIP instead of DMG | Easier to create, smaller download | Permission issues, no visual installer, unprofessional feel | Okay for developer-focused tools, not end-user apps |
| No screenshots in README | Faster to write docs | Low GitHub engagement, users can't tell what app does | Never - screenshots are essential for GitHub releases |
| Generic app icon | No design work needed | Unprofessional appearance, hard to find in Applications folder | Only for internal/prototype releases |
| Manual installation steps | No installer code needed | Users mess up installation, support burden increases | Never for Quick Look extensions - require clear steps |
| Skip "About" window | Less UI code to write | Can't verify version, no support contact, feels incomplete | Never - About window is table stakes for macOS apps |

## Integration Gotchas

Common mistakes when connecting to external services or frameworks.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| GitHub Releases | Only upload source code, no binary | Attach compiled .dmg/.zip as release asset |
| Sparkle auto-updater | Point to GitHub release ZIP without notarization | Sign and notarize both app and release assets |
| Homebrew Cask | Create PR without testing formula | Test locally with `brew install --cask ./local-formula.rb` first |
| macOS Quarantine | Assume signed app skips quarantine | Sign, notarize, AND staple to avoid quarantine issues |
| System Extensions | Extension loads during development but not on user systems | Must launch parent app once for system to discover extension |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Large markdown files freeze Quick Look | Preview never appears, system beach ball | Implement size limit (500KB) and show truncation message | Files >1MB without truncation |
| Loading all images from disk | Preview slow to render, file access errors | Defer image loading or show placeholders only | >10 images in document |
| No rendering timeout | Quick Look preview hangs indefinitely on complex documents | Set max render time (2 seconds), show error if exceeded | Complex tables, deeply nested lists |
| Unbounded memory for markdown parsing | Memory spikes, preview process crashes | Stream parsing or chunk-based processing | Files >5MB |

## Security Mistakes

Domain-specific security issues beyond general web security.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Not sandboxing Quick Look extension | Fails App Store review, security risk if markdown has exploits | Enable App Sandbox entitlement for extension target |
| Rendering arbitrary HTML/JavaScript from markdown | XSS attacks, code execution | Use safe markdown renderer (AttributedString, not WebView) |
| Loading remote images in markdown | Privacy leak (IP tracking), network delays | Disable remote image loading, show placeholders only |
| File access without entitlements | Silently fails to preview files, no error shown | Request proper entitlements for file access in sandbox |
| Hardcoded signing identity in build scripts | Breaks on CI/CD, can't build on other machines | Use environment variables or Xcode's automatic signing |

## UX Pitfalls

Common user experience mistakes in this domain.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No visual feedback that extension is installed | User thinks installation failed | App first-launch UI confirms extension is installed + how to use |
| Extension name doesn't match app name | Can't find extension in System Settings | Extension display name = app name (MD Quick Look) |
| No explanation of what Quick Look is | Non-technical users don't know to press spacebar | README explains "Quick Look = spacebar preview in Finder" |
| About window shows build numbers/technical info | User confusion, looks unpolished | Show semantic version (1.0.0) and simple description |
| Preferences window empty on first release | Feels half-finished | Either don't ship Preferences or include 1-2 actual settings |
| No dark mode support | Preview looks broken in dark mode | Use system semantic colors for automatic dark mode |
| Error messages show code/stack traces | User panic, no actionable info | Show friendly message: "This markdown file is too large to preview" |
| Permission dialog fatigue | Users blindly click through warnings, or give up entirely | Minimize permission requests, explain each one clearly in context |
| Technical jargon in dialogs | Users don't understand "daemon" or "notarization" | Use plain language: "MD Quick Look needs to install a preview extension" |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Code Signing:** App launches on dev Mac ≠ signed correctly — verify with `codesign --verify --verbose=4 MyApp.app`
- [ ] **Notarization:** Signed ≠ notarized — verify with `spctl --assess --verbose MyApp.app`
- [ ] **Stapling:** Notarized ≠ stapled — verify with `stapler validate MyApp.app`
- [ ] **Extension Discovery:** Extension works in Xcode ≠ works after installation — test by: delete app, reinstall from release .dmg, launch once, check System Settings
- [ ] **Bundle Identifier:** Changed in Xcode ≠ changed everywhere — search entire project for old name ("spotlighter")
- [ ] **App Icon:** Icon in asset catalog ≠ appears everywhere — verify in Finder, About window, Dock, System Settings
- [ ] **Version Numbers:** Git tag matches ≠ app Info.plist matches — verify CFBundleShortVersionString equals release tag
- [ ] **DMG Contents:** DMG opens ≠ contents signed — verify every .app, .framework, .dylib inside DMG is signed
- [ ] **README Screenshots:** Have screenshots ≠ screenshots show value — first image should show main functionality, not icon
- [ ] **Installation Instructions:** Have steps ≠ steps tested by non-developer — ask someone non-technical to follow them
- [ ] **About Window:** Window opens ≠ shows correct version — verify version number matches release
- [ ] **Preferences Window:** Window opens ≠ has useful content — either remove or add real settings
- [ ] **First Launch:** App opens ≠ explains extension installed — show helpful message on first run
- [ ] **Quarantine Removal:** Notarized ≠ no quarantine warning — test on clean Mac by downloading from GitHub
- [ ] **Documentation Complete:** README exists ≠ covers installation, troubleshooting, usage — have non-dev read it

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Unsigned release already public | MEDIUM | 1. Sign and notarize app 2. Create new GitHub release (1.0.1) 3. Post update notice in original release 4. Add "Download 1.0.1 instead" to README |
| Wrong bundle identifier in v1.0 | HIGH | Can't change without new app - if pre-App-Store, acceptable to push v1.1 with new bundle ID + migration notice. If App Store submitted, must create entirely new app listing. |
| .qlgenerator format used | HIGH | Complete rewrite using Quick Look App Extension API - different architecture, ~3-5 days work |
| No screenshots in README | LOW | Take screenshots, update README, no new release needed (GitHub shows latest README always) |
| ZIP instead of DMG | LOW | Create DMG, add to existing release as additional asset, update README to recommend DMG |
| Forgot to notarize | MEDIUM | Notarize existing build, re-upload to same release, update download links (can use same version number) |
| Missing icon sizes | LOW | Generate missing sizes in asset catalog, rebuild, bump build number to 1.0.1 |
| Version numbering wrong | LOW | Fix in next release, document version scheme in CONTRIBUTING.md to prevent repeat |
| Installation instructions unclear | LOW | Update README with clearer steps + screenshots, no code changes needed |
| Preferences window empty | LOW | Either remove menu item or add placeholder text "Settings coming in v1.1" |
| No About window | LOW | Add About window, release as 1.0.1 patch - small feature addition |
| Outdated documentation | LOW | Update README, add to release notes "Documentation updated for clarity" |
| Poor screenshot ordering | LOW | Reorder images in README, update immediately (no version bump needed) |
| Technical jargon in instructions | LOW | Simplify language, add glossary section, update README |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Unsigned/unnotarized app | Code signing & notarization setup | Test download on clean Mac, verify no security warnings |
| Wrong asset format (ZIP/DMG) | Distribution packaging | Test DMG installation flow on clean Mac |
| Missing/wrong app icon | App polish & branding | Verify icon appears in Finder, About window, Dock, System Settings at all sizes |
| Bundle identifier mistakes | Naming consistency & cleanup | Search entire project for old name, verify extension bundle ID prefixed correctly |
| Poor installation instructions | Documentation & README creation | Have non-developer follow steps, collect feedback |
| Screenshot mistakes | Marketing materials creation | Review first screenshot - does it show main value instantly? |
| Version numbering confusion | Release preparation | Verify CFBundleVersion is integer, CFBundleShortVersionString matches git tag |
| Forgot to launch app once | First-launch experience | App shows helpful UI on first launch explaining extension is installed |
| .qlgenerator deprecated format | Architecture & technology choices | Verify extension is .appex inside .app bundle, not standalone .qlgenerator |
| No hardened runtime | Code signing setup | Verify `codesign -d --entitlements :- MyApp.app` shows hardened runtime |

## Documentation-Specific Pitfalls

Additional pitfalls discovered through research on first-time releases:

### Pitfall 11: Outdated Documentation After Release

**What goes wrong:**
README describes features that don't exist yet, or references old app names, or shows screenshots from development builds with different UI.

**Why it happens:**
Documentation is written during development and not updated before release. Features change, UI evolves, but docs stay static.

**How to avoid:**
- Review README immediately before creating GitHub release
- Verify all screenshots match current build
- Check all feature claims against actual app capabilities
- Search for old app name references ("spotlighter")
- Have someone else read docs and verify accuracy

**Warning signs:**
- Screenshots show different UI than shipped app
- Features mentioned that don't exist
- Installation steps reference wrong paths or names
- GitHub issues asking "where is feature X mentioned in README?"

**Phase to address:**
Final documentation review before public release

---

### Pitfall 12: No Troubleshooting Section

**What goes wrong:**
Users encounter common issues (extension not appearing, quarantine warnings, permission dialogs) and have no guidance. They file duplicate GitHub issues or give up.

**Why it happens:**
Developer knows how to solve issues and forgets users don't. Troubleshooting seems obvious until you're not the developer.

**How to avoid:**
Create troubleshooting section covering:
- Extension not appearing in System Settings
- "App is damaged and can't be opened" warning
- Spacebar preview shows nothing
- Dark mode looks wrong
- Files too large to preview
- How to uninstall completely

**Warning signs:**
- No troubleshooting section in README
- GitHub issues all ask same questions
- Users report "doesn't work" without details

**Phase to address:**
Documentation phase before public release

---

### Pitfall 13: No Clear Uninstall Instructions

**What goes wrong:**
Users want to uninstall but don't know how to remove Quick Look extension. Simply deleting app from Applications leaves extension registered. System Settings still shows disabled extension.

**Why it happens:**
macOS extensions persist even after app deletion. First-timers don't know to document uninstall process.

**How to avoid:**
Add uninstall section to README:
1. Open System Settings > Extensions > Quick Look
2. Disable "MD Quick Look"
3. Drag MD Quick Look.app to Trash
4. Empty Trash
5. Run `qlmanage -r` to reset Quick Look cache

**Warning signs:**
- No uninstall section in documentation
- Users report "can't remove extension"
- Extension persists after app deletion

**Phase to address:**
Documentation completeness review

---

## First-Timer Specific Mistakes

Mistakes that experienced developers know to avoid but first-timers commonly make:

### Pitfall 14: No Release Notes

**What goes wrong:**
GitHub release created with title "v1.0.0" and empty description. Users don't know what changed or what the release includes.

**Why it happens:**
First release seems self-explanatory ("it's v1.0, everything is new") but users still need context.

**How to avoid:**
For v1.0.0, include:
- One-sentence description of what the app does
- Key features list (bullet points)
- Installation instructions or link to README
- Known limitations
- System requirements (macOS 26+)
- How to report issues (GitHub Issues link)

**Warning signs:**
- Empty release description
- Just says "First release" with no details
- No link to installation instructions

**Phase to address:**
Release preparation and documentation

---

### Pitfall 15: Testing Only on Development Mac

**What goes wrong:**
App works perfectly on developer's Mac but fails on clean user system. Extension doesn't load, permissions fail, quarantine warnings appear.

**Why it happens:**
Development Mac has Xcode, certificates, entitlements, and other tools that mask issues. Clean user Mac is different environment.

**How to avoid:**
- Test on clean Mac (virtual machine or friend's computer)
- Download release DMG and install as user would
- Don't launch Xcode or enter admin password
- Verify installation steps in README work exactly as written
- Test with non-technical user

**Warning signs:**
- Never tested outside development environment
- No VM or clean Mac available for testing
- Installation instructions say "if this doesn't work, try..."
- Assumption that users have developer tools

**Phase to address:**
Release validation and QA testing

---

## Sources

**Code Signing & Notarization:**
- [Resolving common notarization issues - Apple Developer Documentation](https://developer.apple.com/documentation/security/resolving-common-notarization-issues)
- [The Gates to Hell: Apple's Notarizing - CDFinder](https://www.cdfinder.de/guide/blog/apple_hell.html)
- [macOS Notarization, Code Signing, and Sparkle - Duo Security](https://duo.com/labs/tech-notes/macos-notarization-hardware-backed-code-signing-keys-and-sparkle-code-signing-issues)
- [Distributing Mac Apps With GitHub Actions - defn.io](https://defn.io/2023/09/22/distributing-mac-apps-with-github-actions/)
- [Code Signing and Notarization on macOS - msweet.org](https://www.msweet.org/blog/2020-12-10-macos-notarization.html)

**App Icons:**
- [Apple App Icon Guidelines - Asolytics](https://asolytics.pro/blog/post/apple-app-icon-guidelines-dimensions-requirements-design-rules-and-mistakes-to-avoid/)
- [Updating App Icons for iOS and macOS 26 - praeclarum.org](https://praeclarum.org/2025/09/12/app-icons.html)
- [Apple App Icon Guidelines - Twinr](https://twinr.dev/blogs/apple-app-icon-design-guidelines/)

**Quick Look Extensions:**
- [Sequoia No Longer Supports QuickLook Generator Plug-ins - Michael Tsai](https://mjtsai.com/blog/2024/11/05/sequoia-no-longer-supports-quicklook-generator-plug-ins/)
- [How Sequoia has changed QuickLook - Eclectic Light Company](https://eclecticlight.co/2024/10/31/how-sequoia-has-changed-quicklook-and-its-thumbnails/)
- [QLMarkdown - macOS Quick Look extension for Markdown](https://github.com/sbarex/QLMarkdown)
- [Quick Look Plugins List - sindresorhus](https://github.com/sindresorhus/quick-look-plugins)

**Bundle Identifiers:**
- [CFBundleIdentifier - Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleidentifier)
- [What Are App IDs and Bundle Identifiers - Cocoacasts](https://cocoacasts.com/what-are-app-ids-and-bundle-identifiers)

**Version Numbering:**
- [Semantic Versioning macOS Build Issue - Lens App](https://github.com/lensapp/lens/issues/3288)
- [App Version Best Practice - Eon's Swift Blog](https://eon.codes/blog/2023/03/25/app-version-best-practice/)
- [App Version Numbering - Egeniq](https://egeniq.com/blog/app-version-numbering/)

**Distribution Formats:**
- [Use .zip and .dmg for packaging on macOS - PrismLauncher](https://github.com/PrismLauncher/PrismLauncher/issues/221)
- [create-dmg - Create good-looking DMG - sindresorhus](https://github.com/sindresorhus/create-dmg)

**Documentation & Screenshots:**
- [5 App Store Screenshot Mistakes Killing Conversions (2026) - DEV Community](https://dev.to/appscreenshotstudio/5-app-store-screenshot-mistakes-killing-conversions-2026-5adp)
- [5 Common Documentation Mistakes - Medium](https://medium.com/@AnweshaB/5-common-documentation-mistakes-and-how-to-fix-them-9d095572947c)
- [Software Documentation Best Practices - Helpjuice](https://helpjuice.com/blog/software-documentation)
- [10 Common Developer Documentation Mistakes - Document360](https://document360.com/blog/developer-documentation-mistakes/)

**User Experience & Permissions:**
- [The MacOS System Permission Dialog - MacMAD](https://macmad.org/blog/2023/12/the-macos-system-permission-dialog/)
- [macOS 15 Sequoia's Excessive Permissions Prompts - TidBITS](https://tidbits.com/2024/08/12/macos-15-sequoias-excessive-permissions-prompts-will-hurt-security/)
- [App Permissions on macOS Sequoia - TrozWare](https://troz.net/post/2024/sequoia_app_permissions/)

**Privacy Manifests:**
- [Privacy manifest files - Apple Developer Documentation](https://developer.apple.com/documentation/bundleresources/privacy-manifest-files)
- [Apple's New Privacy Manifest Requirements - Xojo Blog](https://blog.xojo.com/2024/03/20/apples-new-privacy-manifest-requirements/)

---
*Pitfalls research for: MD Quick Look - First public release (GitHub)*
*Researched: 2026-02-02*
*Confidence: MEDIUM to HIGH - based on official Apple documentation, real-world GitHub issues, developer community discussions, and successful Quick Look extension examples*
