import XCTest
import SnapshotTesting

/// Cross-context snapshot tests for MD Quick Look Extension
///
/// Tests all v1.2 features (YAML front matter, tables, task lists, layout scaling)
/// across multiple Quick Look contexts (narrow/medium/wide) in both light and dark mode.
final class CrossContextSnapshotTests: XCTestCase {

    // MARK: - Test Configuration

    /// Width configurations matching WidthTier breakpoints
    private let widths: [(name: String, width: CGFloat)] = [
        ("narrow", 260),    // Finder column preview pane
        ("medium", 500),    // Intermediate width context
        ("wide", 800),      // Spacebar popup / fullscreen
    ]

    /// Appearance configurations for light and dark mode
    private let appearances: [(name: String, appearance: NSAppearance.Name)] = [
        ("light", .aqua),
        ("dark", .darkAqua)
    ]

    /// Set to true to regenerate all baseline snapshots
    /// WARNING: NEVER commit with this set to true
    private let shouldRecordSnapshots = false

    // MARK: - Recording Mode Control

    override func invokeTest() {
        if shouldRecordSnapshots {
            withSnapshotTesting(record: .all) {
                super.invokeTest()
            }
        } else {
            super.invokeTest()
        }
    }

    // MARK: - Comprehensive Context Tests

    /// Tests all width × appearance combinations (6 total snapshots)
    func testAllContexts() {
        for width in widths {
            for appearance in appearances {
                let name = "\(width.name)-\(appearance.name)"
                verifySnapshot(
                    width: width.width,
                    appearance: appearance.appearance,
                    named: name
                )
            }
        }
    }

    // MARK: - Private Helpers

    /// Verifies a snapshot at the specified width and appearance
    ///
    /// Uses a tall height (3000px) to ensure all markdown features are captured
    /// regardless of document length.
    ///
    /// - Parameters:
    ///   - width: View width in points
    ///   - appearance: NSAppearance for light/dark mode
    ///   - name: Snapshot name for identification
    private func verifySnapshot(
        width: CGFloat,
        appearance: NSAppearance.Name,
        named name: String
    ) {
        // Create PreviewViewController
        let vc = PreviewViewController()
        vc.loadView()

        // Use tall height to capture full document content including:
        // YAML front matter, headings, lists, task lists, tables, code blocks, blockquotes, etc.
        vc.view.frame = CGRect(x: 0, y: 0, width: width, height: 3000)

        // Set appearance BEFORE loading content (ensures semantic colors resolve correctly)
        vc.view.appearance = NSAppearance(named: appearance)

        // Load comprehensive test markdown file
        guard let url = Bundle(for: type(of: self)).url(
            forResource: "comprehensive-v1.2",
            withExtension: "md"
        ) else {
            XCTFail("Failed to locate comprehensive-v1.2.md in test bundle")
            return
        }

        // Wait for async preview loading
        let expectation = XCTestExpectation(description: "Preview loaded")
        vc.preparePreviewOfFile(at: url) { error in
            if let error = error {
                XCTFail("Failed to load preview: \(error.localizedDescription)")
            }
            expectation.fulfill()
        }

        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(result, .completed, "Preview loading timed out")

        // Snapshot with 0.98 precision to handle minor rendering variations
        assertSnapshot(
            matching: vc.view,
            as: .image(precision: 0.98),
            named: name
        )
    }
}
