import Cocoa
import Quartz
import os.log
import Foundation

extension OSLog {
    private static var subsystem = "com.rocketpop.MDQuickLook"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

class PreviewViewController: NSViewController, QLPreviewingController {

    // MARK: - Instance Properties for Width-Adaptive Rendering
    private var currentWidthTier: WidthTier?
    private var markdownContent: String?
    private var scrollView: NSScrollView?
    private var textView: NSTextView?
    private var textStorage: NSTextStorage?
    private var mdLayoutManager: MarkdownLayoutManager?

    override func loadView() {
        // Create a simple view to hold the text view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        os_log("=== MD Quick Look Extension ===", log: .quicklook, type: .info)
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, url.path)
        os_log("File exists: %@", log: .quicklook, type: .debug, FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")

        do {
            // Check file size before reading
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attrs[.size] as? UInt64 else {
                os_log("ERROR: Cannot determine file size", log: .quicklook, type: .error)
                handler(NSError(domain: "MDQuickLook", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine file size"]))
                return
            }

            os_log("File size: %lld bytes", log: .quicklook, type: .info, fileSize)

            // Define truncation threshold - 500KB supports large docs while ensuring <1s render
            let maxSize: UInt64 = 500_000

            // Detect initial width tier
            let initialTier: WidthTier = view.bounds.width < 320 ? .narrow : .normal
            currentWidthTier = initialTier
            os_log("Initial width tier: %{public}s (width: %.0f)", log: .quicklook, type: .info,
                   initialTier == .narrow ? "narrow" : "normal", view.bounds.width)

            // Load markdown content with truncation if needed
            let markdownContent: String
            if fileSize > maxSize {
                // File is large - read only first 500KB
                guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
                    os_log("ERROR: Cannot open file for reading", log: .quicklook, type: .error)
                    handler(NSError(domain: "MDQuickLook", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot open file for reading"]))
                    return
                }
                defer { try? fileHandle.close() }

                let data = fileHandle.readData(ofLength: Int(maxSize))
                var truncated = String(data: data, encoding: .utf8) ?? ""

                // Add user-friendly truncation message at bottom
                let sizeStr = ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
                truncated.append("\n\n---\n\nContent truncated (file is \(sizeStr))")
                markdownContent = truncated

                os_log("Truncated large file: %@ (%lld bytes, showing first 500KB)", log: .quicklook, type: .info, url.lastPathComponent, fileSize)
            } else {
                // File is typical size - read fully
                markdownContent = try String(contentsOf: url, encoding: .utf8)
            }

            os_log("File read successfully, length: %d bytes", log: .quicklook, type: .info, markdownContent.count)
            os_log("First 100 chars: %@", log: .quicklook, type: .debug, String(markdownContent.prefix(100)))

            // Store markdown content for re-rendering
            self.markdownContent = markdownContent

            // Render markdown with custom MarkdownRenderer and initial tier
            let renderer = MarkdownRenderer()
            let styledContent = renderer.render(markdown: markdownContent, widthTier: initialTier)
            os_log("MarkdownRenderer completed styling with %{public}s tier", log: .quicklook, type: .info,
                   initialTier == .narrow ? "narrow" : "normal")

            // Create scroll view
            let scrollView = NSScrollView(frame: view.bounds)
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.borderType = .noBorder

            // Create custom text stack for blockquote border rendering
            let textStorage = NSTextStorage()
            let layoutManager = MarkdownLayoutManager()  // Custom layout manager
            layoutManager.widthTier = initialTier  // Set initial tier

            // Calculate initial inset width for text container
            let insetWidth: CGFloat = initialTier == .narrow ? 12 : 40
            let textContainer = NSTextContainer(containerSize: NSSize(
                width: scrollView.contentSize.width - insetWidth,
                height: CGFloat.greatestFiniteMagnitude
            ))
            textContainer.widthTracksTextView = true
            textContainer.heightTracksTextView = false  // Allow infinite height for scrolling

            // Wire text components together
            layoutManager.addTextContainer(textContainer)
            textStorage.addLayoutManager(layoutManager)

            // Create text view with custom container
            let textView = NSTextView(frame: scrollView.bounds, textContainer: textContainer)
            textView.autoresizingMask = [.width]
            textView.isEditable = false
            textView.isSelectable = true
            textView.backgroundColor = .textBackgroundColor  // Semantic color for Dark Mode

            // Set initial textContainerInset based on tier
            if initialTier == .narrow {
                textView.textContainerInset = NSSize(width: 6, height: 6)
            } else {
                textView.textContainerInset = NSSize(width: 20, height: 20)
            }

            // Store references for re-rendering
            self.scrollView = scrollView
            self.textView = textView
            self.textStorage = textStorage
            self.mdLayoutManager = layoutManager

            // Configure text view for vertical scrolling
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textView.minSize = NSSize(width: 0, height: 0)
            textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)

            // Apply styled content to text storage
            textStorage.setAttributedString(styledContent)
            os_log("Custom text stack configured with MarkdownLayoutManager", log: .quicklook, type: .debug)

            scrollView.documentView = textView
            view.addSubview(scrollView)

            // Force layout to establish proper content height for scrolling
            layoutManager.ensureLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length))

            // Log scroll configuration for debugging
            os_log("ScrollView configured - contentSize: %@", log: .quicklook, type: .debug, NSStringFromSize(scrollView.contentSize))
            os_log("TextView frame after layout: %@", log: .quicklook, type: .debug, NSStringFromRect(textView.frame))
            os_log("TextView content height: %.2f", log: .quicklook, type: .info, textView.frame.height)

            os_log("Quick Look preview complete - AttributedString rendered", log: .quicklook, type: .info)

            // Call completion handler immediately - no async rendering needed
            handler(nil)

        } catch let error as CocoaError where error.code == .fileReadUnknownStringEncoding {
            os_log("ERROR: File encoding issue: %@", log: .quicklook, type: .error, error.localizedDescription)
            handler(error)
        } catch {
            os_log("ERROR rendering markdown: %@", log: .quicklook, type: .error, error.localizedDescription)
            handler(error)
        }
    }

    // MARK: - Width-Adaptive Layout

    override func viewDidLayout() {
        super.viewDidLayout()

        let availableWidth = view.bounds.width
        let newTier: WidthTier = availableWidth < 320 ? .narrow : .normal

        // Only regenerate if tier actually changed
        guard newTier != currentWidthTier else {
            // Even if tier didn't change, update insets for normal mode (max content width)
            updateInsetsForWidth(availableWidth, tier: newTier)
            return
        }

        currentWidthTier = newTier
        os_log("Width tier changed to %{public}s (width: %.0f)", log: .quicklook, type: .info,
               newTier == .narrow ? "narrow" : "normal", availableWidth)

        regenerateContent()
    }

    private func updateInsetsForWidth(_ availableWidth: CGFloat, tier: WidthTier) {
        guard let textView = textView else { return }

        switch tier {
        case .narrow:
            textView.textContainerInset = NSSize(width: 6, height: 6)
        case .normal:
            // Max content width cap: ~75 chars at 14pt body font
            let maxContentWidth: CGFloat = 640
            let totalInsetWidth = maxContentWidth + 40  // 40 for minimum 20pt each side

            if availableWidth > totalInsetWidth {
                let horizontalInset = (availableWidth - maxContentWidth) / 2
                textView.textContainerInset = NSSize(width: horizontalInset, height: 20)
            } else {
                textView.textContainerInset = NSSize(width: 20, height: 20)
            }
        }

        // Update text container width to account for new insets
        if let textContainer = textView.textContainer {
            textContainer.containerSize = NSSize(
                width: textView.bounds.width - textView.textContainerInset.width * 2,
                height: CGFloat.greatestFiniteMagnitude
            )
        }
    }

    private func regenerateContent() {
        guard let markdownContent = markdownContent,
              let textStorage = textStorage,
              let textView = textView,
              let tier = currentWidthTier else { return }

        // Update LayoutManager tier
        mdLayoutManager?.widthTier = tier

        // Update insets first
        updateInsetsForWidth(view.bounds.width, tier: tier)

        // Re-render with new tier
        let renderer = MarkdownRenderer()
        let styledContent = renderer.render(markdown: markdownContent, widthTier: tier)
        textStorage.setAttributedString(styledContent)

        // Force layout
        if let layoutManager = textView.layoutManager {
            layoutManager.ensureLayout(forCharacterRange: NSRange(location: 0, length: textStorage.length))
        }

        os_log("Content regenerated for %{public}s tier", log: .quicklook, type: .info,
               tier == .narrow ? "narrow" : "normal")
    }
}
