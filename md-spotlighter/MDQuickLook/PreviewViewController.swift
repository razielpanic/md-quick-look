import Cocoa
import QuickLookUI
import os.log

extension OSLog {
    private static var subsystem = "com.razielpanic.md-spotlighter"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

class PreviewViewController: NSViewController, QLPreviewingController {

    override var nibName: NSNib.Name? {
        return NSNib.Name("PreviewViewController")
    }

    override func loadView() {
        self.view = NSView()
        self.view.autoresizingMask = [.width, .height]
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, url.path)

        do {
            // Load markdown content
            let content = try String(contentsOf: url, encoding: .utf8)

            // Parse and render to AttributedString (macOS 12+ native markdown support)
            let attributedString = try AttributedString(markdown: content)

            // Create NSTextView for display
            let textView = NSTextView(frame: self.view.bounds)
            textView.autoresizingMask = [.width, .height]
            textView.isEditable = false
            textView.isSelectable = true
            textView.textStorage?.setAttributedString(NSAttributedString(attributedString))

            self.view.addSubview(textView)

            os_log("Rendering complete", log: .quicklook, type: .info)
            handler(nil)
        } catch {
            os_log("Error rendering markdown: %@", log: .quicklook, type: .error, error.localizedDescription)

            // Show error message in view instead of crashing
            let errorView = NSTextView(frame: self.view.bounds)
            errorView.autoresizingMask = [.width, .height]
            errorView.isEditable = false
            errorView.string = "Error loading markdown file:\n\(error.localizedDescription)"
            self.view.addSubview(errorView)

            handler(error)
        }
    }
}
