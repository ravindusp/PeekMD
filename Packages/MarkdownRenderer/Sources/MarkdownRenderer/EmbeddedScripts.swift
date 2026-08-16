import Foundation

public enum EmbeddedScripts {
    public static let katexCSS = """
    .katex, .math-inline, .math-block {
        font-family: "KaTeX_Main", "Cambria Math", "Latin Modern Math", "STIX Two Math", serif;
        line-height: 1.2;
        text-indent: 0;
        text-rendering: auto;
    }
    .math-inline {
        display: inline-block;
        padding: 0 0.15em;
    }
    .math-block {
        display: flex;
        justify-content: center;
        margin: 1.2em 0;
        padding: 0.8em 1em;
        overflow-x: auto;
        border-radius: 8px;
        background-color: var(--card-bg);
    }
    .katex-display {
        display: block;
        margin: 1em 0;
        text-align: center;
    }
    """

    public static let katexScript = """
    <script>
    function renderAllMath() {
        if (typeof renderMathInElement === "function") {
            renderMathInElement(document.body, {
                delimiters: [
                    {left: "$$", right: "$$", display: true},
                    {left: "\\\\[", right: "\\\\]", display: true},
                    {left: "$", right: "$", display: false},
                    {left: "\\\\(", right: "\\\\)", display: false}
                ],
                throwOnError: false
            });
        }
    }
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", renderAllMath);
    } else {
        renderAllMath();
    }
    </script>
    """
}
