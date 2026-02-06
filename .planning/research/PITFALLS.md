# Domain Pitfalls: v1.2 Rendering Features

**Domain:** Quick Look extension enhancement (macOS 26+)
**Researched:** 2026-02-05
**Project Context:** MD Quick Look v1.2 -- adding preview pane support, YAML front matter, GFM task lists, responsive tables, and window sizing to existing NSTextView + MarkdownLayoutManager architecture
**Builds on:** v1.0/v1.1 pitfalls (see git history for original PITFALLS.md)

---

## Critical Pitfalls

Mistakes that cause rewrites, broken rendering, or user-visible failures across Quick Look contexts.

### Pitfall 1: preferredContentSize Breaks Auto-Resizing of Subviews

**What goes wrong:**
Setting `preferredContentSize` on the Quick Look view controller changes the initial window dimensions as intended, but then breaks all subsequent auto-resizing of subviews. The NSTextView and NSScrollView no longer track the preview window size when the user resizes manually or enters fullscreen. Content appears clipped or surrounded by dead space.

**Why it happens:**
Quick Look manages the preview window lifecycle externally. When you set `preferredContentSize`, the system treats it as a fixed constraint rather than an initial suggestion. The autoresizing masks (`[.width, .height]`) currently set on the NSScrollView in PreviewViewController compete with the preferredContentSize constraint. After the initial layout pass, the text view's frame no longer responds to window resizes because the system has locked the content area.

**Consequences:**
- Spacebar preview looks correct at first, but resizing the window leaves the text view stuck at original size
- Fullscreen mode shows content in a small rectangle instead of filling the screen
- Preview pane rendering breaks because the view cannot shrink below preferredContentSize
- User perception: "the preview is broken when I resize"

**Prevention:**
1. **Do not set preferredContentSize for text content.** Let Quick Look determine the window size naturally. The existing approach (800x600 initial frame with autoresizing masks) works correctly because it lets the system resize freely.
2. **If sizing hints are needed,** set them only once in `loadView()` or `viewDidLoad()`, never update them dynamically, and test that manual resize and fullscreen still work.
3. **Test all resize scenarios:** initial spacebar popup, manual drag-resize of popup, fullscreen toggle, and exit fullscreen. Verify NSTextView tracks the container at each transition.
4. **Use Auto Layout constraints instead of autoresizing masks** if you need more precise control -- but avoid mixing the two approaches.

**Detection:**
- Preview appears correct at first but breaks after any window resize
- Fullscreen shows content in a small centered rectangle
- `textView.frame` does not match `scrollView.contentSize` after resize

**Confidence:** HIGH -- Confirmed via Apple Developer Forums thread on preferredContentSize in QL extensions.

**Phase impact:** Window sizing feature -- address first before other layout work.

---

### Pitfall 2: Preview Pane Renders in Extremely Narrow Width Without Notice

**What goes wrong:**
Quick Look preview extensions are invoked in multiple contexts: spacebar popup (~800px wide), Finder preview pane in column view (~260-300px wide), Get Info panel (~200px), and Spotlight. The extension receives no explicit signal about which context it is running in. The same `preparePreviewOfFile(at:completionHandler:)` is called for all contexts, but `view.bounds` is dramatically different.

**Why it happens:**
The QLPreviewingController protocol provides no API to distinguish between presentation contexts. The view controller's `view.bounds` reflects the allocated space, but this value is set by the host (Finder/Spotlight), not by the extension. The current PreviewViewController creates an 800x600 initial frame in `loadView()`, which is then resized by the host. If the host provides a narrow frame (preview pane), the text view must adapt. The current code sets `textContainer.widthTracksTextView = true`, which should handle this, but the text container's initial width is calculated as `scrollView.contentSize.width - 40`, which may be computed before the host has set the final bounds.

**Consequences:**
- Tables with absolute widths (current TableRenderer uses `.fixedLayoutAlgorithm` with `absoluteValueType`) extend far beyond the visible area, creating horizontal overflow
- Content rendered at 800px width gets clipped to 260px with no horizontal scroll (current config: `scrollView.hasHorizontalScroller = false`)
- Text container width mismatch: initial width calculated from 800px frame, but actual display is 260px
- Blockquote borders and code block backgrounds drawn at wrong positions by MarkdownLayoutManager

**Prevention:**
1. **Override `viewDidLayout()` or `viewWillLayout()`** to detect actual available width after the host has set final bounds. Reconfigure text container width there.
2. **Test in all Quick Look contexts:** spacebar popup, Finder column view (View > as Columns with preview column enabled), Get Info panel, Spotlight. Use `qlmanage -p` for spacebar testing; manually test Finder column view.
3. **Make table rendering width-aware:** Pass actual available width to TableRenderer instead of using hardcoded 800px max. Switch from `.fixedLayoutAlgorithm` with absolute widths to percentage-based or automatic widths.
4. **Consider a minimum useful width threshold:** Below ~200px, show a simplified single-column fallback instead of trying to render tables.
5. **Defer final layout until `viewDidAppear()`** to ensure the host has provided final dimensions.

**Detection:**
- Open Finder in column view mode, enable "Show preview column" (View > Show View Options)
- Select a markdown file with tables -- if table extends beyond visible area, this pitfall is active
- Check Console.app for layout-related warnings from the extension

**Confidence:** HIGH -- The current code's hardcoded 800x600 frame and absolute table widths will definitely break in preview pane context. This is a structural issue visible in the existing source.

**Phase impact:** Preview pane support -- this is the primary challenge of the entire feature.

---

### Pitfall 3: NSTextTable Absolute Widths Overflow in Constrained Containers

**What goes wrong:**
The current TableRenderer uses `.fixedLayoutAlgorithm` with `absoluteValueType` column widths (measured from content). Tables that fit a spacebar popup (800px) overflow in the preview pane (260px), Get Info, or narrow Finder windows. Overflow content is invisible because `hasHorizontalScroller = false`.

**Why it happens:**
The current `measureColumnWidths` method measures text content and adds padding, with a max table width of 800pt. When this table is placed in a 260px text container, NSTextTable with `.fixedLayoutAlgorithm` does not shrink to fit -- it renders at the specified absolute width and overflows. The `.fixedLayoutAlgorithm` explicitly means "do not adjust widths based on available space." Meanwhile `hasHorizontalScroller = false` prevents users from scrolling to see clipped content.

**Consequences:**
- Table content silently clipped on the right side in narrow contexts
- No indication to user that content is missing
- Tables with many columns become completely unreadable

**Prevention:**
1. **Switch to percentage-based widths** for table columns. Use `.percentageValueType` instead of `.absoluteValueType`. Distribute column widths as percentages of the container width.
2. **Use `.automaticLayoutAlgorithm`** instead of `.fixedLayoutAlgorithm` to let NSTextTable calculate widths based on available space.
3. **Cap table total width to container width.** In the render method, accept a `availableWidth` parameter and constrain all calculations to it.
4. **For very narrow widths (<300px),** consider switching from NSTextTable to a stacked/linear format: each row shown as a block with "Header: Value" pairs instead of a grid.
5. **Enable horizontal scrolling as fallback** for tables that genuinely cannot fit, or wrap NSTextTable in a horizontally-scrollable sub-view.

**Detection:**
- Render a 5-column table and preview in Finder column view -- right columns will be invisible
- Check `textView.frame.width` vs total NSTextTable content width in logs
- Visual: table header visible but last columns cut off

**Confidence:** HIGH -- Direct code analysis of TableRenderer.swift confirms absolute widths with fixed layout algorithm. This will overflow in any context narrower than measured content width.

**Phase impact:** Responsive table rendering -- must be addressed before table feature is useful in preview pane.

---

### Pitfall 4: YAML Front Matter Parsed as ThematicBreak + Heading

**What goes wrong:**
YAML front matter delimited by `---` is misinterpreted by the markdown parser. The opening `---` becomes a ThematicBreak (horizontal rule), the key-value pairs become content or headings (keys with colons are interpreted as Setext-style headings), and the closing `---` becomes another ThematicBreak. Users see garbled content at the top of every file that uses front matter.

**Why it happens:**
Neither `AttributedString(markdown:)` nor Apple's swift-markdown library supports YAML front matter. This is by design -- YAML front matter is not part of the CommonMark spec or GFM spec. It is a convention popularized by Jekyll and adopted by tools like Hugo, Obsidian, and GitHub. The `---` delimiter is valid CommonMark syntax for a thematic break, so the parser interprets it literally.

Swift-markdown's GitHub issue #73 explicitly states this is not planned for inclusion, and recommends stripping front matter before parsing.

**Consequences:**
- Every markdown file with YAML front matter (extremely common in Jekyll, Hugo, Obsidian, Gatsby) displays a horizontal rule followed by garbled metadata at the top of the preview
- Keys with colons become styled as headings or bold text
- Multi-line YAML values create unpredictable rendering
- Users perceive the extension as broken for their "normal" markdown files

**Prevention:**
1. **Pre-strip front matter before passing to any parser.** Detect the pattern: file starts with `---\n`, find the next `---\n`, strip everything between (inclusive of delimiters).
2. **Use regex with anchoring:** The pattern must be anchored to the absolute start of the file. Only `---` on the very first line is front matter; `---` appearing later in the document is a legitimate thematic break.
   ```
   Pattern: ^---\n([\s\S]*?)\n---\n
   ```
3. **Handle edge cases in the stripper:**
   - File starts with `---` but has no closing `---` (malformed): show raw content, do not strip
   - Empty front matter (`---\n---\n`): strip silently
   - Front matter contains `---` within a YAML value: the first `\n---\n` after the opening delimiter is the closing; do not be greedy
   - File starts with whitespace/BOM before `---`: trim leading whitespace before checking
   - Windows line endings (`\r\n`): normalize line endings before pattern matching
4. **Optionally render front matter as a styled metadata block** rather than hiding it entirely. Display key-value pairs in a subtle gray box at the top.
5. **Never pass YAML content to `AttributedString(markdown:)`** -- even stripped YAML may contain markdown-like characters that parse incorrectly.

**Detection:**
- Create test files with front matter (Jekyll-style, Hugo-style, Obsidian-style) and verify preview does not show garbled metadata
- Test malformed front matter: missing closing `---`, empty front matter, front matter with markdown-like content
- Search Console.app for unexpected ThematicBreak parsing in first few lines

**Confidence:** HIGH -- Confirmed by swift-markdown GitHub issue #73 and direct testing that `---` parses as ThematicBreak.

**Phase impact:** YAML front matter feature -- must be implemented as a preprocessing step before any markdown parsing occurs.

---

### Pitfall 5: Task List Checkboxes Have No Native NSAttributedString Representation

**What goes wrong:**
GFM task list checkboxes (`- [ ]` and `- [x]`) have no native representation in `AttributedString(markdown:)`. The `AttributedString` markdown parser does not produce any checkbox-related attributes. If you pass task list markdown through the standard pipeline, the `[ ]` and `[x]` markers are either swallowed entirely or rendered as literal bracket text within list items, with no visual checkbox.

**Why it happens:**
Apple's `AttributedString(markdown:)` uses a CommonMark parser that does not support GFM task lists. The PresentationIntent system has `.listItem(ordinal:)` but no checkbox state. Meanwhile, the swift-markdown library (already in the project as a dependency for table extraction) DOES support task list checkboxes via `ListItem.checkbox` (an optional `Checkbox` enum with `.checked` and `.unchecked` cases), but this is a separate AST from `AttributedString`.

The current architecture uses two parallel parsing paths: `AttributedString(markdown:)` for the main pipeline and swift-markdown's `Document(parsing:)` for table extraction. Task list checkboxes exist only in the swift-markdown AST and must be bridged into the NSAttributedString output.

**Consequences:**
- Task lists render as regular unordered lists with no visual distinction
- `[ ]` and `[x]` markers either disappear or appear as literal text
- Users with TODO-heavy markdown files see no checkboxes
- The existing `insertListPrefixes` method in MarkdownRenderer inserts `"bullet "` for all unordered list items, overwriting any checkbox information

**Prevention:**
1. **Use swift-markdown AST to detect task list items.** Parse with `Document(parsing:)`, walk the tree for `ListItem` nodes, check `listItem.checkbox` property.
2. **Render checkboxes as NSTextAttachment with SF Symbols.** Use `checkmark.square` for checked and `square` for unchecked. This is the same pattern already used for image placeholders in the existing code.
3. **Bridge between the two parsing paths:** Parse once with swift-markdown to detect checkbox positions, then apply checkbox rendering during the `insertListPrefixes` phase.
4. **Handle baseline alignment carefully.** SF Symbol attachments in NSTextAttachment need their bounds adjusted with a negative `y` value to align with the text baseline. Without this, checkboxes float above or below the text line:
   ```swift
   attachment.bounds = CGRect(x: 0, y: -3, width: fontSize, height: fontSize)
   ```
5. **Preserve checkbox state in the prefix text.** Replace the `"bullet "` prefix with checkbox attachment + space for task list items.

**Detection:**
- Create markdown with `- [ ] unchecked` and `- [x] checked` items
- Verify visual distinction between checked and unchecked
- Check vertical alignment: checkbox icon should align with text baseline

**Confidence:** HIGH -- Direct code inspection of ListItem.swift confirms `Checkbox` enum exists in swift-markdown. Direct code inspection of MarkdownRenderer confirms `insertListPrefixes` unconditionally inserts bullet for unordered lists.

**Phase impact:** Task list checkbox feature -- requires bridging between swift-markdown AST and the NSAttributedString pipeline.

---

## Moderate Pitfalls

Mistakes that cause visual bugs, poor UX, or technical debt requiring significant rework.

### Pitfall 6: Text Container Width Calculated Before Host Sets Final Bounds

**What goes wrong:**
In `preparePreviewOfFile`, the text container size is calculated as `scrollView.contentSize.width - 40` (line 81 of PreviewViewController.swift). This calculation happens immediately during view setup, before the Quick Look host has resized the view to its final dimensions. In preview pane context, the view starts at 800x600 (from `loadView`) and is later resized to ~260px by Finder, but the text container retains the original ~760px width.

**Why it happens:**
The current code performs all setup synchronously in `preparePreviewOfFile`: creates scroll view, text container, text view, sets content, and calls handler. There is no mechanism to recalculate text container width after the host resizes the view. While `widthTracksTextView = true` should theoretically handle this, the text container size is the initial size at creation time. The `ensureLayout` call at the end forces a layout pass at the wrong width.

**Consequences:**
- In preview pane: text is laid out for ~760px but displayed in ~260px, causing horizontal clipping
- Long lines wrap at the wrong position
- Code blocks extend beyond visible area
- Blockquote backgrounds drawn at wrong width by MarkdownLayoutManager

**Prevention:**
1. **Move text container width calculation to `viewDidLayout()`.** Override this method to recalculate the container size based on actual view bounds.
2. **Do not call `ensureLayout` in `preparePreviewOfFile`.** Let the layout manager perform layout naturally when the view is actually displayed at its final size.
3. **Alternatively, set text container width to a very large value** and rely on `widthTracksTextView = true` to constrain it to the actual text view width at display time.
4. **Test with logging:** Add `os_log` in `viewDidLayout()` to confirm the view bounds received from the host, and compare with the text container width.

**Detection:**
- Add logging: `os_log("viewDidLayout bounds: %@", view.bounds)` and compare with initial 800x600
- In preview pane, check if text wraps at ~760px instead of ~260px

**Confidence:** HIGH -- Direct code analysis shows the width is computed from the initial 800x600 frame.

**Phase impact:** Preview pane support -- foundational fix needed before any narrow-width rendering works correctly.

---

### Pitfall 7: MarkdownLayoutManager Background Drawing Uses Hardcoded Offsets

**What goes wrong:**
The MarkdownLayoutManager draws blockquote borders at `origin.x + 4` and backgrounds starting at `origin.x + 12` with width `textContainer.containerSize.width - 24`. Code block backgrounds start at `origin.x + 8` with width `containerSize.width - 16`. These offsets assume a wide rendering context. In a narrow preview pane (~260px), the 24px total horizontal reduction is proportionally large (9% of width), and the absolute positioning of the vertical bar at x=4 may overlap with the text container inset.

**Why it happens:**
The hardcoded pixel offsets were designed for the spacebar popup width (~800px) where 24px of padding is visually appropriate. These values do not scale with container width.

**Consequences:**
- In narrow views, blockquote backgrounds may extend beyond the visible area or overlap with content
- Vertical bar positioning at x=4 may overlap with the text container's 20px inset
- Code block backgrounds may clip or look disproportionately padded

**Prevention:**
1. **Use proportional offsets** relative to container width, or at minimum, clamp offsets to not exceed a percentage of available width.
2. **Reduce insets for narrow contexts:** If container width < 400px, use smaller padding (e.g., 4px instead of 12px).
3. **Test in all contexts:** Verify blockquote and code block backgrounds look correct at both ~800px and ~260px widths.
4. **Consider using the text view's textContainerInset** as the reference point instead of hardcoded values.

**Detection:**
- Preview a file with blockquotes in Finder column view -- check if the blue bar and gray background render proportionally
- Compare appearance between spacebar popup and preview pane

**Confidence:** MEDIUM -- The hardcoded values are visible in code, but the actual visual impact at 260px width needs testing. The proportional impact may be acceptable.

**Phase impact:** Preview pane support -- cosmetic but important for polish.

---

### Pitfall 8: YAML Front Matter Stripping Breaks Document Source Ranges

**What goes wrong:**
The current table rendering uses source ranges from swift-markdown's AST to split the document into table and non-table segments (see `renderWithSourceRanges` in MarkdownRenderer.swift). If YAML front matter is stripped before parsing, all source range line numbers shift by the number of stripped lines. Tables are then extracted from the wrong line ranges, causing garbled output.

**Why it happens:**
The `renderWithSourceRanges` method uses `sourceRange.lowerBound.line` and `sourceRange.upperBound.line` to slice the original markdown string by line number. If N lines of front matter are stripped, all source ranges in the AST are relative to the stripped content, but the line array used for slicing is the original (pre-strip) content. The line numbers are off by N.

**Consequences:**
- Tables in documents with YAML front matter render with wrong content (offset by front matter line count)
- Non-table segments between tables contain table markdown instead of prose
- Garbled rendering that is hard to debug because it only occurs when front matter is present AND tables are present in the same document

**Prevention:**
1. **Strip front matter AND track the line offset.** Return both the stripped content and the number of lines removed from the front matter stripping function.
2. **Pass stripped content consistently.** After stripping, use the stripped content for ALL parsing paths: both `AttributedString(markdown:)` and `Document(parsing:)` for table extraction. Never mix pre-strip and post-strip content.
3. **Alternative approach:** Strip front matter, then pass the stripped content to both parsers. Source ranges from swift-markdown will be relative to the stripped content, and line-based slicing should also use the stripped content. Consistency eliminates the offset problem.
4. **Test the specific combination:** Document with front matter + table + non-table content after table.

**Detection:**
- Create a test file with YAML front matter followed by a GFM table, then paragraph text
- If table renders wrong content or the paragraph after the table includes table syntax, this pitfall is active
- Add logging: compare source range line numbers with actual line content

**Confidence:** HIGH -- Direct code analysis of `renderWithSourceRanges` shows it slices the original markdown string by line number. Front matter stripping will desynchronize these line numbers.

**Phase impact:** YAML front matter feature -- must be coordinated with existing table rendering pipeline.

---

### Pitfall 9: Checkbox NSTextAttachment Vertical Misalignment

**What goes wrong:**
SF Symbol images inserted via NSTextAttachment sit above or below the text baseline. Checkboxes appear to "float" relative to the task list text, creating an unprofessional appearance. The misalignment is more noticeable with larger or smaller font sizes.

**Why it happens:**
NSTextAttachment's default bounds place the image at the text baseline, but SF Symbols have their own internal baseline that does not match. On macOS specifically, NSTextAttachment requires an `attachmentCell` (conforming to `NSTextAttachmentCellProtocol`) for proper rendering -- simply setting `.image` on the attachment may not render at all on macOS without the cell, or may render with wrong alignment.

The existing image placeholder code (in `applyImagePlaceholderStyles`) uses `NSTextAttachment()` with `.image` set directly, which works because those placeholders are inline text elements. But for task list items, the checkbox replaces the list bullet prefix and needs precise baseline alignment with the list item text.

**Why it happens (macOS-specific):**
On macOS (unlike iOS), NSTextAttachment has an `attachmentCell` property. If you set `.image` without providing an attachment cell, the attachment may use a default cell that does not align correctly. The correct approach on macOS is to either:
- Set `attachment.bounds` with a negative y offset to shift the symbol down
- Create a custom `NSTextAttachmentCell` that properly computes the baseline

**Consequences:**
- Checkboxes visually misaligned with text -- looks amateurish
- Alignment varies across font sizes if using absolute pixel offsets
- May look correct at 14pt (current body size) but break if heading sizes change

**Prevention:**
1. **Compute y offset from font metrics:**
   ```swift
   let font = NSFont.systemFont(ofSize: bodyFontSize)
   let yOffset = (font.capHeight - symbolSize) / 2.0
   attachment.bounds = CGRect(x: 0, y: yOffset, width: symbolSize, height: symbolSize)
   ```
2. **Use `.baselineOffset` attribute** on the attachment's attributed string range to fine-tune vertical position.
3. **Test at multiple font sizes:** Verify alignment looks correct at 14pt body text and at heading sizes if task lists appear in different contexts.
4. **Use SF Symbol configuration with matching text style** to ensure the symbol scales with the font.

**Detection:**
- Visual inspection: checkbox icon should align with the center of the lowercase text (x-height), not sit above or below
- Screenshot comparison at different text sizes

**Confidence:** MEDIUM -- The macOS NSTextAttachment behavior is documented, but exact offset values require iterative testing. The existing image placeholder code provides a working pattern to follow.

**Phase impact:** Task list checkbox feature -- visual polish step after basic rendering works.

---

### Pitfall 10: `insertListPrefixes` Ordinal Tracking Does Not Distinguish Task Lists

**What goes wrong:**
The current `insertListPrefixes` method in MarkdownRenderer tracks `lastProcessedOrdinal` to avoid inserting duplicate prefixes for the same list item. It checks `isOrderedList` and `isUnorderedList` from PresentationIntent components. But PresentationIntent has no concept of task lists -- a task list item appears as a regular unordered list item. The method will insert a bullet (`"bullet "`) for every task list item, overwriting the checkbox.

**Why it happens:**
`AttributedString(markdown:)` does not parse GFM task lists. All list items are either ordered or unordered with no checkbox metadata in PresentationIntent. The checkbox information only exists in swift-markdown's AST (via `ListItem.checkbox`). The current architecture cannot distinguish task list items from regular unordered list items at the `insertListPrefixes` stage.

**Consequences:**
- If checkboxes are added as NSTextAttachment before `insertListPrefixes`, the method overwrites them with bullet prefixes
- If checkboxes are added after `insertListPrefixes`, the item already has a bullet that must be found and replaced
- Race condition between two systems that both want to control list item prefixes

**Prevention:**
1. **Pre-mark task list item ranges** using a custom NSAttributedString.Key (similar to `.blockquoteMarker` and `.codeBlockMarker` already in the project). During the swift-markdown parsing pass, identify task list items and mark their ranges with a `.taskListMarker` attribute containing the checked/unchecked state.
2. **Modify `insertListPrefixes` to skip marked ranges.** Check for `.taskListMarker` before inserting a bullet prefix. If present, insert checkbox attachment instead.
3. **Alternatively, integrate task list detection into the swift-markdown pass** that already runs for table extraction. Extend `TableExtractor` (or create a parallel walker) to also find task list items with their line positions.
4. **Be aware of index shifting.** Inserting checkbox attachments changes string indices. If task list detection and prefix insertion happen in separate passes, indices must be recalculated between passes. Process in reverse order (highest index first) to avoid invalidation.

**Detection:**
- Create markdown with mixed regular list items and task list items in the same list
- Verify regular items get bullets and task items get checkboxes, not both

**Confidence:** HIGH -- Direct code inspection of `insertListPrefixes` shows unconditional bullet insertion for all unordered list items.

**Phase impact:** Task list checkbox feature -- requires careful integration with existing list prefix system.

---

### Pitfall 11: Front Matter Regex Greedily Matches Code Blocks Containing `---`

**What goes wrong:**
A naive front matter stripping regex matches `---` delimiters that appear inside fenced code blocks. If a markdown file contains a code block showing front matter syntax as an example, the stripper removes content from the middle of the document.

**Why it happens:**
Front matter detection typically uses a regex like `^---\n([\s\S]*?)\n---\n`. While `^` anchors to the start of the file (limiting false positives for the opening delimiter), a more relaxed implementation might scan for `---` pairs throughout the document. Even with proper anchoring, if the file starts with actual front matter and a code block later contains `---`, a greedy match could extend the front matter region into the code block.

**Consequences:**
- Content between the front matter and a code block containing `---` is stripped from the preview
- Particularly dangerous for documentation files that show YAML/front matter examples in code blocks
- Silent data loss -- user sees missing content with no error

**Prevention:**
1. **Anchor strictly to byte 0.** The opening `---` must be the very first three characters of the file (after optional BOM/whitespace). Use `\A` anchor in regex (absolute start) rather than `^` (line start).
2. **Use non-greedy matching.** `([\s\S]*?)` with lazy quantifier stops at the FIRST `\n---\n` after the opening delimiter.
3. **Limit search scope.** Do not scan beyond the first 50 lines for the closing `---`. If not found within 50 lines, treat as malformed and do not strip.
4. **Do not use regex at all for this.** Instead, use simple string operations:
   ```
   if content starts with "---\n":
       find index of next "\n---\n" (or "\n---" at EOF)
       if found within first 50 lines:
           strip from 0 to end of closing delimiter
   ```
5. **Test with code blocks containing `---`:** Verify they are preserved.

**Detection:**
- Test file: front matter at top, then a code block with triple-dash syntax inside
- If the code block content disappears, the regex is too greedy

**Confidence:** HIGH -- This is a well-known pitfall in every front matter implementation. The gray-matter npm package lists this as a solved issue; Swift implementations must handle it explicitly.

**Phase impact:** YAML front matter feature -- edge case handling.

---

## Minor Pitfalls

Mistakes that cause visual inconsistencies or minor UX issues but are straightforward to fix.

### Pitfall 12: Empty YAML Front Matter Leaves Blank Space

**What goes wrong:**
Files with empty front matter (`---\n---\n`) or front matter followed by a blank line result in extra whitespace at the top of the rendered preview. The stripping removes the YAML delimiters but leaves behind leading newlines.

**Prevention:**
- After stripping front matter, trim leading whitespace/newlines from the remaining content before passing to the markdown parser.

**Confidence:** HIGH -- trivial string operation but easy to overlook.

**Phase impact:** YAML front matter feature -- cleanup step.

---

### Pitfall 13: Checked/Unchecked Checkbox Symbols Lack Sufficient Visual Contrast

**What goes wrong:**
Using SF Symbols `square` (unchecked) and `checkmark.square` (checked) at body font size (14pt) produces small icons where the visual distinction between states is subtle, especially in Dark Mode. Users cannot quickly scan a task list to see completion status.

**Prevention:**
1. **Use filled variants:** `checkmark.square.fill` for checked (green-tinted) and `square` for unchecked provides stronger contrast.
2. **Apply color:** Set `.foregroundColor` to `.systemGreen` for checked and `.secondaryLabelColor` for unchecked.
3. **Test in both Light and Dark Mode.** Verify contrast meets accessibility guidelines.
4. **Consider using `circle` and `checkmark.circle.fill`** instead of squares for better visual distinction at small sizes.

**Confidence:** MEDIUM -- depends on design preferences, but the default monochrome symbols at 14pt are objectively low contrast.

**Phase impact:** Task list checkbox feature -- visual design choice.

---

### Pitfall 14: Table `lineBreakMode = .byTruncatingTail` Hides Content Without Indication

**What goes wrong:**
The current TableRenderer sets `paragraphStyle.lineBreakMode = .byTruncatingTail` on all cells. In narrow contexts, this silently truncates cell content with an ellipsis. Users see "Feature Na..." and cannot access the full text. There is no tooltip or hover to reveal full content.

**Prevention:**
1. **Switch to `.byWordWrapping`** for narrow contexts where cell content would be truncated. This increases row height but shows all content.
2. **Keep `.byTruncatingTail`** only for wide contexts where columns have sufficient space.
3. **Adaptive approach:** Measure whether cell content fits at the given column width. If it fits, use truncation. If not, use wrapping.

**Confidence:** MEDIUM -- The current truncation behavior is intentional for wide contexts but problematic in narrow ones.

**Phase impact:** Responsive table rendering -- interaction between table width and content display.

---

### Pitfall 15: Windows-Style Line Endings in Front Matter Break Delimiter Detection

**What goes wrong:**
Markdown files created on Windows or with certain editors use `\r\n` line endings. Front matter detection looking for `---\n` fails because the actual sequence is `---\r\n`. The front matter is not stripped, and the YAML content appears as garbled text.

**Prevention:**
1. **Normalize line endings first.** Before any front matter detection, replace `\r\n` with `\n` and `\r` with `\n`.
2. **Apply normalization to the entire file content**, not just the front matter region, as the markdown parsers also expect consistent line endings.

**Confidence:** HIGH -- standard text processing pitfall that affects any line-based parsing.

**Phase impact:** YAML front matter feature -- preprocessing step.

---

### Pitfall 16: Mixed Task List and Regular List Items in Same List

**What goes wrong:**
A markdown list can contain both task list items and regular items:
```markdown
- [ ] Task item
- Regular item
- [x] Done item
```
If the task list detection is not item-by-item, it may treat the entire list as either all-tasks or all-regular, missing the mixed case.

**Prevention:**
1. **Process task list detection per-item, not per-list.** The swift-markdown AST provides `ListItem.checkbox` on individual items, not on the list as a whole. Check each item independently.
2. **The `insertListPrefixes` modification** must handle mixed lists: bullet for items with `checkbox == nil`, checkbox attachment for items with `.checked` or `.unchecked`.

**Confidence:** HIGH -- swift-markdown's API supports this naturally, but the integration must preserve per-item granularity.

**Phase impact:** Task list checkbox feature -- completeness requirement.

---

## Phase-Specific Warnings

| Phase/Feature | Likely Pitfall | Severity | Mitigation |
|---------------|---------------|----------|------------|
| Window Sizing | Pitfall 1: preferredContentSize breaks auto-resize | Critical | Do not set preferredContentSize; let system manage window size |
| Preview Pane | Pitfall 2: Narrow width without notice | Critical | Override viewDidLayout(), reconfigure text container width |
| Preview Pane | Pitfall 6: Text container width from initial frame | Critical | Defer width calculation to after host sets final bounds |
| Preview Pane | Pitfall 7: Hardcoded LayoutManager offsets | Moderate | Use proportional offsets or width-aware calculations |
| Responsive Tables | Pitfall 3: Absolute widths overflow | Critical | Switch to percentage-based widths or automatic layout |
| Responsive Tables | Pitfall 14: Truncation hides content | Minor | Use word wrapping in narrow contexts |
| YAML Front Matter | Pitfall 4: Parsed as ThematicBreak | Critical | Pre-strip before any parsing; anchor to file start |
| YAML Front Matter | Pitfall 8: Source ranges desynchronized | Moderate | Pass stripped content to ALL parsers consistently |
| YAML Front Matter | Pitfall 11: Greedy regex matches code blocks | Moderate | Use non-greedy match, limit search scope |
| YAML Front Matter | Pitfall 12: Empty front matter leaves whitespace | Minor | Trim leading whitespace after stripping |
| YAML Front Matter | Pitfall 15: Windows line endings | Minor | Normalize line endings before detection |
| Task List Checkboxes | Pitfall 5: No native AttributedString support | Critical | Bridge swift-markdown AST checkbox data into NSAttributedString |
| Task List Checkboxes | Pitfall 10: insertListPrefixes overwrites checkboxes | Moderate | Use custom attribute marker; modify prefix logic |
| Task List Checkboxes | Pitfall 9: Vertical misalignment | Moderate | Compute y offset from font metrics |
| Task List Checkboxes | Pitfall 13: Low contrast symbols | Minor | Use filled/colored SF Symbol variants |
| Task List Checkboxes | Pitfall 16: Mixed list items | Minor | Per-item checkbox detection, not per-list |

---

## Integration Dependency Map

The v1.2 features have ordering dependencies based on pitfall analysis:

```
YAML Front Matter Stripping (Pitfall 4, 8, 11)
  |
  v
Preview Pane Width Detection (Pitfall 2, 6)
  |
  +---> Responsive Table Rendering (Pitfall 3, 14)
  |       depends on: knowing available width
  |
  +---> LayoutManager Background Scaling (Pitfall 7)
  |       depends on: correct container width
  |
  v
Task List Checkboxes (Pitfall 5, 10, 9)
  |   can proceed independently but must integrate
  |   with existing list prefix system
  v
Window Sizing (Pitfall 1)
  |   must NOT break the above work
  v
Final integration testing across all Quick Look contexts
```

**Recommended phase ordering based on pitfall analysis:**
1. YAML front matter stripping -- preprocessing, affects all downstream parsing
2. Preview pane width detection -- foundational for responsive rendering
3. Responsive table rendering -- depends on width detection
4. Task list checkboxes -- independent but integrates with list system
5. Window sizing -- last, as it must not regress existing behavior

---

## Sources

- [Apple Developer Forums: Setting preferredContentSize of QL extension](https://developer.apple.com/forums/thread/673369) -- Confirmed auto-resize breakage
- [Apple Developer: NSTextTable Documentation](https://developer.apple.com/documentation/appkit/nstexttable) -- Layout algorithm types
- [Apple Developer: Using Text Tables (Archive)](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextLayout/Articles/TextTables.html) -- Absolute vs percentage value types
- [Apple Developer: widthTracksTextView](https://developer.apple.com/documentation/appkit/nstextcontainer/widthtrackstextview) -- Container width tracking behavior
- [swift-markdown GitHub Issue #73: YAML Front Matter](https://github.com/swiftlang/swift-markdown/issues/73) -- Confirmed no YAML support; "parsed as ThematicBreak followed by Heading level: 2"
- [swift-markdown ListItem.swift source](https://github.com/swiftlang/swift-markdown) -- Checkbox enum: `.checked` and `.unchecked`
- [GitHub: QLMarkdown Issue #76](https://github.com/sbarex/QLMarkdown/issues/76) -- Preview column requires separate Finder setting
- [GitHub: QLMarkdown](https://github.com/sbarex/QLMarkdown) -- Reference Quick Look markdown extension
- [GitHub: PreviewCode](https://github.com/smittytone/PreviewCode) -- Reference Quick Look extension for text content
- [gray-matter npm package](https://github.com/jonschlinkert/gray-matter) -- Front matter parsing edge cases and best practices
- [NSTextAttachment macOS vs iOS](https://bdewey.com/til/2023/08/21/nstextattachment-in-macos-vs-ios/) -- macOS-specific attachmentCell requirements
- [Apple Developer: baselineOffset](https://developer.apple.com/documentation/foundation/nsattributedstring/key/baselineoffset) -- Text attachment alignment
- [Apple Developer: NSTextTable.LayoutAlgorithm](https://developer.apple.com/documentation/appkit/nstexttable/layoutalgorithm) -- Fixed vs automatic layout
