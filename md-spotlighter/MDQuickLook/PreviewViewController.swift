import Cocoa
import Quartz
import os.log
import Foundation
import WebKit

extension OSLog {
    private static var subsystem = "com.razielpanic.md-spotlighter"
    static let quicklook = OSLog(subsystem: subsystem, category: "quicklook")
}

extension String {
    func appending(to url: URL, encoding: String.Encoding = .utf8) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: url.path) {
            try self.write(to: url, atomically: true, encoding: encoding)
        } else {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            if let data = self.data(using: encoding) {
                fileHandle.write(data)
            }
            try fileHandle.close()
        }
    }
}

class PreviewViewController: NSViewController, QLPreviewingController {
    let debugLog = "/tmp/md-spotlighter-debug.log"
    var webView: WKWebView!

    override func loadView() {
        let debugLog = "/tmp/md-spotlighter-debug.log"
        try? "\n[INIT] PreviewViewController loadView called\n".appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        webView.autoresizingMask = [.width, .height]
        self.view = webView
    }

    func preparePreviewOfFile(at url: URL, completionHandler handler: @escaping (Error?) -> Void) {
        let timestamp = Date().description
        let logMessage = "\n[\(timestamp)] preparePreviewOfFile called for: \(url.path)\n"
        try? logMessage.appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)

        os_log("=== MD Spotlighter Quick Look Extension ===", log: .quicklook, type: .info)
        os_log("Extension loaded for file: %@", log: .quicklook, type: .info, url.path)
        os_log("File exists: %@", log: .quicklook, type: .debug, FileManager.default.fileExists(atPath: url.path) ? "YES" : "NO")

        // Load markdown content with error handling
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
            os_log("File read successfully, length: %d bytes", log: .quicklook, type: .info, content.count)
            os_log("First 100 chars: %@", log: .quicklook, type: .debug, String(content.prefix(100)))
            try? "Content length: \(content.count) bytes\n".appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)
        } catch {
            os_log("ERROR reading file: %@", log: .quicklook, type: .error, error.localizedDescription)
            try? "ERROR reading file: \(error.localizedDescription)\n".appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)
            handler(error)
            return
        }

        // Create styled HTML with proper markdown rendering
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;
                    font-size: 14px;
                    line-height: 1.6;
                    color: #24292e;
                    background-color: #fff;
                    padding: 20px;
                    max-width: 980px;
                    margin: 0 auto;
                }
                h1, h2, h3, h4, h5, h6 {
                    margin-top: 24px;
                    margin-bottom: 16px;
                    font-weight: 600;
                    line-height: 1.25;
                }
                h1 { font-size: 2em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                h2 { font-size: 1.5em; border-bottom: 1px solid #eaecef; padding-bottom: 0.3em; }
                h3 { font-size: 1.25em; }
                code {
                    background-color: rgba(27,31,35,0.05);
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, Menlo, Consolas, monospace;
                    font-size: 85%;
                    padding: 0.2em 0.4em;
                }
                pre {
                    background-color: #f6f8fa;
                    border-radius: 3px;
                    font-family: 'SF Mono', Monaco, Menlo, Consolas, monospace;
                    font-size: 85%;
                    line-height: 1.45;
                    overflow: auto;
                    padding: 16px;
                }
                pre code {
                    background-color: transparent;
                    padding: 0;
                }
                strong { font-weight: 600; }
                em { font-style: italic; }
                ul, ol { padding-left: 2em; }
                li { margin-top: 0.25em; }
                blockquote {
                    border-left: 4px solid #dfe2e5;
                    color: #6a737d;
                    padding-left: 1em;
                    margin-left: 0;
                }
                a { color: #0366d6; text-decoration: none; }
                a:hover { text-decoration: underline; }
            </style>
        </head>
        <body>
        <div style="background: #e3f2fd; padding: 10px; margin-bottom: 20px; border-left: 4px solid #2196F3; font-weight: bold;">
            ✓ Rendered by md-spotlighter Quick Look Extension
        </div>
        \(renderMarkdownToHTML(content))
        </body>
        </html>
        """

        try? "HTML generated: \(html.count) bytes\n".appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)
        os_log("Rendering complete, HTML length: %d", log: .quicklook, type: .info, html.count)

        // Ensure webView is ready
        if webView == nil {
            os_log("ERROR: webView is nil!", log: .quicklook, type: .error)
            handler(NSError(domain: "MDQuickLook", code: 1, userInfo: [NSLocalizedDescriptionKey: "WebView not initialized"]))
            return
        }

        // Load HTML into WebView
        os_log("Loading HTML into WebView...", log: .quicklook, type: .debug)
        webView.loadHTMLString(html, baseURL: nil)
        try? "WebView loaded HTML\n".appending(to: URL(fileURLWithPath: debugLog), encoding: .utf8)

        // Signal completion
        os_log("Quick Look preview complete", log: .quicklook, type: .info)
        handler(nil)
    }

    private func renderMarkdownToHTML(_ markdown: String) -> String {
        // Basic markdown-to-HTML conversion
        var html = markdown

        os_log("Rendering markdown, length: %d", log: .quicklook, type: .debug, markdown.count)

        // Headers (must be done FIRST, before any escaping)
        html = html.replacingOccurrences(of: #"(?m)^### (.+)$"#, with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"(?m)^## (.+)$"#, with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"(?m)^# (.+)$"#, with: "<h1>$1</h1>", options: .regularExpression)

        // Inline code (before bold/italic to avoid conflicts)
        html = html.replacingOccurrences(of: #"`([^`]+)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Bold and italic
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)

        // Paragraphs (double newline = paragraph break)
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { para in
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "" }
            if trimmed.hasPrefix("<h") { return trimmed }
            return "<p>\(trimmed.replacingOccurrences(of: "\n", with: "<br>"))</p>"
        }.joined(separator: "\n")

        os_log("Rendered HTML length: %d", log: .quicklook, type: .debug, html.count)

        return html
    }
}
