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

        os_log("Rendering complete", log: .quicklook, type: .info)

        // Return QLPreviewReply with HTML data
        return QLPreviewReply(dataOfContentType: .html, contentSize: .zero) { _ in
            return html.data(using: .utf8)!
        }
    }

    private func renderMarkdownToHTML(_ markdown: String) -> String {
        // Basic markdown-to-HTML conversion
        var html = markdown

        // Escape HTML entities first
        html = html.replacingOccurrences(of: "&", with: "&amp;")
        html = html.replacingOccurrences(of: "<", with: "&lt;")
        html = html.replacingOccurrences(of: ">", with: "&gt;")

        // Headers (must be done before bold/italic to avoid conflicts)
        html = html.replacingOccurrences(of: #"(?m)^### (.+)$"#, with: "<h3>$1</h3>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"(?m)^## (.+)$"#, with: "<h2>$1</h2>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"(?m)^# (.+)$"#, with: "<h1>$1</h1>", options: .regularExpression)

        // Bold and italic
        html = html.replacingOccurrences(of: #"\*\*(.+?)\*\*"#, with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: #"\*(.+?)\*"#, with: "<em>$1</em>", options: .regularExpression)

        // Inline code
        html = html.replacingOccurrences(of: #"`(.+?)`"#, with: "<code>$1</code>", options: .regularExpression)

        // Paragraphs (double newline = paragraph break)
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { para in
            let trimmed = para.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { return "" }
            if trimmed.hasPrefix("<h") || trimmed.hasPrefix("<pre") { return trimmed }
            return "<p>\(trimmed.replacingOccurrences(of: "\n", with: "<br>"))</p>"
        }.joined(separator: "\n")

        return html
    }
}
