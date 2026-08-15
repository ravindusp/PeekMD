import Foundation

public struct CalloutBlock: Sendable {
    public enum CalloutType: String, Sendable {
        case note = "note"
        case tip = "tip"
        case warning = "warning"
        case important = "important"
        case caution = "caution"

        public var title: String {
            switch self {
            case .note: return "Note"
            case .tip: return "Tip"
            case .warning: return "Warning"
            case .important: return "Important"
            case .caution: return "Caution"
            }
        }

        public var iconSvg: String {
            switch self {
            case .note:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM0 8a8 8 0 1116 0A8 8 0 010 8zm6.5-.25A.75.75 0 017.25 7h1a.75.75 0 01.75.75v2.75h.25a.75.75 0 010 1.5h-2.5a.75.75 0 010-1.5h.25v-2h-.25a.75.75 0 01-.75-.75zM8 6a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            case .tip:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5c-2.363 0-4 1.69-4 3.75 0 .984.424 1.625.984 2.304l.214.253c.223.264.47.556.673.92.208.373.379.882.379 1.523v.25h3.5v-.25c0-.641.171-1.15.379-1.523.203-.364.45-.656.673-.92l.214-.253c.56-.679.984-1.32.984-2.304 0-2.06-1.637-3.75-4-3.75zM5.5 12h5v1.25a.75.75 0 01-.75.75h-3.5a.75.75 0 01-.75-.75V12z"/></svg>
                """
            case .warning:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0114.082 15H1.918a1.75 1.75 0 01-1.543-2.575L6.457 1.047zM8 5a.75.75 0 00-.75.75v3.5a.75.75 0 001.5 0v-3.5A.75.75 0 008 5zm0 8a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            case .important:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM0 8a8 8 0 1116 0A8 8 0 010 8zm7.25 2.5a.75.75 0 011.5 0v1.5a.75.75 0 01-1.5 0v-1.5zm.75-7a.75.75 0 00-.75.75v4a.75.75 0 001.5 0v-4A.75.75 0 008 4.5z"/></svg>
                """
            case .caution:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M4.47.04c.17-.04.35-.04.53 0l6 1.5a1.75 1.75 0 011.3 1.69v4.27c0 4.14-2.82 7.82-6.86 8.94a1.75 1.75 0 01-.88 0C3.52 15.32.7 11.64.7 7.5V3.23a1.75 1.75 0 011.3-1.69l2.47-.62v-.88zM8 4.5a.75.75 0 00-.75.75v3a.75.75 0 001.5 0v-3A.75.75 0 008 4.5zm0 6.5a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            }
        }
    }
}

public enum CalloutParser {
    private static let calloutRegex = try? NSRegularExpression(
        pattern: #"^\[!(NOTE|TIP|WARNING|IMPORTANT|CAUTION)\](?:\s*(.*))?$"#,
        options: [.caseInsensitive]
    )

    public static func match(firstLine: String) -> (type: CalloutBlock.CalloutType, customTitle: String?)? {
        guard let regex = calloutRegex else { return nil }
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)

        guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else {
            return nil
        }

        guard let typeRange = Range(match.range(at: 1), in: trimmed) else { return nil }
        let typeStr = String(trimmed[typeRange]).lowercased()
        guard let type = CalloutBlock.CalloutType(rawValue: typeStr) else { return nil }

        var customTitle: String? = nil
        if match.numberOfRanges > 2, let titleRange = Range(match.range(at: 2), in: trimmed) {
            let extracted = String(trimmed[titleRange]).trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty {
                customTitle = extracted
            }
        }

        return (type, customTitle)
    }

    public static func renderHTML(type: CalloutBlock.CalloutType, title: String, contentHTML: String) -> String {
        return """
        <div class="callout callout-\(type.rawValue)">
            <div class="callout-header">
                <span class="callout-icon">\(type.iconSvg)</span>
                <span>\(title)</span>
            </div>
            <div class="callout-body">
                \(contentHTML)
            </div>
        </div>
        """
    }
}
