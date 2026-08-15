import Foundation

public enum Theme: String, CaseIterable, Sendable {
    case system = "System"
    case github = "GitHub"
    case minimal = "Minimal"
    case academic = "Academic"

    public var css: String {
        switch self {
        case .system:
            return ThemeStyles.systemCSS
        case .github:
            return ThemeStyles.githubCSS
        case .minimal:
            return ThemeStyles.minimalCSS
        case .academic:
            return ThemeStyles.academicCSS
        }
    }
}

private enum ThemeStyles {
    static let baseResetAndTypography = """
    *, *::before, *::after {
        box-sizing: border-box;
    }

    html {
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
        text-rendering: optimizeLegibility;
        overflow-x: hidden;
        width: 100%;
    }

    body {
        margin: 0;
        padding: 2.5rem 3rem;
        max-width: 860px;
        margin-left: auto;
        margin-right: auto;
        line-height: 1.65;
        font-size: 15px;
        font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Segoe UI", Helvetica, Arial, sans-serif;
        color: var(--text-color);
        background-color: var(--bg-color);
        overflow-wrap: break-word;
        word-break: break-word;
        overflow-x: hidden;
        transition: background-color 0.2s ease, color 0.2s ease;
    }

    .markdown-body {
        max-width: 100%;
        overflow-wrap: break-word;
        word-break: break-word;
    }

    h1, h2, h3, h4, h5, h6 {
        margin-top: 1.8em;
        margin-bottom: 0.6em;
        font-weight: 600;
        line-height: 1.25;
        color: var(--heading-color);
        letter-spacing: -0.015em;
        overflow-wrap: break-word;
    }

    h1 { font-size: 2.1em; border-bottom: 1px solid var(--border-subtle); padding-bottom: 0.3em; margin-top: 0.8em; }
    h2 { font-size: 1.55em; border-bottom: 1px solid var(--border-subtle); padding-bottom: 0.25em; }
    h3 { font-size: 1.28em; }
    h4 { font-size: 1.1em; }
    h5 { font-size: 0.95em; text-transform: uppercase; letter-spacing: 0.05em; color: var(--text-muted); }
    h6 { font-size: 0.88em; color: var(--text-muted); }

    p {
        margin-top: 0;
        margin-bottom: 1.1em;
        overflow-wrap: break-word;
    }

    a {
        color: var(--accent-color);
        text-decoration: none;
        border-bottom: 1px solid transparent;
        transition: border-color 0.15s ease;
        overflow-wrap: break-word;
        word-break: break-word;
    }

    a:hover {
        border-bottom-color: var(--accent-color);
    }

    strong { font-weight: 600; color: var(--heading-color); }
    em { font-style: italic; }
    del { opacity: 0.65; text-decoration: line-through; }
    mark {
        background-color: var(--highlight-bg, #fff3a8);
        color: var(--highlight-text, #1f2328);
        padding: 0.15em 0.35em;
        border-radius: 4px;
    }
    kbd {
        display: inline-block;
        padding: 3px 6px;
        font-family: "SF Mono", "Menlo", monospace;
        font-size: 0.82em;
        line-height: 1.1;
        color: var(--text-color);
        vertical-align: middle;
        background-color: var(--card-bg);
        border: solid 1px var(--border-strong);
        border-radius: 6px;
        box-shadow: inset 0 -1px 0 var(--border-subtle);
    }
    sub, sup {
        font-size: 0.75em;
        line-height: 0;
        position: relative;
        vertical-align: baseline;
    }
    sup { top: -0.5em; }
    sub { bottom: -0.25em; }

    hr {
        height: 1px;
        background-color: var(--border-subtle);
        border: none;
        margin: 2.2em 0;
    }

    blockquote {
        margin: 1.4em 0;
        padding: 0.6em 1.2em;
        border-left: 3.5px solid var(--accent-color);
        background-color: var(--callout-bg);
        border-radius: 0 8px 8px 0;
        color: var(--text-secondary);
        overflow-wrap: break-word;
    }

    blockquote > p:last-child {
        margin-bottom: 0;
    }

    ul, ol {
        margin-top: 0;
        margin-bottom: 1.1em;
        padding-left: 1.8em;
    }

    li {
        margin-bottom: 0.35em;
        overflow-wrap: break-word;
    }

    li > p {
        margin-bottom: 0.4em;
    }

    /* Nested Lists */
    li > ul, li > ol {
        margin-top: 0.3em;
        margin-bottom: 0.3em;
        padding-left: 1.5em;
    }

    /* Task Lists */
    ul.task-list {
        list-style-type: none;
        padding-left: 0.2em;
    }

    li.task-list-item {
        display: flex;
        align-items: baseline;
        gap: 0.55em;
        margin-bottom: 0.4em;
        list-style: none;
    }

    .task-list-content {
        flex: 1;
        min-width: 0;
    }

    .task-checkbox {
        appearance: none;
        -webkit-appearance: none;
        width: 15px;
        height: 15px;
        border: 1.5px solid var(--border-strong);
        border-radius: 4px;
        background-color: var(--card-bg);
        outline: none;
        cursor: default;
        position: relative;
        top: 2px;
        flex-shrink: 0;
    }

    .task-checkbox:checked {
        background-color: var(--accent-color);
        border-color: var(--accent-color);
    }

    .task-checkbox:checked::after {
        content: '';
        position: absolute;
        left: 4px;
        top: 1px;
        width: 4px;
        height: 8px;
        border: solid #ffffff;
        border-width: 0 2px 2px 0;
        transform: rotate(45deg);
    }

    /* Code & Syntax */
    code {
        font-family: "SF Mono", "Menlo", "Monaco", "Consolas", monospace;
        font-size: 0.88em;
        padding: 0.2em 0.45em;
        border-radius: 5px;
        background-color: var(--code-inline-bg);
        color: var(--code-inline-text);
        border: 1px solid var(--code-inline-border);
        overflow-wrap: break-word;
    }

    pre {
        margin: 1.4em 0;
        padding: 1.1em 1.3em;
        border-radius: 8px;
        background-color: var(--code-block-bg);
        border: 1px solid var(--border-subtle);
        overflow-x: auto;
        max-width: 100%;
        line-height: 1.5;
        white-space: pre;
        box-sizing: border-box;
    }

    pre code {
        font-size: 0.88em;
        padding: 0;
        background: transparent;
        border: none;
        color: var(--code-block-text);
        display: block;
        overflow-wrap: normal;
        word-break: normal;
    }

    .code-block-container {
        position: relative;
        margin: 1.4em 0;
        max-width: 100%;
    }

    .code-block-container pre {
        margin: 0;
    }

    .code-lang-tag {
        position: absolute;
        top: 0.55em;
        right: 0.85em;
        font-family: "SF Mono", "Menlo", monospace;
        font-size: 0.72em;
        color: var(--text-muted);
        text-transform: uppercase;
        letter-spacing: 0.05em;
        user-select: none;
    }

    /* Syntax Highlighting Tokens */
    .token-keyword { color: var(--syn-keyword); font-weight: 600; }
    .token-string { color: var(--syn-string); }
    .token-number { color: var(--syn-number); }
    .token-comment { color: var(--syn-comment); font-style: italic; }
    .token-type { color: var(--syn-type); }
    .token-func { color: var(--syn-func); }
    .token-operator { color: var(--syn-operator); }
    .token-property { color: var(--syn-property); }
    .token-tag { color: var(--syn-keyword); font-weight: 600; }

    /* Tables */
    .table-wrapper {
        width: 100%;
        max-width: 100%;
        overflow-x: auto;
        margin: 1.4em 0;
        -webkit-overflow-scrolling: touch;
    }

    table {
        width: 100%;
        border-collapse: collapse;
        margin: 0;
        font-size: 0.94em;
        border-radius: 7px;
        border: 1px solid var(--border-subtle);
    }

    th, td {
        padding: 0.65em 1em;
        text-align: left;
        border-bottom: 1px solid var(--border-subtle);
        overflow-wrap: break-word;
    }

    th {
        font-weight: 600;
        background-color: var(--table-th-bg);
        color: var(--heading-color);
        border-bottom: 2px solid var(--border-subtle);
    }

    tr:last-child td {
        border-bottom: none;
    }

    tr:nth-child(even) td {
        background-color: var(--table-alt-bg);
    }

    /* Images */
    img, picture, video {
        max-width: 100%;
        height: auto;
        border-radius: 8px;
        margin: 1.2em 0;
        display: block;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
    }

    .image-caption {
        text-align: center;
        font-size: 0.85em;
        color: var(--text-muted);
        margin-top: -0.6em;
        margin-bottom: 1.2em;
    }

    /* Details / Summary */
    details {
        margin: 1.2em 0;
        padding: 0.6em 1em;
        border-radius: 8px;
        background-color: var(--card-bg);
        border: 1px solid var(--border-subtle);
    }

    details summary {
        cursor: pointer;
        font-weight: 600;
        color: var(--heading-color);
        outline: none;
    }

    details[open] {
        padding-bottom: 0.8em;
    }

    /* Frontmatter Card */
    .frontmatter-card {
        margin-bottom: 2em;
        padding: 0.9em 1.2em;
        border-radius: 8px;
        background-color: var(--frontmatter-bg);
        border: 1px solid var(--border-subtle);
        font-size: 0.85em;
    }

    .frontmatter-title {
        font-weight: 600;
        text-transform: uppercase;
        letter-spacing: 0.05em;
        color: var(--text-muted);
        margin-bottom: 0.5em;
    }

    .frontmatter-entry {
        display: flex;
        gap: 0.8em;
        margin-bottom: 0.25em;
        overflow-wrap: break-word;
    }

    .frontmatter-key {
        font-weight: 600;
        color: var(--text-secondary);
        min-width: 80px;
    }

    .frontmatter-val {
        color: var(--text-color);
        flex: 1;
        overflow-wrap: break-word;
    }

    /* Callouts */
    .callout {
        margin: 1.4em 0;
        padding: 0.9em 1.1em;
        border-radius: 8px;
        border-left: 4px solid var(--callout-border);
        background-color: var(--callout-bg);
    }

    .callout-header {
        display: flex;
        align-items: center;
        gap: 0.55em;
        font-weight: 600;
        font-size: 0.95em;
        color: var(--callout-title-color);
        margin-bottom: 0.4em;
    }

    details.callout-foldable summary.callout-header {
        cursor: pointer;
        user-select: none;
        list-style: none;
    }

    details.callout-foldable summary::-webkit-details-marker {
        display: none;
    }

    .callout-icon {
        width: 16px;
        height: 16px;
        display: inline-flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
    }

    .callout-title {
        flex: 1;
    }

    .callout-body {
        font-size: 0.93em;
        color: var(--text-color);
    }

    .callout-body > p:last-child {
        margin-bottom: 0;
    }

    .callout-note { --callout-border: #007aff; --callout-bg: rgba(0, 122, 255, 0.07); --callout-title-color: #007aff; }
    .callout-tip { --callout-border: #34c759; --callout-bg: rgba(52, 199, 89, 0.07); --callout-title-color: #28a745; }
    .callout-info { --callout-border: #007aff; --callout-bg: rgba(0, 122, 255, 0.07); --callout-title-color: #007aff; }
    .callout-warning { --callout-border: #ff9500; --callout-bg: rgba(255, 149, 0, 0.08); --callout-title-color: #e67e00; }
    .callout-important { --callout-border: #af52de; --callout-bg: rgba(175, 82, 222, 0.07); --callout-title-color: #9b30d9; }
    .callout-caution { --callout-border: #ff3b30; --callout-bg: rgba(255, 59, 48, 0.08); --callout-title-color: #d9251b; }
    .callout-success { --callout-border: #28a745; --callout-bg: rgba(40, 167, 69, 0.07); --callout-title-color: #28a745; }
    .callout-question { --callout-border: #e36209; --callout-bg: rgba(227, 98, 9, 0.07); --callout-title-color: #d05700; }
    .callout-failure { --callout-border: #cb2431; --callout-bg: rgba(203, 36, 49, 0.08); --callout-title-color: #cb2431; }
    .callout-danger { --callout-border: #d73a49; --callout-bg: rgba(215, 58, 73, 0.08); --callout-title-color: #d73a49; }
    .callout-bug { --callout-border: #ea4a5a; --callout-bg: rgba(234, 74, 90, 0.08); --callout-title-color: #ea4a5a; }
    .callout-example { --callout-border: #6f42c1; --callout-bg: rgba(111, 66, 193, 0.07); --callout-title-color: #6f42c1; }
    .callout-quote { --callout-border: #6a737d; --callout-bg: rgba(106, 115, 125, 0.07); --callout-title-color: #586069; }

    /* Math Equations */
    .math-block {
        display: flex;
        justify-content: center;
        margin: 1.4em 0;
        padding: 0.9em;
        border-radius: 8px;
        background-color: var(--card-bg);
        font-family: "KaTeX_Main", "Cambria Math", "Latin Modern Math", "STIX Two Math", "SF Pro Text", serif;
        font-size: 1.1em;
        overflow-x: auto;
        max-width: 100%;
    }

    .math-inline {
        font-family: "KaTeX_Main", "Cambria Math", "Latin Modern Math", "STIX Two Math", serif;
        padding: 0 0.2em;
    }

    /* Wikilinks & Embeds */
    .wikilink {
        font-weight: 500;
        border-bottom: 1px dashed var(--accent-color);
    }

    .embedded-note-link {
        margin: 0.8em 0;
        padding: 0.5em 0.8em;
        background-color: var(--card-bg);
        border-radius: 6px;
        border: 1px solid var(--border-subtle);
    }

    /* Mermaid Diagrams */
    .mermaid-block {
        margin: 1.4em 0;
        padding: 1.2em;
        background-color: var(--card-bg);
        border-radius: 8px;
        border: 1px solid var(--border-subtle);
        overflow-x: auto;
        text-align: center;
    }

    .mermaid-block pre.mermaid {
        background: transparent;
        border: none;
        padding: 0;
        margin: 0;
        font-size: 0.9em;
        display: inline-block;
        text-align: left;
    }

    /* Footnotes */
    .footnotes {
        margin-top: 3em;
        font-size: 0.88em;
        color: var(--text-secondary);
    }

    .footnotes hr {
        margin-bottom: 1.5em;
    }

    .footnotes ol {
        padding-left: 1.5em;
    }

    .footnotes li {
        margin-bottom: 0.5em;
    }

    .footnote-ref a {
        text-decoration: none;
        font-weight: 600;
        color: var(--accent-color);
    }

    .footnote-backref {
        text-decoration: none;
        color: var(--accent-color);
        margin-left: 0.3em;
    }
    """

    static let systemCSS = """
    :root {
        --bg-color: #ffffff;
        --text-color: #1d1d1f;
        --text-secondary: #515154;
        --text-muted: #86868b;
        --heading-color: #111112;
        --accent-color: #0071e3;
        --border-subtle: rgba(0, 0, 0, 0.09);
        --border-strong: rgba(0, 0, 0, 0.22);
        --card-bg: #f5f5f7;
        --code-inline-bg: rgba(0, 0, 0, 0.05);
        --code-inline-text: #bf1b4b;
        --code-inline-border: rgba(0, 0, 0, 0.06);
        --code-block-bg: #f8f9fa;
        --code-block-text: #24292f;
        --table-th-bg: #f2f2f5;
        --table-alt-bg: rgba(0, 0, 0, 0.018);
        --frontmatter-bg: #fafafc;
        --highlight-bg: #fff3a8;
        --highlight-text: #1f2328;

        --syn-keyword: #ad3da4;
        --syn-string: #c41a16;
        --syn-number: #1c00cf;
        --syn-comment: #707f8c;
        --syn-type: #3e6b89;
        --syn-func: #2e6284;
        --syn-operator: #5c6370;
        --syn-property: #006b75;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --bg-color: #1e1e1e;
            --text-color: #e3e3e8;
            --text-secondary: #a1a1a6;
            --text-muted: #6e6e73;
            --heading-color: #f5f5f7;
            --accent-color: #2997ff;
            --border-subtle: rgba(255, 255, 255, 0.1);
            --border-strong: rgba(255, 255, 255, 0.28);
            --card-bg: #28282a;
            --code-inline-bg: rgba(255, 255, 255, 0.09);
            --code-inline-text: #ff7b99;
            --code-inline-border: rgba(255, 255, 255, 0.08);
            --code-block-bg: #161618;
            --code-block-text: #e6edf3;
            --table-th-bg: #262629;
            --table-alt-bg: rgba(255, 255, 255, 0.025);
            --frontmatter-bg: #252528;
            --highlight-bg: #634d00;
            --highlight-text: #fff3a8;

            --syn-keyword: #fc5fa3;
            --syn-string: #fc6a5d;
            --syn-number: #d0bf69;
            --syn-comment: #6c7986;
            --syn-type: #5dd8ff;
            --syn-func: #6bdfff;
            --syn-operator: #abb2bf;
            --syn-property: #79c0ff;
        }
    }

    \(baseResetAndTypography)
    """

    static let githubCSS = """
    :root {
        --bg-color: #ffffff;
        --text-color: #1f2328;
        --text-secondary: #656d76;
        --text-muted: #8c959f;
        --heading-color: #1f2328;
        --accent-color: #0969da;
        --border-subtle: #d0d7de;
        --border-strong: #8c959f;
        --card-bg: #f6f8fa;
        --code-inline-bg: #eff1f3;
        --code-inline-text: #1f2328;
        --code-inline-border: #d0d7de;
        --code-block-bg: #f6f8fa;
        --code-block-text: #1f2328;
        --table-th-bg: #f6f8fa;
        --table-alt-bg: #ffffff;
        --frontmatter-bg: #f6f8fa;
        --highlight-bg: #fff8c5;
        --highlight-text: #1f2328;

        --syn-keyword: #cf222e;
        --syn-string: #0a3069;
        --syn-number: #0550ae;
        --syn-comment: #6e7781;
        --syn-type: #953800;
        --syn-func: #8250df;
        --syn-operator: #24292f;
        --syn-property: #0550ae;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --bg-color: #0d1117;
            --text-color: #e6edf3;
            --text-secondary: #7d8590;
            --text-muted: #6e7681;
            --heading-color: #e6edf3;
            --accent-color: #4493f8;
            --border-subtle: #30363d;
            --border-strong: #6e7681;
            --card-bg: #161b22;
            --code-inline-bg: #21262d;
            --code-inline-text: #e6edf3;
            --code-inline-border: #30363d;
            --code-block-bg: #161b22;
            --code-block-text: #e6edf3;
            --table-th-bg: #161b22;
            --table-alt-bg: #0d1117;
            --frontmatter-bg: #161b22;
            --highlight-bg: #5a3e00;
            --highlight-text: #ffdf5d;

            --syn-keyword: #ff7b72;
            --syn-string: #a5d6ff;
            --syn-number: #79c0ff;
            --syn-comment: #8b949e;
            --syn-type: #ffa657;
            --syn-func: #d2a8ff;
            --syn-operator: #c9d1d9;
            --syn-property: #79c0ff;
        }
    }

    \(baseResetAndTypography)
    """

    static let minimalCSS = """
    :root {
        --bg-color: #fafaf9;
        --text-color: #27272a;
        --text-secondary: #52525b;
        --text-muted: #a1a1aa;
        --heading-color: #18181b;
        --accent-color: #18181b;
        --border-subtle: #e4e4e7;
        --border-strong: #71717a;
        --card-bg: #f4f4f5;
        --code-inline-bg: #f4f4f5;
        --code-inline-text: #18181b;
        --code-inline-border: transparent;
        --code-block-bg: #f4f4f5;
        --code-block-text: #18181b;
        --table-th-bg: #e4e4e7;
        --table-alt-bg: transparent;
        --frontmatter-bg: #f4f4f5;
        --highlight-bg: #e4e4e7;
        --highlight-text: #18181b;

        --syn-keyword: #71717a;
        --syn-string: #52525b;
        --syn-number: #3f3f46;
        --syn-comment: #a1a1aa;
        --syn-type: #27272a;
        --syn-func: #18181b;
        --syn-operator: #71717a;
        --syn-property: #3f3f46;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --bg-color: #121214;
            --text-color: #e4e4e7;
            --text-secondary: #a1a1aa;
            --text-muted: #71717a;
            --heading-color: #f4f4f5;
            --accent-color: #fafafa;
            --border-subtle: #27272a;
            --border-strong: #52525b;
            --card-bg: #18181b;
            --code-inline-bg: #18181b;
            --code-inline-text: #f4f4f5;
            --code-inline-border: transparent;
            --code-block-bg: #18181b;
            --code-block-text: #f4f4f5;
            --table-th-bg: #27272a;
            --table-alt-bg: transparent;
            --frontmatter-bg: #18181b;
            --highlight-bg: #3f3f46;
            --highlight-text: #f4f4f5;

            --syn-keyword: #a1a1aa;
            --syn-string: #d4d4d8;
            --syn-number: #e4e4e7;
            --syn-comment: #71717a;
            --syn-type: #f4f4f5;
            --syn-func: #fafafa;
            --syn-operator: #a1a1aa;
            --syn-property: #d4d4d8;
        }
    }

    \(baseResetAndTypography)
    """

    static let academicCSS = """
    :root {
        --bg-color: #fefefe;
        --text-color: #2b2b2b;
        --text-secondary: #4a4a4a;
        --text-muted: #767676;
        --heading-color: #111111;
        --accent-color: #8b0000;
        --border-subtle: #e0e0e0;
        --border-strong: #999999;
        --card-bg: #f7f7f7;
        --code-inline-bg: #f0f0f0;
        --code-inline-text: #8b0000;
        --code-inline-border: #e0e0e0;
        --code-block-bg: #f9f9f9;
        --code-block-text: #222222;
        --table-th-bg: #f0f0f0;
        --table-alt-bg: #fafafa;
        --frontmatter-bg: #f7f7f7;
        --highlight-bg: #fff0b3;
        --highlight-text: #2b2b2b;

        --syn-keyword: #8b0000;
        --syn-string: #006400;
        --syn-number: #00008b;
        --syn-comment: #808080;
        --syn-type: #4b0082;
        --syn-func: #2f4f4f;
        --syn-operator: #333333;
        --syn-property: #4b0082;
    }

    @media (prefers-color-scheme: dark) {
        :root {
            --bg-color: #1c1c1c;
            --text-color: #e0e0e0;
            --text-secondary: #aaaaaa;
            --text-muted: #777777;
            --heading-color: #ffffff;
            --accent-color: #ff6b6b;
            --border-subtle: #333333;
            --border-strong: #666666;
            --card-bg: #242424;
            --code-inline-bg: #292929;
            --code-inline-text: #ff8787;
            --code-inline-border: #383838;
            --code-block-bg: #222222;
            --code-block-text: #e0e0e0;
            --table-th-bg: #2b2b2b;
            --table-alt-bg: #1f1f1f;
            --frontmatter-bg: #242424;
            --highlight-bg: #4a3800;
            --highlight-text: #fff0b3;

            --syn-keyword: #ff8787;
            --syn-string: #8ce99a;
            --syn-number: #74c0fc;
            --syn-comment: #868e96;
            --syn-type: #d0bfff;
            --syn-func: #a5d8ff;
            --syn-operator: #ced4da;
            --syn-property: #d0bfff;
        }
    }

    \(baseResetAndTypography)

    body {
        font-family: "Charter", "Georgia", "Cambria", "Times New Roman", serif;
        font-size: 16px;
        line-height: 1.75;
    }
    """
}
