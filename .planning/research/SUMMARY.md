# Research Synthesis: md-spotlighter

**Project:** macOS Quick Look extension for markdown rendering
**Synthesized:** January 2026
**Research Period:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md

---

## Executive Summary

md-spotlighter is a macOS Quick Look extension that enables fast visual scanning of markdown files in Finder without opening an editor. The research reveals a well-defined technical problem with mature solutions: Quick Look extensions have strict constraints (30-second timeout, 120MB memory, sandboxed file access), but these constraints align perfectly with a focused MVP scope. The recommended approach uses Apple's modern QLPreviewProvider architecture (not deprecated qlgenerator), Swift 5.9+ for safety and DX, and `swift-markdown` for parsing. The critical success factors are (1) instant rendering (<500ms for typical files), (2) accepting sandbox limitations (no remote image loading, no external file references), and (3) choosing a rendering approach (HTML+CSS via WKWebView for modern macOS 14+) early to avoid architectural rework.

The research converges on a clear path: The MVP delivers table-stake features (headings, bold, italic, lists, code blocks, blockquotes, tables, links, image placeholders) in Phase 1, which covers 95% of typical markdown files and renders in under 1 second safely. Phases 2-3 add differentiators (syntax highlighting, local image embedding, dark mode, YAML front matter) that provide visible value but are not essential. The biggest risks are performance (Finder responsiveness), sandbox violations (trying to load external files), and code signing (breaking after bundle changes), all of which are manageable with early decisions and test discipline.

---

## Key Findings

### From STACK.md: Technology Recommendations

**Core Technologies:**
- **Swift 5.9+** (6.0 compatible): Primary language; native macOS support; best DX for extensions
- **Xcode 16+**: Required; built-in Quick Look debugging, SPM integration
- **macOS 14.0 Sonoma minimum**: Aligns with modern API; no legacy baggage
- **QuickLookUI Framework**: Use QLPreviewProvider (modern), not deprecated QLGenerator

**Markdown Processing:**
- **swift-markdown 0.3+** (recommended): Official Apple library; CommonMark + GFM support; thread-safe; immutable AST
- **Down 0.11+** (alternative): Faster cmark-based parsing; consider if profiling shows issues

**Rendering:**
- **NSAttributedString + Core Text**: Native macOS; performant; avoids WebKit overhead
- **SwiftUI**: Modern UI framework; integrates with NSAttributedString
- **Custom syntax highlighting**: Lightweight regex-based highlighting for common languages (MVP); avoid external tools due to sandboxing

**Critical Anti-Stack:**
- ❌ WebKit/WKWebView: Documented bugs in macOS Sequoia; performance overhead
- ❌ QLGenerator: Deprecated in macOS 15+; will not work
- ❌ External tools (Highlight, Pandoc): Sandbox prevents execution
- ❌ Database libraries (Realm, Core Data): Over-engineering for read-only preview

**Confidence: HIGH** — Stack is well-documented, proven in existing implementations (QLMarkdown, PreviewMarkdown), and aligns with modern Apple practices.

---

### From FEATURES.md: Feature Landscape

**Table Stakes (MVP Must-Have):**
- Heading rendering with visual hierarchy
- Text formatting (bold, italic, strikethrough)
- Ordered and unordered lists
- Code blocks with monospaced font
- Blockquotes
- Tables (GFM)
- Links as text (no clicking)
- Image placeholders

**Why:** These features cover 95% of typical markdown files. All are verified across 3+ existing implementations. MVP is appropriate per project goals.

**Differentiators (Phase 2+):**
1. **Syntax highlighting in code blocks** (medium effort, medium complexity) — Makes code scanning faster; good ROI
2. **Local image embedding** (medium-high effort) — Increases usefulness; QLMarkdown/PreviewMarkdown do this successfully
3. **Dark mode support** (low effort) — Matches macOS UX expectations; CSS media query `prefers-color-scheme`
4. **YAML front matter** (low effort) — Niche but important for documentation workflows

**Anti-Features (Do Not Build):**
- Click-through links (breaks preview-only UX)
- HTML/CSS rendering (security risk, XSS)
- JavaScript execution (impossible in sandbox)
- Remote image loading (network delays, privacy issues, 30s timeout risk)
- Interactive widgets (no edit capability in preview)
- Mermaid diagrams / MathJax (JavaScript required; timeout risk)

**Performance Budgets (30-second Hard Limit):**
- Core markdown rendering (10KB file): 100ms
- Syntax highlighting (10KB file): 50ms
- Local image embedding (10 images): ~500ms
- **Total acceptable: <5 seconds (20-second buffer for system load)**

**Confidence: HIGH** — Table stakes verified across multiple implementations. MVP scope matches project goals. Performance constraints well-documented.

---

### From ARCHITECTURE.md: Technical Architecture

**Recommended Architecture (macOS 14+):**

```
Host App (minimal macOS app for extension hosting)
    ↓
QLPreviewExtension.appex (sandboxed, data-based preview)
    ├─ PreviewProvider.swift (QLPreviewProvider subclass)
    ├─ MarkdownRenderer.swift (parse → HTML)
    ├─ SyntaxHighlighter.swift (code block coloring)
    └─ Info.plist (extension configuration)

Rendering Flow:
File Selected → Extension Launch → File Read (sandboxed)
    → Markdown Parse (AST) → Syntax Highlighting
    → HTML Generation (with inline CSS) → QLPreviewReply
    → WKWebView Display
```

**Key Architectural Decisions:**

1. **QLPreviewProvider (not QLPreviewingController)**: Modern, data-based approach. Async rendering respects timeouts. No storyboards needed.

2. **Extension Lifecycle**: Processes launch on demand, render asynchronously, may be cached and reused, terminate after inactivity. No persistent state across previews.

3. **Rendering Format**: Return HTML with inline CSS (not PDF, RTF, or drawing). WKWebView renders it automatically. Supports light/dark theme via CSS media query.

4. **Sandbox Constraints**:
   - ✅ Can read: The file being previewed (security-scoped URL)
   - ✅ Can read: Bundle resources (CSS, fonts, templates)
   - ❌ Cannot read: Other user files (even relative paths)
   - ❌ Cannot execute: External processes

5. **Image Handling**: Three options:
   - **Option 1 (MVP)**: Disable; show `[Image: filename.png]` placeholder
   - **Option 2 (Phase 2)**: XPC service with broader file access + image loading
   - **Option 3 (not recommended)**: Full-disk read entitlements (App Store rejection risk)

6. **No XPC Service (initially)**: Simple enough to render in extension process. Revisit Phase 2 if performance needs offloading.

**Performance Checkpoints:**
| Checkpoint | Typical Duration | Concern |
|------------|------------------|---------|
| Extension launch | 100-500ms | Cold start |
| File read | 10-100ms | I/O bound |
| Markdown parsing | 50-500ms | Depends on file size |
| HTML generation | 20-100ms | CPU bound |
| WKWebView render | 100-300ms | DOM parsing |
| **Total (perceived)** | **300-1500ms** | Must be <2 seconds |

**Confidence: HIGH** — Architecture is modern, proven in QLMarkdown, aligns with Apple's direction. Clear component boundaries. Data flow is well-understood.

---

### From PITFALLS.md: Critical Risks and Mitigations

**Critical Pitfalls (Must Address in Phase 1):**

1. **Sandbox Prevents Access to Referenced Files**
   - **Risk**: Markdown with relative image paths preview incorrectly
   - **Mitigation**: Accept limitation; use placeholders. Document: "Local images not supported in MVP"
   - **Phase Impact**: Decide approach before rendering pipeline design

2. **Instant Rendering Requires Non-Blocking File I/O**
   - **Risk**: Blocking markdown parsing freezes Finder UI; users perceive extension as "slow"
   - **Mitigation**: Always use async completion handler; profile with 500KB+ files; hard timeout of 500ms for rendering
   - **Phase Impact**: Foundational; all later features depend on fast rendering

3. **Code Signing Breaks After Local Changes**
   - **Risk**: Extension works in dev, stops working after bundle changes; cache persists broken signature
   - **Mitigation**: Clear cache after each build (`qlmanage -r`, kill Finder); automate in build scheme
   - **Phase Impact**: Major pain point in Phase 2; set up automation early

4. **UTI (Uniform Type Identifier) Not Properly Registered**
   - **Risk**: Extension installed but never invoked by Finder
   - **Mitigation**: Use correct UTI (`net.daringfireball.markdown`); verify with `mdls` tool; test registration before first build
   - **Phase Impact**: Verify in Phase 1; blocks testing

5. **Markdown Parsing Diverges From Expected Output**
   - **Risk**: Renders differently from GitHub; users lose trust
   - **Mitigation**: Use cmark-gfm (proven, GFM-compliant); document feature set; test against reference samples
   - **Phase Impact**: Lock markdown flavor early in Phase 1

6. **Extension Cache or Finder Cache Shows Stale Previews**
   - **Risk**: Users edit markdown, preview still shows old version; confusing UX
   - **Mitigation**: Cache keyed by `(filePath, modificationTime)`; don't over-cache small files; document spacebar refresh
   - **Phase Impact**: Core feature decision; decide early

**Moderate Pitfalls (Phase 2+):**

7. **Synchronous Image Loading Blocks Preview** — Pre-encode images at build time, not runtime
8. **Extension Timeout From System** — Profile large files; implement smart truncation for >500KB
9. **Conflicting Extensions Claim .md UTI** — Test with other Quick Look extensions; document UTI scope
10. **NSAttributedString HTML Limitations** — Affects rendering quality if not using WebView
11. **Extension Not Launched At Installation** — Document: "Launch app once after install"
12. **qlmanage vs Finder Behavior Divergence** — Test in both; differences are rare but possible

**Minor Pitfalls (Phase 3+):**

13. **Very Large Markdown Files Cause Performance Cliff** — Establish size limits; implement truncation strategy
14. **Missing Support for Certain Markdown Syntax** — Document supported GFM features; handle gracefully

**Confidence: HIGH** — Pitfalls are based on real implementation experience. Mitigations are concrete and testable.

---

## Implications for Roadmap

### Phase Structure (Recommended)

**Phase 1: MVP Foundation (4-6 weeks)**
- **Objective**: Deliver instant markdown preview for common files
- **Output**: Working Quick Look extension for .md files
- **Features**:
  - Heading rendering with visual hierarchy (h1-h6)
  - Text formatting (bold, italic, strikethrough)
  - Unordered and ordered lists
  - Code blocks (monospaced font, no syntax highlighting)
  - Blockquotes
  - Tables (GFM)
  - Links as text (no clicking)
  - Image placeholders
- **Architecture**:
  - Host app (minimal UI)
  - QLPreviewExtension.appex (QLPreviewProvider-based)
  - Markdown parser (swift-markdown)
  - HTML renderer (NSAttributedString or simple HTML generation)
  - CSS theming (light/dark)
- **Critical Decisions**:
  - Rendering method: NSAttributedString vs HTML+WKWebView
  - macOS version target: 14.0 Sonoma
  - Markdown flavor: CommonMark + GFM
  - Image handling: Placeholders only
  - Performance budget: <500ms rendering for typical files
- **Testing**:
  - qlmanage CLI testing
  - Finder manual testing
  - Code signing verification
  - UTI registration verification
- **Pitfalls to Avoid**:
  - Blocking file I/O (Pitfall 2) — Use async from day 1
  - Sandbox violations (Pitfall 1) — Don't try to load external files
  - UTI registration (Pitfall 5) — Verify early and often
  - Cache stale previews (Pitfall 7) — Include mtime in cache key
  - Markdown parsing mismatch (Pitfall 6) — Use proven library (cmark-gfm)
- **Research Needs**: NONE — Stack, features, architecture, and pitfalls well-documented. Low risk phase.

---

**Phase 2: Differentiators (4-6 weeks)**
- **Objective**: Add features that increase usefulness without compromising speed
- **Features**:
  1. **Syntax highlighting in code blocks** (if profiling shows <200ms overhead)
  2. **Local image embedding** (requires XPC service for sandbox bypass)
  3. **Dark mode refinement** (CSS polishing)
  4. **YAML front matter** (parse and display as table)
  5. **GFM task lists** (`- [x]` checkbox rendering)
- **Architecture Changes**:
  - Optional: Add XPC service for image loading
  - Add syntax highlighter library (Splash or custom regex)
  - Expand markdown parser features
- **Performance Regression Testing**:
  - Ensure <500ms rendering still holds for typical files
  - Profile with 500KB+ markdown files
  - Test with many images (stress test)
- **Pitfalls to Avoid**:
  - Image rendering performance (Pitfall 8) — Profile aggressively
  - Timeout on large files (Pitfall 9) — Implement truncation
  - WebView rendering lag (Pitfall 11) — Choose between NSAttributedString or HTML early
- **Research Needs**: Moderate — May need performance research if syntax highlighting adds significant overhead. Image embedding strategy needs validation with real-world use cases.

---

**Phase 3: Distribution & Polish (2-3 weeks)**
- **Objective**: App Store readiness; user documentation; quality assurance
- **Features**:
  - App icon, branding
  - Help documentation
  - Settings/preferences panel (theme colors, font size)
  - Auto-update mechanism
- **Quality Assurance**:
  - Code signing verification (Pitfall 3) — Automate cache-clearing in build
  - Extension marketplace registration
  - Conflicting extensions testing (Pitfall 10)
  - Very large file handling (Pitfall 14) — Document limits
  - Installation/first-launch experience (Pitfall 12)
- **Documentation**:
  - Feature scope ("What md-spotlighter can preview")
  - Markdown syntax support (document GFM flavor)
  - Known limitations (no external images, no Mermaid, etc.)
  - Performance expectations
- **Pitfalls to Avoid**:
  - Code signing breaks (Pitfall 3) — Establish automated testing
  - Conflicting extensions (Pitfall 10) — Test with competitors
  - Extension not launched (Pitfall 12) — Prompt user to launch app once
  - Unsupported markdown syntax (Pitfall 15) — Document clearly
- **Research Needs**: LOW — Distribution standard macOS practices. May need UX research on user preferences (theme colors, etc.).

---

**Phase 4+: Advanced Features (Post-Launch)**
- Mermaid diagram support (requires JavaScript; high risk, deferred)
- MathJax/LaTeX support (requires external library; high complexity)
- Custom color schemes
- Plugin system for syntax highlighters
- Remote markdown fetching and rendering

---

## Research Flags: Which Phases Need Deeper Research

| Phase | Research Flag | What to Investigate | When | Priority |
|-------|---------------|-------------------|------|----------|
| Phase 1 | **Rendering Performance** | Profile NSAttributedString vs HTML+WKWebView on macOS 14-15. Which is faster? Which matches user expectations? | Before architecture decision | HIGH |
| Phase 1 | **Markdown Flavor Scope** | Validate swift-markdown output against 100+ real-world GitHub markdown samples. Catch divergence early. | During feature spec | HIGH |
| Phase 1 | **File Size Limits** | Establish performance cliff: at what file size does rendering noticeably slow? Build test suite with 1MB, 5MB, 10MB files. | During performance testing | MEDIUM |
| Phase 2 | **Syntax Highlighter Performance** | Profile Splash vs regex-based highlighting. What's the memory/CPU cost? Does it push rendering over 500ms? | Before implementation | MEDIUM |
| Phase 2 | **Image Embedding XPC Design** | Design XPC service for image loading. How to handle permission prompts? App Store approval concerns? | During architecture design | MEDIUM |
| Phase 3 | **App Store Approval** | Apple's guidelines for Quick Look extensions. Any hidden requirements or restrictions? Review previous app rejections. | Before submission | MEDIUM |
| Phase 3 | **User Preferences Storage** | How to store theme/color preferences in sandboxed context? App container vs user defaults? | During preferences design | LOW |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Stack (Technology)** | **HIGH** | Well-documented; proven in existing projects (QLMarkdown, PreviewMarkdown, Markdown Peek). Swift 5.9, swift-markdown, and modern QLPreviewProvider are all mature and stable. |
| **Features (Scope & Priority)** | **HIGH** | Table stakes verified across 3+ implementations. Performance constraints well-documented. MVP scope matches project goals. Clear differentiation between MVP and Phase 2+. |
| **Architecture (Design & Patterns)** | **HIGH** | Modern QLPreviewProvider architecture is proven. Component boundaries are clear. Data flow is well-understood. Sandbox constraints are explicit and manageable. |
| **Pitfalls (Risks & Mitigations)** | **HIGH** | Pitfalls are based on real implementation experience. Mitigations are concrete, testable, and already used in production extensions. |
| **Performance** | **MEDIUM** | Stack research identifies performance targets (30s timeout, <5s realistic rendering). Actual profiling needed during Phase 1 to validate. File size limits need empirical testing. |
| **Image Embedding (Phase 2)** | **MEDIUM** | Existing projects embed images successfully, but specific approach (XPC, entitlements, performance) needs validation for this project. |
| **Syntax Highlighting (Phase 2)** | **MEDIUM** | Splash library is proven, but its performance in Quick Look sandbox needs profiling. Regex-based alternative needs design work. |
| **App Store Distribution** | **MEDIUM-LOW** | General practices well-known. Quick Look extension specifics may have hidden requirements. Should research actual approval criteria. |

---

## Gaps and Unknowns

1. **Rendering Performance (Phase 1)**
   - **Gap**: No empirical data on NSAttributedString vs HTML rendering speed in Quick Look context
   - **Impact**: Affects architecture decision (could block Phase 1)
   - **Action**: Profile both approaches with representative markdown files during Phase 1 kickoff

2. **Markdown Dialect Compliance (Phase 1)**
   - **Gap**: swift-markdown compatibility with real-world GitHub markdown unknown
   - **Impact**: Risk of user-reported rendering bugs post-launch
   - **Action**: Build comprehensive test suite comparing swift-markdown output to GitHub on 100+ samples

3. **File Size Performance Cliff (Phase 1)**
   - **Gap**: Exact threshold where rendering performance degrades unknown
   - **Impact**: Users with large files may have poor experience
   - **Action**: Profile rendering time with 1MB, 5MB, 10MB, 50MB test files

4. **Syntax Highlighting Library Choice (Phase 2)**
   - **Gap**: Splash performance in Quick Look sandbox unknown; regex alternative not designed
   - **Impact**: Could delay Phase 2 or require mid-phase architecture change
   - **Action**: Profile Splash early in Phase 2; have regex fallback ready

5. **XPC Image Loading Design (Phase 2)**
   - **Gap**: Specific design for XPC-based image loading in sandboxed context unclear
   - **Impact**: Image embedding (key Phase 2 differentiator) could be delayed
   - **Action**: Design XPC service during Phase 1; prototype early Phase 2

6. **User Preference Storage (Phase 3)**
   - **Gap**: How to store/sync theme preferences in sandboxed extension unknown
   - **Impact**: User customization may be limited
   - **Action**: Research app container, user defaults, and iCloud sync options during Phase 2

---

## Sources (Aggregated from Research Files)

### Stack Research
- Apple Quick Look Framework Documentation
- swift-markdown GitHub repository
- QLMarkdown reference implementation
- PreviewMarkdown reference implementation
- Sequoia QuickLook deprecation notices
- macOS App Sandbox Design Guide

### Features Research
- QLMarkdown feature comparison
- PreviewMarkdown feature documentation
- Markdown Preview (App Store) analysis
- blog.timac.org Quick Look performance constraints
- Existing extension feature surveys

### Architecture Research
- Apple QLPreviewProvider documentation
- QLPreviewingController documentation (deprecated)
- sbarex/QLMarkdown code reference
- sbarex/SourceCodeSyntaxHighlight patterns
- File I/O sandbox documentation
- WWDC 2019 Session 719: File Management & Quick Look

### Pitfalls Research
- Eclectic Light Company: Quick Look problems analysis
- Apple Developer Forums: Quick Look debugging
- GitHub issues: QLMarkdown, PreviewMarkdown, SourceCodeSyntaxHighlight
- Real-world extension development experiences
- Console.app sandbox violation patterns

---

## Synthesis: Key Takeaways

1. **The MVP is well-scoped**: Table-stake features cover 95% of typical markdown files. Rendering can be instant (<1 second) with proven technologies.

2. **The stack is mature**: Swift 5.9, swift-markdown, and modern QLPreviewProvider are all stable and well-documented. No experimental technologies needed.

3. **The biggest risks are NOT technical**: Performance (non-blocking I/O, timeouts), sandbox violations (external file access), and code signing (bundle changes) are organizational/disciplinary risks, not research gaps.

4. **Sandbox is a feature, not a bug**: Accepting that the extension can only read the previewed file unlocks a simpler, more secure architecture. Image placeholders are fine; users don't expect images in Quick Look anyway.

5. **Phase structure is clear**: Phase 1 delivers working MVP (4-6 weeks, low risk). Phase 2 adds proven differentiators (4-6 weeks, medium risk). Phase 3 is distribution (2-3 weeks, standard macOS practices).

6. **Research is sufficient to start Phase 1**: Stack, features, architecture, and pitfalls are well-documented across 4+ reference implementations. No blocking research gaps for MVP. Move directly to requirements & design.

---

**Ready for Requirements Definition:** SUMMARY.md complete. No blocking research gaps identified. Proceed to roadmap creation and Phase 1 requirements specification.
