import Foundation

public enum MarkdownRenderer {
    public static func render(
        markdown: String,
        baseURL: URL? = nil,
        theme: Theme = .system,
        options: RenderOptions = .default
    ) -> String {
        let bodyHTML = MarkdownParser.parseToHTML(
            markdown: markdown,
            baseURL: baseURL,
            options: options
        )

        let mathCSS = options.enableMath ? "\n<style>\n\(EmbeddedScripts.katexCSS)\n</style>" : ""
        let mathJS = options.enableMath ? "\n\(EmbeddedScripts.katexScript)" : ""

        let completeHTML = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
            <style>
            \(theme.css)
            </style>\(mathCSS)
        </head>
        <body>
            <main class="markdown-body">
                \(bodyHTML)
            </main>\(mathJS)
        </body>
        </html>
        """

        return completeHTML
    }

    public static func renderHTMLFragment(
        markdown: String,
        baseURL: URL? = nil,
        options: RenderOptions = .default
    ) -> String {
        return MarkdownParser.parseToHTML(
            markdown: markdown,
            baseURL: baseURL,
            options: options
        )
    }
}
