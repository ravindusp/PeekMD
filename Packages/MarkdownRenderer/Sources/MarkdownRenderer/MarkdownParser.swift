import Foundation
import Markdown

public final class MarkdownParser {
    public static func parseToHTML(
        markdown: String,
        baseURL: URL? = nil,
        options: RenderOptions = .default
    ) -> String {
        var processedMarkdown = markdown
        var frontmatterHTML = ""

        // 1. Extract YAML Frontmatter
        if options.enableFrontmatter {
            let (extractedFM, remainingMD) = extractFrontmatter(processedMarkdown)
            if let fm = extractedFM {
                frontmatterHTML = renderFrontmatterCard(fm)
            }
            processedMarkdown = remainingMD
        }

        var inlineMathTable: [String: String] = [:]

        // 2. Preprocess Math (Display blocks & Inlines)
        if options.enableMath {
            let mathResult = MathParser.preprocessMath(processedMarkdown)
            processedMarkdown = mathResult.markdown
            inlineMathTable = mathResult.inlineMathTable
        }

        // 3. Preprocess Footnotes
        let (preprocessedWithFootnotes, footnoteDefinitions) = extractFootnotes(processedMarkdown)
        processedMarkdown = preprocessedWithFootnotes

        // 4. Build AST using swift-markdown (backed by cmark-gfm)
        let document = Document(
            parsing: processedMarkdown,
            options: [
                .parseBlockDirectives
            ]
        )

        // 5. Visit AST with MarkdownHTMLVisitor
        var visitor = MarkdownHTMLVisitor(baseURL: baseURL, options: options)
        var bodyHTML = visitor.visit(document)

        // 6. Append Footnotes Section if any definitions were collected
        if !footnoteDefinitions.isEmpty {
            bodyHTML += renderFootnotesSection(footnoteDefinitions, baseURL: baseURL, options: options)
        }

        // 7. Restore Inline Math Placeholders
        if options.enableMath && !inlineMathTable.isEmpty {
            bodyHTML = MathParser.restoreInlineMath(in: bodyHTML, table: inlineMathTable)
        }

        return frontmatterHTML + bodyHTML
    }

    // MARK: - Frontmatter Handling

    private static func extractFrontmatter(_ text: String) -> ([String]?, String) {
        let lines = text.components(separatedBy: "\n")
        guard let first = lines.first?.trimmingCharacters(in: .whitespaces), first == "---" else {
            return (nil, text)
        }

        var fmLines: [String] = []
        var closingIndex = -1

        for i in 1..<lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces) == "---" {
                closingIndex = i
                break
            }
            fmLines.append(line)
        }

        guard closingIndex != -1, !fmLines.isEmpty else {
            return (nil, text)
        }

        let remaining = lines.dropFirst(closingIndex + 1).joined(separator: "\n")
        return (fmLines, remaining)
    }

    private static func renderFrontmatterCard(_ lines: [String]) -> String {
        var entries: [(key: String, value: String)] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.hasPrefix("#") { continue }

            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                var val = String(trimmed[trimmed.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)

                if (val.hasPrefix("\"") && val.hasSuffix("\"")) || (val.hasPrefix("'") && val.hasSuffix("'")) {
                    val = String(val.dropFirst().dropLast())
                }

                entries.append((key: key, value: val))
            }
        }

        guard !entries.isEmpty else { return "" }

        var html = "<div class=\"frontmatter-card\">\n"
        html += "  <div class=\"frontmatter-title\">Metadata</div>\n"
        for entry in entries {
            let k = HTMLGenerator.escapeHTML(entry.key)
            let v = HTMLGenerator.escapeHTML(entry.value)
            html += "  <div class=\"frontmatter-entry\"><span class=\"frontmatter-key\">\(k):</span> <span class=\"frontmatter-val\">\(v)</span></div>\n"
        }
        html += "</div>\n"

        return html
    }


    // MARK: - Footnotes Preprocessing & Rendering

    private static func extractFootnotes(_ text: String) -> (String, [String: String]) {
        var definitions: [String: String] = [:]
        let lines = text.components(separatedBy: "\n")
        var filteredLines: [String] = []

        let defPattern = #"^\[\^([a-zA-Z0-9_-]+)\]:\s*(.*)$"#
        guard let defRegex = try? NSRegularExpression(pattern: defPattern) else {
            return (text, [:])
        }

        var currentDefKey: String? = nil
        var currentDefContent: [String] = []

        for line in lines {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            if let match = defRegex.firstMatch(in: line, options: [], range: range) {
                if let key = currentDefKey {
                    definitions[key] = currentDefContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    currentDefContent = []
                }
                if let keyRange = Range(match.range(at: 1), in: line),
                   let contentRange = Range(match.range(at: 2), in: line) {
                    currentDefKey = String(line[keyRange])
                    currentDefContent.append(String(line[contentRange]))
                }
            } else if let _ = currentDefKey, line.hasPrefix("    ") || line.hasPrefix("\t") {
                currentDefContent.append(line.trimmingCharacters(in: .whitespaces))
            } else {
                if let key = currentDefKey {
                    definitions[key] = currentDefContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    currentDefKey = nil
                    currentDefContent = []
                }
                filteredLines.append(line)
            }
        }

        if let key = currentDefKey {
            definitions[key] = currentDefContent.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var cleanedText = filteredLines.joined(separator: "\n")

        // Replace inline footnote references [^1] with HTML superscript links
        let refPattern = #"\[\^([a-zA-Z0-9_-]+)\]"#
        if let refRegex = try? NSRegularExpression(pattern: refPattern) {
            let range = NSRange(cleanedText.startIndex..<cleanedText.endIndex, in: cleanedText)
            cleanedText = refRegex.stringByReplacingMatches(
                in: cleanedText,
                options: [],
                range: range,
                withTemplate: "<sup class=\"footnote-ref\"><a href=\"#fn-$1\" id=\"fnref-$1\">$1</a></sup>"
            )
        }

        return (cleanedText, definitions)
    }

    private static func renderFootnotesSection(_ definitions: [String: String], baseURL: URL?, options: RenderOptions) -> String {
        guard !definitions.isEmpty else { return "" }

        var html = "<section class=\"footnotes\">\n<hr />\n<ol>\n"
        for (key, content) in definitions.sorted(by: { $0.key < $1.key }) {
            let doc = Document(parsing: content)
            var visitor = MarkdownHTMLVisitor(baseURL: baseURL, options: options)
            let contentHTML = visitor.visit(doc).trimmingCharacters(in: .whitespacesAndNewlines)
            let escapedKey = HTMLGenerator.escapeHTML(key)
            html += "<li id=\"fn-\(escapedKey)\">\(contentHTML) <a href=\"#fnref-\(escapedKey)\" class=\"footnote-backref\">↩</a></li>\n"
        }
        html += "</ol>\n</section>\n"
        return html
    }
}
