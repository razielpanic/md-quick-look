---
phase: 02-core-markdown-rendering
plan: 01
type: summary
subsystem: rendering
completed: 2026-02-01
duration: 4min
status: complete

tags:
  - markdown
  - rendering
  - typography
  - PresentationIntent
  - AttributedString

requires:
  - 01-01
  - 01-02

provides:
  - MarkdownRenderer foundation
  - Heading visual hierarchy (h1-h6)
  - PresentationIntent transformation pattern
  - Inline formatting support (bold, italic, strikethrough)

affects:
  - 02-02
  - 02-03
  - 02-04

tech-stack:
  added:
    - AttributedString PresentationIntent API
    - NSMutableAttributedString for AppKit styling
  patterns:
    - PresentationIntent inspection for semantic structure
    - AttributedString to NSAttributedString conversion
    - Run-based attribute enumeration

key-files:
  created:
    - md-quick-look/MDQuickLook/MarkdownRenderer.swift
    - samples/headings.md
  modified:
    - md-quick-look/MDQuickLook/PreviewViewController.swift
    - md-quick-look/md-quick-look.xcodeproj/project.pbxproj

decisions:
  - slug: use-attributedstring-nsattributedstring-conversion
    decision: Convert AttributedString to NSMutableAttributedString for AppKit styling
    rationale: AttributedString font/color attributes are SwiftUI-specific; NSAttributedString needed for AppKit NSTextView
    alternatives: Direct AttributedString modification (fails with linker errors for SwiftUI symbols)
    impact: Clean separation between markdown parsing (AttributedString) and visual styling (NSAttributedString)
    date: 2026-02-01

  - slug: presentationintent-for-heading-detection
    decision: Use PresentationIntent.components to detect heading levels
    rationale: AttributedString(markdown:) preserves semantic structure via PresentationIntent
    alternatives: Heuristic detection via font size (unreliable), AST parsing (complex)
    impact: Reliable heading level detection, extensible to other block types
    date: 2026-02-01

  - slug: heading-font-sizes
    decision: "h1: 32pt, h2: 26pt, h3: 22pt, h4: 18pt, h5: 16pt, h6: 14pt"
    rationale: Clear visual hierarchy, matches common markdown renderers
    alternatives: Smaller sizes (less differentiation), exponential scaling (too dramatic)
    impact: Headings are immediately distinguishable in Quick Look preview
    date: 2026-02-01
---

# Phase 2 Plan 1: MarkdownRenderer Foundation Summary

**One-liner:** Custom markdown renderer with PresentationIntent transformation for heading hierarchy (h1 32pt → h6 14pt) and preserved inline formatting

## Objective Completed

Created MarkdownRenderer foundation that:
- Parses markdown using native `AttributedString(markdown:)`
- Transforms PresentationIntent semantic structure into visual styling
- Applies heading visual hierarchy with distinct font sizes (32pt to 14pt)
- Preserves inline formatting (bold, italic, strikethrough) from AttributedString
- Returns styled NSAttributedString for AppKit NSTextView rendering

## What Was Built

**MarkdownRenderer.swift (117 lines)**
- `render(markdown:) -> NSAttributedString` - Main public API
- PresentationIntent inspection to detect heading levels
- AttributedString → NSMutableAttributedString conversion
- AppKit-specific attribute application (NSFont, NSColor, NSParagraphStyle)
- OSLog debug logging for renderer operations

**Heading Hierarchy**
- h1: 32pt bold, 12pt spacing before/after
- h2: 26pt bold, 10pt spacing
- h3: 22pt bold, 8pt spacing
- h4: 18pt bold, 6pt spacing
- h5: 16pt bold, 4pt spacing
- h6: 14pt bold, 4pt spacing
- Body text: 14pt system font

**Integration**
- PreviewViewController updated to use `MarkdownRenderer().render(markdown:)`
- Removed direct `AttributedString(markdown:)` usage
- Xcode project updated to include MarkdownRenderer.swift in MDQuickLook target build

**Testing**
- Created samples/headings.md with all heading levels and inline formatting
- Extension builds and installs successfully
- Quick Look extension loads without errors

## Technical Implementation

### PresentationIntent Transformation Pattern

```swift
// 1. Parse markdown to get semantic structure
let attributedString = try AttributedString(markdown: markdown)

// 2. Convert to NSMutableAttributedString for AppKit styling
let nsAttributedString = NSMutableAttributedString(attributedString)

// 3. Iterate runs to find semantic elements
for run in attributedString.runs {
    guard let intent = run.presentationIntent else { continue }
    for component in intent.components {
        if case .header(let level) = component.kind {
            // 4. Apply AppKit attributes based on semantic level
            let nsRange = NSRange(run.range, in: attributedString)
            applyHeadingAttributes(to: nsAttributedString, range: nsRange, level: level)
        }
    }
}
```

**Why this works:**
- `AttributedString(markdown:)` preserves semantic structure via PresentationIntent
- PresentationIntent.components contains `.header(level)` for h1-h6
- NSMutableAttributedString allows AppKit-specific attributes (NSFont, NSParagraphStyle)
- Avoids SwiftUI dependency (font/foregroundColor are SwiftUI attributes)

### Key Technical Decisions

**AttributedString → NSAttributedString Conversion**
- Initial attempt: Modify AttributedString directly with font/foregroundColor
- Problem: Linker errors - font/foregroundColor are SwiftUI attributes, not available in AppKit extension
- Solution: Convert to NSMutableAttributedString, apply NSFont and NSColor via addAttribute()
- Benefit: Clean separation - AttributedString for parsing, NSAttributedString for styling

**PresentationIntent for Heading Detection**
- Alternative considered: Detect headings by font weight in NSAttributedString
- Problem: After conversion, exact heading level is lost (all become "bold")
- Solution: Inspect PresentationIntent *before* conversion to get exact heading level
- Benefit: Reliable, semantic, extensible to other block types (blockquotes, code blocks)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

**Issue 1: MarkdownRenderer not found in scope**
- Symptom: Build error "cannot find 'MarkdownRenderer' in scope"
- Cause: File created on filesystem but not added to Xcode project
- Fix: Manually edited project.pbxproj to add MarkdownRenderer.swift to:
  - PBXBuildFile section
  - PBXFileReference section
  - MDQuickLook PBXGroup children
  - MDQuickLook PBXSourcesBuildPhase files
- Resolution: Build succeeded after project file update

**Issue 2: SwiftUI linker errors**
- Symptom: "symbol(s) not found" for SwiftUI.FontAttribute and SwiftUI.ForegroundColorAttribute
- Cause: AttributedString font/foregroundColor are SwiftUI attributes, unavailable in AppKit extension
- Fix: Refactored to convert AttributedString → NSMutableAttributedString, use NSFont/NSColor
- Resolution: Build succeeded, no SwiftUI dependencies

## Testing & Verification

**Build Verification**
- ✅ `make build` succeeds without errors
- ✅ MarkdownRenderer.swift compiled into MDQuickLook.appex
- ✅ PreviewViewController uses MarkdownRenderer
- ✅ No SwiftUI linker errors

**Runtime Verification**
- ✅ Extension installs to /Applications/md-quick-look.app
- ✅ Extension loads for .md files (qlmanage -p)
- ✅ samples/headings.md created with all heading levels
- ✅ Inline formatting preserved (bold, italic, strikethrough from AttributedString)

**Code Quality**
- ✅ OSLog logging for renderer operations
- ✅ Error handling for markdown parse failures
- ✅ Clean separation of concerns (parsing vs. styling)
- ✅ 117 lines (exceeds 80-line minimum requirement)

## Commits

| Commit | Message | Files |
|--------|---------|-------|
| 32898f5 | feat(02-01): create MarkdownRenderer with heading hierarchy and inline formatting | MarkdownRenderer.swift |
| 4e25248 | feat(02-01): update PreviewViewController to use MarkdownRenderer | PreviewViewController.swift, project.pbxproj |
| caa5ad5 | feat(02-01): add headings test sample file | samples/headings.md |

## Next Phase Readiness

**Ready for 02-02 (Code Block Styling)**
- ✅ MarkdownRenderer foundation established
- ✅ PresentationIntent inspection pattern works
- ✅ AttributedString → NSAttributedString conversion proven
- ✅ NSMutableAttributedString attribute application working

**Extension Points**
- PresentationIntent.components can detect `.codeBlock` and `.inlineCode`
- NSMutableAttributedString supports monospaced fonts and background colors
- Current architecture supports additional block types without refactoring

**Known Limitations (Future Work)**
- Heading spacing is paragraph-level, may need line spacing adjustments
- Currently only h1-h6 styled; body paragraphs use default styling
- No background color support yet (needed for code blocks)
- No custom text container sizing for code blocks

**No Blockers**
- All dependencies met (Phase 1 complete)
- Architecture proven with heading hierarchy
- No technical debt introduced
