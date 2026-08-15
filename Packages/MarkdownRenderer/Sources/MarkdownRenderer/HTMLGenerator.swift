import Foundation

public enum HTMLGenerator {
    public static func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }

    public static func renderInlineFormatting(_ rawText: String, baseURL: URL? = nil, enableMath: Bool = true) -> String {
        // First escape raw HTML
        var result = escapeHTML(rawText)

        // 1. Math formulas ($...$) if enabled (before math syntax becomes altered)
        if enableMath {
            result = MathParser.renderInlineMath(in: result)
        }

        // 2. Images: ![alt](url)
        let imgPattern = #"!\[(.*?)\]\((.*?)\)"#
        if let imgRegex = try? NSRegularExpression(pattern: imgPattern) {
            let nsStr = result as NSString
            let matches = imgRegex.matches(in: result, range: NSRange(location: 0, length: nsStr.length))
            var newResult = ""
            var lastIndex = 0

            for match in matches {
                let fullRange = match.range
                let altRange = match.range(at: 1)
                let urlRange = match.range(at: 2)

                newResult += nsStr.substring(with: NSRange(location: lastIndex, length: fullRange.location - lastIndex))

                let alt = nsStr.substring(with: altRange)
                let rawUrl = nsStr.substring(with: urlRange).replacingOccurrences(of: "&amp;", with: "&")
                let resolved = ImageResolver.resolveImageSource(rawPath: rawUrl, baseURL: baseURL)

                newResult += "<img src=\"\(resolved)\" alt=\"\(alt)\" loading=\"lazy\" />"
                if !alt.isEmpty {
                    newResult += "<div class=\"image-caption\">\(alt)</div>"
                }

                lastIndex = fullRange.location + fullRange.length
            }
            newResult += nsStr.substring(from: lastIndex)
            result = newResult
        }

        // 3. Wikilinks: [[Target]] or [[Target|Display]]
        let wikiPattern = #"\[\[(.*?)\]\]"#
        if let wikiRegex = try? NSRegularExpression(pattern: wikiPattern) {
            let nsStr = result as NSString
            let matches = wikiRegex.matches(in: result, range: NSRange(location: 0, length: nsStr.length))
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

                newResult += "<a href=\"#wikilink:\(target)\" class=\"wikilink\">\(label)</a>"

                lastIndex = fullRange.location + fullRange.length
            }
            newResult += nsStr.substring(from: lastIndex)
            result = newResult
        }

        // 4. Links: [text](url)
        let linkPattern = #"(?<!!)\[(.*?)\]\((.*?)\)"#
        if let linkRegex = try? NSRegularExpression(pattern: linkPattern) {
            let nsStr = result as NSString
            let matches = linkRegex.matches(in: result, range: NSRange(location: 0, length: nsStr.length))
            var newResult = ""
            var lastIndex = 0

            for match in matches {
                let fullRange = match.range
                let textRange = match.range(at: 1)
                let urlRange = match.range(at: 2)

                newResult += nsStr.substring(with: NSRange(location: lastIndex, length: fullRange.location - lastIndex))

                let label = nsStr.substring(with: textRange)
                let url = nsStr.substring(with: urlRange).replacingOccurrences(of: "&amp;", with: "&")

                newResult += "<a href=\"\(url)\" target=\"_blank\" rel=\"noopener noreferrer\">\(label)</a>"

                lastIndex = fullRange.location + fullRange.length
            }
            newResult += nsStr.substring(from: lastIndex)
            result = newResult
        }

        // 5. Inline Code: `code`
        let codePattern = #"`([^`]+)`"#
        if let codeRegex = try? NSRegularExpression(pattern: codePattern) {
            result = codeRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..<result.endIndex, in: result),
                withTemplate: "<code>$1</code>"
            )
        }

        // 6. Bold & Italic: ***text*** or ___text___
        let boldItalicPattern = #"(\*\*\*|___)(.*?)\1"#
        if let boldItalicRegex = try? NSRegularExpression(pattern: boldItalicPattern) {
            result = boldItalicRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..<result.endIndex, in: result),
                withTemplate: "<strong><em>$2</em></strong>"
            )
        }

        // 7. Bold: **text** or __text__
        let boldPattern = #"(\*\*|__)(.*?)\1"#
        if let boldRegex = try? NSRegularExpression(pattern: boldPattern) {
            result = boldRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..<result.endIndex, in: result),
                withTemplate: "<strong>$2</strong>"
            )
        }

        // 8. Italic: *text* or _text_
        let italicPattern = #"(?<!\*|\w)(\*|_)(?!\*)(.*?)(?<!\*)\1(?!\w)"#
        if let italicRegex = try? NSRegularExpression(pattern: italicPattern) {
            result = italicRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..<result.endIndex, in: result),
                withTemplate: "<em>$2</em>"
            )
        }

        // 9. Strikethrough: ~~text~~
        let strikePattern = #"~~(.*?)~~"#
        if let strikeRegex = try? NSRegularExpression(pattern: strikePattern) {
            result = strikeRegex.stringByReplacingMatches(
                in: result,
                range: NSRange(result.startIndex..<result.endIndex, in: result),
                withTemplate: "<del>$1</del>"
            )
        }

        return result
    }

    public static func highlightCode(code: String, language: String) -> String {
        let escaped = escapeHTML(code)
        let lang = language.lowercased().trimmingCharacters(in: .whitespaces)

        // If no syntax rules apply, return escaped code
        if lang.isEmpty || ["text", "txt", "plain"].contains(lang) {
            return escaped
        }

        var highlighted = escaped

        // Keyword dictionary based on language
        let keywords: [String]
        switch lang {
        case "swift":
            keywords = ["func", "let", "var", "import", "class", "struct", "enum", "protocol", "extension", "guard", "if", "else", "switch", "case", "default", "return", "self", "public", "private", "fileprivate", "open", "override", "final", "mutating", "async", "await", "throws", "try", "catch", "init", "deinit", "nil", "true", "false", "where", "for", "in", "while", "do", "repeat", "break", "continue", "static", "some", "any", "actor", "Sendable"]
        case "python", "py":
            keywords = ["def", "class", "import", "from", "return", "if", "elif", "else", "for", "while", "in", "is", "not", "and", "or", "try", "except", "finally", "with", "as", "pass", "break", "continue", "lambda", "yield", "async", "await", "None", "True", "False", "self"]
        case "javascript", "js", "typescript", "ts":
            keywords = ["function", "const", "let", "var", "import", "export", "from", "default", "class", "extends", "return", "if", "else", "switch", "case", "default", "try", "catch", "finally", "throw", "async", "await", "new", "this", "null", "undefined", "true", "false", "for", "of", "in", "while", "break", "continue", "type", "interface"]
        case "rust", "rs":
            keywords = ["fn", "let", "mut", "pub", "use", "mod", "struct", "enum", "impl", "trait", "for", "in", "loop", "while", "if", "else", "match", "return", "self", "Self", "async", "await", "true", "false", "Some", "None", "Ok", "Err", "where", "type", "const"]
        case "go", "golang":
            keywords = ["func", "package", "import", "var", "const", "type", "struct", "interface", "return", "if", "else", "switch", "case", "default", "for", "range", "go", "chan", "select", "defer", "nil", "true", "false", "make", "new", "len"]
        default:
            keywords = ["func", "function", "def", "let", "var", "const", "if", "else", "for", "while", "return", "import", "export", "class", "struct", "true", "false", "null", "nil"]
        }

        // Highlight strings
        let stringPattern = #"(&quot;.*?&quot;|&#39;.*?&#39;|&quot;&quot;&quot;[\s\S]*?&quot;&quot;&quot;)"#
        if let stringRegex = try? NSRegularExpression(pattern: stringPattern) {
            highlighted = stringRegex.stringByReplacingMatches(
                in: highlighted,
                range: NSRange(highlighted.startIndex..<highlighted.endIndex, in: highlighted),
                withTemplate: "<span class=\"token-string\">$1</span>"
            )
        }

        // Highlight comments (// or #)
        let commentPattern = #"(//.*$|#.*$)"#
        if let commentRegex = try? NSRegularExpression(pattern: commentPattern, options: [.anchorsMatchLines]) {
            highlighted = commentRegex.stringByReplacingMatches(
                in: highlighted,
                range: NSRange(highlighted.startIndex..<highlighted.endIndex, in: highlighted),
                withTemplate: "<span class=\"token-comment\">$1</span>"
            )
        }

        // Highlight numbers
        let numberPattern = #"\b([0-9]+(?:\.[0-9]+)?)\b"#
        if let numRegex = try? NSRegularExpression(pattern: numberPattern) {
            highlighted = numRegex.stringByReplacingMatches(
                in: highlighted,
                range: NSRange(highlighted.startIndex..<highlighted.endIndex, in: highlighted),
                withTemplate: "<span class=\"token-number\">$1</span>"
            )
        }

        // Highlight keywords
        let kwJoined = keywords.joined(separator: "|")
        if let kwRegex = try? NSRegularExpression(pattern: "\\b(\(kwJoined))\\b") {
            highlighted = kwRegex.stringByReplacingMatches(
                in: highlighted,
                range: NSRange(highlighted.startIndex..<highlighted.endIndex, in: highlighted),
                withTemplate: "<span class=\"token-keyword\">$1</span>"
            )
        }

        return highlighted
    }
}
