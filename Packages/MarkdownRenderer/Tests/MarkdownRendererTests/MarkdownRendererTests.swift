import XCTest
@testable import MarkdownRenderer

final class MarkdownRendererTests: XCTestCase {

    // MARK: - Headings

    func testHeadingsATXAndSetext() {
        let md = """
        # Heading 1
        ## Heading 2
        ### Heading 3
        #### Heading 4
        ##### Heading 5
        ###### Heading 6

        Setext H1
        =========

        Setext H2
        ---------
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<h1 id=\"heading-1\">Heading 1</h1>"))
        XCTAssertTrue(html.contains("<h2 id=\"heading-2\">Heading 2</h2>"))
        XCTAssertTrue(html.contains("<h3 id=\"heading-3\">Heading 3</h3>"))
        XCTAssertTrue(html.contains("<h4 id=\"heading-4\">Heading 4</h4>"))
        XCTAssertTrue(html.contains("<h5 id=\"heading-5\">Heading 5</h5>"))
        XCTAssertTrue(html.contains("<h6 id=\"heading-6\">Heading 6</h6>"))
        XCTAssertTrue(html.contains("<h1 id=\"setext-h1\">Setext H1</h1>"))
        XCTAssertTrue(html.contains("<h2 id=\"setext-h2\">Setext H2</h2>"))
    }

    // MARK: - Inline Formatting

    func testInlineFormatting() {
        let md = "This is **bold**, *italic*, ***bold-italic***, `code`, and ~~strike~~ with ==highlight==, x^2^, and H~2~O."
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
        XCTAssertTrue(html.contains("<em><strong>bold-italic</strong></em>") || html.contains("<strong><em>bold-italic</em></strong>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<del>strike</del>"))
        XCTAssertTrue(html.contains("<mark>highlight</mark>"))
        XCTAssertTrue(html.contains("<sup>2</sup>"))
    }

    func testInlineCodeContainingBackticks() {
        let md = "Use `` `code with backticks` `` in Markdown."
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<code>`code with backticks`</code>"))
    }

    // MARK: - Syntax Highlighting & Tokenizer Safety (P0)

    func testSyntaxHighlightingNoTagCorruptionSwift() {
        let code = """
        ```swift
        // Swift string containing token class fragment
        let str = "Dangerous class=\\\"token-string\\\"> fragment"
        let count = 42
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("token-keyword"))
        XCTAssertTrue(html.contains("token-string"))
        XCTAssertTrue(html.contains("token-comment"))
        // Check that literal text inside the code block is never corrupted by multiple regex passes
        XCTAssertFalse(html.contains("class=\"<span"))
        XCTAssertFalse(html.contains("token-string\">>"))
    }

    func testSyntaxHighlightingTypeScript() {
        let code = """
        ```typescript
        interface User {
            id: number;
            name: string;
        }
        const user: User = { id: 1, name: "Alice class=\\\"token-keyword\\\">" };
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-typescript"))
        XCTAssertTrue(html.contains("token-keyword"))
        XCTAssertTrue(html.contains("token-string"))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testSyntaxHighlightingJSON() {
        let code = """
        ```json
        {
          "key": "value class=\\\"token-property\\\">",
          "count": 100,
          "active": true
        }
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-json"))
        XCTAssertTrue(html.contains("token-property"))
        XCTAssertTrue(html.contains("token-string"))
        XCTAssertTrue(html.contains("token-number"))
        XCTAssertTrue(html.contains("token-keyword"))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testSyntaxHighlightingBashWithURLsAndComments() {
        let code = """
        ```bash
        #!/usr/bin/env bash
        # Download from https://github.com/oneloop/PeekMD
        curl -s https://example.com/api?param=class%3Dtoken
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-bash"))
        XCTAssertTrue(html.contains("token-comment"))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testSyntaxHighlightingHTMLSource() {
        let code = """
        ```html
        <div class="header">
            <h1 id="title">Hello World</h1>
        </div>
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-html"))
        XCTAssertTrue(html.contains("token-tag"))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testSyntaxHighlightingUnknownLanguage() {
        let code = """
        ```customlang
        CUSTOM_TOKEN 12345 "some string"
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("language-customlang"))
        XCTAssertTrue(html.contains("CUSTOM_TOKEN"))
        XCTAssertTrue(html.contains("token-number"))
        XCTAssertTrue(html.contains("token-string"))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testPlainCodeBlockNoHighlighting() {
        let code = """
        ```text
        CUSTOM_TOKEN 12345 "some string"
        ```
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: code)
        XCTAssertTrue(html.contains("CUSTOM_TOKEN 12345 &quot;some string&quot;"))
        XCTAssertFalse(html.contains("token-"))
    }

    // MARK: - Tables & Escaped Pipes (P1)

    func testGFMTableParsingWithEscapedPipes() {
        let md = """
        | Value | Description | Number |
        | :--- | :---: | ---: |
        | `A \\| B` | Pipe character | 100 |
        | Text | Second row | 200 |
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<div class=\"table-wrapper\"><table>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: left;\">Value</th>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: center;\">Description</th>"))
        XCTAssertTrue(html.contains("<th style=\"text-align: right;\">Number</th>"))
        XCTAssertTrue(html.contains("<code>A | B</code>"))
        XCTAssertTrue(html.contains("<td style=\"text-align: right;\">100</td>"))
    }

    // MARK: - Lists & Hierarchy Preservation (P1)

    func testNestedListsAndContinuationParagraphs() {
        let md = """
        1. First paragraph.

           Second paragraph.

           ```text
           Code inside the same list item.
           ```

        2. Second item.
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<ol>"))
        XCTAssertTrue(html.contains("First paragraph."))
        XCTAssertTrue(html.contains("Second paragraph."))
        XCTAssertTrue(html.contains("Code inside the same list item."))
        XCTAssertTrue(html.contains("Second item."))
    }

    func testTaskListParsing() {
        let md = """
        - [x] Completed task
          - [x] Nested complete
          - [ ] Nested incomplete
        - [ ] Pending task
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"task-list\""))
        XCTAssertTrue(html.contains("class=\"task-checkbox\" disabled checked"))
        XCTAssertTrue(html.contains("class=\"task-checkbox\" disabled"))
        XCTAssertTrue(html.contains("Completed task"))
        XCTAssertTrue(html.contains("Nested complete"))
        XCTAssertTrue(html.contains("Pending task"))
    }

    // MARK: - Callouts (P1)

    func testObsidianCalloutVariants() {
        let md = """
        > [!NOTE] Custom Note
        > Note content.

        > [!TIP]
        > Tip content.

        > [!WARNING]
        > Warning content.

        > [!IMPORTANT]
        > Important content.

        > [!CAUTION]
        > Caution content.

        > [!SUCCESS]
        > Success content.

        > [!QUESTION]
        > Question content.

        > [!DANGER]
        > Danger content.

        > [!BUG]
        > Bug content.

        > [!EXAMPLE]
        > Example content.

        > [!QUOTE]
        > Quote content.
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("callout callout-note"))
        XCTAssertTrue(html.contains("Custom Note"))
        XCTAssertTrue(html.contains("callout callout-tip"))
        XCTAssertTrue(html.contains("callout callout-warning"))
        XCTAssertTrue(html.contains("callout callout-important"))
        XCTAssertTrue(html.contains("callout callout-caution"))
        XCTAssertTrue(html.contains("callout callout-success"))
        XCTAssertTrue(html.contains("callout callout-question"))
        XCTAssertTrue(html.contains("callout callout-danger"))
        XCTAssertTrue(html.contains("callout callout-bug"))
        XCTAssertTrue(html.contains("callout callout-example"))
        XCTAssertTrue(html.contains("callout callout-quote"))
    }

    func testFoldableCallouts() {
        let md = """
        > [!NOTE]+ Expanded Callout
        > Expanded body text.

        > [!WARNING]- Collapsed Callout
        > Collapsed body text.
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<details class=\"callout callout-note callout-foldable\" open>"))
        XCTAssertTrue(html.contains("<summary class=\"callout-header\">"))
        XCTAssertTrue(html.contains("Expanded Callout"))
        XCTAssertTrue(html.contains("<details class=\"callout callout-warning callout-foldable\">"))
        XCTAssertTrue(html.contains("Collapsed Callout"))
    }

    // MARK: - Wikilinks (P1)

    func testWikilinksAndEmbeds() {
        let md = """
        Link to [[README]] and [[Guide|User Guide]] and [[Doc#Section]] and [[Doc#^block-42]].
        Embed ![[assets/diagram.png|300]].
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("<a href=\"#wikilink:README\" class=\"wikilink\">README</a>"))
        XCTAssertTrue(html.contains("<a href=\"#wikilink:Guide\" class=\"wikilink\">User Guide</a>"))
        XCTAssertTrue(html.contains("<a href=\"#wikilink:Doc#Section\" class=\"wikilink\">Doc#Section</a>"))
        XCTAssertTrue(html.contains("<a href=\"#wikilink:Doc#^block-42\" class=\"wikilink\">Doc#^block-42</a>"))
        XCTAssertTrue(html.contains("<img src=\"assets/diagram.png\" alt=\"assets/diagram.png\" loading=\"lazy\" width=\"300\" />"))
    }

    // MARK: - Math (P1)

    func testMathParsing() {
        let md = """
        Inline formula: $E = mc^2$.
        Currency: $50 and $100 should remain plain numbers.
        Display formula:
        $$
        \\int_{-\\infty}^{\\infty} e^{-x^2}\\,dx = \\sqrt{\\pi}
        $$
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-inline\""))
        XCTAssertTrue(html.contains("\\(E = mc^2\\)"))
        XCTAssertTrue(html.contains("class=\"math-block\""))
        XCTAssertTrue(html.contains("\\[\\int_{-\\infty}^{\\infty} e^{-x^2}\\,dx = \\sqrt{\\pi}\\]"))
        XCTAssertTrue(html.contains("$50 and $100"))
    }

    func testLaTeXBracketDisplayMathUserReportedBug() {
        let md = """
        The contribution is an experimentally tested hybrid framework:

        \\[ \\text{Deterministic harmonisation} \\rightarrow \\text{Material prior} \\rightarrow \\text{Real-EPD calibration} \\rightarrow \\text{Uncertainty/OOD} \\rightarrow \\text{Abstain or provisional estimate} \\rightarrow \\text{Human validation} \\]

        The framework is compared against:
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-block\""), "Should render display math block for \\[ ... \\]")
        XCTAssertTrue(html.contains("\\text{Deterministic harmonisation} \\rightarrow \\text{Material prior}"), "Should preserve math content with arrows and formatting")
        XCTAssertFalse(html.contains("<p>[ \\text{Deterministic"), "Should not render raw stripped brackets as a paragraph")
    }

    func testLaTeXBracketMultilineDisplayMath() {
        let md = """
        \\[
        \\sum_{i=1}^{n} X_i = \\mu
        \\]
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-block\""))
        XCTAssertTrue(html.contains("\\[\\sum_{i=1}^{n} X_i = \\mu\\]"))
    }

    func testSingleLineDoubleDollarDisplayMath() {
        let md = """
        $$ a^2 + b^2 = c^2 $$
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-block\""))
        XCTAssertTrue(html.contains("\\[a^2 + b^2 = c^2\\]"))
    }

    func testLaTeXEnvironments() {
        let md = """
        \\begin{align}
        a &= b + c \\\\
        d &= e + f
        \\end{align}
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-block\""))
        XCTAssertTrue(html.contains("\\begin{align}"))
        XCTAssertTrue(html.contains("\\end{align}"))
    }

    func testInlineLaTeXParenMath() {
        let md = """
        Given \\( f(x) = \\frac{1}{x} \\) and \\( x \\neq 0 \\).
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("class=\"math-inline\""))
        XCTAssertTrue(html.contains("\\(f(x) = \\frac{1}{x}\\)"))
        XCTAssertTrue(html.contains("\\(x \\neq 0\\)"))
    }

    func testMathInCodeBlocksPreserved() {
        let md = """
        ```swift
        let bracket = "\\[ not math \\]"
        let price = "$50"
        ```
        And inline code: `\\[ not math \\]` and `$not_math$`.
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertTrue(html.contains("&quot;\\[ not math \\]&quot;"))
        XCTAssertTrue(html.contains("<code>\\[ not math \\]</code>"))
        XCTAssertTrue(html.contains("<code>$not_math$</code>"))
        XCTAssertFalse(html.contains("class=\"math-block\""))
    }

    func testFullPageRenderWithKaTeXBundle() {
        let md = """
        \\[\\hat y=p+\\hat r\\]
        """
        let html = MarkdownRenderer.render(markdown: md)
        XCTAssertTrue(html.contains("<div class=\"math-block\">\\[\\hat y=p+\\hat r\\]</div>"))
        XCTAssertTrue(html.contains("katex"))
        XCTAssertTrue(html.contains("renderMathInElement"))
    }

    // MARK: - Safe Raw HTML & Sanitization (P0)

    func testSafeHTMLGitHubREADME() {
        let md = """
        <!-- Comment: should be hidden -->
        <div align="center">
            <h1 id="title">PeekMD</h1>
            <p align="center">Modern Markdown Viewer</p>
            <img src="assets/logo.png" width="120" alt="Logo" />
        </div>

        <details>
            <summary>Requirements</summary>
            <p>macOS 13+</p>
        </details>

        Safe inlines: <kbd>Cmd</kbd> + <kbd>C</kbd> and <mark>highlight</mark>.

        <script>alert('xss')</script>
        <img src="assets/safe.png" onerror="alert('hack')" />
        """
        let html = MarkdownRenderer.renderHTMLFragment(markdown: md)
        XCTAssertFalse(html.contains("<!-- Comment:"))
        XCTAssertTrue(html.contains("<div align=\"center\">"))
        XCTAssertTrue(html.contains("<p align=\"center\">"))
        XCTAssertTrue(html.contains("<img src=\"assets/logo.png\" width=\"120\" alt=\"Logo\" />"))
        XCTAssertTrue(html.contains("<details>"))
        XCTAssertTrue(html.contains("<summary>Requirements</summary>"))
        XCTAssertTrue(html.contains("<kbd>Cmd</kbd>"))
        XCTAssertTrue(html.contains("<mark>highlight</mark>"))

        // Malicious elements must be stripped
        XCTAssertFalse(html.contains("<script>"))
        XCTAssertFalse(html.contains("alert('xss')"))
        XCTAssertFalse(html.contains("onerror="))
        XCTAssertFalse(html.contains("alert('hack')"))
    }

    // MARK: - Frontmatter

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
        XCTAssertTrue(html.contains("<h1 id=\"real-content\">Real Content</h1>"))
    }

    // MARK: - Full Compatibility Fixtures

    func testCompatibilityFixtureRendering() {
        let currentDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let fixtureURL = currentDir.appendingPathComponent("Fixtures/PeekMD-Markdown-Compatibility-Test.md")

        guard FileManager.default.fileExists(atPath: fixtureURL.path),
              let md = try? String(contentsOf: fixtureURL) else {
            XCTFail("Could not read compatibility fixture at \(fixtureURL.path)")
            return
        }

        let html = MarkdownRenderer.render(
            markdown: md,
            baseURL: currentDir.appendingPathComponent("Fixtures"),
            theme: .system
        )

        XCTAssertTrue(html.contains("<!DOCTYPE html>"))
        XCTAssertTrue(html.contains("PeekMD Compatibility Test Suite"))
        XCTAssertTrue(html.contains("<div class=\"frontmatter-card\">"))
        XCTAssertTrue(html.contains("<h1 id=\"heading-1-atx\">Heading 1 (ATX)</h1>"))
        XCTAssertTrue(html.contains("<div class=\"table-wrapper\"><table>"))
        XCTAssertTrue(html.contains("callout callout-note"))
        XCTAssertTrue(html.contains("callout-foldable"))
        XCTAssertTrue(html.contains("language-swift"))
        XCTAssertTrue(html.contains("language-typescript"))
        XCTAssertTrue(html.contains("language-json"))
        XCTAssertTrue(html.contains("<details>"))
        XCTAssertTrue(html.contains("<summary>Click to view system requirements</summary>"))
        XCTAssertTrue(html.contains("class=\"math-inline\""))
        XCTAssertTrue(html.contains("class=\"math-block\""))
        XCTAssertTrue(html.contains("class=\"mermaid-block\""))
        XCTAssertTrue(html.contains("<section class=\"footnotes\">"))
        XCTAssertFalse(html.contains("<script>alert("))
        XCTAssertFalse(html.contains("onerror=\"alert("))
        XCTAssertFalse(html.contains("class=\"<span"))
    }

    func testGitHubREADMEFixtureRendering() {
        let currentDir = URL(fileURLWithPath: #file).deletingLastPathComponent()
        let fixtureURL = currentDir.appendingPathComponent("Fixtures/GitHub-README-Test.md")

        guard FileManager.default.fileExists(atPath: fixtureURL.path),
              let md = try? String(contentsOf: fixtureURL) else {
            XCTFail("Could not read GitHub README fixture at \(fixtureURL.path)")
            return
        }

        let html = MarkdownRenderer.render(
            markdown: md,
            baseURL: currentDir.appendingPathComponent("Fixtures"),
            theme: .github
        )

        XCTAssertTrue(html.contains("<div align=\"center\">"))
        XCTAssertTrue(html.contains("<p align=\"center\">"))
        XCTAssertTrue(html.contains("<details>"))
        XCTAssertTrue(html.contains("<summary>"))
        XCTAssertTrue(html.contains("<kbd>Space</kbd>"))
        XCTAssertTrue(html.contains("<div class=\"table-wrapper\"><table>"))
    }

    func testProjectREADMEFileRendering() {
        let currentDir = URL(fileURLWithPath: #file)
        // Climb up to root project directory
        let rootREADMEURL = currentDir
            .deletingLastPathComponent() // Tests
            .deletingLastPathComponent() // MarkdownRenderer
            .deletingLastPathComponent() // Packages
            .deletingLastPathComponent() // MD
            .appendingPathComponent("README.md")

        if FileManager.default.fileExists(atPath: rootREADMEURL.path),
           let md = try? String(contentsOf: rootREADMEURL) {
            let html = MarkdownRenderer.render(
                markdown: md,
                baseURL: rootREADMEURL.deletingLastPathComponent(),
                theme: .system
            )
            XCTAssertTrue(html.contains("<h1 id=\"peekmd-\">PeekMD 📝</h1>") || html.contains("PeekMD 📝"))
            XCTAssertTrue(html.contains("Features"))
            XCTAssertTrue(html.contains("Architecture"))
            XCTAssertTrue(html.contains("Building &amp; Running"))
        }
    }
}

