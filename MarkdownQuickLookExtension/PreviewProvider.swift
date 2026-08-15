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
            let data = try Data(contentsOf: fileURL)
            let markdownContent: String
            if let utf8 = String(data: data, encoding: .utf8) {
                markdownContent = utf8
            } else if let latin1 = String(data: data, encoding: .isoLatin1) {
                markdownContent = latin1
            } else {
                markdownContent = String(decoding: data, as: UTF8.self)
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
                throw NSError(domain: "MarkdownPreview", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode HTML data"])
            }

            return htmlData
        }

        handler(reply, nil)
    }
}
