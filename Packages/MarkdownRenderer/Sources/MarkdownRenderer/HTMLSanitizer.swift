import Foundation

public enum HTMLSanitizer {
    private static let allowedTags: Set<String> = [
        "div", "p", "span", "strong", "b", "em", "i", "mark", "kbd", "br", "hr",
        "img", "a", "details", "summary", "table", "thead", "tbody", "tfoot",
        "tr", "th", "td", "sub", "sup", "picture", "source", "pre", "code",
        "blockquote", "ul", "ol", "li", "del", "s", "strike", "h1", "h2", "h3",
        "h4", "h5", "h6", "dd", "dt", "dl", "figure", "figcaption", "section",
        "header", "footer", "aside", "nav", "article", "main", "ruby", "rt", "rp",
        "abbr", "cite", "q", "time", "var", "samp", "video", "audio"
    ]

    private static let dangerousTags: Set<String> = [
        "script", "iframe", "object", "embed", "applet", "style", "form",
        "input", "button", "textarea", "select", "option", "meta", "link",
        "base", "frame", "frameset"
    ]

    private static let allowedAttributes: Set<String> = [
        "align", "valign", "width", "height", "src", "alt", "href", "title",
        "class", "id", "open", "target", "rel", "srcset", "media", "type",
        "start", "reversed", "style", "dir", "lang", "colspan", "rowspan",
        "border", "cellpadding", "cellspacing", "loading", "decoding"
    ]

    private static let tagRegex = try? NSRegularExpression(
        pattern: #"<(/)?([a-zA-Z0-9]+)([^>]*)>"#,
        options: [.dotMatchesLineSeparators]
    )

    private static let attrRegex = try? NSRegularExpression(
        pattern: #"([a-zA-Z0-9_-]+)(?:\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+)))?"#,
        options: []
    )

    private static let commentRegex = try? NSRegularExpression(
        pattern: #"<!--[\s\S]*?-->"#,
        options: []
    )

    private static let dangerousBlockRegexes: [NSRegularExpression] = {
        return ["script", "iframe", "object", "embed", "applet", "style", "form"].compactMap { tag in
            try? NSRegularExpression(pattern: #"<\#(tag)\b[^>]*>[\s\S]*?</\#(tag)>"#, options: [.caseInsensitive])
        }
    }()

    public static func sanitizeHTML(_ html: String, baseURL: URL? = nil) -> String {
        var processed = html

        // 1. Remove dangerous block containers completely (e.g. <script>...</script>)
        for regex in dangerousBlockRegexes {
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            processed = regex.stringByReplacingMatches(in: processed, options: [], range: range, withTemplate: "")
        }

        // 2. Remove HTML comments
        if let commentRegex = commentRegex {
            let range = NSRange(processed.startIndex..<processed.endIndex, in: processed)
            processed = commentRegex.stringByReplacingMatches(in: processed, options: [], range: range, withTemplate: "")
        }

        // 3. Parse and sanitize individual tags
        guard let tagRegex = tagRegex else { return processed }

        let nsString = processed as NSString
        let matches = tagRegex.matches(in: processed, options: [], range: NSRange(location: 0, length: nsString.length))

        var output = ""
        var lastLocation = 0

        for match in matches {
            let fullRange = match.range
            let isClosing = match.range(at: 1).location != NSNotFound
            let tagNameRange = match.range(at: 2)
            let attrsRange = match.range(at: 3)

            let before = nsString.substring(with: NSRange(location: lastLocation, length: fullRange.location - lastLocation))
            output += before

            let tagName = nsString.substring(with: tagNameRange).lowercased()
            let rawAttrs = attrsRange.location != NSNotFound ? nsString.substring(with: attrsRange) : ""

            if allowedTags.contains(tagName) {
                if isClosing {
                    output += "</\(tagName)>"
                } else {
                    let sanitizedAttrs = sanitizeAttributes(rawAttrs, forTag: tagName, baseURL: baseURL)
                    let isSelfClosing = rawAttrs.trimmingCharacters(in: .whitespaces).hasSuffix("/")
                    if sanitizedAttrs.isEmpty {
                        output += isSelfClosing ? "<\(tagName) />" : "<\(tagName)>"
                    } else {
                        output += isSelfClosing ? "<\(tagName) \(sanitizedAttrs) />" : "<\(tagName) \(sanitizedAttrs)>"
                    }
                }
            } else if dangerousTags.contains(tagName) {
                // Completely drop dangerous tags
            } else {
                // Unknown tag: escape it safely
                let rawTag = nsString.substring(with: fullRange)
                output += HTMLGenerator.escapeHTML(rawTag)
            }

            lastLocation = fullRange.location + fullRange.length
        }

        output += nsString.substring(from: lastLocation)
        return output
    }

    private static func sanitizeAttributes(_ rawAttrs: String, forTag tagName: String, baseURL: URL?) -> String {
        guard let attrRegex = attrRegex else { return "" }
        let trimmed = rawAttrs.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "/" { return "" }

        let nsString = trimmed as NSString
        let matches = attrRegex.matches(in: trimmed, options: [], range: NSRange(location: 0, length: nsString.length))

        var sanitizedAttrsList: [String] = []

        for match in matches {
            let nameRange = match.range(at: 1)
            let attrName = nsString.substring(with: nameRange).lowercased()

            // Disallow event handlers (on*)
            if attrName.hasPrefix("on") {
                continue
            }

            // Only allow whitelisted attributes
            if !allowedAttributes.contains(attrName) {
                continue
            }

            var attrValue: String? = nil
            if match.range(at: 2).location != NSNotFound {
                attrValue = nsString.substring(with: match.range(at: 2))
            } else if match.range(at: 3).location != NSNotFound {
                attrValue = nsString.substring(with: match.range(at: 3))
            } else if match.range(at: 4).location != NSNotFound {
                attrValue = nsString.substring(with: match.range(at: 4))
            }

            guard let val = attrValue else {
                // Boolean attribute (e.g. open)
                sanitizedAttrsList.append(attrName)
                continue
            }

            let trimmedVal = val.trimmingCharacters(in: .whitespacesAndNewlines)
            let lowerVal = trimmedVal.lowercased()

            // Check for unsafe URLs in href, src, srcset
            if attrName == "href" || attrName == "src" {
                if lowerVal.hasPrefix("javascript:") ||
                    lowerVal.hasPrefix("vbscript:") ||
                    lowerVal.hasPrefix("data:text/html") {
                    continue
                }

                // If this is an img src or picture source, resolve relative paths
                if (attrName == "src" && (tagName == "img" || tagName == "source")) {
                    let resolved = ImageResolver.resolveImageSource(rawPath: trimmedVal, baseURL: baseURL)
                    let escapedVal = HTMLGenerator.escapeHTML(resolved)
                    sanitizedAttrsList.append("\(attrName)=\"\(escapedVal)\"")
                    continue
                }
            }

            if attrName == "style" {
                // Disallow javascript/expression in style
                if lowerVal.contains("javascript:") || lowerVal.contains("expression(") || lowerVal.contains("behavior:") {
                    continue
                }
            }

            let escapedVal = HTMLGenerator.escapeHTML(trimmedVal)
            sanitizedAttrsList.append("\(attrName)=\"\(escapedVal)\"")
        }

        return sanitizedAttrsList.joined(separator: " ")
    }
}
