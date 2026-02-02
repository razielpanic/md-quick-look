# GitHub Public Release Features

**Domain:** macOS app GitHub public release (end-user focused)
**Researched:** 2026-02-02
**Confidence:** HIGH

## Executive Summary

A successful first GitHub release for a macOS app targeting end users requires balancing technical polish (code signing, notarization) with clear communication (README, visuals, installation instructions). Research across successful macOS apps, Quick Look plugins, and open source release best practices reveals three critical success factors:

1. **Remove friction**: Code signing + notarization eliminates security warnings (the #1 barrier to adoption)
2. **Visual proof first**: Screenshots/GIFs engage users before text; demo the "magic moment"
3. **Multiple installation paths**: Homebrew + manual download accommodates different user preferences

The "Very Mac-assed" positioning requires extra attention to polish: icon quality, clean README, native feel messaging. First-time releasers often over-document or under-sign; the sweet spot is comprehensive-but-scannable README with properly notarized binaries.

## Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or unprofessional.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| **Clear README with app description** | First impression - users judge projects by README quality in 2026 | LOW | One-line "what it does" at top, followed by 2-3 sentence explanation |
| **Installation instructions** | Users need to know how to get it running | LOW | Both manual DMG download path + troubleshooting steps |
| **Screenshots or demo GIF** | Visual proof the app works as described; text-only READMEs underperform | LOW | 2-8 MB GIF showing Quick Look in action, or 100-400 KB screenshots |
| **LICENSE file** | Without license, code isn't truly open source; users and contributors avoid legally ambiguous projects | LOW | MIT or similar permissive license expected for utilities |
| **GitHub Releases page with DMG** | Standard distribution method for macOS apps; users expect to find releases | MEDIUM | Requires notarization for macOS 10.15+ |
| **App icon** | Polished apps have recognizable, professional icons | MEDIUM | 1024x1024 master image, system generates runtime sizes |
| **Basic release notes** | Users want to know what's in each version | LOW | "What's new" summary for v1.0; can use GitHub auto-generated format |
| **macOS version compatibility** | Users need to know if it works on their system before downloading | LOW | "macOS 10.15+" or similar in README header |
| **Installation troubleshooting** | Quick Look plugins require specific setup; users will have issues | LOW | De-quarantine instructions, `qlmanage -r` command, common errors |
| **Code signing + notarization** | macOS 10.15+ shows security warnings for unsigned apps; users abandon | MEDIUM | Requires Apple Developer account ($99/year); non-negotiable for end users |

## Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable for "Very Mac-assed" positioning.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **Animated demo GIF in README** | Shows the "magic moment" of using Quick Look; much more engaging than screenshots | LOW | Screen recording of pressing spacebar → rendered markdown appears in 5-10 seconds |
| **Multiple installation methods** | Reduces friction - users choose their preferred method | LOW-MEDIUM | Manual download for v1.0; Homebrew cask for v1.x when adoption proven |
| **"Very Mac-assed" positioning** | Appeals to users who value native Mac experience over cross-platform apps | LOW | Emphasize polish, native feel, "fits right in" messaging in README |
| **Before/after comparison** | Shows problem → solution visually; helps users understand value instantly | LOW | Plain text markdown view vs. beautiful rendered preview side-by-side |
| **One-line value prop at top** | Instantly communicates benefit without scrolling | LOW | "Beautiful markdown previews in Finder" type messaging in README header |
| **First-run simplicity messaging** | No configuration needed - just works; highlight as differentiator | N/A | Already built - emphasize this in README and release notes |
| **Performance messaging** | "Fast, polished rendering" as selling point vs. slow competitors | LOW | Mention in README, possibly with informal performance comparison |
| **Clean, scannable README** | Comprehensive but not overwhelming; users can find what they need quickly | LOW | Keep under 10-12 screens; use clear headings, bullet points, visual hierarchy |

## Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for first releases.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Multi-page documentation site** | Seems "professional" for releases | Overkill for v1.0, creates maintenance burden, delays launch | Keep README comprehensive but scannable (<12 screens); use clear sections |
| **Extensive configuration options** | Developers think users want control | End users want "it just works", not settings; adds support burden | Opinionated defaults, defer customization to post-v1 based on demand |
| **App Store submission for v1.0** | Seems like the "proper" way to distribute Mac apps | Review time delays release, $99/year cost, Quick Look extensions have App Store complications | Start with GitHub + Homebrew, consider App Store after market validation |
| **Detailed CONTRIBUTING.md for v1.0** | Feels complete/welcoming to contributors | Premature for first release - no contributors yet, wastes time | Add CONTRIBUTING.md after first external interest or contribution attempt |
| **Complex build-from-source instructions in main README** | Developer mindset - want to be transparent | End users don't build from source; clutters README, confuses audience | Focus on download/install for end users; move build docs to DEVELOPMENT.md |
| **Feature roadmap in README** | Shows ambition and vision | Sets expectations that may not be met, clutters first impression, commits prematurely | Mention "future ideas" briefly in one sentence; use GitHub Issues for detailed roadmap |
| **Unsigned/unnotarized release** | Saves $99 Apple Developer account cost | Creates security warnings; end users abandon immediately; destroys professional impression | Code signing + notarization is non-negotiable for end-user macOS apps in 2026 |
| **Text-only README (no visuals)** | Seems sufficient - "code speaks for itself" | Users scan visuals first, read text second; no demo = low engagement | Prioritize demo GIF or screenshots above installation instructions |
| **20+ page README** | Want to be comprehensive and helpful | Overwhelming; users abandon; information buried; hard to maintain | Keep under 10-12 screens; link to separate docs for advanced topics |

## Feature Dependencies

```
README.md
    ├──requires──> Screenshots/Demo GIF (visual proof)
    ├──requires──> Installation instructions (how to use)
    ├──requires──> Value proposition (what it does)
    └──requires──> LICENSE file reference (legal clarity)

GitHub Release v1.0
    ├──requires──> DMG file (distribution package)
    ├──requires──> Code signing (macOS security)
    ├──requires──> Notarization (macOS 10.15+ requirement)
    ├──requires──> Release notes (what's included)
    └──requires──> Version tag (semantic versioning)

DMG file
    ├──requires──> .app bundle (compiled application)
    └──requires──> App icon (proper packaging, visual identity)

Code signing + Notarization
    ├──requires──> Apple Developer account ($99/year)
    └──requires──> Build infrastructure (certificates, provisioning)

Homebrew distribution (v1.x)
    ├──requires──> GitHub Release (cask references release asset)
    ├──requires──> DMG file (cask downloads this)
    └──enhances──> Installation experience (one-command install)

Screenshots/Demo GIF
    └──enhances──> README (visual engagement, proof of concept)

Before/after comparison
    └──enhances──> Value proposition (shows problem solved)
```

### Dependency Notes

- **README requires visuals BEFORE launch:** Text-only READMEs underperform in 2026. Screenshots/GIFs are table stakes, not nice-to-haves.
- **GitHub Release requires notarization for end users:** macOS 10.15+ enforces notarization for apps outside App Store. Users see "cannot verify developer" warnings without it; this kills adoption.
- **Code signing requires Apple Developer account:** $99/year investment needed for legitimate macOS distribution. Non-negotiable for "Very Mac-assed" positioning.
- **Homebrew enhances but isn't required for v1.0:** Nice to have, but manual download works fine. Can add Homebrew tap post-launch when adoption is proven (10+ stars).
- **Demo GIF is higher ROI than multiple screenshots:** One 5-10 second GIF showing the "magic moment" (spacebar → preview) is worth 5+ static screenshots.

## MVP Definition

### Launch With (v1.0)

Minimum viable **public release** — what's needed to make a strong first impression.

- [x] **Core app functionality** — Already built: markdown rendering in Quick Look with syntax highlighting
- [ ] **README with clear value prop** — "Beautiful markdown previews in Finder" + 2-3 sentence explanation at top
- [ ] **Demo GIF showing Quick Look in action** — 5-10 second screen recording: select .md file → press spacebar → rendered preview appears
- [ ] **2-3 screenshots** — Rendered markdown examples showing different features (headings, code blocks with highlighting, tables)
- [ ] **Installation instructions** — Manual download path + de-quarantine steps if needed + `qlmanage -r` command + troubleshooting section
- [ ] **LICENSE file** — MIT or Apache 2.0 (permissive, standard for utilities)
- [ ] **App icon** — Simple, recognizable icon representing markdown + Quick Look (1024x1024 master)
- [ ] **GitHub Release v1.0** — DMG file + release notes with "What's new" summary
- [ ] **Code signing + notarization** — So users don't get security warnings; uses Apple Developer account
- [ ] **macOS compatibility statement** — "macOS 10.15 or later" or "macOS 11+ recommended" in README header
- [ ] **One-line value prop** — Clear benefit statement in README first paragraph
- [ ] **Before/after comparison** — Optional but recommended: show plain Quick Look vs. rendered preview

**Why this set:**
- Removes all adoption friction (no security warnings, clear instructions)
- Visual proof before text (GIF + screenshots engage immediately)
- Professional polish ("Very Mac-assed" requires icon, notarization, clean presentation)
- Scannable README (users can evaluate in <1 minute)

**Total effort:** ~8-16 hours beyond app development (icon creation, README writing, GIF recording, release setup)

### Add After Validation (v1.x)

Features to add once core release is successful and adoption is proven.

- [ ] **Homebrew cask** — Trigger: 10+ GitHub stars OR 3+ user requests for easier installation
- [ ] **Video demo (if GIF insufficient)** — Trigger: Users ask for more detailed walkthrough or feature explanation
- [ ] **CONTRIBUTING.md** — Trigger: First external contributor OR first issue labeled "good first issue"
- [ ] **Comparison with built-in Quick Look** — Trigger: Users ask "why not use default Quick Look?" repeatedly
- [ ] **Performance benchmarks** — Trigger: Competing tools emerge OR users question speed claims
- [ ] **FAQ section in README** — Trigger: Same questions asked 3+ times in issues
- [ ] **Additional theme examples** — Trigger: Users request dark mode or alternative styling (if not in v1.0)

**Effort estimates:**
- Homebrew cask: 1-2 hours (create formula, submit PR to homebrew-cask)
- CONTRIBUTING.md: 1-2 hours (outline process, code standards, testing)
- FAQ section: 30 minutes per question (curate from issues)

### Future Consideration (v2+)

Features to defer until product-market fit is established and user base grows.

- [ ] **App Store distribution** — Why defer: $99/year + review delays + unclear if Quick Look extensions work well in App Store context; GitHub/Homebrew sufficient for validation
- [ ] **Customization settings (themes, fonts, etc.)** — Why defer: End users value simplicity over configurability; add only if heavily requested (10+ requests)
- [ ] **Auto-update mechanism (Sparkle, etc.)** — Why defer: Homebrew handles updates if adopted; premature complexity for v1; adds maintenance burden
- [ ] **Analytics/telemetry** — Why defer: Privacy-conscious Mac users resist tracking; no clear user benefit; wait for explicit need
- [ ] **Multi-language README support** — Why defer: English-first sufficient for technical tools; add translations if international adoption warrants (non-English issues)
- [ ] **Dedicated documentation site (GitHub Pages)** — Why defer: README sufficient for v1.0; create separate docs only if README exceeds 12 screens or complex use cases emerge

**Why defer:**
- v1.0 focus is validation and initial adoption, not feature completeness
- Adding features before validation wastes effort if direction changes
- Each feature adds maintenance burden; defer until ROI is proven

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| README with value prop | HIGH | LOW | P1 |
| Demo GIF | HIGH | LOW | P1 |
| Code signing + notarization | HIGH | MEDIUM | P1 |
| Installation instructions | HIGH | LOW | P1 |
| LICENSE file | HIGH | LOW | P1 |
| GitHub Release with DMG | HIGH | MEDIUM | P1 |
| App icon | HIGH | MEDIUM | P1 |
| macOS compatibility info | MEDIUM | LOW | P1 |
| Release notes | MEDIUM | LOW | P1 |
| Screenshots (2-3) | MEDIUM | LOW | P1 |
| Troubleshooting section | MEDIUM | LOW | P1 |
| Before/after comparison | MEDIUM | LOW | P2 |
| Homebrew cask | MEDIUM | MEDIUM | P2 |
| One-line value prop | HIGH | LOW | P1 |
| CONTRIBUTING.md | LOW | LOW | P2 |
| FAQ section | MEDIUM | LOW | P2 |
| Video demo | LOW | MEDIUM | P3 |
| App Store submission | LOW | HIGH | P3 |
| Auto-update mechanism | LOW | HIGH | P3 |
| Analytics/telemetry | LOW | MEDIUM | P3 |

**Priority key:**
- **P1: Must have for launch (v1.0)** — Non-negotiable for professional first impression
- **P2: Should have, add when possible (v1.x)** — Improves experience, add based on demand signals
- **P3: Nice to have, future consideration (v2+)** — Defer until product-market fit established

## Competitor Feature Analysis

| Feature | Other Quick Look Plugins | General macOS Apps | MD Quick Look Approach |
|---------|--------------------------|-------------------|------------------------|
| Installation | Manual download (often unsigned) OR Homebrew | App Store OR direct download (signed) | Manual download (signed + notarized) for v1.0; Homebrew for v1.x |
| Visual documentation | Screenshots vary; many have none or minimal | Polished marketing screenshots and videos | Prioritize demo GIF showing "spacebar magic moment"; 2-3 feature screenshots |
| Code signing | Many unsigned (users see security warnings) | Properly signed and notarized apps | MUST sign + notarize (table stakes for end-user release) |
| README length | Often brief (developer-focused) or overly technical | Marketing-heavy (App Store description) or sparse (GitHub) | Balanced: clear value prop + practical instructions; scannable (~8-10 screens) |
| Positioning | "Developer tool" or technical utility framing | "Productivity app" or feature-list framing | "Very Mac-assed" - native, polished, end-user friendly; emphasize simplicity |
| Release process | Informal (upload .qlgenerator) or GitHub Releases | Formal releases via App Store or website | GitHub Releases with proper semantic versioning and release notes |
| Icon quality | Often generic, placeholder, or missing | Polished, professionally designed icons | Custom icon emphasizing markdown + Quick Look; professional quality |
| Target audience | Developers (assume technical knowledge) | End users (clear instructions, no jargon) | End users who work with markdown (broader than just developers) |

## First-Timer Guidance

### What Makes a Successful First GitHub Release

Based on research into successful macOS app releases, open source best practices, and first-timer mistakes, prioritize:

**1. Visual proof before text**
- Users scan screenshots/GIFs first, then read README if interested
- Demo GIF showing the "magic moment" is highest ROI content
- Before/after comparison instantly communicates value

**2. Remove installation friction**
- Code signing + notarization eliminates the #1 barrier (macOS security warnings)
- Clear, tested installation instructions (not assumptions about user knowledge)
- Troubleshooting section for common issues (Quick Look plugins need `qlmanage -r`, de-quarantine)

**3. Clear value proposition**
- Answer "what does this do?" in one sentence at the README top
- Explain "why does this matter?" in 2-3 sentences after that
- Use benefit language ("Beautiful markdown previews") not feature language ("Renders markdown using cmark-gfm")

**4. Multiple installation paths (but not immediately)**
- v1.0: Manual download is sufficient (don't delay for Homebrew)
- v1.x: Add Homebrew cask once adoption is proven (10+ stars)
- Future: Consider App Store only if significant demand emerges

**5. Professional polish for "Very Mac-assed" positioning**
- App icon matters (users judge quality by icon + README)
- Notarization matters (security warnings destroy trust)
- README quality matters (professional, scannable, comprehensive)

### Common First-Release Mistakes to Avoid

**Mistake 1: No visuals (text-only README)**
- Why harmful: Users scan visually first; text-only READMEs fail to engage in 2026
- Fix: Prioritize demo GIF creation; record 5-10 second "magic moment" screen capture

**Mistake 2: Unsigned code (skipping notarization to save $99)**
- Why harmful: macOS shows security warnings; end users abandon immediately; destroys professional impression
- Fix: Invest in Apple Developer account ($99/year); code signing + notarization is non-negotiable for end-user apps

**Mistake 3: Unclear installation instructions (assume user knowledge)**
- Why harmful: Quick Look plugins require specific setup; users don't know about `~/Library/QuickLook`, `qlmanage -r`, quarantine attributes
- Fix: Write step-by-step instructions; test with non-technical user; add troubleshooting section

**Mistake 4: Feature creep (trying to be "complete" before launching)**
- Why harmful: Delays release, wastes effort on features users may not want, prevents validation
- Fix: Ship v1.0 with core value prop working; add features based on real user feedback

**Mistake 5: Over-documentation (20+ page README or separate docs site)**
- Why harmful: Overwhelming; users abandon; information buried; hard to maintain; wastes time
- Fix: Keep README under 10-12 screens; use clear sections, bullet points; link to separate docs only if truly needed

**Mistake 6: Missing LICENSE file**
- Why harmful: Legally ambiguous; users and potential contributors avoid unlicensed projects; not truly open source
- Fix: Add MIT or Apache 2.0 license in LICENSE file; reference in README

**Mistake 7: No release notes or vague notes ("Initial release")**
- Why harmful: Users want to know what's included; builds poor expectations for future releases
- Fix: Write "What's new in v1.0" with bullet points of features; can use GitHub auto-generated format

**Mistake 8: Premature roadmap or contributing guidelines**
- Why harmful: Sets expectations that may not be met; wastes time before validation; clutters README
- Fix: Mention "future ideas" in one sentence; add CONTRIBUTING.md after first external interest

### Success Metrics for v1.0

A successful first release achieves:

**Installation success:**
- Users can install without security warnings (code signing + notarization works)
- Users can get it running in <5 minutes (clear installation instructions)
- Users don't need to ask "how do I install this?" in issues

**Clarity success:**
- Users understand what it does in <10 seconds (demo GIF + value prop)
- Users can evaluate fit in <1 minute (scannable README)
- Users don't need to ask "what is this for?" in issues

**Polish success:**
- Users feel it's "native" and "Mac-assed" (icon + notarization + clean presentation)
- Users describe it as "polished" or "professional" in feedback
- Users trust the quality (no security warnings, clear documentation)

**Legal success:**
- Users can legally use and modify it (LICENSE present and clear)
- Potential contributors understand permissions (MIT or similar permissive license)

**Validation success:**
- 10+ stars within first week (indicates product-market fit)
- 1-3+ issues or discussions (indicates user engagement)
- 0 "how do I install?" or "what is this?" questions (indicates clarity success)

### Platform-Specific Considerations for macOS Quick Look

**Quick Look plugin installation is non-standard:**
- Not drag-to-Applications like normal Mac apps
- Requires placing in `~/Library/QuickLook` or `/Library/QuickLook`
- Requires `qlmanage -r` to refresh Quick Look framework
- May require de-quarantine (`xattr -d com.apple.quarantine`)

**User expectations for Quick Look plugins:**
- Should "just work" after installation (no configuration)
- Should be fast (Quick Look is for quick previews, not slow loading)
- Should respect system preferences (dark mode, font sizes)
- Should look native (not like a web page or custom UI)

**macOS security requirements:**
- Notarization required for macOS 10.15+ (Catalina and later)
- Users will see "cannot verify developer" warnings without notarization
- Code signing certificates require Apple Developer account ($99/year)
- Unsigned plugins are often blocked by Gatekeeper

**macOS version compatibility:**
- macOS 15 (Sequoia) deprecated `.qlgenerator` format
- Modern QuickLook App Extensions required for macOS 15+
- Specify minimum macOS version clearly in README (e.g., "macOS 10.15+")
- Test on multiple macOS versions before release (at least 2-3 recent versions)

### README Structure Recommendation

Based on research into successful macOS app READMEs:

```markdown
# [Project Name] — [One-line value prop]

[Demo GIF here — shows "magic moment" in 5-10 seconds]

[2-3 sentence explanation of what it does and why it matters]

## Features

- [Key feature 1]
- [Key feature 2]
- [Key feature 3]
- [Key feature 4 (max 5-6 features)]

## Installation

### Download

[Step-by-step instructions with actual terminal commands]

### Troubleshooting

[Common issues: security warnings, qlmanage -r, quarantine]

## Requirements

- macOS [version]+
- [Any other requirements]

## Screenshots

[2-3 screenshots showing different markdown features rendered]

## Why [Project Name]?

[Optional: before/after comparison or comparison with alternatives]

## License

[License type] - see LICENSE file for details

## Credits

[Optional: acknowledgments, related projects]
```

**Total README length:** 8-10 screens (scrollable on laptop); comprehensive but scannable

## Sources

### GitHub Release Best Practices
- [GitHub: proper-packaging-principles](https://github.com/n8felton/proper-packaging-principles) - macOS packaging guidance from MacAdmins community
- [GitHub: open-source-project-template](https://github.com/cfpb/open-source-project-template/blob/main/opensource-checklist.md) - CFPB open source pre-launch checklist
- [Medium: Open source GitHub repository pre-launch checklist](https://medium.com/binbash-inc/open-source-github-repository-pre-launch-checklist-4a52dbbe4af1)
- [GitHub: open-source-checklist](https://github.com/libresource/open-source-checklist) - Checklist to build successful open source projects

### README & Visual Documentation
- [GitHub: awesome-readme](https://github.com/matiassingers/awesome-readme) - Curated list of high-quality README examples
- [DEV: Demo your App with an Animated GIF](https://dev.to/kelli/demo-your-app-in-your-github-readme-with-an-animated-gif-2o3c) - Tutorial on creating engaging demo GIFs
- [Medium: Make Your Readme Better with Images and GIFs](https://medium.com/@alenanikulina0/make-your-readme-better-with-images-and-gifs-b141bd54bff3) - Best practices for visual content
- [Voxel51: Elevate Your GitHub README Game](https://voxel51.com/blog/computer-vision-elevate-your-github-readme-game) - Lessons from creating 25+ READMEs
- [GitHub: readme-checklist](https://github.com/ddbeck/readme-checklist/blob/main/checklist.md) - Comprehensive README quality checklist
- [Make a README](https://www.makeareadme.com/) - README writing guide and best practices
- [GitHub: Best-README-Template](https://github.com/othneildrew/Best-README-Template) - Popular README template

### macOS App Icons
- [GitHub: macOS-icon-generator](https://github.com/SAP/macOS-icon-generator) - SAP tool for creating macOS app icons
- [Gist: How to create an .icns macOS app icon](https://gist.github.com/jamieweavis/b4c394607641e1280d447deed5fc85fc) - Step-by-step icon creation process
- [Asolytics: Apple App Icon Guidelines](https://asolytics.pro/blog/post/apple-app-icon-guidelines-dimensions-requirements-design-rules-and-mistakes-to-avoid/) - Official Apple icon requirements

### Code Signing & Notarization
- [GitHub: electron/notarize](https://github.com/electron/notarize) - Notarization tooling and API documentation
- [Federico Terzi: Automatic Code-signing with GitHub Actions](https://federicoterzi.com/blog/automatic-code-signing-and-notarization-for-macos-apps-using-github-actions/) - CI/CD automation guide
- [Random Errata: Notarizing CLI apps for macOS](https://www.randomerrata.com/articles/2024/notarize/) - Practical notarization guide
- [Gist: macOS distribution guide](https://gist.github.com/rsms/929c9c2fec231f0cf843a1a746a416f5) - Comprehensive distribution reference

### DMG & Installation
- [GitHub: create-dmg](https://github.com/sindresorhus/create-dmg) - Popular DMG creation tool by Sindre Sorhus
- [Gist: Download and install a .dmg](https://gist.github.com/durkinza/ca7e1aa02bd4901c08c496d97d2e0daa) - User-facing installation instructions

### Release Notes & Changelog
- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) - Changelog format standard (semantic versioning)
- [GitHub Docs: Automatically generated release notes](https://docs.github.com/en/repositories/releasing-projects-on-github/automatically-generated-release-notes) - GitHub's built-in release notes feature
- [LaunchNotes: Release Notes vs Changelog](https://www.launchnotes.com/blog/release-notes-vs-changelog-understanding-the-key-differences-and-when-to-use-each) - When to use each format

### Quick Look Plugin Ecosystem
- [GitHub: sindresorhus/quick-look-plugins](https://github.com/sindresorhus/quick-look-plugins) - Curated list of Quick Look plugins with examples
- [QuickLook Plugins List](https://www.quicklookplugins.com/) - Community-maintained plugin directory
- [Addictivetips: How to install a plugin in QuickLook](https://www.addictivetips.com/mac-os/install-a-plugin-in-quicklook-on-macos/) - End-user installation guide

### macOS App Best Practices
- [GitHub: awesome-mac](https://github.com/jaywcjlove/awesome-mac) - Curated list of 98k+ starred macOS applications
- [GitHub: open-source-mac-os-apps](https://github.com/serhii-londar/open-source-mac-os-apps) - Open source macOS app examples

### Open Source Release Mistakes
- [Opensource.com: 7 mistakes to avoid](https://opensource.com/article/17/8/mistakes-open-source-avoid) - Common open source project pitfalls
- [Linux Audit: Why we use your open-source project](https://linux-audit.com/software/why-we-use-your-open-source-project-or-not/) - What makes projects trustworthy

---
*Feature research for: MD Quick Look GitHub public release*
*Researched: 2026-02-02*
*Confidence: HIGH - Based on verified sources, successful macOS app patterns, and open source best practices*
