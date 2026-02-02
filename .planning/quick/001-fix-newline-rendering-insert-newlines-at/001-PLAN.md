---
type: quick
plan: 001
files_modified:
  - md-spotlighter/MDQuickLook/MarkdownRenderer.swift
autonomous: true
estimated_context: 30%

must_haves:
  truths:
    - "Headings have line breaks before/after"
    - "List items appear on separate lines"
    - "Paragraphs are visually separated"
    - "Code blocks retain existing behavior"
  artifacts:
    - path: "md-spotlighter/MDQuickLook/MarkdownRenderer.swift"
      provides: "Block boundary newline insertion"
      contains: "insertBlockBoundaryNewlines"
  key_links:
    - from: "MarkdownRenderer.render()"
      to: "insertBlockBoundaryNewlines()"
      via: "Called before NSAttributedString conversion"
      pattern: "insertBlockBoundaryNewlines"
---

<objective>
Fix newline rendering by inserting newlines at block boundaries in MarkdownRenderer.

Purpose: AttributedString(markdown:) strips inter-block newlines, causing all text to run together. Block structure is preserved via PresentationIntent attributes, but these don't translate to visual line breaks when converted to NSAttributedString.

Output: MarkdownRenderer that correctly separates headings, paragraphs, list items, and other block elements with newlines.
</objective>

<context>
@md-spotlighter/MDQuickLook/MarkdownRenderer.swift

**Root Cause Analysis:**
1. `AttributedString(markdown:)` parses markdown and represents block structure via `PresentationIntent` attributes
2. When converting to `NSAttributedString`, PresentationIntent is available but newline characters between blocks are NOT preserved
3. The `render()` method converts directly: `NSMutableAttributedString(attributedString)` - no newline insertion
4. Result: All blocks run together except code blocks (which preserve internal newlines)

**Solution Approach:**
1. Before converting to NSAttributedString, iterate through AttributedString runs
2. Track the previous run's PresentationIntent
3. When PresentationIntent changes (new block), insert newline at boundary
4. Skip insertion for first run and consecutive runs within same block
</context>

<tasks>

<task type="auto">
  <name>Task 1: Add block boundary newline insertion to MarkdownRenderer</name>
  <files>md-spotlighter/MDQuickLook/MarkdownRenderer.swift</files>
  <action>
Add a new private method `insertBlockBoundaryNewlines(in:) -> AttributedString` that:

1. Creates a mutable copy of the input AttributedString
2. Iterates through runs tracking previous PresentationIntent
3. When a run has a DIFFERENT PresentationIntent than previous (block boundary):
   - Insert "\n" character at the start of that run's range
   - Use AttributedString's insert/replaceSubrange API
4. Handle edge cases:
   - First run: no insertion needed
   - Runs with NO PresentationIntent: treat as paragraph (normal text)
   - Consecutive runs with SAME intent ID: no insertion (same block)
   - Code blocks: already have internal newlines, but need boundary newlines

Key implementation detail: PresentationIntent has an `identity` property (Int) that uniquely identifies each block instance. Compare identities, not just component types.

Call this method in `render()` BEFORE the `NSMutableAttributedString(attributedString)` conversion:

```swift
// After: guard let attributedString = try? AttributedString(...)
// Add:
let withNewlines = insertBlockBoundaryNewlines(in: attributedString)
// Then convert withNewlines instead of attributedString
```
  </action>
  <verify>
Build with `make build` - should compile without errors.
Test by previewing a markdown file with multiple block elements (headings, paragraphs, lists).
  </verify>
  <done>
- Headings appear on their own lines with separation from following content
- List items appear on separate lines
- Paragraphs have visual separation
- Code blocks still render correctly (preserve internal newlines, have boundary separation)
  </done>
</task>

</tasks>

<verification>
1. `make build` succeeds
2. Preview test markdown file containing:
   - Multiple headings (h1, h2, h3)
   - Regular paragraphs
   - Unordered and ordered lists
   - Code blocks
   - Blockquotes
3. Each block element appears on its own line(s)
4. No text runs together inappropriately
</verification>

<success_criteria>
- Build succeeds without errors
- Block elements (headings, paragraphs, lists, code, blockquotes) are visually separated
- Existing styling (fonts, colors, indentation) is preserved
- Code blocks maintain their internal newline structure
</success_criteria>

<output>
After completion, update .planning/STATE.md to note the fix.
No SUMMARY.md needed for quick plans.
</output>
