import XCTest
@testable import MarkdownRenderer

final class MarkdownRendererTests: XCTestCase {
    func testHeadingsParsing() {
        let md = """
        # Title H1
        ## Subtitle H2
        ### Section H3
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<h1>Title H1</h1>"))
        XCTAssertTrue(html.contains("<h2>Subtitle H2</h2>"))
        XCTAssertTrue(html.contains("<h3>Section H3</h3>"))
    }

    func testInlineFormatting() {
        let md = "This is **bold**, *italic*, ***bold-italic***, `code`, and ~~strike~~."
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
        XCTAssertTrue(html.contains("<strong><em>bold-italic</em></strong>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<del>strike</del>"))
    }

    func testFencedCodeBlockWithLanguage() {
        let md = """
        ```swift
        func greet() -> String {
            return "Hello"
        }
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("code-block-container"))
        XCTAssertTrue(html.contains("token-keyword"))
    }

    func testGFMTableParsing() {
        let md = """
        | Syntax | Description | Align |
        | :--- | :---: | ---: |
        | Header | Title | 100 |
        | Paragraph | Text | 200 |
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<table>"))
        XCTAssertTrue(html.contains("Syntax</th>"))
        XCTAssertTrue(html.contains("<td style=\"text-align: right;\">100</td>"))
    }

    func testTaskListParsing() {
        let md = """
        - [ ] Buy groceries
        - [x] Read docs
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("task-list"))
        XCTAssertTrue(html.contains("task-checkbox"))
        XCTAssertTrue(html.contains("checked disabled"))
    }

    func testCalloutParsing() {
        let md = """
        > [!NOTE] Custom Notice
        > This is important information.
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("callout callout-note"))
        XCTAssertTrue(html.contains("Custom Notice"))
        XCTAssertTrue(html.contains("This is important information."))
    }

    func testMathParsing() {
        let md = "Energy formula is $E=mc^2$."
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("math-inline"))
        XCTAssertTrue(html.contains("\\(E=mc^2\\)"))
    }

    func testHTMLSanitization() {
        let md = "Dangerous <script>alert('xss')</script> tag"
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertTrue(html.contains("&lt;script&gt;"))
    }

    func testFrontmatterParsing() {
        let md = """
        ---
        title: Sample Document
        author: Steve
        ---
        # Real Content
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("frontmatter-card"))
        XCTAssertTrue(html.contains("Sample Document"))
        XCTAssertTrue(html.contains("Steve"))
        XCTAssertTrue(html.contains("<h1>Real Content</h1>"))
    }
}
