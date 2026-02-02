# Debug Session: Blockquote Line Rendering

**Date:** 2026-02-01
**Issue:** First 2 lines of 3-line blockquote are rendered together on one line instead of separately
**Test:** UAT Round 10, Test 14
**Severity:** Major

## Problem Statement

In the comprehensive.md test file (lines 55-58), we have a blockquote:
```markdown
> This is a blockquote.
> It can span multiple lines.
>
> And have multiple paragraphs.
```

The user reports that lines 1 and 2 ("This is a blockquote." and "It can span multiple lines.") are rendered together on one line instead of on separate lines.

## Investigation Steps

### Step 1: Understanding Markdown Structure

Looking at the markdown:
- Line 1: `> This is a blockquote.`
- Line 2: `> It can span multiple lines.`
- Line 3: `>`
- Line 4: `> And have multiple paragraphs.`

In standard markdown:
- Lines 1-2 form a single **paragraph** within the blockquote (no blank line between them)
- Line 3 is an empty line (creating a paragraph break)
- Line 4 starts a new **paragraph** within the blockquote

**Key Insight:** Lines 1-2 are part of the SAME paragraph in the blockquote, just soft-wrapped in the source.

### Step 2: Examining the Code

Looking at `MarkdownRenderer.swift`:

1. **Block Boundary Newlines** (lines 90-171):
   - `insertBlockBoundaryNewlines()` handles newlines BETWEEN different blocks
   - Uses `previousBlockIdentity` to detect when block identity changes
   - For blockquotes, this would only trigger between different blockquote blocks, not within

2. **Intra-Block Newlines** (lines 176-221):
   - `ensureIntraBlockNewlines()` is supposed to handle newlines WITHIN blocks
   - Lines 199-211 show the blockquote logic:
   ```swift
   if isBlockquote {
       if previousBlockquoteIdentity != nil && previousBlockquoteIdentity != currentBlockquoteIdentity {
           let runText = String(attributedString[run.range].characters)
           if !runText.hasSuffix("\n") {
               insertionPositions.append(run.range.upperBound)
               ...
           }
       }
       previousBlockquoteIdentity = currentBlockquoteIdentity
   }
   ```

**HYPOTHESIS 1:** The code only inserts newlines when blockquote identity CHANGES (line 200). Lines 1-2 of the blockquote are the SAME paragraph, so they have the SAME identity and no newline is inserted.

### Step 3: Understanding PresentationIntent for Blockquotes

The swift-markdown AttributedString parser treats:
- Continuous lines in a blockquote (without blank lines) as a single paragraph
- Each paragraph gets a unique `identity` value in the `blockQuote` component

So for our test case:
- "This is a blockquote.\nIt can span multiple lines." → One paragraph, one identity
- "And have multiple paragraphs." → Different paragraph, different identity

The current code logic in `ensureIntraBlockNewlines()`:
- Only inserts newline when identity CHANGES
- Does NOT handle soft line breaks WITHIN the same paragraph

### Step 4: Hypothesis Formation

**ROOT CAUSE HYPOTHESIS:**
The `ensureIntraBlockNewlines()` function only inserts newlines at paragraph boundaries (when blockquote identity changes), not at soft line breaks within the same paragraph.

Lines 1-2 of the blockquote are a single paragraph (same identity), so:
1. Native AttributedString parsing keeps them as one continuous text run (with a newline/soft break character between them)
2. `ensureIntraBlockNewlines()` doesn't insert a newline because the identity doesn't change
3. The soft break character is not being preserved or rendered as a line break

### Step 5: Testing the Hypothesis

Let me check what happens to soft breaks in blockquotes. Looking at the code flow:

1. Line 46: `AttributedString(markdown: preprocessedMarkdown)` - parses the markdown
2. Line 54: `insertBlockBoundaryNewlines()` - inserts newlines between blocks
3. Line 57: `ensureIntraBlockNewlines()` - inserts newlines within blocks
4. Line 60: Converts to NSMutableAttributedString

**Question:** What happens to the newline character between "blockquote." and "It can span"?

The markdown source has:
```
> This is a blockquote.
> It can span multiple lines.
```

When parsed by swift-markdown, this likely becomes:
- A single paragraph with text: "This is a blockquote.\nIt can span multiple lines."
- OR: "This is a blockquote. It can span multiple lines." (newline converted to space)

### Step 6: Examining Swift Markdown Behavior

Swift's markdown parser treats consecutive lines in a blockquote (without blank lines) as:
- A single paragraph
- Soft breaks (single newlines) are converted to spaces OR to SoftBreak inline elements

This is standard CommonMark behavior: consecutive lines in a paragraph are joined with spaces unless you use:
- Two trailing spaces + newline (hard break)
- Blank line (paragraph break)

**CRITICAL FINDING:**
In CommonMark/swift-markdown, this:
```
> This is a blockquote.
> It can span multiple lines.
```

Becomes a single paragraph: "This is a blockquote. It can span multiple lines." (single line of text with space, not newline)

The source file structure doesn't preserve the line break because it's a soft wrap!

### Step 7: Verifying Against Expected Behavior

The UAT test expects:
> "Lines within blockquote paragraph render on separate lines (e.g., lines 1-2 of 3-line blockquote should be on separate lines)"

But the markdown structure treats lines 1-2 as:
- Same paragraph (soft-wrapped in source)
- Should be flowed together (standard markdown behavior)

**CONFLICT DETECTED:**
The test expectation conflicts with standard markdown rendering behavior!

However, let me reconsider: The test says "3-line blockquote" - maybe it's counting:
1. "This is a blockquote. It can span multiple lines."
2. (empty line)
3. "And have multiple paragraphs."

OR the user's interpretation might be different.

### Step 8: Re-examining the User Report

User report: "fail. first 2 lines of the 3 line blockquote are rendered together on one line"

If the user sees 3 lines as:
1. "This is a blockquote."
2. "It can span multiple lines."
3. "And have multiple paragraphs."

Then they expect line 1 and 2 to be separate. But in the markdown source, there's NO blank line between them, so they're part of the same paragraph!

**WAIT** - Let me check if swift-markdown preserves SoftBreak elements...

### Step 9: Checking for SoftBreak Handling

Looking at the inline node types in swift-markdown, there's a `SoftBreak` type. This represents newlines within a paragraph that should be preserved.

The question is: Does AttributedString preserve these, and if so, how?

When using `AttributedString(markdown:)`, soft breaks might be:
1. Converted to actual newline characters in the string
2. Lost (converted to spaces)
3. Preserved as some attribute

Looking at the code, I don't see any handling of SoftBreak inline elements!

### Step 10: Root Cause Identification

**ROOT CAUSE:**
The code does not handle SoftBreak inline elements within blockquote paragraphs.

When swift-markdown parses:
```
> This is a blockquote.
> It can span multiple lines.
```

It creates:
- One blockquote with one paragraph containing:
  - Text: "This is a blockquote."
  - SoftBreak
  - Text: "It can span multiple lines."

The AttributedString might preserve this as newline characters OR convert to spaces. Either way, our code:
1. Does NOT explicitly look for or preserve soft breaks within paragraphs
2. The `ensureIntraBlockNewlines()` only works on paragraph boundaries (identity changes)
3. Block boundary logic doesn't apply (same block)

**Evidence:**
1. Lines 176-221 of MarkdownRenderer.swift: `ensureIntraBlockNewlines()` only inserts newlines when blockquote identity changes (different paragraphs)
2. No code handles intra-paragraph line breaks (soft breaks)
3. Standard AttributedString parsing may collapse soft breaks to spaces

**Verification Needed:**
Need to check what the AttributedString actually contains after parsing - does it have a newline character between the two sentences, or a space?

### Step 11: VERIFICATION - Testing AttributedString Output

Created a test script to parse the exact markdown and inspect the AttributedString:

**Input:**
```markdown
> This is a blockquote.
> It can span multiple lines.
>
> And have multiple paragraphs.
```

**Output:**
```
String: 'This is a blockquote. It can span multiple lines.And have multiple paragraphs.'

Runs:
Run: 'This is a blockquote.'
  Intent components:
    - paragraph (id: 2)
    - blockQuote (id: 1)
Run: ' '
  Intent components:
    - paragraph (id: 2)
    - blockQuote (id: 1)
Run: 'It can span multiple lines.'
  Intent components:
    - paragraph (id: 2)
    - blockQuote (id: 1)
Run: 'And have multiple paragraphs.'
  Intent components:
    - paragraph (id: 3)
    - blockQuote (id: 1)
```

**CRITICAL FINDINGS:**

1. **Soft break becomes SPACE**: The newline between "blockquote." and "It can span" is converted to a SPACE character, not a newline
2. **Three separate runs**: The first paragraph is split into THREE runs:
   - Run 1: "This is a blockquote."
   - Run 2: " " (single space)
   - Run 3: "It can span multiple lines."
3. **Same paragraph identity**: All three runs have the same paragraph identity (id: 2)
4. **No newline between paragraphs**: The second paragraph "And have multiple paragraphs." directly follows with no newline separator (paragraph id: 3)

This is STANDARD CommonMark behavior - soft breaks (single newlines in source) are converted to spaces.

**HOWEVER**, the user expectation is that these should render on separate lines!

## Conclusion

**ROOT CAUSE FOUND:**

Swift's AttributedString markdown parser follows CommonMark specification and converts soft breaks (single newlines within a paragraph) to SPACE characters. The blockquote in the test file:

```markdown
> This is a blockquote.
> It can span multiple lines.
```

Is parsed as a single paragraph with a space between the sentences, creating three runs:
1. "This is a blockquote."
2. " " (space)
3. "It can span multiple lines."

All three runs have the same blockquote identity (id: 1) and paragraph identity (id: 2), so the `ensureIntraBlockNewlines()` function sees them as one continuous paragraph and does NOT insert any newlines.

**The Issue:**
The user's expectation is that each source line in a blockquote should render on a separate line, but CommonMark treats consecutive lines as a single flowed paragraph (like HTML `<p>` behavior).

**Design Conflict:**
There's a mismatch between:
- CommonMark spec behavior (soft breaks → spaces, flow text together)
- User expectation (preserve source line breaks in blockquotes)

**Files Involved:**
- `MarkdownRenderer.swift` lines 176-221: `ensureIntraBlockNewlines()` only handles paragraph boundaries (identity changes), not soft breaks within paragraphs
- AttributedString markdown parser: Converts soft breaks to spaces per CommonMark spec

### Step 12: Understanding SoftBreak vs LineBreak

Examined the swift-markdown source code:

**SoftBreak.swift (line 38-40):**
```swift
var plainText: String {
    return " "
}
```

**LineBreak.swift (line 38-40):**
```swift
var plainText: String {
    return "\n"
}
```

This confirms:
- **SoftBreak** (single newline in source) → converted to SPACE in output
- **LineBreak** (two trailing spaces + newline, or `<br>` in HTML) → converted to NEWLINE in output

This is standard CommonMark behavior and intentional.

## Root Cause Summary

**DEFINITIVE ROOT CAUSE:**

The gap exists because of a design mismatch between CommonMark specification and user expectations:

1. **CommonMark Behavior (Current):**
   - Consecutive lines in a blockquote without blank lines form ONE paragraph
   - Soft breaks (single newlines) are converted to spaces
   - This is standard markdown behavior (same as GitHub, Stack Overflow, etc.)

2. **User Expectation:**
   - Each source line in a blockquote should render on its own line
   - Preserving visual structure from source

3. **Code Implementation:**
   - `AttributedString(markdown:)` follows CommonMark spec correctly
   - Soft breaks become space characters
   - `ensureIntraBlockNewlines()` only handles paragraph boundaries, not soft breaks
   - No mechanism exists to override CommonMark soft break behavior for blockquotes

**Suggested Fix Direction:**

To meet user expectations while preserving markdown semantics, we should:

1. **Pre-process markdown before parsing**: Detect blockquote lines and convert soft breaks to hard breaks
   - Replace `>\n>` patterns with `>  \n>` (two trailing spaces create hard break)
   - This works with CommonMark spec rather than against it
   - Simple regex-based solution before AttributedString parsing

2. **Alternative: Use swift-markdown parser directly**:
   - Parse markdown with full Markdown library (not AttributedString)
   - Walk the AST and detect SoftBreak elements within BlockQuote contexts
   - Replace SoftBreak with LineBreak for blockquotes only
   - Then convert to AttributedString

3. **Not recommended: Post-process AttributedString**:
   - Would require heuristics to detect which spaces were soft breaks
   - Too fragile and unreliable

**Recommended approach: Option 1 (pre-processing)** - it's the simplest, most reliable, and works with the existing CommonMark infrastructure.
