import Cocoa
import Quartz
import os.log
import Foundation

extension OSLog {
    private static var subsystem = "com.razielpanic.md-spotlighter"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

class PreviewViewController: NSViewController, QLPreviewingController {

    override func loadView() {
        // Create a simple view to hold the text view
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        os_log("=== MD Spotlighter Quick Look Extension ===", log: .quicklook, type: .info)
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, url.path)
        os_log("File exists: %@", log: .quicklook, type: .debug, FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")

        do {
            // Check file size before reading
            let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
            guard let fileSize = attrs[.size] as? UInt64 else {
                os_log("ERROR: Cannot determine file size", log: .quicklook, type: .error)
                handler(NSError(domain: "MDSpotlighter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot determine file size"]))
                return
            }

            os_log("File size: %lld bytes", log: .quicklook, type: .info, fileSize)

            // Define truncation threshold - 500KB supports large docs while ensuring <1s render
            let maxSize: UInt64 = 500_000

            // Load markdown content with truncation if needed
            let markdownContent: String
            if fileSize > maxSize {
                // File is large - read only first 500KB
                guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
                    os_log("ERROR: Cannot open file for reading", log: .quicklook, type: .error)
                    handler(NSError(domain: "MDSpotlighter", code: -1, userInfo: [NSLocalizedDescriptionKey: "Cannot open file for reading"]))
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

            // Render markdown with custom MarkdownRenderer
            let renderer = MarkdownRenderer()
            let styledContent = renderer.render(markdown: markdownContent)
            os_log("MarkdownRenderer completed styling", log: .quicklook, type: .info)

            // Create scroll view
            let scrollView = NSScrollView(frame: view.bounds)
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.borderType = .noBorder

            // Create custom text stack for blockquote border rendering
            let textStorage = NSTextStorage()
            let layoutManager = MarkdownLayoutManager()  // Custom layout manager
            let textContainer = NSTextContainer(containerSize: NSSize(
                width: scrollView.contentSize.width - 40,  // Account for insets
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
            textView.textContainerInset = NSSize(width: 20, height: 20)

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
}
