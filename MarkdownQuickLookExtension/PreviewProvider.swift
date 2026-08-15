import Cocoa
import QuickLook
import QuickLookUI
import UniformTypeIdentifiers
import MarkdownRenderer

@objc(PreviewProvider)
final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let preferences = SharedPreferences.shared

    func providePreview(for request: QLFilePreviewRequest, completionHandler handler: @escaping (QLPreviewReply?, Error?) -> Void) {
        let fileURL = request.fileURL

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: CGSize(width: 860, height: 1000)) { (reply: QLPreviewReply) throws -> Data in
            let didStartAccess = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccess {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            let markdownContent: String
            do {
                let data = try Data(contentsOf: fileURL)
                if let utf8 = String(data: data, encoding: .utf8) {
                    markdownContent = utf8
                } else if let latin1 = String(data: data, encoding: .isoLatin1) {
                    markdownContent = latin1
                } else {
                    markdownContent = String(decoding: data, as: UTF8.self)
                }
            } catch {
                let errorHTML = """
                <!DOCTYPE html>
                <html>
                <head><meta charset="utf-8"/><style>body{font-family:-apple-system,sans-serif;padding:2rem;color:#666;}</style></head>
                <body><h3>Unable to preview markdown file</h3><p>\(HTMLGenerator.escapeHTML(error.localizedDescription))</p></body>
                </html>
                """
                return errorHTML.data(using: .utf8) ?? Data()
            }

            let themeRaw = self.preferences.selectedTheme
            let theme = Theme(rawValue: themeRaw) ?? .system
            let options = RenderOptions(
                enableSyntaxHighlighting: self.preferences.enableSyntaxHighlighting,
                enableMath: self.preferences.enableMathRendering,
                enableCallouts: true,
                enableFrontmatter: true,
                enableWikilinks: true
            )

            let baseURL = fileURL.deletingLastPathComponent()
            let fullHTML = MarkdownRenderer.render(
                markdown: markdownContent,
                baseURL: baseURL,
                theme: theme,
                options: options
            )

            guard let htmlData = fullHTML.data(using: .utf8) else {
                let fallback = """
                <!DOCTYPE html>
                <html><head><meta charset="utf-8"/></head><body><pre>\(HTMLGenerator.escapeHTML(markdownContent))</pre></body></html>
                """
                return fallback.data(using: .utf8) ?? Data()
            }

            return htmlData
        }

        handler(reply, nil)
    }
}
