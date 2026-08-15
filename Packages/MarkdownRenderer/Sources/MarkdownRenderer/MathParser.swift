import Foundation

public enum MathParser {
    // Regex matching inline math $...$ avoiding \$ or empty $$ or currency $50 ... $100
    private static let inlineMathRegex = try? NSRegularExpression(
        pattern: #"(?<!\\)\$(?!\$)([^\$\n\r]+?)(?<!\\)\$"#,
        options: []
    )

    public static func renderInlineMath(in text: String) -> String {
        guard let regex = inlineMathRegex else { return text }

        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        var output = ""
        var lastLocation = 0

        for match in matches {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            let before = nsString.substring(with: NSRange(location: lastLocation, length: fullRange.location - lastLocation))
            output += before

            let rawMath = nsString.substring(with: contentRange)
            let trimmed = rawMath.trimmingCharacters(in: .whitespaces)

            // Avoid treating currency amounts ($50) as math if it looks purely like numbers without math operators
            if isCurrency(trimmed) {
                output += nsString.substring(with: fullRange)
            } else {
                let escaped = HTMLGenerator.escapeHTML(rawMath)
                output += "<span class=\"math-inline\">\\(\(escaped)\\)</span>"
            }

            lastLocation = fullRange.location + fullRange.length
        }

        output += nsString.substring(from: lastLocation)
        return output
    }

    public static func renderDisplayMath(_ content: String) -> String {
        let escaped = HTMLGenerator.escapeHTML(content.trimmingCharacters(in: .whitespacesAndNewlines))
        return "<div class=\"math-block\">\\[\(escaped)\\]</div>"
    }

    private static func isCurrency(_ text: String) -> Bool {
        // If it starts with digits and contains no math symbols (+, -, *, /, =, \, ^, _, {, })
        let mathChars = CharacterSet(charactersIn: "+-*/=\\^_{}()[]<>&|")
        if text.rangeOfCharacter(from: mathChars) == nil {
            if let first = text.first, first.isNumber {
                return true
            }
        }
        return false
    }
}
