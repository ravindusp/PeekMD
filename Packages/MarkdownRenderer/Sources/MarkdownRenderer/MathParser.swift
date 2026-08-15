import Foundation

public enum MathParser {
    public static func renderInlineMath(in text: String) -> String {
        // Matches $...$ but avoids matching escaped \$ or empty $$
        let pattern = #"(?<!\\)\$(?!\$)([^\$\n]+?)(?<!\\)\$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }

        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))

        var output = ""
        var lastLocation = 0

        for match in results {
            let fullRange = match.range
            let contentRange = match.range(at: 1)

            let before = nsString.substring(with: NSRange(location: lastLocation, length: fullRange.location - lastLocation))
            output += before

            let mathContent = nsString.substring(with: contentRange)
            let escaped = escapeHTML(mathContent)
            output += "<span class=\"math-inline\">\\(\(escaped)\\)</span>"

            lastLocation = fullRange.location + fullRange.length
        }

        output += nsString.substring(from: lastLocation)
        return output
    }

    public static func renderDisplayMath(_ content: String) -> String {
        let escaped = escapeHTML(content.trimmingCharacters(in: .whitespacesAndNewlines))
        return "<div class=\"math-block\">\\[\(escaped)\\]</div>"
    }

    private static func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
