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
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        let html = MarkdownRenderer.render(
            markdown: markdown,
            baseURL: baseURL,
            theme: theme,
            options: options
        )
        webView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        let html = MarkdownRenderer.render(
            markdown: markdown,
            baseURL: baseURL,
            theme: theme,
            options: options
        )
        nsView.loadHTMLString(html, baseURL: Bundle.main.resourceURL)
    }
}
