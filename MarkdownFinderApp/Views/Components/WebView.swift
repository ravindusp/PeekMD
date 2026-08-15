import SwiftUI
import WebKit
import MarkdownRenderer

public struct MarkdownWebView: NSViewRepresentable {
    public let markdown: String
    public let baseURL: URL?
    public let theme: Theme
    public let options: RenderOptions

    public init(
        markdown: String,
        baseURL: URL? = nil,
        theme: Theme = .system,
        options: RenderOptions = .default
    ) {
        self.markdown = markdown
        self.baseURL = baseURL
        self.theme = theme
        self.options = options
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        let html = MarkdownRenderer.render(
            markdown: markdown,
            baseURL: baseURL,
            theme: theme,
            options: options
        )

        let targetBaseURL = baseURL ?? Bundle.main.bundleURL
        nsView.loadHTMLString(html, baseURL: targetBaseURL)
    }
}
