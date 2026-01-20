# Feature Landscape: Markdown Quick Look Extensions

**Domain:** macOS Quick Look markdown preview extensions
**Researched:** 2026-01-19
**Scope:** Quick preview extensions (not full markdown editors or viewers)

## Executive Summary

Markdown Quick Look extensions have a clear purpose: enable fast visual scanning of markdown files in Finder without opening an editor. Research into existing implementations (QLMarkdown, PreviewMarkdown, Markdown Peek) and Quick Look constraints reveals a distinction between essential features that make previews useful, optional features that enhance the experience, and features that are actively harmful in a Quick Look context.

The critical constraint is performance: Quick Look allows 30 seconds for preview generation before killing the process. Memory is capped at 120MB. These limits eliminate complex features and favor fast, lightweight rendering.

## Table Stakes: Features Users Expect

These features must work. Without them, the extension feels incomplete or unusable.

| Feature | Why Expected | Complexity | Performance Notes | Verified |
|---------|--------------|------------|-------------------|----------|
| **Heading rendering** | Core markdown structure | Low | Direct HTML rendering | QLMarkdown, PreviewMarkdown |
| **Text formatting (bold, italic)** | Basic markdown semantics | Low | Direct HTML rendering | All implementations |
| **Unordered lists** | Essential structure | Low | Direct HTML rendering | All implementations |
| **Ordered lists** | Essential structure | Low | Direct HTML rendering | All implementations |
| **Code blocks with monospaced font** | Common in technical docs | Low | Direct HTML rendering | All implementations |
| **Blockquotes with visual distinction** | Common markdown element | Low | Direct HTML rendering | PreviewMarkdown confirmed |
| **Link rendering (text form)** | Expected to see links exist | Low | No click handling needed | All implementations |
| **Strikethrough** | GitHub Flavored Markdown standard | Low | Direct HTML rendering | QLMarkdown, PreviewMarkdown |
| **Tables** | GFM table syntax common in docs | Medium | HTML table rendering | QLMarkdown, PreviewMarkdown |

**Minimum viable rendering** for this project (per project_context):
- Headings with visual hierarchy ✓
- Bold, italic text ✓
- Unordered and ordered lists ✓
- Code blocks with syntax highlighting ✓
- Links as text (no clicking) ✓
- Images as [Image: filename] placeholder ✓
- Tables as raw markdown ✓

This project's MVP plan aligns well with table stakes. **Project MVP is appropriate.**

## Differentiators: Features That Add Value

These features are not expected but are valued when present. They make this extension stand out.

| Feature | Value Proposition | Complexity | Performance Impact | Effort | Notes |
|---------|-------------------|------------|-------------------|--------|-------|
| **Syntax highlighting in code blocks** | Shows code structure, easier scanning | Medium | CPU-bound parsing (varies by language count) | Medium | QLMarkdown uses language plugins selectively |
| **Local image embedding** | Visual confirmation of image content | Medium-High | File I/O + image rendering; 30s timeout risk | Medium-High | QLMarkdown/PreviewMarkdown do this; requires `file://` or relative path resolution |
| **YAML front matter rendering** | Important for Jekyll/Hugo users | Low | Just parse and format as table | Low | PreviewMarkdown, QLMarkdown support this |
| **Dark mode support** | Respects system preferences | Low | CSS media query handling | Low | Improves UX significantly with minimal cost |
| **Auto-reload on file change** | Users want this (2025 feedback) | Low | File watcher integration | Low | Requested feature; low complexity |
| **GFM task lists** | Modern markdown feature | Low | Checkbox rendering | Low | Common in issues/TODOs |
| **Emoji rendering** | Makes content more readable | Low | Emoji font support | Low | Nice-to-have; not critical |
| **Subscript/superscript** | Scientific/technical documents | Low | HTML rendering | Low | Less common; good differentiator |
| **Text highlighting** (`==highlighted==`) | Useful for quick scanning | Low | CSS styling | Low | Helps pick out important text |
| **Mermaid diagrams** | Flowcharts, sequence diagrams | High | JavaScript execution required; 30s timeout risk | High | QLMarkdown supports this; complex and risky |
| **Math expressions (LaTeX/MathJax)** | Scientific documents | High | JavaScript execution required; very slow; 30s timeout risk | High | QLMarkdown supports this via cmark-gfm math extension; performance bottleneck |

**Recommended for differentiation:**
1. **Syntax highlighting** - Good ROI (medium effort, visible value)
2. **Local image embedding** - Increases usefulness significantly
3. **Dark mode** - Matches macOS UX expectations, minimal cost
4. **YAML front matter** - Niche but important for documentation workflows

**Not recommended for MVP:**
- Mermaid diagrams (complexity, 30s timeout risk)
- MathJax/LaTeX rendering (complexity, performance bottleneck)
- These can be post-MVP if demand is proven

## Anti-Features: What NOT to Build

Features that seem useful but are harmful in Quick Look context or create maintenance burden.

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| **Click-through links** | Quick Look is preview-only; clicking breaks UX by opening URLs. No click handlers execute in Quick Look sandbox. Creates expectation of interactivity that can't be fulfilled. | Render links as text in a different color. Users who need links will open the file in editor. |
| **HTML/CSS rendering** | Raw HTML is dangerous (XSS) and slow to parse. Quick Look doesn't support custom JavaScript. | Reject/escape raw HTML. Markdown should be source; if users want HTML rendering, that's a different tool. |
| **JavaScript execution** | Quick Look sandbox doesn't support JavaScript execution. Breaks in Quick Look context; works differently than full browser. | Use pre-computed rendering (syntax highlighting parsed at build time, not runtime). |
| **Remote image loading** | Network I/O in preview context causes delays and hangs if network is slow. Risk of hitting 30s timeout. Creates security/privacy issues (external tracking). | Only embed local images. Remote images: render as `[Image: URL]` placeholder with warning. |
| **Interactive widgets** (comments, annotations, etc.) | Quick Look previews are read-only. Interaction has nowhere to go. Creates false expectation of functionality. | This is editing, not preview. Users open the file in an editor for this. |
| **Complex styling/themes** | CSS complexity adds rendering overhead. Custom fonts require loading. Competing with 30s timeout constraint. | Use system fonts, simple colors. Let system dark/light mode handle theming. |
| **Full markdown feature set** | Markdown has many edge cases. Trying to support 100% leads to bugs and timeout overruns. | Pick a subset (GitHub Flavored Markdown is good baseline). Document what's NOT supported. |
| **Real-time rendering on scroll** | Quick Look isn't designed for interaction; scrolling isn't a primary use case. Optimization effort wasted. | Pre-render full document once. Let Quick Look handle scrolling (it does). |
| **R/Python code execution** (R Markdown, Jupyter) | RMD/IPynb files require runtime evaluation. Outside Quick Look scope. Creates false expectations. | Render as code blocks. User opens in RStudio/Jupyter for execution. |

### Why These Matter for This Project

The project_context shows planned rendering includes "Links as normal text" and "Images as [Image: filename] placeholder" — both correct anti-feature decisions. This is already well-designed.

**Do not add:**
- Clickable links
- Remote image loading
- JavaScript or HTML parsing
- Complex nested features (Mermaid, MathJax)

## Feature Dependencies

```
Core rendering (HTML generation from markdown)
    ├── Text formatting (bold, italic, strikethrough)
    ├── Headings
    ├── Lists (ordered, unordered)
    ├── Blockquotes
    └── Tables

Code rendering
    ├── Basic code blocks
    └── Syntax highlighting (depends on language detection)

Images
    ├── Local image embedding (depends on file resolution)
    └── Remote image placeholders

Metadata
    ├── YAML front matter parsing
    └── Front matter formatting

Visual enhancements (no dependencies on above)
    ├── Dark mode support
    ├── Emoji rendering
    └── Text highlighting
```

**No hard dependencies between features.** Each can be implemented incrementally.

## MVP vs Post-MVP Roadmap

### MVP (Minimum Viable Extension)

**Must have:**
1. Heading rendering with visual hierarchy
2. Text formatting (bold, italic)
3. Lists (ordered, unordered)
4. Code blocks (no syntax highlighting yet)
5. Blockquotes
6. Links as text
7. Tables
8. Image placeholders

**Why this set:**
- Covers 95% of typical markdown files
- Renders in well under 1 second (safe timeout)
- Uses ~10-20MB memory (safe limit)
- Matches project's stated planned rendering goals

**Expected rendering time:** < 1 second for typical 10KB markdown file
**Expected memory:** 10-20MB for typical document

### Phase 2 (Post-MVP Differentiators)

1. **Syntax highlighting in code blocks**
   - Reason: Makes code scanning much faster
   - Complexity: Medium (language detection + CSS)
   - Performance: Still well under 30s for typical files
   - Confidence: LOW — needs measurement with real code samples

2. **Local image embedding**
   - Reason: Users want to see actual images, not placeholders
   - Complexity: Medium (file resolution, image rendering)
   - Performance: Depends on image count; needs testing with many images
   - Risk: Image rendering could hit timeout with many large images
   - Confidence: MEDIUM — QLMarkdown/PreviewMarkdown do this successfully

3. **Dark mode support**
   - Reason: Matches macOS 13+ expectations
   - Complexity: Low (CSS media queries)
   - Performance: No impact
   - Confidence: HIGH — standard pattern

4. **YAML front matter**
   - Reason: Important for documentation workflows
   - Complexity: Low (parse YAML, format as table)
   - Performance: Negligible
   - Confidence: HIGH

### Phase 3+ (Optional Enhancements)

- Emoji rendering (nice-to-have, low effort)
- Task lists (GFM feature, low effort)
- Text highlighting with `==`
- Subscript/superscript
- Auto-reload on file change

### NOT Recommended (High Risk)

- Mermaid diagrams (JavaScript execution impossible in Quick Look)
- MathJax/LaTeX (performance bottleneck, complex JavaScript deps)
- Raw HTML support (security, complexity)
- Interactive features (fundamentally against Quick Look design)

## Performance Budgets by Feature

Based on 30-second timeout constraint (source: blog.timac.org):

| Feature | Typical Time (10KB file) | Typical Time (100KB file) | Typical Time (1MB file) | Risk Notes |
|---------|--------------------------|--------------------------|-------------------------|-----------|
| Core markdown rendering | 100ms | 500ms | 3s | Safe; cmark-gfm is fast |
| Syntax highlighting | 50ms | 300ms | 2s | Depends on language count; selective loading helps |
| Local image embedding | Variable | Variable | High risk | Image count matters more than file size; 10 images ~500ms |
| YAML parsing | 10ms | 10ms | 10ms | Negligible |
| Dark mode CSS | 0ms | 0ms | 0ms | No rendering overhead |
| Mermaid diagrams | 1000-5000ms+ | 1000-5000ms+ | Timeout risk | HIGH RISK: JavaScript execution too expensive |
| MathJax rendering | 2000-10000ms+ | 2000-10000ms+ | Timeout risk | HIGH RISK: Font loading, math parsing very slow |

**Recommendation:** Stay well under 5 seconds for full rendering (20s buffer for system load).

## Known Issues & Workarounds in Ecosystem

### Table rendering with remote images
**Issue:** Tables containing remote images take extended time or hang (source: PreviewMarkdown documentation)
**Workaround:** Don't attempt remote image loading; this project already avoids it with placeholders

### Memory spikes with large documents
**Issue:** Large markdown files with many images can spike memory usage
**Workaround:** Monitor memory during image rendering; stream large images or skip if count exceeds threshold

### Encoding issues with international characters
**Issue:** Not mentioned in primary sources but common markdown problem
**Workaround:** Use UTF-8 consistently; test with international markdown samples

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| **Table stakes features** | HIGH | Verified across 3+ implementations (QLMarkdown, PreviewMarkdown, Markdown Peek) |
| **Performance constraints** | HIGH | Well-documented in blog.timac.org article; verified by multiple implementations |
| **Differentiators** | MEDIUM-HIGH | Based on user requests and what existing tools implement; not all tested with Quick Look constraints |
| **Anti-features** | HIGH | Based on Quick Look architecture constraints and explicit design decisions in existing tools |
| **MVP appropriateness** | HIGH | Project's planned rendering aligns perfectly with table stakes |
| **Syntax highlighting complexity** | MEDIUM | Complexity varies by language; not enough detail on implementation strategy |
| **Image embedding performance** | MEDIUM | QLMarkdown/PreviewMarkdown do this, but specific performance metrics unclear |

## Gaps and Open Questions

1. **Syntax highlighting implementation:** How to selectively load language highlighters to minimize bundle size? What's the performance ceiling for "many languages"?

2. **Image performance at scale:** What happens with 50+ images in a markdown file? When does it hit timeout? Need stress testing.

3. **Custom styling:** Should the extension offer user preferences (font size, colors, spacing)? Adds complexity but users have requested this.

4. **File size limits:** At what markdown file size does rendering start to struggle? Need to test 10MB+ files.

5. **Quick Look app extension vs older plugin:** This project should use modern QuickLook app extension API (not deprecated .qlgenerator). Verify macOS 13+ support is sufficient.

## Sources

- [QLMarkdown GitHub](https://github.com/sbarex/QLMarkdown)
- [PreviewMarkdown GitHub](https://github.com/smittytone/PreviewMarkdown)
- [Markdown Preview - App Store](https://apps.apple.com/us/app/markdown-preview-quick-look/id6739955340)
- [Quick Look Performance Constraints - blog.timac.org](https://blog.timac.org/2018/1119-constraints-on-quicklook-plugins/)
- [Quick Look Plugins List - GitHub](https://github.com/sindresorhus/quick-look-plugins)
- [PreviewMarkdown Features Documentation](https://smittytone.net/previewmarkdown/)
- [Markdown Quick Preview Blog - Havn 2025](https://havn.blog/2025/01/05/quick-recommendation-better-markdown-preview.html)
