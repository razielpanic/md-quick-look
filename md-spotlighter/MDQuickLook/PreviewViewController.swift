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
            // Load markdown content
            let markdownContent = try String(contentsOf: url, encoding: .utf8)
            os_log("File read successfully, length: %d bytes", log: .quicklook, type: .info, markdownContent.count)
            os_log("First 100 chars: %@", log: .quicklook, type: .debug, String(markdownContent.prefix(100)))

            // Render markdown with custom MarkdownRenderer
            let renderer = MarkdownRenderer()
            let styledContent = renderer.render(markdown: markdownContent)
            os_log("MarkdownRenderer completed styling", log: .quicklook, type: .info)

            // Create NSTextView to display the attributed string
            let scrollView = NSScrollView(frame: view.bounds)
            scrollView.autoresizingMask = [.width, .height]
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.borderType = .noBorder

            let textView = NSTextView(frame: scrollView.bounds)
            textView.autoresizingMask = [.width]
            textView.isEditable = false
            textView.isSelectable = true
            textView.backgroundColor = .white
            textView.textContainerInset = NSSize(width: 20, height: 20)

            // Apply styled content from renderer
            textView.textStorage?.setAttributedString(styledContent)

            // Configure text container for word wrapping
            textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width - 40, height: CGFloat.greatestFiniteMagnitude)
            textView.textContainer?.widthTracksTextView = true

            scrollView.documentView = textView
            view.addSubview(scrollView)

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
