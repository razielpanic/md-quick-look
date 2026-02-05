# Phase 10: Documentation & Marketing - Research

**Researched:** 2026-02-04
**Domain:** GitHub README documentation, macOS app marketing, demo GIF creation
**Confidence:** HIGH

## Summary

Documentation for macOS Quick Look extensions follows established GitHub README patterns but requires macOS-specific sections for troubleshooting (quarantine attributes, Gatekeeper warnings, extension discovery). The standard stack uses native macOS screenshot tools combined with specialized GIF recorders, avoiding hand-rolled solutions for image optimization and annotation.

Research reveals three critical success factors: (1) hero screenshot placement above the fold showing the "magic moment" in Finder, (2) troubleshooting section addressing quarantine/Gatekeeper issues that plague all third-party macOS apps, and (3) scannable structure under 10-12 screens using visual hierarchy principles.

The ecosystem has converged on specific tools: CleanShot X or Kap for GIF recording, ImageOptim for compression, and native macOS Screenshots (Cmd+Shift+5) for static captures. README structure follows a predictable pattern: hero image, one-liner description, installation (with Homebrew primary), troubleshooting, features with screenshots, and license.

**Primary recommendation:** Use CleanShot X or Kap for demo GIF (keep under 5MB, 10 seconds max), place hero screenshot immediately after title, structure troubleshooting around quarantine removal with exact `xattr` commands, and use MIT license for maximum accessibility.

## Standard Stack

The established tools for macOS app documentation:

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| macOS Screenshots | Built-in | Static screenshots | Native, retina-aware, no install required |
| CleanShot X | Latest | GIF recording + annotation | Industry standard for macOS, cloud sharing, instant annotation |
| Kap | Latest (OSS) | GIF recording | Open-source alternative, exports GIF/MP4/WebM/APNG |
| ImageOptim | Latest | Image/GIF optimization | Smallest file sizes, lossless, integrates with Finder |
| GitHub web editor | Built-in | LICENSE file generation | Auto-fills MIT/Apache 2.0 templates correctly |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Gifox | Latest | Precise GIF capture | Need compression control, menu bar workflow |
| Shottr | Latest | Screenshot annotation | Free alternative to CleanShot X, OCR support |
| Gifski | Latest | Video-to-GIF conversion | Converting screen recordings to optimized GIFs |
| Preview.app | Built-in | Image resizing/DPI adjustment | Reduce retina screenshot file sizes (144ppi → 72ppi) |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|-----------|-----------|----------|
| CleanShot X | Shottr + Kap | Free, but no cloud sharing or integrated workflow |
| ImageOptim | Optimage | Optimage has more formats (APNG, WebP) but paid |
| Kap | GIPHY Capture | GIPHY Capture simpler but fewer export options |

**Installation:**
```bash
# Primary stack (free + open source)
# Screenshots: Built-in (Cmd+Shift+5)
brew install kap
brew install --cask imageoptim

# Premium alternative
# CleanShot X: https://cleanshot.com/ (paid)
```

## Architecture Patterns

### Recommended README Structure
```
README.md
├── Hero Screenshot          # Above the fold, shows "magic moment"
├── Title + One-liner        # What it does in <15 words
├── Badges (2-4 max)        # License, macOS version, status
├── Installation            # Homebrew primary, manual secondary
│   ├── Method 1: Homebrew  # brew install --cask --no-quarantine
│   └── Method 2: DMG       # Download + drag to /Applications
├── Troubleshooting         # CRITICAL for macOS apps
│   ├── Extension not appearing
│   ├── Quarantine warnings
│   └── System Preferences check
├── Features                # 2-3 screenshots showing rendering
├── Demo GIF               # "Select .md → spacebar → preview"
├── Usage                  # Quick start guide
├── Contributing (optional)
└── License                # MIT or Apache 2.0
```

### Pattern 1: Hero Screenshot Above the Fold
**What:** Place the primary value demonstration (markdown rendered in Quick Look panel) immediately after the title, before any text.
**When to use:** Always for visual apps, especially Quick Look extensions where the "magic moment" is the rendered preview.
**Example:**
```markdown
# MD Quick Look

> Render markdown files beautifully in Finder's Quick Look preview

![MD Quick Look showing rendered markdown in Finder](./docs/hero-screenshot.png)

Press spacebar on any `.md` file to see rich markdown rendering with syntax highlighting, tables, and images.
```

### Pattern 2: Troubleshooting-First Installation
**What:** Embed troubleshooting guidance directly in installation section, not as separate afterthought.
**When to use:** All macOS apps distributed outside App Store (Gatekeeper/quarantine issues are guaranteed).
**Example:**
```markdown
## Installation

### Homebrew (Recommended)
```bash
brew install --cask --no-quarantine md-quick-look
```

The `--no-quarantine` flag prevents macOS security warnings.

### Manual Installation

1. Download `MD-Quick-Look.dmg` from [Releases](...)
2. Open DMG and drag app to `/Applications`
3. **Important:** Right-click the app and select "Open" the first time to bypass Gatekeeper

#### Troubleshooting

**Extension not appearing?**
- Launch the app once (this registers the extension)
- Check System Preferences > Extensions > Quick Look
- Run `qlmanage -r` to reload Quick Look

**"Cannot be opened because the developer cannot be verified"?**
```bash
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```
```

### Pattern 3: Demo GIF as "Magic Moment"
**What:** 5-10 second GIF showing the complete user flow: select file → press spacebar → see preview.
**When to use:** Quick Look extensions where the value is immediate visual transformation.
**Example:**
```markdown
## See It In Action

![Demo: Select markdown file, press spacebar, see rendered preview](./docs/demo.gif)

No configuration needed. Just press spacebar on any `.md` file.
```

### Pattern 4: Scannable Visual Hierarchy
**What:** Use headings, bullets, bold text, and whitespace to create scannable 10-12 screen README.
**When to use:** Always. Readers scan, don't read linearly.
**Techniques:**
- **Headings (##, ###):** Every major section
- **Bullets:** Lists, feature enumerations, steps
- **Bold:** Key actions, warnings, tool names
- **Code blocks:** Commands, file paths, configuration
- **Whitespace:** Blank lines between sections, breathing room
- **Tables:** Comparing options, showing supported formats

### Anti-Patterns to Avoid
- **Long paragraphs:** Break into bullets or shorter paragraphs (3-4 sentences max)
- **Too many badges:** Stick to 2-4 (license, macOS version, build status)
- **Generic installation:** Must address macOS quarantine/Gatekeeper issues explicitly
- **No troubleshooting:** Quick Look extensions have discovery problems, must document
- **GIFs too large:** >5MB slows page load, use ImageOptim to compress
- **Screenshots too large:** Retina displays create 2-4MB PNGs, resize to 72ppi
- **LICENSE in README body:** Use separate LICENSE file in root

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GIF optimization | Custom ffmpeg scripts | ImageOptim, Gifski | Handles cross-frame palettes, temporal dithering automatically |
| Screenshot annotation | Drawing tool integration | CleanShot X, Shottr | Built-in arrows, boxes, text, blur, backgrounds |
| Image resizing | Manual Preview.app workflow | ImageOptim batch processing | Maintains quality, strips metadata, optimizes compression |
| README templates | Writing from scratch | makeareadme.com, jehna/readme-best-practices | Proven structure, includes all essential sections |
| LICENSE file text | Copy-paste from web | GitHub license picker (web UI) | Auto-fills year, copyright holder, correct formatting |
| GIF recording | QuickTime + conversion | Kap, CleanShot X, Gifox | Direct GIF export, compression controls, easier workflow |
| Quarantine removal instructions | "Just open it" | Exact `xattr -dr com.apple.quarantine` command | Users need copy-paste solution, not vague guidance |

**Key insight:** Documentation tooling on macOS is mature and specialized. Custom solutions add maintenance burden without improving quality. Users expect standard formats (GitHub-flavored markdown, recognizable section names, Homebrew install commands).

## Common Pitfalls

### Pitfall 1: Retina Screenshots Too Large
**What goes wrong:** Screenshots from Retina displays are 144ppi and 2-4MB, slowing README load times and bloating repository size.
**Why it happens:** macOS defaults to native retina resolution for screenshots. Developers don't optimize before committing.
**How to avoid:**
- Use Preview.app → Tools → Adjust Size → set Resolution to 72ppi
- Or use ImageOptim to batch optimize all screenshots
- Target <500KB per screenshot, <5MB for GIFs
**Warning signs:** README takes >3 seconds to load, git repo size grows rapidly with each screenshot addition.

### Pitfall 2: Missing Quarantine Troubleshooting
**What goes wrong:** Users download DMG, try to open app, see "cannot be opened because developer cannot be verified," give up.
**Why it happens:** All apps downloaded from outside App Store are quarantined by macOS. Developers forget this because they build locally (no quarantine).
**How to avoid:**
- Document `xattr -dr com.apple.quarantine` command with exact path
- Mention right-click → Open alternative
- Add `--no-quarantine` flag to Homebrew install
- Test installation flow on clean macOS system
**Warning signs:** GitHub issues saying "app won't open," "security warning," "unidentified developer."

### Pitfall 3: Extension Discovery Failure
**What goes wrong:** Quick Look extension installed but doesn't appear in System Preferences or doesn't activate for markdown files.
**Why it happens:**
- App not launched (extensions require first launch to register)
- Quick Look cache not refreshed
- Conflicting extension registered for same file types
**How to avoid:**
- Document "launch app at least once" requirement explicitly
- Provide `qlmanage -r` command to reload Quick Look
- Show screenshot of System Preferences > Extensions > Quick Look with extension enabled
- List supported UTIs (public.markdown, net.daringfireball.markdown, etc.)
**Warning signs:** Users report "nothing happens when I press spacebar," "still shows plain text."

### Pitfall 4: Demo GIF File Size Bloat
**What goes wrong:** 30-second GIF at 60fps with 256 colors creates 50MB file, exceeds GitHub's 10MB limit, slows page load.
**Why it happens:** Screen recorders default to high framerate and full color palette. Developers don't optimize.
**How to avoid:**
- Limit GIF duration to 5-10 seconds (show only "magic moment")
- Use 10fps instead of 30fps for screen captures (UI doesn't need high framerate)
- Reduce color palette to 128-200 colors
- Run ImageOptim on final GIF
- Target 2-5MB maximum
**Warning signs:** GitHub rejects GIF upload, README scrolling is janky, users on mobile connections see slow load.

### Pitfall 5: Too Many or Too Few Badges
**What goes wrong:** Either README has 10+ badges cluttering the header, or zero badges making it unclear what platforms/licenses apply.
**Why it happens:** Badge generators make it easy to add many; developers don't curate.
**How to avoid:**
- Stick to 2-4 badges: License, macOS version, build status (if CI exists), latest release
- Avoid vanity metrics (stars, forks, downloads) for new projects
- Place badges after title but before description
**Warning signs:** First screen is mostly badges, or users ask "what license?" "what macOS version?"

### Pitfall 6: Vague Installation Instructions
**What goes wrong:** Installation section says "download and install" without specifying /Applications vs ~/Applications, or how to handle security warnings.
**Why it happens:** Developers assume users understand macOS app installation conventions.
**How to avoid:**
- Specify exact directory: "drag to `/Applications`"
- Show Homebrew command with `--no-quarantine` flag
- Document first-launch requirement for Quick Look extensions
- Provide step-by-step with screenshots for manual install
**Warning signs:** Users ask "where do I put this?" in issues, installation-related questions dominate support.

### Pitfall 7: README Length Sprawl
**What goes wrong:** README becomes 20+ screens with every possible detail, overwhelming new users.
**Why it happens:** Accumulation over time, fear of missing information, no pruning.
**How to avoid:**
- Keep README to 10-12 screens of scrolling
- Move advanced topics to `/docs` folder or wiki
- Use progressive disclosure (link to detailed guides)
- Front-load essential info (install, basic usage, troubleshooting)
**Warning signs:** Scrolling takes >30 seconds, users ask questions answered "somewhere" in README.

## Code Examples

Verified patterns from official sources and established Quick Look extensions:

### Installation Section with Troubleshooting
```markdown
## Installation

### Homebrew (Recommended)

```bash
brew install --cask --no-quarantine md-quick-look
```

The `--no-quarantine` flag prevents macOS Gatekeeper warnings.

### Manual Installation

1. **Download** the latest `MD-Quick-Look.dmg` from [Releases](https://github.com/user/repo/releases)
2. **Open** the DMG file
3. **Drag** MD Quick Look.app to your `/Applications` folder
4. **Launch** the app once (required to register the Quick Look extension)

#### First Launch Security Warning

On first launch, macOS may show: *"MD Quick Look cannot be opened because the developer cannot be verified."*

**Solution:** Right-click the app and select "Open", then click "Open" in the dialog.

**Alternative (Terminal):**
```bash
xattr -dr com.apple.quarantine /Applications/MD\ Quick\ Look.app
```

#### Extension Not Appearing?

1. Verify the app is in `/Applications` (not `~/Applications` or `~/Downloads`)
2. Launch the app at least once
3. Check System Preferences > Extensions > Quick Look
4. Enable "MD Quick Look" if it's unchecked
5. Reload Quick Look: `qlmanage -r`

If the extension still doesn't appear, restart Finder:
- Press `Cmd + Option + Esc`
- Select "Finder"
- Click "Relaunch"
```

Source: Synthesized from [sindresorhus/quick-look-plugins](https://github.com/sindresorhus/quick-look-plugins) and [sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) patterns.

### Hero Screenshot with Context
```markdown
# MD Quick Look

> Beautiful markdown previews in Finder. Just press spacebar.

<p align="center">
  <img src="docs/hero-screenshot.png" alt="MD Quick Look showing rendered markdown with syntax highlighting in Finder's Quick Look panel" width="800">
</p>

**Features:**
- Syntax highlighting for code blocks
- Renders tables, lists, and images
- Dark mode support
- No configuration required

[Download](https://github.com/user/repo/releases) • [Installation](#installation) • [Troubleshooting](#troubleshooting)
```

Source: Adapted from [jehna/readme-best-practices](https://github.com/jehna/readme-best-practices) and [makeareadme.com](https://www.makeareadme.com/) guidance.

### Demo GIF Section
```markdown
## See It in Action

<p align="center">
  <img src="docs/demo.gif" alt="Demo: Select a markdown file in Finder, press spacebar, see beautifully rendered preview" width="600">
</p>

Select any `.md` file in Finder and press `spacebar`. That's it.
```

**GIF Creation Workflow:**
```bash
# 1. Record with Kap (free) or CleanShot X (paid)
#    - 10 seconds max
#    - 10fps
#    - Focus on core workflow: select → spacebar → preview

# 2. Optimize with ImageOptim
open -a ImageOptim demo.gif

# 3. Verify file size
ls -lh docs/demo.gif  # Target: <5MB
```

Source: Based on [Kap](https://github.com/wulkano/Kap) and [ImageOptim](https://imageoptim.com/mac) documentation.

### LICENSE File Generation
```markdown
# Via GitHub Web UI (Recommended)

1. Go to your repository on GitHub
2. Click "Add file" > "Create new file"
3. Name the file `LICENSE`
4. Click "Choose a license template"
5. Select "MIT License" or "Apache License 2.0"
6. GitHub auto-fills with your name and year
7. Commit directly to main

# Result: Root-level LICENSE file with correct formatting
```

Source: [GitHub Docs - Licensing a repository](https://docs.github.com/articles/licensing-a-repository)

### Badge Section
```markdown
# MD Quick Look

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 14+](https://img.shields.io/badge/macOS-14+-blue.svg)](https://www.apple.com/macos/)
[![Release](https://img.shields.io/github/v/release/user/repo.svg)](https://github.com/user/repo/releases)

> Beautiful markdown previews in Finder
```

**Stick to 2-4 badges maximum.** Badges should provide essential metadata: license (required), platform version (macOS 14+), and optionally latest release or build status.

Source: Ecosystem standard from [shields.io](https://shields.io/) and GitHub community practices.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| .qlgenerator plugins in ~/Library/QuickLook | QuickLook App Extensions (.app bundles) | macOS 15 (Sequoia), 2024 | Old plugins no longer supported, must use app extension API |
| README with wall of text | Scannable README with visual hierarchy | ~2020-2021 | Readers scan, don't read; must accommodate with bullets, headings, whitespace |
| Large unoptimized GIFs | Compressed GIFs <5MB with ImageOptim/Gifski | Ongoing, accelerated 2023+ | Mobile users, GitHub 10MB limit, page load performance |
| Generic installation instructions | macOS-specific quarantine troubleshooting | ~2019 (Catalina Gatekeeper changes) | All third-party apps must document `xattr -dr com.apple.quarantine` |
| Apache 2.0 as default | MIT as default for small projects | Ongoing trend 2022+ | MIT is simpler, more permissive; Apache for patent-heavy projects |
| Screenshots at 144ppi (retina) | Screenshots optimized to 72ppi | Ongoing best practice | Reduces file size from 2-4MB to <500KB without visible quality loss |

**Deprecated/outdated:**
- **.qlgenerator format:** No longer works on macOS 15+, must use QuickLook App Extensions
- **Homebrew without --no-quarantine flag:** Users still get Gatekeeper warnings, defeats purpose of Homebrew convenience
- **README-only documentation:** Long READMEs (>15 screens) should split into /docs folder or wiki
- **Video embeds in GitHub README:** GitHub doesn't natively support video, must use GIF or link to external hosting

## Open Questions

Things that couldn't be fully resolved:

1. **macOS Sequoia (15+) Quick Look Extension Compatibility**
   - What we know: .qlgenerator plugins deprecated, must use QuickLook App Extensions
   - What's unclear: Exact migration path for existing .qlgenerator-based extensions to app extensions
   - Recommendation: Assume app extension architecture (already planned for Phase 09), document both formats if supporting macOS 14 and 15+

2. **Optimal GIF Duration for Quick Look Demos**
   - What we know: Community recommends 5-10 seconds, <5MB file size
   - What's unclear: Specific user engagement data for Quick Look extension demos
   - Recommendation: Target 8-10 seconds showing complete workflow: select → spacebar → preview → close. Test with real users.

3. **Screenshot Hosting: In-Repo vs External**
   - What we know: In-repo keeps everything together but bloats repo size; GitHub Releases or external CDN reduces repo size
   - What's unclear: Best practice for small projects (<10 screenshots)
   - Recommendation: For this project (4-5 screenshots total), store in `/docs` folder in-repo. Optimize all to <500KB.

4. **License Choice for Quick Look Extension**
   - What we know: MIT is simpler and more permissive, Apache 2.0 provides patent grants
   - What's unclear: Whether patent protection matters for a markdown rendering extension
   - Recommendation: MIT unless using third-party libraries with patent concerns. Check dependencies' licenses first.

## Sources

### Primary (HIGH confidence)
- [GitHub - sindresorhus/quick-look-plugins](https://github.com/sindresorhus/quick-look-plugins) - Ecosystem standards for Quick Look plugin documentation
- [GitHub - sbarex/QLMarkdown](https://github.com/sbarex/QLMarkdown) - Real-world Quick Look extension README structure
- [GitHub - sbarex/SourceCodeSyntaxHighlight](https://github.com/sbarex/SourceCodeSyntaxHighlight) - Installation and troubleshooting patterns
- [GitHub - jehna/readme-best-practices](https://github.com/jehna/readme-best-practices) - README structure template
- [Make a README](https://www.makeareadme.com/) - Essential sections and ordering
- [GitHub Docs - Licensing a repository](https://docs.github.com/articles/licensing-a-repository) - LICENSE file format and location
- [Apple Support - Safely open apps on your Mac](https://support.apple.com/en-us/102445) - Official Gatekeeper documentation
- [ImageOptim](https://imageoptim.com/mac) - Image optimization tool documentation

### Secondary (MEDIUM confidence)
- [How to write a good README - DEV Community](https://dev.to/merlos/how-to-write-a-good-readme-bog) - README structure best practices
- [Best Practices For An Eye Catching GitHub Readme - Hatica](https://www.hatica.io/blog/best-practices-for-github-readme/) - Common mistakes and pitfalls
- [12 Best GIF Recorders for Mac in 2026 - Movavi](https://www.movavi.com/learning-portal/gif-recorder-for-mac.html) - Tool comparison for GIF recording
- [CleanShot X Review](https://cleanshot.com/) - Premium screenshot/GIF tool features
- [Kap GitHub](https://github.com/wulkano/Kap) - Open-source screen recorder
- [MIT vs. Apache 2.0 License Comparison](https://mikatuo.com/blog/apache-20-vs-mit-licenses/) - License choice guidance
- [Demo GIF Best Practices - Voxel51](https://voxel51.com/blog/computer-vision-elevate-your-github-readme-game) - File size and duration recommendations
- [GitHub README Best Practices - Tilburg Science Hub](https://www.tilburgsciencehub.com/topics/collaborate-share/share-your-work/content-creation/readme-best-practices/) - Visual hierarchy principles

### Tertiary (LOW confidence - marked for validation)
- [SkreenPro - Open Source Screenshot Tool](https://chatgate.ai/post/skreenpro/) - Annotation tool option (newly launched Jan 2026, unverified)
- [Optimage](https://optimage.app/) - Alternative to ImageOptim (features claimed but not independently verified)
- WebSearch results for "demo GIF best practices" - File size recommendations (community consensus but not authoritative source)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Tools verified through official documentation (ImageOptim, Kap, CleanShot X), ecosystem adoption confirmed via multiple sources
- Architecture: HIGH - README structure patterns extracted from successful Quick Look extensions (QLMarkdown, SourceCodeSyntaxHighlight) and validated against community best practices repositories
- Pitfalls: HIGH - Quarantine/Gatekeeper issues confirmed via Apple official docs and observed in real Quick Look extension READMEs; GIF file size limits confirmed via GitHub documentation
- Code examples: HIGH - Installation patterns directly extracted from sindresorhus/quick-look-plugins (>15k stars, authoritative source); troubleshooting commands verified against Apple Support docs

**Research date:** 2026-02-04
**Valid until:** 2026-03-04 (30 days - stable domain, macOS QL extension API mature)

**Notes:**
- macOS 15 (Sequoia) transition from .qlgenerator to App Extensions is recent (2024); some older documentation may reference deprecated format
- GIF optimization best practices are stable; tools (ImageOptim, Gifski) have been standard for 2+ years
- README best practices evolve slowly; jehna/readme-best-practices template stable since 2018 with minor updates
- License choice (MIT vs Apache 2.0) is stable decision framework; no recent changes to either license text
