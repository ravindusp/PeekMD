import Foundation
import Markdown

public struct MarkdownHTMLVisitor: MarkupVisitor {
    public typealias Result = String

    public let baseURL: URL?
    public let options: RenderOptions

    private var currentTableAlignments: [Table.ColumnAlignment?] = []
    private var currentColumnIndex: Int = 0

    public init(baseURL: URL? = nil, options: RenderOptions = .default) {
        self.baseURL = baseURL
        self.options = options
    }

    public mutating func defaultVisit(_ markup: Markup) -> String {
        var result = ""
        for child in markup.children {
            result += visit(child)
        }
        return result
    }

    // MARK: - Document

    public mutating func visitDocument(_ document: Document) -> String {
        return defaultVisit(document)
    }

    // MARK: - Block Elements

    public mutating func visitHeading(_ heading: Heading) -> String {
        let level = min(max(heading.level, 1), 6)
        let innerHTML = defaultVisit(heading)
        let plainText = heading.plainText
        let anchorID = generateAnchorID(from: plainText)
        return "<h\(level) id=\"\(anchorID)\">\(innerHTML)</h\(level)>\n"
    }

    public mutating func visitParagraph(_ paragraph: Paragraph) -> String {
        let innerHTML = defaultVisit(paragraph)
        let trimmed = innerHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return ""
        }
        return "<p>\(innerHTML)</p>\n"
    }

    public mutating func visitBlockQuote(_ blockQuote: BlockQuote) -> String {
        if options.enableCallouts, let callout = extractCallout(from: blockQuote) {
            return callout
        }

        let innerHTML = defaultVisit(blockQuote)
        return "<blockquote>\n\(innerHTML)</blockquote>\n"
    }

    public mutating func visitOrderedList(_ orderedList: OrderedList) -> String {
        let start = orderedList.startIndex
        var result = ""
        if start != 1 {
            result += "<ol start=\"\(start)\">\n"
        } else {
            result += "<ol>\n"
        }

        for child in orderedList.children {
            result += visit(child)
        }
        result += "</ol>\n"
        return result
    }

    public mutating func visitUnorderedList(_ unorderedList: UnorderedList) -> String {
        let hasTaskItems = unorderedList.children.contains { child in
            if let item = child as? ListItem, item.checkbox != nil {
                return true
            }
            return false
        }

        let listClass = hasTaskItems ? " class=\"task-list\"" : ""
        var result = "<ul\(listClass)>\n"
        for child in unorderedList.children {
            result += visit(child)
        }
        result += "</ul>\n"
        return result
    }

    public mutating func visitListItem(_ listItem: ListItem) -> String {
        var innerHTML = ""
        for child in listItem.children {
            innerHTML += visit(child)
        }

        if let checkbox = listItem.checkbox {
            let isChecked = (checkbox == .checked)
            let checkedAttr = isChecked ? " checked" : ""
            return "<li class=\"task-list-item\"><input type=\"checkbox\" class=\"task-checkbox\" disabled\(checkedAttr) /> <div class=\"task-list-content\">\(innerHTML)</div></li>\n"
        } else {
            return "<li>\(innerHTML)</li>\n"
        }
    }

    public mutating func visitCodeBlock(_ codeBlock: CodeBlock) -> String {
        let lang = codeBlock.language?.lowercased().trimmingCharacters(in: .whitespaces) ?? ""
        let code = codeBlock.code

        if lang == "mermaid" {
            let escapedCode = HTMLGenerator.escapeHTML(code)
            return "<div class=\"mermaid-block\"><pre class=\"mermaid\">\(escapedCode)</pre></div>\n"
        }

        // Display math fence ```math ... ```
        if (lang == "math" || lang == "latex" || lang == "tex") && options.enableMath {
            return MathParser.renderDisplayMath(code) + "\n"
        }

        let highlighted = options.enableSyntaxHighlighting
            ? HTMLGenerator.highlightCode(code: code, language: lang)
            : HTMLGenerator.escapeHTML(code)

        let langTag = lang.isEmpty ? "" : "<div class=\"code-lang-tag\">\(HTMLGenerator.escapeHTML(lang))</div>"
        let langClass = lang.isEmpty ? "" : " class=\"language-\(HTMLGenerator.escapeHTML(lang))\""

        return "<div class=\"code-block-container\">\(langTag)<pre><code\(langClass)>\(highlighted)</code></pre></div>\n"
    }

    public mutating func visitHTMLBlock(_ html: HTMLBlock) -> String {
        return HTMLSanitizer.sanitizeHTML(html.rawHTML, baseURL: baseURL) + "\n"
    }

    public mutating func visitThematicBreak(_ thematicBreak: ThematicBreak) -> String {
        return "<hr />\n"
    }

    // MARK: - Tables

    public mutating func visitTable(_ table: Table) -> String {
        currentTableAlignments = table.columnAlignments
        var result = "<div class=\"table-wrapper\"><table>\n"
        for child in table.children {
            result += visit(child)
        }
        result += "</table></div>\n"
        currentTableAlignments = []
        return result
    }

    public mutating func visitTableHead(_ tableHead: Table.Head) -> String {
        var result = "<thead>\n"
        for child in tableHead.children {
            result += visit(child)
        }
        result += "</thead>\n"
        return result
    }

    public mutating func visitTableBody(_ tableBody: Table.Body) -> String {
        var result = "<tbody>\n"
        for child in tableBody.children {
            result += visit(child)
        }
        result += "</tbody>\n"
        return result
    }

    public mutating func visitTableRow(_ tableRow: Table.Row) -> String {
        currentColumnIndex = 0
        var result = "<tr>\n"
        for child in tableRow.children {
            result += visit(child)
        }
        result += "</tr>\n"
        return result
    }

    public mutating func visitTableCell(_ tableCell: Table.Cell) -> String {
        let isHeader = (tableCell.parent is Table.Head) || (tableCell.parent?.parent is Table.Head)
        let tag = isHeader ? "th" : "td"

        var alignStyle = ""
        if currentColumnIndex < currentTableAlignments.count, let alignment = currentTableAlignments[currentColumnIndex] {
            switch alignment {
            case .left:
                alignStyle = " style=\"text-align: left;\""
            case .center:
                alignStyle = " style=\"text-align: center;\""
            case .right:
                alignStyle = " style=\"text-align: right;\""
            }
        }
        currentColumnIndex += 1

        var innerHTML = ""
        for child in tableCell.children {
            innerHTML += visit(child)
        }

        return "<\(tag)\(alignStyle)>\(innerHTML)</\(tag)>\n"
    }

    // MARK: - Inline Elements

    public mutating func visitInlineCode(_ inlineCode: InlineCode) -> String {
        let escaped = HTMLGenerator.escapeHTML(inlineCode.code)
        return "<code>\(escaped)</code>"
    }

    public mutating func visitSymbolLink(_ symbolLink: SymbolLink) -> String {
        let dest = symbolLink.destination ?? ""
        let escaped = HTMLGenerator.escapeHTML(dest)
        return "<code>\(escaped)</code>"
    }

    public mutating func visitEmphasis(_ emphasis: Emphasis) -> String {
        let innerHTML = defaultVisit(emphasis)
        return "<em>\(innerHTML)</em>"
    }

    public mutating func visitStrong(_ strong: Strong) -> String {
        let innerHTML = defaultVisit(strong)
        return "<strong>\(innerHTML)</strong>"
    }

    public mutating func visitStrikethrough(_ strikethrough: Strikethrough) -> String {
        let innerHTML = defaultVisit(strikethrough)
        return "<del>\(innerHTML)</del>"
    }

    public mutating func visitLink(_ link: Link) -> String {
        let destination = link.destination ?? ""
        let innerHTML = defaultVisit(link)

        let safeDest: String
        let lowerDest = destination.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if lowerDest.hasPrefix("javascript:") || lowerDest.hasPrefix("vbscript:") || lowerDest.hasPrefix("data:text/html") {
            safeDest = "#"
        } else {
            safeDest = destination
        }

        var titleAttr = ""
        if let title = link.title, !title.isEmpty {
            titleAttr = " title=\"\(HTMLGenerator.escapeHTML(title))\""
        }

        let isExternal = safeDest.hasPrefix("http://") || safeDest.hasPrefix("https://")
        let targetAttr = isExternal ? " target=\"_blank\" rel=\"noopener noreferrer\"" : ""
        let isWikilink = safeDest.hasPrefix("#wikilink:")
        let classAttr = isWikilink ? " class=\"wikilink\"" : ""

        let escapedHref = HTMLGenerator.escapeHTML(safeDest)
        return "<a href=\"\(escapedHref)\"\(classAttr)\(targetAttr)\(titleAttr)>\(innerHTML)</a>"
    }

    public mutating func visitImage(_ image: Image) -> String {
        let rawSource = image.source ?? ""
        let resolvedSource = ImageResolver.resolveImageSource(rawPath: rawSource, baseURL: baseURL)

        let plainAlt = image.plainText
        var widthAttr = ""
        var cleanAlt = plainAlt

        // Sizing in alt text: e.g. "Diagram|300" or "Diagram|300x200" or "|300"
        if let pipeIndex = plainAlt.range(of: "|") {
            let left = String(plainAlt[..<pipeIndex.lowerBound]).trimmingCharacters(in: .whitespaces)
            let right = String(plainAlt[pipeIndex.upperBound...]).trimmingCharacters(in: .whitespaces)
            if let width = Int(right) {
                widthAttr = " width=\"\(width)\""
                cleanAlt = left
            } else if right.contains("x") {
                let parts = right.components(separatedBy: "x")
                if parts.count == 2, let w = Int(parts[0]), let h = Int(parts[1]) {
                    widthAttr = " width=\"\(w)\" height=\"\(h)\""
                    cleanAlt = left
                }
            }
        }

        let escapedSrc = HTMLGenerator.escapeHTML(resolvedSource)
        let escapedAlt = HTMLGenerator.escapeHTML(cleanAlt)

        var titleAttr = ""
        if let title = image.title, !title.isEmpty {
            titleAttr = " title=\"\(HTMLGenerator.escapeHTML(title))\""
        }

        var result = "<img src=\"\(escapedSrc)\" alt=\"\(escapedAlt)\" loading=\"lazy\"\(widthAttr)\(titleAttr) />"
        if !cleanAlt.isEmpty {
            result += "<div class=\"image-caption\">\(escapedAlt)</div>"
        }
        return result
    }

    public mutating func visitInlineHTML(_ inlineHTML: InlineHTML) -> String {
        return HTMLSanitizer.sanitizeHTML(inlineHTML.rawHTML, baseURL: baseURL)
    }

    public mutating func visitLineBreak(_ lineBreak: LineBreak) -> String {
        return "<br />\n"
    }

    public mutating func visitSoftBreak(_ softBreak: SoftBreak) -> String {
        return "\n"
    }

    public mutating func visitText(_ text: Text) -> String {
        return processInlineExtensions(text.string)
    }

    // MARK: - Helper Methods

    private mutating func extractCallout(from blockQuote: BlockQuote) -> String? {
        guard let firstParagraph = blockQuote.children.first(where: { $0 is Paragraph }) as? Paragraph else {
            return nil
        }

        let plainFirst = firstParagraph.plainText
        let lines = plainFirst.components(separatedBy: "\n")
        guard let firstLine = lines.first,
              let match = CalloutParser.match(firstLine: firstLine) else {
            return nil
        }

        let title = match.customTitle ?? match.type.defaultTitle

        // Reconstruct content of the callout without the [!TYPE] marker
        var bodyChildren: [Markup] = []
        var isFirst = true

        for child in blockQuote.children {
            if isFirst, let _ = child as? Paragraph {
                isFirst = false
                // Create a paragraph omitting the callout marker line
                let remainingLines = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainingLines.isEmpty {
                    let doc = Document(parsing: remainingLines)
                    for sub in doc.children {
                        bodyChildren.append(sub)
                    }
                }
            } else {
                bodyChildren.append(child)
            }
        }

        var contentHTML = ""
        for child in bodyChildren {
            contentHTML += visit(child)
        }

        return CalloutParser.renderHTML(
            type: match.type,
            title: title,
            contentHTML: contentHTML,
            foldable: match.foldable
        ) + "\n"
    }

    private func processInlineExtensions(_ text: String) -> String {
        var processed = text

        // 1. Math formulas ($...$)
        if options.enableMath {
            processed = MathParser.renderInlineMath(in: processed)
        }

        // 2. Wikilinks & Embeds: ![[image.png]] and [[Target|Display]]
        if options.enableWikilinks {
            processed = processWikilinks(processed)
        }

        // 3. Highlight: ==highlighted text==
        processed = processHighlights(processed)

        // 4. Superscript: ^text^ and Subscript: ~text~
        processed = processSuperAndSubscripts(processed)

        // Escape any remaining plain characters that weren't already structured HTML tags
        // Since step 1-4 might have injected safe tags, split on tags and escape text outside tags
        return escapePreservingTags(processed)
    }

    private func processWikilinks(_ text: String) -> String {
        var result = text

        // Wikilink embeds: ![[image.png|300]] or ![[image.png]]
        let embedPattern = #"!\[\[(.*?)\]\]"#
        if let regex = try? NSRegularExpression(pattern: embedPattern) {
            let nsStr = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsStr.length))
            var newResult = ""
            var lastIndex = 0

            for match in matches {
                let fullRange = match.range
                let contentRange = match.range(at: 1)

                newResult += nsStr.substring(with: NSRange(location: lastIndex, length: fullRange.location - lastIndex))

                let rawContent = nsStr.substring(with: contentRange)
                let parts = rawContent.components(separatedBy: "|")
                let path = parts[0].trimmingCharacters(in: .whitespaces)
                let extra = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : ""

                let ext = (path as NSString).pathExtension.lowercased()
                let isImage = ["png", "jpg", "jpeg", "gif", "webp", "svg", "ico", "bmp", "tiff", "avif"].contains(ext)

                if isImage {
                    let resolved = ImageResolver.resolveImageSource(rawPath: path, baseURL: baseURL)
                    let escapedSrc = HTMLGenerator.escapeHTML(resolved)
                    var widthAttr = ""
                    if let width = Int(extra) {
                        widthAttr = " width=\"\(width)\""
                    }
                    newResult += "<img src=\"\(escapedSrc)\" alt=\"\(HTMLGenerator.escapeHTML(path))\" loading=\"lazy\"\(widthAttr) />"
                } else {
                    // Graceful fallback for non-image embeds
                    let label = extra.isEmpty ? path : extra
                    newResult += "<div class=\"embedded-note-link\"><a href=\"#wikilink:\(HTMLGenerator.escapeHTML(path))\" class=\"wikilink\">📄 \(HTMLGenerator.escapeHTML(label))</a></div>"
                }

                lastIndex = fullRange.location + fullRange.length
            }
            newResult += nsStr.substring(from: lastIndex)
            result = newResult
        }

        // Standard Wikilinks: [[Target]] or [[Target|Display]] or [[Target#Section]] or [[Target#^block]]
        let wikiPattern = #"\[\[(.*?)\]\]"#
        if let regex = try? NSRegularExpression(pattern: wikiPattern) {
            let nsStr = result as NSString
            let matches = regex.matches(in: result, range: NSRange(location: 0, length: nsStr.length))
            var newResult = ""
            var lastIndex = 0

            for match in matches {
                let fullRange = match.range
                let contentRange = match.range(at: 1)

                newResult += nsStr.substring(with: NSRange(location: lastIndex, length: fullRange.location - lastIndex))

                let rawContent = nsStr.substring(with: contentRange)
                let parts = rawContent.components(separatedBy: "|")
                let target = parts[0].trimmingCharacters(in: .whitespaces)
                let label = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : target

                let escapedTarget = HTMLGenerator.escapeHTML(target)
                let escapedLabel = HTMLGenerator.escapeHTML(label)

                newResult += "<a href=\"#wikilink:\(escapedTarget)\" class=\"wikilink\">\(escapedLabel)</a>"

                lastIndex = fullRange.location + fullRange.length
            }
            newResult += nsStr.substring(from: lastIndex)
            result = newResult
        }

        return result
    }

    private func processHighlights(_ text: String) -> String {
        let pattern = #"==([^=\n]+?)=="#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "<mark>$1</mark>")
    }

    private func processSuperAndSubscripts(_ text: String) -> String {
        var result = text

        // Superscript: ^text^
        let supPattern = #"\^([^\^\s\n]+?)\^"#
        if let regex = try? NSRegularExpression(pattern: supPattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "<sup>$1</sup>")
        }

        // Subscript: ~text~ (single tilde, avoid ~~strikethrough~~)
        let subPattern = #"(?<!~)\~([^~\s\n]+?)\~(?!~)"#
        if let regex = try? NSRegularExpression(pattern: subPattern) {
            let range = NSRange(result.startIndex..<result.endIndex, in: result)
            result = regex.stringByReplacingMatches(in: result, options: [], range: range, withTemplate: "<sub>$1</sub>")
        }

        return result
    }

    private func escapePreservingTags(_ html: String) -> String {
        // Find tags <...> and only escape text outside of tags
        let pattern = #"<[^>]+>"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return HTMLGenerator.escapeHTML(html)
        }

        let nsString = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))

        var output = ""
        var lastLocation = 0

        for match in matches {
            let fullRange = match.range
            if fullRange.location > lastLocation {
                let textChunk = nsString.substring(with: NSRange(location: lastLocation, length: fullRange.location - lastLocation))
                output += HTMLGenerator.escapeHTML(textChunk)
            }
            output += nsString.substring(with: fullRange)
            lastLocation = fullRange.location + fullRange.length
        }

        if lastLocation < nsString.length {
            let textChunk = nsString.substring(from: lastLocation)
            output += HTMLGenerator.escapeHTML(textChunk)
        }

        return output
    }

    private func generateAnchorID(from text: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let lower = text.lowercased()
        var result = ""
        var prevHyphen = false

        for scalar in lower.unicodeScalars {
            if allowed.contains(scalar) {
                result.unicodeScalars.append(scalar)
                prevHyphen = false
            } else if scalar == " " || scalar == "\t" || scalar == "-" {
                if !prevHyphen && !result.isEmpty {
                    result.append("-")
                    prevHyphen = true
                }
            }
        }

        return result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
