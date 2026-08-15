import Foundation

public enum HTMLGenerator {
    public static func escapeHTML(_ text: String) -> String {
        var escaped = ""
        escaped.reserveCapacity(text.count)
        for char in text {
            switch char {
            case "&": escaped.append("&amp;")
            case "<": escaped.append("&lt;")
            case ">": escaped.append("&gt;")
            case "\"": escaped.append("&quot;")
            case "'": escaped.append("&#39;")
            default: escaped.append(char)
            }
        }
        return escaped
    }

    public enum TokenType {
        case keyword
        case string
        case number
        case comment
        case type
        case function
        case `operator`
        case property
        case tag
        case attrName
        case attrValue
        case plain

        public var cssClass: String? {
            switch self {
            case .keyword: return "token-keyword"
            case .string: return "token-string"
            case .number: return "token-number"
            case .comment: return "token-comment"
            case .type: return "token-type"
            case .function: return "token-func"
            case .operator: return "token-operator"
            case .property: return "token-property"
            case .tag: return "token-tag"
            case .attrName: return "token-type"
            case .attrValue: return "token-string"
            case .plain: return nil
            }
        }
    }

    public struct Token {
        public let range: Range<String.Index>
        public let type: TokenType

        public init(range: Range<String.Index>, type: TokenType) {
            self.range = range
            self.type = type
        }
    }

    public static func highlightCode(code: String, language: String) -> String {
        let lang = language.lowercased().trimmingCharacters(in: .whitespaces)

        if lang.isEmpty || ["text", "txt", "plain", "plaintext"].contains(lang) {
            return escapeHTML(code)
        }

        let tokens = tokenize(code: code, language: lang)

        var output = ""
        output.reserveCapacity(code.count + tokens.count * 30)

        var currentIndex = code.startIndex

        for token in tokens {
            if currentIndex < token.range.lowerBound {
                let plainText = String(code[currentIndex..<token.range.lowerBound])
                output.append(escapeHTML(plainText))
            }

            let tokenText = String(code[token.range])
            let escapedText = escapeHTML(tokenText)

            if let cssClass = token.type.cssClass {
                output.append("<span class=\"\(cssClass)\">\(escapedText)</span>")
            } else {
                output.append(escapedText)
            }

            currentIndex = token.range.upperBound
        }

        if currentIndex < code.endIndex {
            let remaining = String(code[currentIndex..<code.endIndex])
            output.append(escapeHTML(remaining))
        }

        return output
    }

    // MARK: - Tokenizer Implementation

    private static func tokenize(code: String, language: String) -> [Token] {
        switch language {
        case "json":
            return tokenizeJSON(code)
        case "html", "xml", "svg":
            return tokenizeHTML(code)
        default:
            return tokenizeGeneral(code: code, language: language)
        }
    }

    private static func tokenizeJSON(_ code: String) -> [Token] {
        var tokens: [Token] = []
        var index = code.startIndex
        let end = code.endIndex

        while index < end {
            let char = code[index]

            if char.isWhitespace {
                index = code.index(after: index)
                continue
            }

            // String or property key
            if char == "\"" {
                let start = index
                index = code.index(after: index)
                var escaped = false
                while index < end {
                    let c = code[index]
                    if escaped {
                        escaped = false
                    } else if c == "\\" {
                        escaped = true
                    } else if c == "\"" {
                        index = code.index(after: index)
                        break
                    }
                    index = code.index(after: index)
                }

                // Check if followed by colon (key)
                var lookAhead = index
                while lookAhead < end && code[lookAhead].isWhitespace {
                    lookAhead = code.index(after: lookAhead)
                }
                if lookAhead < end && code[lookAhead] == ":" {
                    tokens.append(Token(range: start..<index, type: .property))
                } else {
                    tokens.append(Token(range: start..<index, type: .string))
                }
                continue
            }

            // Numbers
            if char.isNumber || char == "-" {
                let start = index
                index = code.index(after: index)
                while index < end && (code[index].isNumber || code[index] == "." || code[index] == "e" || code[index] == "E" || code[index] == "+" || code[index] == "-") {
                    index = code.index(after: index)
                }
                tokens.append(Token(range: start..<index, type: .number))
                continue
            }

            // Literals true/false/null
            if char.isLetter {
                let start = index
                while index < end && code[index].isLetter {
                    index = code.index(after: index)
                }
                let word = String(code[start..<index])
                if ["true", "false", "null"].contains(word) {
                    tokens.append(Token(range: start..<index, type: .keyword))
                }
                continue
            }

            index = code.index(after: index)
        }

        return tokens
    }

    private static func tokenizeHTML(_ code: String) -> [Token] {
        var tokens: [Token] = []
        var index = code.startIndex
        let end = code.endIndex

        while index < end {
            // Check comment <!-- ... -->
            if code[index...].hasPrefix("<!--") {
                let start = index
                if let closeRange = code[index...].range(of: "-->") {
                    index = closeRange.upperBound
                } else {
                    index = end
                }
                tokens.append(Token(range: start..<index, type: .comment))
                continue
            }

            // Tag <... >
            if code[index] == "<" {
                let tagStart = index
                index = code.index(after: index)

                // Closing slash?
                if index < end && code[index] == "/" {
                    index = code.index(after: index)
                }

                // Tag name
                let nameStart = index
                while index < end && (code[index].isLetter || code[index].isNumber || code[index] == "-" || code[index] == ":") {
                    index = code.index(after: index)
                }

                if nameStart < index {
                    tokens.append(Token(range: tagStart..<index, type: .tag))
                }

                // Tag attributes
                while index < end && code[index] != ">" {
                    if code[index].isWhitespace || code[index] == "/" {
                        index = code.index(after: index)
                        continue
                    }

                    // Attribute name
                    let attrStart = index
                    while index < end && !code[index].isWhitespace && code[index] != "=" && code[index] != ">" && code[index] != "/" {
                        index = code.index(after: index)
                    }
                    if attrStart < index {
                        tokens.append(Token(range: attrStart..<index, type: .attrName))
                    }

                    while index < end && code[index].isWhitespace {
                        index = code.index(after: index)
                    }

                    if index < end && code[index] == "=" {
                        index = code.index(after: index)
                        while index < end && code[index].isWhitespace {
                            index = code.index(after: index)
                        }

                        // Attribute value (quoted or unquoted)
                        if index < end && (code[index] == "\"" || code[index] == "'") {
                            let quote = code[index]
                            let valStart = index
                            index = code.index(after: index)
                            while index < end && code[index] != quote {
                                index = code.index(after: index)
                            }
                            if index < end {
                                index = code.index(after: index)
                            }
                            tokens.append(Token(range: valStart..<index, type: .attrValue))
                        } else if index < end && code[index] != ">" {
                            let valStart = index
                            while index < end && !code[index].isWhitespace && code[index] != ">" {
                                index = code.index(after: index)
                            }
                            tokens.append(Token(range: valStart..<index, type: .attrValue))
                        }
                    }
                }

                if index < end && code[index] == ">" {
                    index = code.index(after: index)
                }
                continue
            }

            index = code.index(after: index)
        }

        return tokens
    }

    private static func tokenizeGeneral(code: String, language: String) -> [Token] {
        var tokens: [Token] = []
        var index = code.startIndex
        let end = code.endIndex

        let keywords = keywordsForLanguage(language)
        let isBash = ["bash", "sh", "zsh", "shell"].contains(language)

        while index < end {
            let char = code[index]

            // 1. Line Comments
            if !isBash && (code[index...].hasPrefix("//") || (["python", "py", "ruby", "rb", "yaml", "yml", "r"].contains(language) && char == "#")) {
                let start = index
                while index < end && code[index] != "\n" {
                    index = code.index(after: index)
                }
                tokens.append(Token(range: start..<index, type: .comment))
                continue
            }

            // Bash line comments (# at start of line or after whitespace, not in variables)
            if isBash && char == "#" {
                let start = index
                while index < end && code[index] != "\n" {
                    index = code.index(after: index)
                }
                tokens.append(Token(range: start..<index, type: .comment))
                continue
            }

            // SQL / Lua / Haskell comments
            if ["sql", "lua", "hs", "haskell"].contains(language) && code[index...].hasPrefix("--") {
                let start = index
                while index < end && code[index] != "\n" {
                    index = code.index(after: index)
                }
                tokens.append(Token(range: start..<index, type: .comment))
                continue
            }

            // 2. Block Comments /* ... */
            if code[index...].hasPrefix("/*") {
                let start = index
                if let closeRange = code[index...].range(of: "*/") {
                    index = closeRange.upperBound
                } else {
                    index = end
                }
                tokens.append(Token(range: start..<index, type: .comment))
                continue
            }

            // 3. Multi-line Strings ("""...""" or '''...''')
            if code[index...].hasPrefix("\"\"\"") || code[index...].hasPrefix("'''") {
                let delimiter = String(code[index..<code.index(index, offsetBy: 3)])
                let start = index
                index = code.index(index, offsetBy: 3)
                if let closeRange = code[index...].range(of: delimiter) {
                    index = closeRange.upperBound
                } else {
                    index = end
                }
                tokens.append(Token(range: start..<index, type: .string))
                continue
            }

            // 4. Single-line Strings ("..." or '...' or `...`)
            if char == "\"" || char == "'" || (["javascript", "js", "typescript", "ts", "go", "golang"].contains(language) && char == "`") {
                let quote = char
                let start = index
                index = code.index(after: index)
                var escaped = false
                while index < end {
                    let c = code[index]
                    if escaped {
                        escaped = false
                    } else if c == "\\" {
                        escaped = true
                    } else if c == quote {
                        index = code.index(after: index)
                        break
                    } else if c == "\n" && quote != "`" {
                        break // unterminated single-line string
                    }
                    index = code.index(after: index)
                }
                tokens.append(Token(range: start..<index, type: .string))
                continue
            }

            // 5. Numbers (Hex, Binary, Octal, Decimal, Float)
            if char.isNumber || (char == "." && code.index(after: index) < end && code[code.index(after: index)].isNumber) {
                let start = index
                if code[index...].hasPrefix("0x") || code[index...].hasPrefix("0X") ||
                    code[index...].hasPrefix("0b") || code[index...].hasPrefix("0B") ||
                    code[index...].hasPrefix("0o") || code[index...].hasPrefix("0O") {
                    index = code.index(index, offsetBy: 2)
                    while index < end && (code[index].isHexDigit || code[index] == "_") {
                        index = code.index(after: index)
                    }
                } else {
                    var hasDot = (char == ".")
                    while index < end {
                        let c = code[index]
                        if c.isNumber || c == "_" {
                            index = code.index(after: index)
                        } else if c == "." && !hasDot && code.index(after: index) < end && code[code.index(after: index)].isNumber {
                            hasDot = true
                            index = code.index(after: index)
                        } else if (c == "e" || c == "E") && code.index(after: index) < end {
                            index = code.index(after: index)
                            if index < end && (code[index] == "+" || code[index] == "-") {
                                index = code.index(after: index)
                            }
                        } else {
                            break
                        }
                    }
                }
                tokens.append(Token(range: start..<index, type: .number))
                continue
            }

            // 6. Identifiers (Keywords, Types, Functions)
            if char.isLetter || char == "_" || char == "$" || (isBash && char == "-") {
                let start = index
                while index < end && (code[index].isLetter || code[index].isNumber || code[index] == "_" || code[index] == "$" || (isBash && code[index] == "-")) {
                    index = code.index(after: index)
                }

                let word = String(code[start..<index])

                if keywords.contains(word) {
                    tokens.append(Token(range: start..<index, type: .keyword))
                } else if word.first?.isUppercase == true && word.count > 1 {
                    tokens.append(Token(range: start..<index, type: .type))
                } else {
                    // Check if function call (word followed by `(`)
                    var lookAhead = index
                    while lookAhead < end && code[lookAhead].isWhitespace && code[lookAhead] != "\n" {
                        lookAhead = code.index(after: lookAhead)
                    }
                    if lookAhead < end && code[lookAhead] == "(" {
                        tokens.append(Token(range: start..<index, type: .function))
                    }
                }
                continue
            }

            index = code.index(after: index)
        }

        return tokens
    }

    private static func keywordsForLanguage(_ lang: String) -> Set<String> {
        switch lang {
        case "swift":
            return [
                "actor", "any", "as", "associatedtype", "async", "await", "break", "case",
                "catch", "class", "continue", "convenience", "default", "defer", "deinit",
                "do", "dynamic", "else", "enum", "extension", "fallthrough", "false", "fileprivate",
                "final", "for", "func", "get", "guard", "if", "import", "in", "indirect",
                "infix", "init", "inout", "internal", "is", "isolated", "lazy", "let",
                "mutating", "nil", "nonisolated", "open", "operator", "optional", "override",
                "postfix", "prefix", "precedencegroup", "private", "protocol", "public",
                "repeat", "required", "rethrows", "return", "self", "Self", "set", "some",
                "static", "struct", "subscript", "super", "switch", "throw", "throws",
                "true", "try", "typealias", "unowned", "var", "weak", "where", "while",
                "willSet", "didSet", "Sendable"
            ]
        case "javascript", "js", "typescript", "ts", "jsx", "tsx":
            return [
                "abstract", "any", "as", "async", "await", "boolean", "break", "case",
                "catch", "class", "const", "constructor", "continue", "debugger", "declare",
                "default", "delete", "do", "else", "enum", "export", "extends", "false",
                "finally", "for", "from", "function", "get", "if", "implements", "import",
                "in", "infer", "instanceof", "interface", "is", "keyof", "let", "module",
                "namespace", "never", "new", "null", "number", "of", "package", "private",
                "protected", "public", "readonly", "require", "return", "set", "static",
                "string", "super", "switch", "symbol", "this", "throw", "true", "try",
                "type", "typeof", "undefined", "unknown", "var", "void", "while", "with",
                "yield"
            ]
        case "python", "py":
            return [
                "and", "as", "assert", "async", "await", "break", "class", "continue",
                "def", "del", "elif", "else", "except", "False", "finally", "for",
                "from", "global", "if", "import", "in", "is", "lambda", "None",
                "nonlocal", "not", "or", "pass", "raise", "return", "self", "True",
                "try", "while", "with", "yield", "match", "case"
            ]
        case "rust", "rs":
            return [
                "as", "async", "await", "break", "const", "continue", "crate", "dyn",
                "else", "enum", "extern", "false", "fn", "for", "if", "impl", "in",
                "let", "loop", "match", "mod", "move", "mut", "pub", "ref", "return",
                "self", "Self", "static", "struct", "super", "trait", "true", "type",
                "unsafe", "use", "where", "while", "Some", "None", "Ok", "Err"
            ]
        case "go", "golang":
            return [
                "break", "case", "chan", "const", "continue", "default", "defer",
                "else", "fallthrough", "for", "func", "go", "goto", "if", "import",
                "interface", "map", "package", "range", "return", "select", "struct",
                "switch", "type", "var", "nil", "true", "false", "make", "new", "len", "cap", "append"
            ]
        case "bash", "sh", "zsh", "shell":
            return [
                "if", "then", "else", "elif", "fi", "case", "esac", "for", "while",
                "until", "do", "done", "in", "function", "select", "time", "coproc",
                "return", "exit", "export", "local", "readonly", "unset", "shift",
                "source", "alias", "echo", "cd", "mkdir", "rm", "cp", "mv", "chmod",
                "curl", "git", "brew", "sudo", "cat", "grep", "sed", "awk"
            ]
        case "c", "cpp", "c++", "objc", "m", "mm", "h", "hpp":
            return [
                "auto", "break", "case", "char", "const", "continue", "default", "do",
                "double", "else", "enum", "extern", "float", "for", "goto", "if",
                "int", "long", "register", "return", "short", "signed", "sizeof",
                "static", "struct", "switch", "typedef", "union", "unsigned", "void",
                "volatile", "while", "class", "public", "private", "protected", "virtual",
                "override", "template", "typename", "namespace", "using", "new", "delete",
                "nullptr", "true", "false", "bool", "constexpr", "inline", "static_cast",
                "dynamic_cast", "reinterpret_cast", "const_cast", "try", "catch", "throw"
            ]
        case "sql":
            return [
                "SELECT", "FROM", "WHERE", "INSERT", "INTO", "UPDATE", "DELETE", "JOIN",
                "INNER", "LEFT", "RIGHT", "OUTER", "FULL", "ON", "AND", "OR", "NOT",
                "NULL", "IS", "IN", "BETWEEN", "LIKE", "GROUP", "BY", "HAVING", "ORDER",
                "ASC", "DESC", "LIMIT", "OFFSET", "CREATE", "TABLE", "DROP", "ALTER",
                "INDEX", "VIEW", "PRIMARY", "KEY", "FOREIGN", "REFERENCES", "CONSTRAINT",
                "UNION", "ALL", "DISTINCT", "AS", "SET", "VALUES", "CASE", "WHEN", "THEN",
                "ELSE", "END", "EXISTS", "COUNT", "SUM", "AVG", "MIN", "MAX",
                "select", "from", "where", "insert", "into", "update", "delete", "join",
                "inner", "left", "right", "outer", "full", "on", "and", "or", "not",
                "null", "is", "in", "between", "like", "group", "by", "having", "order",
                "asc", "desc", "limit", "offset", "create", "table", "drop", "alter"
            ]
        case "css", "scss", "sass":
            return [
                "important", "root", "media", "keyframes", "font-face", "supports",
                "import", "charset", "namespace", "page"
            ]
        default:
            return [
                "func", "function", "def", "fn", "let", "var", "const", "if", "else",
                "elif", "for", "while", "return", "import", "export", "class", "struct",
                "interface", "true", "false", "null", "nil", "None", "undefined"
            ]
        }
    }
}
