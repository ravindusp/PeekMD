import Foundation

public enum MathParser {
    // Regex matching inline math $...$ avoiding \$ or empty $$ or currency $50 ... $100
    private static let inlineMathRegex = try? NSRegularExpression(
        pattern: #"(?<![\\\$])\$([^\$\n\r]+?)(?<![\\\$])\$"#,
        options: []
    )

    private static let inlineParenRegex = try? NSRegularExpression(
        pattern: #"(?<!\\)\\\(([^\n\r]+?)(?<!\\)\\\)"#,
        options: []
    )

    public struct PreprocessResult {
        public let markdown: String
        public let inlineMathTable: [String: String]

        public init(markdown: String, inlineMathTable: [String: String]) {
            self.markdown = markdown
            self.inlineMathTable = inlineMathTable
        }
    }

    // MARK: - Markdown Preprocessing

    /// Preprocesses markdown text by converting display math (`$$...$$`, `\[...\]`, `\begin{env}...\end{env}`)
    /// into ```` ```math ... ``` ```` code fences, and replacing inline math (`\(...\)`, `$...$`) with safe placeholders
    /// so that markdown AST parsers do not strip backslashes or mangle subscripts/underscores.
    public static func preprocessMath(_ markdown: String) -> PreprocessResult {
        var table: [String: String] = [:]
        var counter = 0

        // Find all fenced code blocks (``` or ~~~) and inline code (`...`)
        let codePattern = #"(?ms)(?:^[ \t]*(`{3,}|~{3,})[^\n]*\n[\s\S]*?\n[ \t]*\1[ \t]*(?:\n|$))|(?:(?<!`)(`+)(?!`)(?:[\s\S]*?)(?<!`)\2(?!`))"#
        guard let codeRegex = try? NSRegularExpression(pattern: codePattern) else {
            let processed = preprocessMathInText(markdown, table: &table, counter: &counter)
            return PreprocessResult(markdown: processed, inlineMathTable: table)
        }

        let nsString = markdown as NSString
        let matches = codeRegex.matches(in: markdown, range: NSRange(location: 0, length: nsString.length))

        if matches.isEmpty {
            let processed = preprocessMathInText(markdown, table: &table, counter: &counter)
            return PreprocessResult(markdown: processed, inlineMathTable: table)
        }

        var result = ""
        var lastLocation = 0

        for match in matches {
            let codeRange = match.range
            if codeRange.location > lastLocation {
                let textChunk = nsString.substring(with: NSRange(location: lastLocation, length: codeRange.location - lastLocation))
                result += preprocessMathInText(textChunk, table: &table, counter: &counter)
            }
            result += nsString.substring(with: codeRange)
            lastLocation = codeRange.location + codeRange.length
        }

        if lastLocation < nsString.length {
            let textChunk = nsString.substring(from: lastLocation)
            result += preprocessMathInText(textChunk, table: &table, counter: &counter)
        }

        return PreprocessResult(markdown: result, inlineMathTable: table)
    }

    private static func preprocessMathInText(_ text: String, table: inout [String: String], counter: inout Int) -> String {
        var processed = text

        // 1. LaTeX Environments: \begin{equation}...\end{equation}, \begin{align}...\end{align}, etc.
        let envPattern = #"(?ms)\\begin\{(equation\*?|align\*?|alignat\*?|gather\*?|multline\*?|matrix|pmatrix|bmatrix|Bmatrix|vmatrix|Vmatrix|cases|split|aligned|gathered)\}([\s\S]*?)\\end\{\1\}"#
        if let envRegex = try? NSRegularExpression(pattern: envPattern) {
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            processed = envRegex.stringByReplacingMatches(
                in: processed,
                options: [],
                range: range,
                withTemplate: "\n\n```math\n$0\n```\n\n"
            )
        }

        // 2. LaTeX Display Math: \[ ... \]
        let bracketPattern = #"(?ms)(?<!\\)\\\[([\s\S]*?)(?<!\\)\\\]"#
        if let bracketRegex = try? NSRegularExpression(pattern: bracketPattern) {
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            processed = bracketRegex.stringByReplacingMatches(
                in: processed,
                options: [],
                range: range,
                withTemplate: "\n\n```math\n$1\n```\n\n"
            )
        }

        // 3. Double Dollar Display Math: $$ ... $$
        let doubleDollarPattern = #"(?ms)(?<!\\)\$\$([\s\S]*?)(?<!\\)\$\$"#
        if let ddRegex = try? NSRegularExpression(pattern: doubleDollarPattern) {
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            processed = ddRegex.stringByReplacingMatches(
                in: processed,
                options: [],
                range: range,
                withTemplate: "\n\n```math\n$1\n```\n\n"
            )
        }

        // 4. Inline LaTeX Math: \( ... \)
        if let ipRegex = inlineParenRegex {
            let nsStr = processed as NSString
            let matches = ipRegex.matches(in: processed, range: NSRange(location: 0, length: nsStr.length))
            if !matches.isEmpty {
                var newProcessed = ""
                var lastLoc = 0
                for match in matches {
                    let fullR = match.range
                    let contentR = match.range(at: 1)
                    newProcessed += nsStr.substring(with: NSRange(location: lastLoc, length: fullR.location - lastLoc))
                    let rawMath = nsStr.substring(with: contentR)
                    let placeholder = "XPEEKMDMATH\(counter)X"
                    counter += 1
                    table[placeholder] = rawMath.trimmingCharacters(in: .whitespaces)
                    newProcessed += placeholder
                    lastLoc = fullR.location + fullR.length
                }
                newProcessed += nsStr.substring(from: lastLoc)
                processed = newProcessed
            }
        }

        // 5. Inline Dollar Math: $ ... $
        if let idRegex = inlineMathRegex {
            let nsStr = processed as NSString
            let matches = idRegex.matches(in: processed, range: NSRange(location: 0, length: nsStr.length))
            if !matches.isEmpty {
                var newProcessed = ""
                var lastLoc = 0
                for match in matches {
                    let fullR = match.range
                    let contentR = match.range(at: 1)
                    newProcessed += nsStr.substring(with: NSRange(location: lastLoc, length: fullR.location - lastLoc))
                    let rawMath = nsStr.substring(with: contentR)
                    let trimmed = rawMath.trimmingCharacters(in: .whitespaces)

                    if isCurrency(trimmed) {
                        newProcessed += nsStr.substring(with: fullR)
                    } else {
                        let placeholder = "XPEEKMDMATH\(counter)X"
                        counter += 1
                        table[placeholder] = trimmed
                        newProcessed += placeholder
                    }
                    lastLoc = fullR.location + fullR.length
                }
                newProcessed += nsStr.substring(from: lastLoc)
                processed = newProcessed
            }
        }

        return processed
    }

    /// Restores inline math placeholders in generated HTML to formatted math spans.
    public static func restoreInlineMath(in html: String, table: [String: String]) -> String {
        guard !table.isEmpty else { return html }
        var result = html
        for (placeholder, rawMath) in table {
            let escaped = HTMLGenerator.escapeHTML(rawMath)
            let span = "<span class=\"math-inline\">\\(\(escaped)\\)</span>"
            result = result.replacingOccurrences(of: placeholder, with: span)
        }
        return result
    }

    // MARK: - HTML Rendering

    public static func renderInlineMath(in text: String) -> String {
        var processed = text

        // Process \( ... \)
        if let ipRegex = inlineParenRegex {
            let nsStr = processed as NSString
            let matches = ipRegex.matches(in: processed, range: NSRange(location: 0, length: nsStr.length))
            if !matches.isEmpty {
                var newProcessed = ""
                var lastLoc = 0
                for match in matches {
                    let fullR = match.range
                    let contentR = match.range(at: 1)
                    newProcessed += nsStr.substring(with: NSRange(location: lastLoc, length: fullR.location - lastLoc))
                    let rawMath = nsStr.substring(with: contentR)
                    let escaped = HTMLGenerator.escapeHTML(rawMath.trimmingCharacters(in: .whitespaces))
                    newProcessed += "<span class=\"math-inline\">\\(\(escaped)\\)</span>"
                    lastLoc = fullR.location + fullR.length
                }
                newProcessed += nsStr.substring(from: lastLoc)
                processed = newProcessed
            }
        }

        // Process $ ... $
        guard let regex = inlineMathRegex else { return processed }
        let nsString = processed as NSString
        let matches = regex.matches(in: processed, options: [], range: NSRange(location: 0, length: nsString.length))
        if matches.isEmpty { return processed }

        var output = ""
        var lastLocation = 0

        for match in matches {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            let before = nsString.substring(with: NSRange(location: lastLocation, length: fullRange.location - lastLocation))
            output += before

            let rawMath = nsString.substring(with: contentRange)
            let trimmed = rawMath.trimmingCharacters(in: .whitespaces)

            if isCurrency(trimmed) {
                output += nsString.substring(with: fullRange)
            } else {
                let escaped = HTMLGenerator.escapeHTML(trimmed)
                output += "<span class=\"math-inline\">\\(\(escaped)\\)</span>"
            }

            lastLocation = fullRange.location + fullRange.length
        }

        output += nsString.substring(from: lastLocation)
        return output
    }

    public static func renderDisplayMath(_ content: String) -> String {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let escaped = HTMLGenerator.escapeHTML(trimmed)
        return "<div class=\"math-block\">\\[\(escaped)\\]</div>"
    }

    // MARK: - Currency Detection

    public static func isCurrency(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        // Math characters that indicate a math equation rather than currency
        let mathChars = CharacterSet(charactersIn: "\\_^}{+-*/=<>|~")
        if trimmed.rangeOfCharacter(from: mathChars) != nil {
            return false
        }

        // Pure numeric currency amount: $50, $100.00, $50k, $1.5 million, etc.
        let currencyPattern = #"^\d+(?:[.,]\d+)*(?:\s*(?:k|m|b|bn|million|billion|trillion|usd|eur|gbp|cad|aud|inr|jpy|cents?|dollars?))?$"#
        if let regex = try? NSRegularExpression(pattern: currencyPattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (trimmed as NSString).length)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }

        // Number followed by sentence connectors: "$50 and $100", "$20 per ticket"
        let currencySentencePattern = #"^\d+(?:[.,]\d+)?\s+(?:and|or|to|each|per|for)\b"#
        if let regex = try? NSRegularExpression(pattern: currencySentencePattern, options: [.caseInsensitive]) {
            let range = NSRange(location: 0, length: (trimmed as NSString).length)
            if regex.firstMatch(in: trimmed, options: [], range: range) != nil {
                return true
            }
        }

        return false
    }
}
