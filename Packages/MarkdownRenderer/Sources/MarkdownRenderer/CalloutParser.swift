import Foundation

public struct CalloutBlock: Sendable {
    public enum FoldableState: Sendable {
        case nonFoldable
        case expanded
        case collapsed
    }

    public enum CalloutType: String, CaseIterable, Sendable {
        case note = "note"
        case tip = "tip"
        case warning = "warning"
        case important = "important"
        case caution = "caution"
        case info = "info"
        case success = "success"
        case question = "question"
        case failure = "failure"
        case danger = "danger"
        case bug = "bug"
        case example = "example"
        case quote = "quote"

        public var defaultTitle: String {
            switch self {
            case .note: return "Note"
            case .tip: return "Tip"
            case .warning: return "Warning"
            case .important: return "Important"
            case .caution: return "Caution"
            case .info: return "Info"
            case .success: return "Success"
            case .question: return "Question"
            case .failure: return "Failure"
            case .danger: return "Danger"
            case .bug: return "Bug"
            case .example: return "Example"
            case .quote: return "Quote"
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
            case .info:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M0 8a8 8 0 1116 0A8 8 0 010 8zm8-6.5a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM6.5 7.75A.75.75 0 017.25 7h1a.75.75 0 01.75.75v2.75h.25a.75.75 0 010 1.5h-2.5a.75.75 0 010-1.5h.25v-2h-.25a.75.75 0 01-.75-.75zM8 6a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            case .success:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 16A8 8 0 108 0a8 8 0 000 16zm3.78-9.72a.75.75 0 00-1.06-1.06L6.75 9.19 5.28 7.72a.75.75 0 00-1.06 1.06l2 2a.75.75 0 001.06 0l4.5-4.5z"/></svg>
                """
            case .question:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M8 1.5a6.5 6.5 0 100 13 6.5 6.5 0 000-13zM0 8a8 8 0 1116 0A8 8 0 010 8zm7.058-2.608a1.25 1.25 0 012.384.458c0 .484-.27.818-.636 1.108-.344.272-.806.59-1.006.942-.1.176-.15.385-.15.6a.75.75 0 001.5 0c0-.022.006-.054.02-.08.106-.186.38-.403.743-.69.544-.431 1.029-.987 1.029-1.88a2.75 2.75 0 00-5.245-1.007.75.75 0 101.361.649zm.942 6.608a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            case .failure:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M2.343 13.657A8 8 0 1113.657 2.343 8 8 0 012.343 13.657zM6.03 4.97a.75.75 0 00-1.06 1.06L7.44 8.5 4.97 10.97a.75.75 0 101.06 1.06L8.5 9.56l2.47 2.47a.75.75 0 001.06-1.06L9.56 8.5l2.47-2.47a.75.75 0 00-1.06-1.06L8.5 7.44 6.03 4.97z"/></svg>
                """
            case .danger:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M6.457 1.047c.659-1.234 2.427-1.234 3.086 0l6.082 11.378A1.75 1.75 0 0114.082 15H1.918a1.75 1.75 0 01-1.543-2.575L6.457 1.047zM8 5a.75.75 0 00-.75.75v3.5a.75.75 0 001.5 0v-3.5A.75.75 0 008 5zm0 8a1 1 0 100-2 1 1 0 000 2z"/></svg>
                """
            case .bug:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M4.72 3.22a.75.75 0 011.06 1.06L4.81 5.25H6.5a4.5 4.5 0 014.33 3.25h1.92a.75.75 0 010 1.5H10.9a4.502 4.502 0 01-2.4 3.32l1.28 1.28a.75.75 0 11-1.06 1.06L7.25 14.19v-2.73a3 3 0 00-2.5-2.96V5.25h-1.69l-.97-.97a.75.75 0 011.06-1.06l1.57 1.57V3.22z"/></svg>
                """
            case .example:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M0 2.75C0 1.784.784 1 1.75 1h12.5c.966 0 1.75.784 1.75 1.75v10.5A1.75 1.75 0 0114.25 15H1.75A1.75 1.75 0 010 13.25V2.75zm1.75-.25a.25.25 0 00-.25.25v10.5c0 .138.112.25.25.25h12.5a.25.25 0 00.25-.25V2.75a.25.25 0 00-.25-.25H1.75zM4.75 5.5a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0 3.5a.75.75 0 000 1.5h4.5a.75.75 0 000-1.5h-4.5z"/></svg>
                """
            case .quote:
                return """
                <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor"><path d="M1.75 3A1.75 1.75 0 000 4.75v5.5C0 11.216.784 12 1.75 12H4.5v1.25a.75.75 0 001.28.53l2.03-2.03.44-.25H10.25A1.75 1.75 0 0012 9.75v-5A1.75 1.75 0 0010.25 3H1.75z"/></svg>
                """
            }
        }
    }
}

public enum CalloutParser {
    private static let calloutRegex = try? NSRegularExpression(
        pattern: #"^\[!([a-zA-Z_-]+)\]([+-])?(?:\s*(.*))?$"#,
        options: []
    )

    private static let aliases: [String: CalloutBlock.CalloutType] = [
        "note": .note,
        "tip": .tip,
        "hint": .tip,
        "important": .important,
        "attention": .important,
        "warning": .warning,
        "caution": .caution,
        "info": .info,
        "todo": .info,
        "success": .success,
        "check": .success,
        "done": .success,
        "question": .question,
        "help": .question,
        "faq": .question,
        "failure": .failure,
        "fail": .failure,
        "missing": .failure,
        "danger": .danger,
        "error": .danger,
        "bug": .bug,
        "example": .example,
        "quote": .quote,
        "cite": .quote
    ]

    public static func match(firstLine: String) -> (type: CalloutBlock.CalloutType, customTitle: String?, foldable: CalloutBlock.FoldableState)? {
        guard let regex = calloutRegex else { return nil }
        let trimmed = firstLine.trimmingCharacters(in: .whitespaces)
        let range = NSRange(trimmed.startIndex..<trimmed.endIndex, in: trimmed)

        guard let match = regex.firstMatch(in: trimmed, options: [], range: range) else {
            return nil
        }

        guard let typeRange = Range(match.range(at: 1), in: trimmed) else { return nil }
        let rawTypeStr = String(trimmed[typeRange]).lowercased()
        guard let type = aliases[rawTypeStr] ?? CalloutBlock.CalloutType(rawValue: rawTypeStr) else { return nil }

        var foldable: CalloutBlock.FoldableState = .nonFoldable
        if match.range(at: 2).location != NSNotFound, let foldRange = Range(match.range(at: 2), in: trimmed) {
            let foldChar = trimmed[foldRange]
            if foldChar == "+" {
                foldable = .expanded
            } else if foldChar == "-" {
                foldable = .collapsed
            }
        }

        var customTitle: String? = nil
        if match.numberOfRanges > 3, match.range(at: 3).location != NSNotFound, let titleRange = Range(match.range(at: 3), in: trimmed) {
            let extracted = String(trimmed[titleRange]).trimmingCharacters(in: .whitespaces)
            if !extracted.isEmpty {
                customTitle = extracted
            }
        }

        return (type, customTitle, foldable)
    }

    public static func renderHTML(type: CalloutBlock.CalloutType, title: String, contentHTML: String, foldable: CalloutBlock.FoldableState = .nonFoldable) -> String {
        let escapedTitle = HTMLGenerator.escapeHTML(title)

        switch foldable {
        case .expanded:
            return """
            <details class="callout callout-\(type.rawValue) callout-foldable" open>
                <summary class="callout-header">
                    <span class="callout-icon">\(type.iconSvg)</span>
                    <span class="callout-title">\(escapedTitle)</span>
                </summary>
                <div class="callout-body">
                    \(contentHTML)
                </div>
            </details>
            """
        case .collapsed:
            return """
            <details class="callout callout-\(type.rawValue) callout-foldable">
                <summary class="callout-header">
                    <span class="callout-icon">\(type.iconSvg)</span>
                    <span class="callout-title">\(escapedTitle)</span>
                </summary>
                <div class="callout-body">
                    \(contentHTML)
                </div>
            </details>
            """
        case .nonFoldable:
            return """
            <div class="callout callout-\(type.rawValue)">
                <div class="callout-header">
                    <span class="callout-icon">\(type.iconSvg)</span>
                    <span class="callout-title">\(escapedTitle)</span>
                </div>
                <div class="callout-body">
                    \(contentHTML)
                </div>
            </div>
            """
        }
    }
}
