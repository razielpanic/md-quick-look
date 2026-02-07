# Phase 15: Cross-Context Integration - Research

**Researched:** 2026-02-07
**Domain:** Snapshot testing for macOS Quick Look extensions with NSView
**Confidence:** HIGH

## Summary

Snapshot testing is the established approach for automated visual regression testing in macOS/Swift applications. The standard tool is `swift-snapshot-testing` by Point-Free, which provides NSView image comparison with configurable precision tolerance. For Quick Look extension testing, the core challenge is that extensions don't have built-in test infrastructure, so tests must instantiate the PreviewViewController directly and render it at specific widths/appearances.

The user requires automated snapshot tests across 3 contexts (spacebar popup, Finder column, fullscreen) at multiple widths (~260px narrow, ~500px medium, ~800px wide) in both light and dark modes. This creates a test matrix of ~18 snapshots per comprehensive test file. The library supports all required features: NSView snapshots, precision tolerance for pixel differences, and can be configured to test different appearances programmatically.

**Primary recommendation:** Use `swift-snapshot-testing` 1.18.9+ via Swift Package Manager in a new XCTest target. Create test methods that instantiate PreviewViewController, set frame size and NSAppearance, render markdown, and capture image snapshots with 0.98-0.99 precision to handle minor rendering variations across environments.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **Verification approach**: Automated snapshot test suite that persists for future regression testing
- **Rendering mechanism**: Render markdown to image/view in a test harness, compare pixel output against saved baselines
- **Mismatch handling**: On mismatch, attempt one automated fix iteration, then warn for human review if it persists
- **Issue tracking**: Descriptive git commit messages, no separate issues log
- **Zero tolerance policy**: Any visible rendering problem must be fixed before v1.2 ships
- **Patch scope**: Can apply minimal targeted patches to phases 11-14 code to resolve integration issues
- **Rework boundary**: Major rework of previous phase features becomes a new phase, not absorbed here
- **Context coverage**: Test all three Quick Look contexts (spacebar popup, Finder column preview pane, fullscreen)
- **Width testing**: Multiple representative widths matching WidthTier breakpoints (~260px narrow, ~500px medium, ~800px wide)
- **Test file structure**: Single comprehensive markdown file exercising all v1.2 features (YAML front matter + tables + task lists + regular content)
- **Appearance testing**: Both light mode and dark mode, snapshots for each context in both appearances

### Claude's Discretion
- Snapshot test target placement (existing vs separate test target)
- Specific snapshot testing library/approach
- Exact pixel tolerance for snapshot comparison
- Test file content details beyond required feature coverage

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

## Standard Stack

The established snapshot testing ecosystem for macOS Swift applications:

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| swift-snapshot-testing | 1.18.9+ | Snapshot comparison testing | De facto standard by Point-Free, active maintenance (updated Jan 29, 2026), NSView support, configurable precision |
| XCTest | Built-in | Test framework | Apple's native testing framework, integrated with Xcode |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Swift Package Manager | Built-in | Dependency management | Adding swift-snapshot-testing to test target |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| swift-snapshot-testing | SnapshotPreviews by EmergeTools | SnapshotPreviews focuses on SwiftUI previews, not ideal for NSViewController/NSTextView testing |
| swift-snapshot-testing | Custom image diff solution | Reinventing the wheel, losing perceptual precision, community testing patterns |

**Installation:**
```swift
// In Xcode: File > Add Package Dependency
// URL: https://github.com/pointfreeco/swift-snapshot-testing
// Version: 1.18.9 or later

// Or create test target and add dependency via Xcode UI
```

## Architecture Patterns

### Recommended Test Target Structure
```
MDQuickLook/
├── MDQuickLook/                    # Host app
├── MDQuickLook Extension/          # Quick Look extension code
├── MDQuickLookTests/               # NEW: Unit test target
│   ├── SnapshotTests/
│   │   └── CrossContextTests.swift # Snapshot test cases
│   └── __Snapshots__/              # Auto-generated snapshot storage
└── MDQuickLook.xcodeproj
```

### Pattern 1: NSView Snapshot Testing with Multiple Widths
**What:** Instantiate view controller programmatically, set frame to specific width, render, and snapshot
**When to use:** Testing responsive layouts across width tiers
**Example:**
```swift
// Source: https://github.com/pointfreeco/swift-snapshot-testing/blob/master/Sources/SnapshotTesting/Snapshotting/NSView.swift
import XCTest
import SnapshotTesting
@testable import MDQuickLook_Extension

final class CrossContextTests: XCTestCase {
    func testNarrowWidth_LightMode() {
        let vc = PreviewViewController()
        vc.loadView()
        vc.view.frame = CGRect(x: 0, y: 0, width: 260, height: 600)

        // Load test markdown file
        let url = Bundle(for: type(of: self)).url(forResource: "comprehensive-v1.2", withExtension: "md")!

        let expectation = XCTestExpectation(description: "Preview loaded")
        vc.preparePreviewOfFile(at: url) { error in
            XCTAssertNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)

        // Snapshot with precision tolerance for minor rendering differences
        assertSnapshot(
            matching: vc.view,
            as: .image(precision: 0.98),
            named: "narrow-light"
        )
    }
}
```

### Pattern 2: Dark Mode Testing with NSAppearance
**What:** Set NSAppearance before rendering to test light/dark mode
**When to use:** Testing appearance-adaptive colors and rendering
**Example:**
```swift
// Source: Combined from https://mackuba.eu/2018/07/10/dark-side-mac-2/ and https://troz.net/post/2020/swiftui_snapshots/
func testNarrowWidth_DarkMode() {
    let vc = PreviewViewController()
    vc.loadView()
    vc.view.frame = CGRect(x: 0, y: 0, width: 260, height: 600)

    // Set dark appearance BEFORE loading content
    vc.view.appearance = NSAppearance(named: .darkAqua)

    let url = Bundle(for: type(of: self)).url(forResource: "comprehensive-v1.2", withExtension: "md")!

    let expectation = XCTestExpectation(description: "Preview loaded")
    vc.preparePreviewOfFile(at: url) { error in
        XCTAssertNil(error)
        expectation.fulfill()
    }
    wait(for: [expectation], timeout: 2.0)

    assertSnapshot(
        matching: vc.view,
        as: .image(precision: 0.98),
        named: "narrow-dark"
    )
}
```

### Pattern 3: Recording Mode for Initial Baseline Capture
**What:** Enable recording mode to generate initial snapshots
**When to use:** First test run, or when intentionally updating all baselines
**Example:**
```swift
// Source: https://github.com/pointfreeco/swift-snapshot-testing
override func invokeTest() {
    // Enable for first run to generate baselines
    // withSnapshotTesting(record: .all) { super.invokeTest() }

    // Normal mode for regression testing
    super.invokeTest()
}
```

### Anti-Patterns to Avoid
- **Automatic baseline updates on failure:** Never use record mode in CI or automated workflows—requires manual review to prevent masking real regressions
- **Platform-specific snapshots:** Don't commit snapshots from different display scales—causes flaky tests. Use consistent test environment (same scale factor)
- **100% pixel precision:** Default precision of 1.0 causes false failures from minor anti-aliasing or font rendering differences across environments

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Image diff comparison | Custom pixel-by-pixel loop | swift-snapshot-testing with perceptualPrecision | Library uses CIE94 color difference calculations for perceptually accurate comparison, handles edge cases |
| Snapshot storage/naming | Custom file organization | swift-snapshot-testing auto-naming | Auto-generates `__Snapshots__/TestClass.testMethod.named.png` paths, handles conflicts |
| Dark mode appearance switching | Custom view hierarchy manipulation | NSAppearance(named:) assignment | System API handles all semantic colors, view refreshing automatically |
| View rendering to image | Custom CGContext/bitmap logic | Snapshotting<NSView, NSImage>.image | Handles view lifecycle, caching display, bitmap representation correctly |
| Test file resource loading | Manual path construction | Bundle(for:).url(forResource:) | Handles test bundle vs main bundle, works in CI environments |

**Key insight:** Snapshot testing has many subtle failure modes (display scale, font rendering, async layout, semantic colors). Use battle-tested library that has solved these edge cases.

## Common Pitfalls

### Pitfall 1: Display Scale / Retina Inconsistency
**What goes wrong:** Snapshots recorded on Retina display (2x scale) fail when run on non-Retina or CI with different scale
**Why it happens:** NSView `bitmapImageRepForCachingDisplay` uses the main screen's backing scale factor, which varies by environment
**How to avoid:**
- Run all tests on same machine/CI environment with consistent display configuration
- Use precision tolerance (0.98-0.99) to absorb minor scale-related differences
- Consider force-device-scale-factor=1 if testing infrastructure allows
**Warning signs:** Tests pass locally but fail in CI, or vice versa; snapshot diffs show identical-looking images

### Pitfall 2: Asynchronous Layout Not Complete
**What goes wrong:** Snapshot captured before NSLayoutManager finishes layout, resulting in partially rendered or zero-height views
**Why it happens:** `preparePreviewOfFile` is async, layout calculation happens lazily
**How to avoid:**
- Always wait for preparePreviewOfFile completion handler before snapshotting
- Call `layoutManager.ensureLayout(forCharacterRange:)` to force synchronous layout
- Set view frame BEFORE loading content, not after
**Warning signs:** Snapshots show blank/white views, or inconsistent heights between runs

### Pitfall 3: Semantic Colors Not Resolving to Appearance
**What goes wrong:** Dark mode test shows light mode colors, or colors don't match expected appearance
**Why it happens:** NSAppearance must be set on view BEFORE content is rendered—semantic colors resolve at draw time
**How to avoid:**
- Set `view.appearance` immediately after `loadView()`, before calling `preparePreviewOfFile`
- Verify appearance with `view.effectiveAppearance.name` after setting
**Warning signs:** Dark mode snapshots look identical to light mode, semantic colors (textBackgroundColor, separatorColor) are wrong

### Pitfall 4: Over-Precise Pixel Matching Causing Flake
**What goes wrong:** Tests fail sporadically with minimal visual differences (1-2 pixels different)
**Why it happens:** Font rendering, anti-aliasing, or sub-pixel positioning varies slightly across macOS versions, GPUs
**How to avoid:**
- Use precision of 0.98-0.995 (allow 0.5-2% pixel difference)
- Use perceptualPrecision for color-based tolerance in addition to pixel count
- Review diff images to distinguish real regressions from rendering noise
**Warning signs:** Tests fail with "image differs by 0.001%" or diff images show no human-visible differences

### Pitfall 5: Test File Not in Test Bundle Resources
**What goes wrong:** `Bundle.url(forResource:)` returns nil, causing test to crash or skip
**Why it happens:** Test markdown file not added to test target's "Copy Bundle Resources" build phase
**How to avoid:**
- Add comprehensive test markdown file to test target in Xcode (not just extension target)
- Verify with "Build Phases > Copy Bundle Resources" in test target
- Use `XCTUnwrap` or guard to fail gracefully with clear error message
**Warning signs:** `url(forResource:)` returns nil, tests crash with "unexpectedly found nil"

### Pitfall 6: Snapshot Path Too Long or Invalid Characters
**What goes wrong:** Snapshot files fail to save or load, git conflicts on case-insensitive filesystems
**Why it happens:** Test names with slashes, colons, or very long descriptive names create invalid file paths
**How to avoid:**
- Keep test method names concise, use named: parameter for disambiguation
- Avoid special characters in test/snapshot names (use underscores, not spaces or slashes)
- Keep total path under ~200 characters for cross-platform compatibility
**Warning signs:** Snapshot tests always fail with "failed to save/load reference", files missing from `__Snapshots__`

## Code Examples

Verified patterns from official sources:

### Comprehensive Test Suite Structure
```swift
// Source: Patterns from https://www.kodeco.com/24426963-snapshot-testing-tutorial-for-swiftui-getting-started
// and https://github.com/pointfreeco/swift-snapshot-testing
import XCTest
import SnapshotTesting
@testable import MDQuickLook_Extension

final class CrossContextSnapshotTests: XCTestCase {

    // Test matrix: 3 widths × 2 appearances = 6 tests minimum
    // Add more widths for thorough coverage

    private let widths: [(name: String, width: CGFloat)] = [
        ("narrow", 260),    // Finder column preview pane
        ("medium", 500),    // Intermediate breakpoint
        ("wide", 800),      // Spacebar popup / fullscreen
    ]

    private let appearances: [(name: String, appearance: NSAppearance.Name)] = [
        ("light", .aqua),
        ("dark", .darkAqua)
    ]

    func testAllContexts() {
        for width in widths {
            for appearance in appearances {
                let name = "\(width.name)-\(appearance.name)"
                verifySnapshot(width: width.width, appearance: appearance.appearance, named: name)
            }
        }
    }

    private func verifySnapshot(width: CGFloat, appearance: NSAppearance.Name, named name: String) {
        let vc = PreviewViewController()
        vc.loadView()
        vc.view.frame = CGRect(x: 0, y: 0, width: width, height: 800)
        vc.view.appearance = NSAppearance(named: appearance)

        let url = XCTUnwrap(Bundle(for: type(of: self)).url(forResource: "comprehensive-v1.2", withExtension: "md"))

        let expectation = XCTestExpectation(description: "Preview loaded")
        vc.preparePreviewOfFile(at: url) { error in
            XCTAssertNil(error, "Failed to load preview: \(error?.localizedDescription ?? "unknown")")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // Allow 2% pixel difference for rendering variations
        assertSnapshot(
            matching: vc.view,
            as: .image(precision: 0.98),
            named: name
        )
    }
}
```

### Recording Mode Helper (Manual Control)
```swift
// Source: https://github.com/pointfreeco/swift-snapshot-testing
final class CrossContextSnapshotTests: XCTestCase {

    // Set to true to regenerate all baselines
    // NEVER commit with this set to true
    private let shouldRecordSnapshots = false

    override func invokeTest() {
        if shouldRecordSnapshots {
            withSnapshotTesting(record: .all) {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }
}
```

### Automated Fix Iteration Pattern
```swift
// Source: User requirement pattern - not from external library
// For handling "attempt one automated fix iteration" requirement
func testSnapshotWithAutoFix() {
    let name = "test-snapshot"
    var attempts = 0
    let maxAttempts = 2

    while attempts < maxAttempts {
        attempts += 1

        // First attempt: verify against baseline
        // Second attempt: record new baseline if first failed
        let mode: SnapshotTestingConfiguration.Record = attempts == 2 ? .all : .missing

        withSnapshotTesting(record: mode) {
            assertSnapshot(
                matching: view,
                as: .image(precision: 0.98),
                named: name
            )
        }

        // If we get here on attempt 2, auto-fix succeeded
        if attempts == 2 {
            print("⚠️ Auto-regenerated snapshot for \(name) - review changes!")
        }

        break // Exit loop if assertion passed
    }
}
```

### NSLayoutManager Force Layout Pattern
```swift
// Source: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html
// and project's PreviewViewController.swift
// Ensure layout is complete before snapshotting
func ensureLayoutComplete(for viewController: PreviewViewController) {
    guard let layoutManager = viewController.textView?.layoutManager,
          let textStorage = viewController.textStorage else {
        return
    }

    // Force complete layout synchronously
    layoutManager.ensureLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length))

    // Verify layout completed
    let usedRect = layoutManager.usedRect(for: viewController.textView!.textContainer!)
    XCTAssertGreaterThan(usedRect.height, 0, "Layout did not complete - zero height")
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| FBSnapshotTestCase (Facebook) | swift-snapshot-testing (Point-Free) | ~2017-2018 | Modern Swift API, generic snapshotting strategies, active maintenance |
| 100% pixel precision | Configurable precision + perceptual precision | 2021-2022 | Reduces flaky tests from minor rendering differences |
| Manual baseline management | `record: .all/.missing/.failed` modes | 2019+ | Easier workflow for updating snapshots intentionally |
| UIView-only | Generic Snapshotting protocol | 2017+ | Works with NSView, CALayer, URLs, strings, any type |
| XCTest only | Swift Testing support added | Jan 2026 | Can use new Swift Testing framework (v1.17.0+) |

**Deprecated/outdated:**
- **FBSnapshotTestCase:** Archived/unmaintained. Use swift-snapshot-testing instead.
- **iOSSnapshotTestCase (Uber fork):** Maintained for legacy projects, but swift-snapshot-testing is modern standard
- **QLGenerator plugins (.qlgenerator):** No longer supported on macOS 15+, use Quick Look App Extensions instead

## Open Questions

Things that couldn't be fully resolved:

1. **Automated fix iteration implementation**
   - What we know: swift-snapshot-testing supports `record: .all/.missing/.failed` modes
   - What's unclear: How to automatically detect "this is second attempt" and switch to record mode within same test run
   - Recommendation: Implement via test method parameter or environment variable. First run: verify. On failure, prompt user to re-run with `RECORD_FAILED=1` environment variable that triggers record mode. Not fully automated within single test execution, but achieves "one retry" goal.

2. **Quick Look context simulation accuracy**
   - What we know: Can set view frame to specific widths (260px, 500px, 800px)
   - What's unclear: Whether frame width alone perfectly simulates actual Quick Look contexts (spacebar popup vs Finder column)
   - Recommendation: Validate with manual Quick Look testing initially. If discrepancies found, may need to investigate NSTextContainer or scroll view configuration differences. Frame width should be sufficient for layout testing.

3. **CI environment display scale standardization**
   - What we know: Snapshots sensitive to display scale factor
   - What's unclear: Whether CI environment (if any) has consistent/configurable display scale
   - Recommendation: Document expected test environment (macOS version, display scale). If CI tests fail due to scale differences, add `--force-device-scale-factor=1` or similar configuration if available for macOS Xcode test runs. Worst case: skip snapshot tests in CI, run locally only.

## Sources

### Primary (HIGH confidence)
- [swift-snapshot-testing GitHub](https://github.com/pointfreeco/swift-snapshot-testing) - Library documentation, NSView.swift source
- [Swift Package Index: swift-snapshot-testing](https://swiftpackageindex.com/pointfreeco/swift-snapshot-testing) - Current version (1.18.9, Jan 29 2026)
- [NSView.swift source](https://github.com/pointfreeco/swift-snapshot-testing/blob/master/Sources/SnapshotTesting/Snapshotting/NSView.swift) - NSView snapshot strategies
- [Apple Developer: NSLayoutManager](https://developer.apple.com/documentation/appkit/nslayoutmanager) - Layout completion API
- [Apple Developer: Tracking Size of TextView](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TextStorageLayer/Tasks/TrackingSize.html) - usedRect pattern

### Secondary (MEDIUM confidence)
- [TrozWare: SwiftUI Snapshot Testing](https://troz.net/post/2020/swiftui_snapshots/) - macOS NSHostingController patterns, dark mode testing
- [Kodeco: Snapshot Testing Tutorial](https://www.kodeco.com/24426963-snapshot-testing-tutorial-for-swiftui-getting-started) - Test suite structure patterns
- [OneUpTime: How to Fix Snapshot Test Failures (2026-01-24)](https://oneuptime.com/blog/post/2026-01-24-snapshot-test-failures/view) - Best practices for handling failures
- [BrowserStack: Snapshot Testing with Playwright (2026)](https://www.browserstack.com/guide/playwright-snapshot-testing) - CI/CD best practices, environment standardization
- [Mackuba.eu: Dark Side of the Mac](https://mackuba.eu/2018/07/10/dark-side-mac-2/) - NSAppearance programmatic setting
- [Point-Free: Perceptual Precision PR #628](https://github.com/pointfreeco/swift-snapshot-testing/pull/628) - perceptualPrecision implementation
- [GitHub Discussion #656: Perceptual Precision Tips](https://github.com/pointfreeco/swift-snapshot-testing/discussions/656) - Community precision recommendations (0.98-0.995)

### Tertiary (LOW confidence)
- WebSearch general results on snapshot testing pitfalls - Community consensus patterns
- Swift Forums: Testing SPM dependencies - General XCTest target configuration

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - swift-snapshot-testing is de facto standard, currently maintained, NSView support verified in source
- Architecture: HIGH - Patterns verified in library documentation and community tutorials
- Pitfalls: MEDIUM-HIGH - Display scale, async layout, appearance setting pitfalls confirmed in GitHub issues; precision/flake pitfalls from community discussions
- Dark mode testing: HIGH - NSAppearance API verified in Apple docs and multiple sources
- Automated fix pattern: LOW-MEDIUM - Custom implementation required, not library feature

**Research date:** 2026-02-07
**Valid until:** ~30 days (2026-03-09) - Library stable, patterns established
