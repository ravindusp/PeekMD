import Foundation

public final class MarkdownParser {
    public static func parseToHTML(
        markdown: String,
        baseURL: URL? = nil,
        options: RenderOptions = .default
    ) -> String {
        let lines = markdown.components(separatedBy: "\n")
        var html = ""
        var lineIndex = 0
        let totalLines = lines.count

        // 1. Check for YAML Frontmatter at the very top
        if options.enableFrontmatter && lineIndex < totalLines && lines[lineIndex].trimmingCharacters(in: .whitespaces) == "---" {
            lineIndex += 1
            var frontmatterLines: [String] = []
            var foundClosing = false

            while lineIndex < totalLines {
                let line = lines[lineIndex]
                if line.trimmingCharacters(in: .whitespaces) == "---" {
                    foundClosing = true
                    lineIndex += 1
                    break
                }
                frontmatterLines.append(line)
                lineIndex += 1
            }

            if foundClosing && !frontmatterLines.isEmpty {
                html += renderFrontmatterCard(frontmatterLines)
            }
        }

        // 2. Parse rest of the document line by line
        while lineIndex < totalLines {
            let line = lines[lineIndex]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Empty line
            if trimmed.isEmpty {
                lineIndex += 1
                continue
            }

            // Fenced Code Block
            if trimmed.hasPrefix("```") {
                let lang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                lineIndex += 1
                var codeLines: [String] = []

                while lineIndex < totalLines {
                    let cLine = lines[lineIndex]
                    if cLine.trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                        lineIndex += 1
                        break
                    }
                    codeLines.append(cLine)
                    lineIndex += 1
                }

                let codeContent = codeLines.joined(separator: "\n")
                let highlighted = options.enableSyntaxHighlighting
                    ? HTMLGenerator.highlightCode(code: codeContent, language: lang)
                    : HTMLGenerator.escapeHTML(codeContent)

                let langTag = lang.isEmpty ? "" : "<div class=\"code-lang-tag\">\(HTMLGenerator.escapeHTML(lang))</div>"
                html += "<div class=\"code-block-container\">\(langTag)<pre><code class=\"language-\(HTMLGenerator.escapeHTML(lang))\">\(highlighted)</code></pre></div>\n"
                continue
            }

            // Display Math Block ($$...$$)
            if options.enableMath && trimmed == "$$" {
                lineIndex += 1
                var mathLines: [String] = []
                while lineIndex < totalLines {
                    let mLine = lines[lineIndex]
                    if mLine.trimmingCharacters(in: .whitespaces) == "$$" {
                        lineIndex += 1
                        break
                    }
                    mathLines.append(mLine)
                    lineIndex += 1
                }
                html += MathParser.renderDisplayMath(mathLines.joined(separator: "\n")) + "\n"
                continue
            }

            // Horizontal Rule
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                html += "<hr />\n"
                lineIndex += 1
                continue
            }

            // Headings
            if let headingHTML = parseHeading(trimmed, baseURL: baseURL, options: options) {
                html += headingHTML + "\n"
                lineIndex += 1
                continue
            }

            // Blockquotes & Callouts
            if trimmed.hasPrefix(">") {
                var quoteLines: [String] = []
                while lineIndex < totalLines && lines[lineIndex].trimmingCharacters(in: .whitespaces).hasPrefix(">") {
                    let qLine = lines[lineIndex].trimmingCharacters(in: .whitespaces)
                    var stripped = String(qLine.dropFirst()).trimmingCharacters(in: .whitespaces)
                    if stripped.hasPrefix(" ") {
                        stripped = String(stripped.dropFirst())
                    }
                    quoteLines.append(stripped)
                    lineIndex += 1
                }

                if options.enableCallouts && !quoteLines.isEmpty,
                   let calloutInfo = CalloutParser.match(firstLine: quoteLines[0]) {
                    let remainingQuote = Array(quoteLines.dropFirst()).joined(separator: "\n")
                    let innerHTML = parseToHTML(markdown: remainingQuote, baseURL: baseURL, options: options)
                    let calloutTitle = calloutInfo.customTitle ?? calloutInfo.type.title
                    html += CalloutParser.renderHTML(type: calloutInfo.type, title: calloutTitle, contentHTML: innerHTML) + "\n"
                } else {
                    let quoteContent = quoteLines.joined(separator: "\n")
                    let innerHTML = parseToHTML(markdown: quoteContent, baseURL: baseURL, options: options)
                    html += "<blockquote>\n\(innerHTML)</blockquote>\n"
                }
                continue
            }

            // GFM Tables
            if trimmed.hasPrefix("|") && lineIndex + 1 < totalLines && isTableSeparator(lines[lineIndex + 1]) {
                var tableLines: [String] = []
                while lineIndex < totalLines && lines[lineIndex].trimmingCharacters(in: .whitespaces).hasPrefix("|") {
                    tableLines.append(lines[lineIndex].trimmingCharacters(in: .whitespaces))
                    lineIndex += 1
                }
                html += renderTable(tableLines, baseURL: baseURL, options: options) + "\n"
                continue
            }

            // Task Lists and Unordered / Ordered Lists
            if isListItem(trimmed) {
                var listLines: [String] = []
                while lineIndex < totalLines {
                    let currentLine = lines[lineIndex]
                    let curTrimmed = currentLine.trimmingCharacters(in: .whitespaces)
                    if curTrimmed.isEmpty {
                        if lineIndex + 1 < totalLines && (isListItem(lines[lineIndex + 1].trimmingCharacters(in: .whitespaces)) || lines[lineIndex + 1].hasPrefix("  ")) {
                            lineIndex += 1
                            continue
                        } else {
                            break
                        }
                    }
                    if isListItem(curTrimmed) || currentLine.hasPrefix("  ") || currentLine.hasPrefix("\t") {
                        listLines.append(currentLine)
                        lineIndex += 1
                    } else {
                        break
                    }
                }
                html += renderList(listLines, baseURL: baseURL, options: options) + "\n"
                continue
            }

            // Standard Paragraph
            var paragraphLines: [String] = []
            while lineIndex < totalLines {
                let pLine = lines[lineIndex]
                let pTrimmed = pLine.trimmingCharacters(in: .whitespaces)
                if pTrimmed.isEmpty || pTrimmed.hasPrefix("```") || pTrimmed.hasPrefix("#") ||
                    pTrimmed.hasPrefix(">") || (pTrimmed.hasPrefix("|") && lineIndex + 1 < totalLines && isTableSeparator(lines[lineIndex + 1])) ||
                    isListItem(pTrimmed) || pTrimmed == "---" || pTrimmed == "***" || pTrimmed == "$$" {
                    break
                }
                paragraphLines.append(pTrimmed)
                lineIndex += 1
            }

            if !paragraphLines.isEmpty {
                let paragraphText = paragraphLines.joined(separator: " ")
                let formatted = HTMLGenerator.renderInlineFormatting(paragraphText, baseURL: baseURL, enableMath: options.enableMath)
                html += "<p>\(formatted)</p>\n"
            }
        }

        return html
    }

    // MARK: - Helper Parsing Methods

    private static func parseHeading(_ line: String, baseURL: URL?, options: RenderOptions) -> String? {
        if line.hasPrefix("###### ") {
            let text = String(line.dropFirst(7))
            return "<h6>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h6>"
        } else if line.hasPrefix("##### ") {
            let text = String(line.dropFirst(6))
            return "<h5>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h5>"
        } else if line.hasPrefix("#### ") {
            let text = String(line.dropFirst(5))
            return "<h4>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h4>"
        } else if line.hasPrefix("### ") {
            let text = String(line.dropFirst(4))
            return "<h3>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h3>"
        } else if line.hasPrefix("## ") {
            let text = String(line.dropFirst(3))
            return "<h2>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h2>"
        } else if line.hasPrefix("# ") {
            let text = String(line.dropFirst(2))
            return "<h1>\(HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath))</h1>"
        }
        return nil
    }

    private static func isListItem(_ line: String) -> Bool {
        return line.hasPrefix("- ") || line.hasPrefix("* ") || line.hasPrefix("+ ") ||
            line.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil
    }

    private static func isTableSeparator(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|") && trimmed.contains("-") else { return false }
        var raw = trimmed
        if raw.hasPrefix("|") { raw = String(raw.dropFirst()) }
        if raw.hasSuffix("|") { raw = String(raw.dropLast()) }
        let cells = raw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return !cells.isEmpty && cells.allSatisfy { cell in
            let cleaned = cell.replacingOccurrences(of: ":", with: "")
            return !cleaned.isEmpty && cleaned.allSatisfy { $0 == "-" }
        }
    }

    private static func renderTable(_ lines: [String], baseURL: URL?, options: RenderOptions) -> String {
        guard lines.count >= 2 else { return "" }

        func splitRow(_ row: String) -> [String] {
            var raw = row.trimmingCharacters(in: .whitespaces)
            if raw.hasPrefix("|") { raw = String(raw.dropFirst()) }
            if raw.hasSuffix("|") { raw = String(raw.dropLast()) }
            return raw.components(separatedBy: "|").map { $0.trimmingCharacters(in: .whitespaces) }
        }

        let headerCells = splitRow(lines[0])
        let alignCells = splitRow(lines[1])

        var alignments: [String] = []
        for a in alignCells {
            let left = a.hasPrefix(":")
            let right = a.hasSuffix(":")
            if left && right {
                alignments.append("text-align: center;")
            } else if right {
                alignments.append("text-align: right;")
            } else {
                alignments.append("text-align: left;")
            }
        }

        var tableHTML = "<table>\n<thead>\n<tr>\n"
        for (i, cell) in headerCells.enumerated() {
            let style = i < alignments.count ? " style=\"\(alignments[i])\"" : ""
            let content = HTMLGenerator.renderInlineFormatting(cell, baseURL: baseURL, enableMath: options.enableMath)
            tableHTML += "  <th\(style)>\(content)</th>\n"
        }
        tableHTML += "</tr>\n</thead>\n<tbody>\n"

        for r in 2..<lines.count {
            let rowCells = splitRow(lines[r])
            tableHTML += "<tr>\n"
            for (i, cell) in rowCells.enumerated() {
                let style = i < alignments.count ? " style=\"\(alignments[i])\"" : ""
                let content = HTMLGenerator.renderInlineFormatting(cell, baseURL: baseURL, enableMath: options.enableMath)
                tableHTML += "  <td\(style)>\(content)</td>\n"
            }
            tableHTML += "</tr>\n"
        }

        tableHTML += "</tbody>\n</table>"
        return tableHTML
    }

    private static func renderList(_ lines: [String], baseURL: URL?, options: RenderOptions) -> String {
        var isOrdered = false
        var isTaskList = false

        if let first = lines.first?.trimmingCharacters(in: .whitespaces) {
            if first.range(of: #"^\d+\.\s"#, options: .regularExpression) != nil {
                isOrdered = true
            } else if first.hasPrefix("- [ ] ") || first.hasPrefix("- [x] ") || first.hasPrefix("* [ ] ") || first.hasPrefix("* [x] ") {
                isTaskList = true
            }
        }

        let tag = isOrdered ? "ol" : (isTaskList ? "ul class=\"task-list\"" : "ul")
        let closeTag = isOrdered ? "ol" : "ul"

        var html = "<\(tag)>\n"

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("* [ ] ") {
                let text = String(trimmed.dropFirst(6))
                let formatted = HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath)
                html += "  <li class=\"task-list-item\"><input type=\"checkbox\" class=\"task-checkbox\" disabled /><span>\(formatted)</span></li>\n"
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") || trimmed.hasPrefix("* [x] ") || trimmed.hasPrefix("* [X] ") {
                let text = String(trimmed.dropFirst(6))
                let formatted = HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath)
                html += "  <li class=\"task-list-item\"><input type=\"checkbox\" class=\"task-checkbox\" checked disabled /><span>\(formatted)</span></li>\n"
            } else if isOrdered, let match = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                let text = String(trimmed[match.upperBound...])
                let formatted = HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath)
                html += "  <li>\(formatted)</li>\n"
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") || trimmed.hasPrefix("+ ") {
                let text = String(trimmed.dropFirst(2))
                let formatted = HTMLGenerator.renderInlineFormatting(text, baseURL: baseURL, enableMath: options.enableMath)
                html += "  <li>\(formatted)</li>\n"
            } else {
                let formatted = HTMLGenerator.renderInlineFormatting(trimmed, baseURL: baseURL, enableMath: options.enableMath)
                html += "  <li>\(formatted)</li>\n"
            }
        }

        html += "</\(closeTag)>"
        return html
    }

    private static func renderFrontmatterCard(_ lines: [String]) -> String {
        var entries: [(key: String, val: String)] = []
        for line in lines {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces)
                let val = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                if !key.isEmpty {
                    entries.append((key, val))
                }
            }
        }

        guard !entries.isEmpty else { return "" }

        var html = "<div class=\"frontmatter-card\">\n<div class=\"frontmatter-title\">Metadata</div>\n"
        for entry in entries {
            let key = HTMLGenerator.escapeHTML(entry.key)
            let val = HTMLGenerator.escapeHTML(entry.val)
            html += "<div class=\"frontmatter-entry\"><span class=\"frontmatter-key\">\(key):</span><span class=\"frontmatter-val\">\(val)</span></div>\n"
        }
        html += "</div>\n"
        return html
    }
}
