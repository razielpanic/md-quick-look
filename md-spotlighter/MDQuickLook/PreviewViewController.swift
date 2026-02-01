import Cocoa
import Quartz
import os.log

extension OSLog {
    private static var subsystem = "com.razielpanic.md-spotlighter"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

class PreviewProvider: QLPreviewProvider {
    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, request.fileURL.path)

        // Load markdown content
        let content = try String(contentsOf: request.fileURL, encoding: .utf8)

        // Parse and render to AttributedString (macOS 12+ native markdown support)
        let attributedString = try AttributedString(markdown: content)

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 800, height: 600)) { (replyToUpdate: QLPreviewReply) in
            // Create HTML from attributed string
            let nsAttributedString = NSAttributedString(attributedString)
            let documentAttributes: [NSAttributedString.DocumentAttributeKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html
            ]

            if let htmlData = try? nsAttributedString.data(from: NSRange(location: 0, length: nsAttributedString.length),
                                                            documentAttributes: documentAttributes) {
                return htmlData
            }

            // Fallback: plain text
            let html = """
            <html>
            <head>
                <meta charset="utf-8">
                <style>
                    body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; padding: 20px; }
                </style>
            </head>
            <body>
                <pre>\(content.replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;"))</pre>
            </body>
            </html>
            """
            return html.data(using: .utf8)!
        }

        os_log("Rendering complete", log: .quicklook, type: .info)
        return reply
    }
}
