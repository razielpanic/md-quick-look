# Feature Landscape: v1.2 Rendering Polish

**Domain:** macOS Quick Look markdown rendering improvements
**Researched:** 2026-02-05
**Scope:** 5 specific features: Quick Look window sizing, preview pane behavior, table rendering in narrow spaces, YAML front matter, GFM task list checkboxes

## Executive Summary

v1.2 focuses on rendering polish -- making the existing Quick Look extension work well across different display contexts and adding two commonly-expected markdown features. Research reveals that the most impactful work is adapting to varying view widths (preview pane vs spacebar vs full screen), since the same QLPreviewingController serves ALL Quick Look contexts. Tables and content must gracefully handle widths ranging from ~250px (Finder preview pane) to full-screen. YAML front matter and task list checkboxes are well-understood features with clear user expectations and moderate implementation complexity given the existing architecture.

## Feature 1: Quick Look Window Sizing

### How It Works

The Quick Look system uses `QLPreviewingController` which is a standard `NSViewController`. The extension's view controller is loaded into different host contexts:

- **Spacebar preview**: Default window starts at approximately 800x600. Users can resize by dragging. The system remembers the last-used size.
- **Full screen**: User clicks the expand button in the Quick Look window. View fills the screen.
- **Finder preview pane**: Narrow column on the right side of Finder. Width varies from ~250px to ~400px depending on user column resizing.
- **Spotlight**: Small inline preview.
- **Open/Save dialogs**: Preview panel in file dialogs.

The controller can set `preferredContentSize` to hint at an ideal size, but there are caveats:

| Aspect | Detail | Confidence |
|--------|--------|------------|
| Default size | ~800x600 for spacebar preview | MEDIUM (based on forum reports, not official docs) |
| `preferredContentSize` | Works on macOS 11+ (Big Sur); broke autoresizing on Catalina | MEDIUM (Apple Developer Forums) |
| User resize | System allows drag-to-resize; remembers last size | HIGH (standard macOS behavior) |
| `defaults write` | Users can customize via `defaults write -g QLPreviewWidth/QLPreviewHeight` | HIGH (documented by multiple sources) |

### Table Stakes

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| Content fills available width | Text should reflow to match window width, not leave huge margins or clip | Low | Existing `autoresizingMask: [.width, .height]` already handles this |
| Vertical scrolling works at any size | Content taller than view must scroll cleanly | Low | Already implemented via NSScrollView |
| No horizontal scrollbar for text content | Body text, headings, lists, blockquotes should never cause horizontal scroll | Low | Already implemented (`hasHorizontalScroller = false`) |

### Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Set `preferredContentSize` to hint initial size | Clean initial presentation | Low | Wrap in `#available(macOS 11, *)` guard; use something like 700x500 to leave comfortable margins |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Fixed pixel widths for content | Breaks at different window sizes |
| Overriding system resize behavior | Users expect standard macOS window resize |

### Current State Assessment

The existing code at `PreviewViewController.swift:16` sets `NSRect(x: 0, y: 0, width: 800, height: 600)` for the initial view frame. This is reasonable. The scroll view uses `autoresizingMask: [.width, .height]` and the text container uses `widthTracksTextView = true`, meaning text already reflows on resize. **This feature is largely already working.** The main v1.2 work is ensuring it works well at extreme sizes (very narrow, very wide).

---

## Feature 2: Finder Preview Pane Behavior

### How It Works

The Finder "Show Preview" pane (View > Show Preview, or the rightmost column in Column View) uses the SAME `QLPreviewingController` extension. There is no separate API or separate method called. The system loads the extension's view controller into a narrow container.

Key characteristics:

| Aspect | Detail | Confidence |
|--------|--------|------------|
| Same controller | `preparePreviewOfFile(at:completionHandler:)` is called identically | HIGH (confirmed by smittytone blog and WWDC 2018/2019 sessions) |
| Width range | ~250px to ~400px, user-adjustable by dragging column divider | MEDIUM (based on user reports; no official pixel measurements) |
| Height | Matches the Finder window height minus chrome | MEDIUM |
| All contexts | Same view also used in Spotlight, Open/Save dialogs | HIGH (WWDC 2019 session 719) |
| Content density | Most markdown Quick Look extensions render the same way regardless of pane width, relying on text reflow | HIGH (observed in QLMarkdown, PreviewMarkdown) |

### How Other Quick Look Extensions Handle It

Most markdown Quick Look extensions do NOT do anything special for the preview pane:

1. **QLMarkdown**: Uses WebView-based rendering. HTML/CSS handles reflow naturally. Tables can overflow.
2. **PreviewMarkdown**: Also WebView-based. Relies on CSS to reflow. Offers a "whitespace margin" preference that adds padding.
3. **Text-based extensions** (e.g., source code viewers): Use monospace text in NSTextView. Long lines simply clip or wrap depending on configuration.

The common pattern: **trust text reflow and test at narrow widths.** No special-casing for preview pane vs spacebar.

### Table Stakes

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| Text reflows at narrow width | Readable at ~250px width | Low | `widthTracksTextView = true` already handles this |
| No visual breakage | No overlapping elements or clipped content at narrow width | Medium | Need to verify: heading font sizes, list indentation, code block widths, blockquote decorations |
| Proportional padding | 20px inset looks fine at 800px but might be too much at 250px | Low-Medium | May want to reduce `textContainerInset` at narrow widths |

### Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Adaptive text insets | Smaller padding at narrow widths so more content is visible | Medium | Detect view width in `viewDidLayout` or `viewWillLayout`, adjust `textContainerInset` |
| Compact font sizing at narrow width | Slightly smaller body text in preview pane context | Medium | Could detect narrow context and reduce `bodyFontSize` slightly; but may be over-engineering |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Detecting "preview pane" vs "spacebar" explicitly | No reliable API to distinguish contexts; fragile |
| Hiding content at narrow widths | Users expect to see all content; removing elements is confusing |
| Horizontal scrolling for body text | Terrible UX in a narrow pane |

### Recommendation

The primary work is **testing and fixing edge cases at narrow widths**, not building a separate "narrow mode." Specific items to test:

1. Heading font sizes at 250px width -- h1 at 32pt may look oversized
2. List indentation (currently 20px first-line + 30px hanging) -- may consume too much width
3. Code block indentation (10px) and `textContainer.width - 40` padding
4. Blockquote decorations (4px bar + 12px offset + 20px indent = 36px consumed)
5. Table rendering (see Feature 3)

---

## Feature 3: Table Rendering in Narrow Spaces

### How Other Markdown Renderers Handle It

Tables are the hardest element to make work at narrow widths. Common approaches:

| Approach | How It Works | Used By | Pros | Cons |
|----------|-------------|---------|------|------|
| **Horizontal scroll** | Wrap table in scrollable container; table keeps natural width | Jekyll, Hugo (CSS `overflow-x: auto`), GitHub | Tables stay readable; familiar pattern | Requires scroll gesture; may not be discoverable |
| **Column compression** | Reduce column widths proportionally until minimum hit | QLMarkdown (HTML tables) | No scrolling needed | Content truncated or wrapped aggressively |
| **Truncation with ellipsis** | Truncate cell content with "..." | Current MD Quick Look TableRenderer | Clean visual; prevents overflow | Loses information |
| **Word wrap in cells** | Allow cell content to wrap to multiple lines | Most HTML renderers by default | Shows all content | Tables become very tall; messy appearance |
| **Responsive stacking** | Stack columns vertically at narrow widths | Some web frameworks (Bootstrap) | Works on mobile | Terrible for data comparison; confusing |

### Current State in This Project

The existing `TableRenderer.swift` uses:
- `fixedLayoutAlgorithm` with absolute-value column widths
- Content-based column width measurement (measures text, adds 32pt padding)
- Min width: 60pt, Max width: 300pt per column
- Total table max: 800pt (scales proportionally if exceeded)
- `lineBreakMode = .byTruncatingTail` (truncation with ellipsis)

**Problem at narrow widths:** A 3-column table with minimum 60pt columns = 180pt minimum. Add padding and the table may exceed the ~250px preview pane width. The `fixedLayoutAlgorithm` with absolute widths will cause the table to extend beyond the text view width, but since `hasHorizontalScroller = false`, the overflow is simply clipped.

### Table Stakes

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| Tables visible at narrow widths | At minimum, tables should not be completely clipped off-screen | Medium | NSTextTable layout changes |
| Cell content readable | At least column headers visible with some content | Medium | Column width scaling |
| No visual corruption | Table borders and alignment maintained | Low-Medium | Testing at various widths |

### Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Horizontal scroll for tables | Allow tables to scroll horizontally while body text wraps normally | High | Requires embedding a separate horizontal scroll view for table content; NSTextView does not natively support per-element horizontal scroll |
| Width-aware column sizing | Detect available width, adjust column min/max accordingly | Medium | Change `measureColumnWidths` to accept available width parameter; scale proportionally |
| Compact table mode at narrow width | Reduce font size and padding in tables when space is tight | Medium | Detect narrow context, use smaller font/padding values |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Responsive table stacking (vertical layout) | Confusing; loses tabular data comparison value |
| Hiding tables at narrow widths | Users need to see tables exist |
| Full horizontal scroll on the entire view | Breaks body text reading |

### Recommendation

**Use width-aware column sizing** (MEDIUM complexity, biggest payoff):

1. Pass available width (from text container) into `measureColumnWidths`
2. Scale `maxTableWidth` to match available width minus margins
3. Reduce `minColumnWidth` from 60pt to 40pt at narrow widths
4. Keep `byTruncatingTail` as the overflow strategy (already clean)
5. Reduce cell padding from 6pt to 4pt at narrow widths

This approach works within the existing `NSTextTable` architecture without needing a separate scroll view (which would be HIGH complexity and architecturally invasive).

For the `NSTextTable.LayoutAlgorithm`:
- **`fixedLayoutAlgorithm`** (current): Column widths are set explicitly. Good for predictable layout. Does NOT adapt to container width changes.
- **`automaticLayoutAlgorithm`**: Columns can resize based on content and container. May help with narrow views but is less predictable.

Recommendation: Stay with `fixedLayoutAlgorithm` but make the explicit widths responsive to the container width.

---

## Feature 4: YAML Front Matter

### What YAML Front Matter Is

A block of YAML metadata at the top of a markdown file, delimited by triple dashes:

```yaml
---
title: "My Document"
date: 2026-02-05
tags: [markdown, documentation]
draft: false
---
```

This is NOT rendered as markdown content. It is metadata used by static site generators, note-taking apps, and documentation tools.

### Common Fields Across Ecosystems

**Jekyll** (static site generator, popularized front matter):

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `title` | string | Page/post title | `title: "Getting Started"` |
| `date` | date | Publication date | `date: 2026-02-05` |
| `layout` | string | Template to use | `layout: post` |
| `permalink` | string | Custom URL path | `permalink: /about/` |
| `categories` | list/string | Content categories | `categories: [blog, tech]` |
| `tags` | list | Content tags | `tags: [swift, macos]` |
| `published` | boolean | Show/hide post | `published: false` |
| `excerpt` | string | Custom excerpt | `excerpt: "A brief intro..."` |

**Hugo** (static site generator):

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `title` | string | Page title | `title: "My Page"` |
| `date` | date | Creation date | `date: 2026-02-05T10:00:00` |
| `lastmod` | date | Last modified | `lastmod: 2026-02-05` |
| `draft` | boolean | Draft status | `draft: true` |
| `description` | string | Meta description | `description: "Page summary"` |
| `tags` | list | Taxonomy tags | `tags: ["go", "hugo"]` |
| `categories` | list | Taxonomy categories | `categories: ["tutorials"]` |
| `weight` | integer | Sort order | `weight: 10` |
| `slug` | string | URL slug override | `slug: "custom-url"` |
| `aliases` | list | Redirect paths | `aliases: ["/old-url/"]` |
| `summary` | string | Content summary | `summary: "A brief..."` |
| `type` | string | Content type | `type: "post"` |
| `keywords` | list | SEO keywords | `keywords: ["swift"]` |
| `expiryDate` | date | Content expiration | `expiryDate: 2027-01-01` |
| `publishDate` | date | Publish date | `publishDate: 2026-03-01` |

**Obsidian** (note-taking):

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `tags` | list | Note tags | `tags: [daily, project]` |
| `aliases` | list | Alternative names | `aliases: [nickname, abbrev]` |
| `cssclasses` | list | Custom CSS classes | `cssclasses: [wide-page]` |
| (custom) | any | User-defined properties | `status: in-progress` |

**GitHub Docs** (documentation):

| Field | Type | Purpose | Example |
|-------|------|---------|---------|
| `title` | string | Page title | `title: "API Reference"` |
| `intro` | string | Page introduction | `intro: "Learn about..."` |
| `versions` | object | Version applicability | `versions: fpt: '*'` |
| `redirect_from` | list | Redirect URLs | `redirect_from: ["/old"]` |

### Universal Front Matter Fields (Cross-Ecosystem)

These fields appear across nearly ALL ecosystems:

| Field | Universality | Notes |
|-------|-------------|-------|
| `title` | Extremely common | Present in Jekyll, Hugo, Hexo, Gatsby, Obsidian, Astro, Zola, Docusaurus |
| `date` | Very common | Creation/publication date; format varies (ISO 8601 most common) |
| `tags` | Very common | List of tags; used for taxonomy in SSGs, organization in note apps |
| `description` / `excerpt` / `summary` | Common | Different names, same purpose; brief content summary |
| `draft` / `published` | Common | Boolean; controls visibility (Jekyll uses `published: false`, Hugo uses `draft: true`) |
| `categories` | Common | Broader grouping than tags |
| `author` | Common | Not built-in to most SSGs but very widely used as custom field |
| `layout` / `template` | SSG-specific | Which template to render with |
| `slug` / `permalink` | SSG-specific | URL customization |

### How Other Tools Display Front Matter

| Tool | Display Approach | Visual Style |
|------|-----------------|--------------|
| **QLMarkdown** | Renders as table (when table extension enabled) or as code block | Table: key-value pairs in standard table. Code: monospaced YAML block |
| **PreviewMarkdown** | Optional display; toggled in preferences. Styled with customizable key color | Keys shown in configurable color; values in body text |
| **Obsidian** (v1.1+) | Properties panel at top of note; each field has its own widget (text input, tag pills, date picker) | Rich UI; NOT a code block; structured form-like display |
| **VS Code** (Markdown Preview) | Extension-dependent. Default: hidden. With extension: rendered as table or styled block | "markdown-yaml-preamble" extension shows as dimmed block at top |
| **GitHub** | Strips front matter from rendered markdown; not displayed to reader | Completely hidden |
| **Jekyll/Hugo** (when served) | Consumed by build process; never shown to reader | Used as data, not displayed |
| **DEVONthink** | Has no built-in YAML rendering; shows raw YAML text | Unstyled raw text |

### Table Stakes for a Quick Look Extension

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Detect and parse YAML block between `---` delimiters | Must correctly identify front matter vs horizontal rules | Low-Medium | Regex or simple string matching at file start |
| Display as visually distinct section | Must look different from body content (it IS metadata) | Low | Use different styling: lighter color, bordered section, or table format |
| Strip from body rendering | Front matter should not also appear as body text | Low | Remove `---..---` block before passing to `AttributedString(markdown:)` |
| Handle common value types | Strings, dates, booleans, lists | Low-Medium | YAML parsing; lists are the tricky part |

### Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| Render as styled key-value table | Clean, structured look | Medium | Reuse existing `TableRenderer` or build a simpler 2-column layout |
| Color-coded keys | Visual distinction between keys and values (like PreviewMarkdown) | Low | Different `.foregroundColor` for key column |
| Collapsible front matter | Show a summary line, expand to see all fields | High | Requires interactive UI; probably an anti-feature for Quick Look |
| List values rendered as comma-separated or tag pills | More readable than raw YAML list syntax | Medium | Parse arrays, format inline |

### Anti-Features for Front Matter

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Collapsible/interactive front matter | Quick Look is non-interactive |
| Editing front matter values | Read-only context |
| Rendering front matter as raw YAML code block | Misses opportunity for structured display |
| Interpreting front matter semantics | Don't try to use `layout` or `permalink` values; just display them |
| Nested YAML rendering | Deep nesting (objects within objects) is rare and complex to display; flatten or show as YAML string |

### Recommendation

**Render as a styled 2-column key-value section** at the top of the document:

1. Parse the `---` delimited block at the top of the file (MUST be first thing in file)
2. Parse YAML key-value pairs (use simple regex or a lightweight YAML parser)
3. Render as a visually distinct section:
   - Light background or bordered area
   - Key in bold or colored text (secondary label color)
   - Value in normal text
   - Lists shown as comma-separated values
4. Add a subtle separator between front matter and body content
5. Strip the raw YAML from the markdown before passing to the body renderer

**YAML Parsing Approach:** For a Quick Look context, do NOT pull in a full YAML parsing library. Front matter is typically flat key-value pairs. A simple line-by-line parser handles 95% of real-world front matter:

```
key: value          -> simple string
key: true/false     -> boolean
key: 123            -> number
key: [a, b, c]      -> inline list
key:                -> multiline list (next lines starting with -)
  - item1
  - item2
```

Deep nesting and YAML anchors/references can be displayed as raw text fallback.

---

## Feature 5: GFM Task List Checkboxes

### How They Work in Markdown

GFM task lists use list items with checkbox markers:

```markdown
- [ ] Unchecked task
- [x] Checked task
- [ ] Another unchecked task
```

These are a subset of unordered lists. The `[ ]` or `[x]` marker replaces the standard bullet.

### How They Render Visually

| Tool | Unchecked | Checked | Style |
|------|-----------|---------|-------|
| **GitHub** | Empty checkbox input (disabled) | Checked checkbox input (disabled) | Standard HTML `<input type="checkbox" disabled>`. Gray square with rounded corners |
| **VS Code Preview** | Empty checkbox | Filled checkbox | System checkbox styling |
| **Obsidian** | Empty circle/square | Filled with checkmark | Custom CSS; rounded checkbox; often with green/blue fill |
| **QLMarkdown** | HTML checkbox rendering | HTML checkbox rendering | WebView-based; standard HTML checkbox |
| **Pandoc** | Unicode ballot box | Unicode checked ballot box | Text-based: uses Unicode characters |

### Visual Approaches for NSAttributedString (Non-HTML)

Since this project uses `NSAttributedString` + `NSTextView` (not a WebView), HTML checkbox inputs are not available. Options:

| Approach | How | Pros | Cons |
|----------|-----|------|------|
| **Unicode characters** | Replace `[ ]` with empty ballot box, `[x]` with checked ballot box | Simple; no special rendering needed | Unicode characters may render inconsistently across fonts |
| **SF Symbols** | Use `NSTextAttachment` with SF Symbol images (`square`, `checkmark.square.fill`) | Native macOS look; crisp at any size; Dark Mode compatible | Requires `NSTextAttachment` insertion (already done for image placeholders) |
| **Custom drawing** | Draw checkbox in `MarkdownLayoutManager` | Full control over appearance | Complex; overkill for this |

**Recommended Unicode characters:**
- Unchecked: (U+2610 BALLOT BOX) or (U+25A1 WHITE SQUARE)
- Checked: (U+2611 BALLOT BOX WITH CHECK) or (U+2705 WHITE HEAVY CHECK MARK)

**Recommended SF Symbols (better):**
- Unchecked: `square` (SF Symbol)
- Checked: `checkmark.square.fill` (SF Symbol)

SF Symbols are the more "Mac-assed" approach and align with the project's design philosophy. The project already uses `NSTextAttachment` with SF Symbols for image placeholders, so the pattern is established.

### Implementation Path in This Codebase

The project uses two markdown parsing approaches:
1. **`AttributedString(markdown:)`** (Foundation) for most content -- this does NOT expose task list checkboxes. It parses `- [ ] text` as a regular list item with the literal `[ ]` in the text.
2. **`Document` from swift-markdown package** (used only for table extraction) -- this DOES support `ListItem.checkbox` property with `.checked` / `.unchecked` enum values.

**This means task list rendering requires either:**

a. **Pre-processing approach** (simpler): Before passing markdown to `AttributedString(markdown:)`, use regex to replace `- [ ] ` and `- [x] ` with marker text (like the image placeholder approach), then style the markers post-render.

b. **Hybrid approach** (more robust): Use the swift-markdown `Document` parser to detect task list items (via `ListItem.checkbox`), similar to how `TableExtractor` works for tables, then handle them in the hybrid rendering pipeline.

Option (a) is simpler and consistent with the existing image placeholder pattern. Option (b) is more architecturally sound but adds complexity to the rendering pipeline.

### Table Stakes

| Feature | Why Expected | Complexity | Depends On |
|---------|--------------|------------|------------|
| Visual checkbox (not raw `[ ]` text) | Users expect checkboxes to look like checkboxes | Low-Medium | Text preprocessing or AST-based extraction |
| Checked vs unchecked distinction | Must clearly see which tasks are done | Low | Different symbol/icon for each state |
| Aligned with list text | Checkbox should align with other list items | Low | Use same paragraph style as existing list items |

### Differentiators

| Feature | Value | Complexity | Notes |
|---------|-------|------------|-------|
| SF Symbol checkboxes | Native macOS appearance; crisp | Low-Medium | Reuse existing `NSTextAttachment` pattern from image placeholders |
| Checked items with strikethrough | Visual completion indicator beyond the checkbox | Low | Add `.strikethroughStyle` to checked item text |
| Checked items dimmed | Completed tasks visually de-emphasized | Low | Use `.secondaryLabelColor` for checked items |

### Anti-Features

| Anti-Feature | Why Avoid |
|--------------|-----------|
| Interactive/clickable checkboxes | Quick Look is read-only |
| Saving checkbox state | No write access; preview only |
| Task progress counting ("3/7 complete") | Over-engineering; not a project management tool |

### Recommendation

Use **SF Symbols via NSTextAttachment** (consistent with image placeholder pattern):
1. Pre-process markdown to detect `- [ ] ` and `- [x] ` patterns
2. Replace with marker text (e.g., `TASKUNCHECKED` / `TASKCHECKED`)
3. After rendering, replace markers with SF Symbol attachments
4. Use `square` for unchecked, `checkmark.square.fill` for checked
5. Optionally dim checked item text with `secondaryLabelColor`

---

## Feature Dependencies

```
Quick Look window sizing
    (no dependencies; existing autoresizing handles most cases)

Preview pane behavior
    depends on: Quick Look window sizing (verify narrow width behavior)
    depends on: Table rendering (tables most likely to break at narrow widths)

Table rendering in narrow spaces
    depends on: Existing TableRenderer.swift
    depends on: Understanding of available container width

YAML front matter
    depends on: Pre-processing before markdown rendering (like existing image preprocessing)
    (independent of other v1.2 features)

GFM task list checkboxes
    depends on: Pre-processing before markdown rendering (like existing image preprocessing)
    depends on: Existing list rendering pipeline (paragraph styles, indentation)
    (independent of other v1.2 features)
```

## Implementation Order Recommendation

1. **Quick Look window sizing + Preview pane behavior** (test and fix first)
   - Rationale: These are testing/verification phases that expose what breaks at narrow widths. Do this first so table work has clear requirements.

2. **Table rendering in narrow spaces** (fix what sizing tests reveal)
   - Rationale: Depends on understanding actual narrow-width behavior from step 1.

3. **YAML front matter** (independent; can be done in parallel)
   - Rationale: Self-contained feature with no dependencies on sizing work.

4. **GFM task list checkboxes** (independent; can be done in parallel)
   - Rationale: Self-contained feature following established preprocessing pattern.

Features 3 and 4 can be done in parallel with each other and potentially in parallel with feature 2.

## Complexity Summary

| Feature | Complexity | Risk | Notes |
|---------|-----------|------|-------|
| Quick Look window sizing | Low | Low | Mostly already working; verify edge cases |
| Preview pane behavior | Low-Medium | Low | Testing-focused; may need padding/indent adjustments |
| Table rendering in narrow spaces | Medium | Medium | NSTextTable behavior at narrow widths needs investigation; may need layout algorithm changes |
| YAML front matter | Medium | Low | Well-understood parsing; display is straightforward |
| GFM task list checkboxes | Low-Medium | Low | Follows established preprocessing pattern |

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Quick Look sizing behavior | MEDIUM | Apple docs are thin; behavior pieced together from forums and blogs |
| Preview pane is same controller | HIGH | Confirmed by WWDC sessions and smittytone blog |
| NSTextTable narrow width behavior | LOW | Apple docs do not describe overflow behavior; needs empirical testing |
| YAML common fields | HIGH | Verified across Jekyll, Hugo, Obsidian official docs |
| YAML display approaches | MEDIUM | QLMarkdown and PreviewMarkdown approaches confirmed; exact rendering details sparse |
| swift-markdown Checkbox support | HIGH | Confirmed: `ListItem.checkbox` property with `.checked` enum; HTMLFormatter source code verified |
| AttributedString task list support | HIGH | Confirmed NOT supported by Foundation's `AttributedString(markdown:)` |
| SF Symbol approach for checkboxes | HIGH | Already proven in this codebase for image placeholders |

## Sources

- [Apple Developer Forums: Setting preferredContentSize of Quick Look](https://developer.apple.com/forums/thread/673369) -- preferredContentSize caveats
- [smittytone blog: Create Previews macOS Catalina](https://blog.smittytone.net/2019/11/07/create_previews_macos_catalina/) -- Quick Look extension serves all preview contexts
- [WWDC 2019 Session 719: What's New in File Management and Quick Look](https://developer.apple.com/videos/play/wwdc2019/719/) -- QLPreviewView contexts
- [WWDC 2018 Session 237: Quick Look from the Ground Up](https://asciiwwdc.com/2018/sessions/237) -- Preview displayed in any QLPreviewView
- [Apple: Using Text Tables](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html) -- NSTextTable/NSTextTableBlock layout
- [NSTextTable.LayoutAlgorithm](https://developer.apple.com/documentation/appkit/nstexttable/layoutalgorithm) -- fixed vs automatic layout
- [Jekyll Front Matter docs](https://jekyllrb.com/docs/front-matter/) -- predefined front matter variables
- [Hugo Front Matter docs](https://gohugo.io/content-management/front-matter/) -- predefined front matter fields
- [Obsidian Properties docs](https://help.obsidian.md/properties) -- Obsidian frontmatter fields
- [QLMarkdown GitHub](https://github.com/sbarex/QLMarkdown) -- YAML front matter as table or code block
- [PreviewMarkdown features](https://smittytone.net/previewmarkdown/) -- YAML front matter display with customizable key colors
- [swift-markdown HTMLFormatter source](https://github.com/swiftlang/swift-markdown/blob/e62a44fd1f2764ba8807db3b6f257627449bbb8c/Sources/Markdown/Walker/Walkers/HTMLFormatter.swift) -- Checkbox enum: `.checked` state confirmed
- [swift-markdown ListItem.checkbox docs](https://swiftinit.org/docs/swift-markdown/markdown/listitem.checkbox) -- ListItem has optional Checkbox property
- [Apple Developer Forums: AttributedString markdown missing elements](https://developer.apple.com/forums/thread/701223) -- Foundation AttributedString markdown limitations
- [Jekyll horizontal scroll tables](https://talk.jekyllrb.com/t/create-horizontally-scrollable-tables-using-markdown-syntax/6805) -- CSS overflow-x approach
- [GitHub task lists blog](https://github.blog/news-insights/product-news/task-lists-in-gfm-issues-pulls-comments/) -- GFM task list specification
- [PyMdown Tasklist extension](https://facelessuser.github.io/pymdown-extensions/extensions/tasklist/) -- task list CSS styling patterns
