import SwiftUI
import AppKit

public struct SourceTextEditor: NSViewRepresentable {
    @Binding public var text: String
    public var font: NSFont
    public var isEditable: Bool
    public var onTextChange: ((String) -> Void)?
    public var editorHelper: SourceEditorHelper?

    public init(
        text: Binding<String>,
        font: NSFont = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular),
        isEditable: Bool = true,
        onTextChange: ((String) -> Void)? = nil,
        editorHelper: SourceEditorHelper? = nil
    ) {
        self._text = text
        self.font = font
        self.isEditable = isEditable
        self.onTextChange = onTextChange
        self.editorHelper = editorHelper
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let contentSize = scrollView.contentSize
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: contentSize.width, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        layoutManager.addTextContainer(textContainer)

        let textView = CustomTextView(frame: NSRect(origin: .zero, size: contentSize), textContainer: textContainer)
        textView.minSize = NSSize(width: 0, height: contentSize.height)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.font = font
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.delegate = context.coordinator

        // Line spacing and typography
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        textView.defaultParagraphStyle = paragraphStyle
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraphStyle
        ]

        textView.string = text
        scrollView.documentView = textView

        // Setup ruler view for line numbers
        let rulerView = LineNumberRulerView(textView: textView)
        scrollView.verticalRulerView = rulerView
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        context.coordinator.textView = textView
        editorHelper?.textView = textView

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? CustomTextView else { return }

        if textView.font != font {
            textView.font = font
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            textView.defaultParagraphStyle = paragraphStyle
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: NSColor.labelColor,
                .paragraphStyle: paragraphStyle
            ]
        }

        if textView.isEditable != isEditable {
            textView.isEditable = isEditable
        }

        if textView.string != text && !context.coordinator.isUpdatingFromTextView {
            let selectedRange = textView.selectedRange()
            textView.string = text
            if selectedRange.location + selectedRange.length <= text.count {
                textView.setSelectedRange(selectedRange)
            }
            nsView.verticalRulerView?.needsDisplay = true
        }

        editorHelper?.textView = textView
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceTextEditor
        weak var textView: CustomTextView?
        var isUpdatingFromTextView = false

        init(_ parent: SourceTextEditor) {
            self.parent = parent
        }

        public func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            isUpdatingFromTextView = true
            let newText = tv.string
            parent.text = newText
            parent.onTextChange?(newText)
            isUpdatingFromTextView = false

            if let scrollView = tv.enclosingScrollView, let ruler = scrollView.verticalRulerView {
                ruler.needsDisplay = true
            }
        }
    }
}

public final class CustomTextView: NSTextView {
    public override func insertNewline(_ sender: Any?) {
        // Smart list continuation
        let text = self.string as NSString
        let selectedRange = self.selectedRange()
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = text.substring(with: lineRange)

        // Check for Markdown list prefixes
        let trimmed = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "-" || trimmed == "*" || trimmed == "+" || trimmed == "- [ ]" || trimmed == "- [x]" {
            // If empty list item, hitting return clears the bullet
            let replaceRange = NSRange(location: lineRange.location, length: lineRange.length)
            if shouldChangeText(in: replaceRange, replacementString: "\n") {
                replaceCharacters(in: replaceRange, with: "\n")
                didChangeText()
            }
            return
        }

        if let match = currentLine.range(of: #"^(\s*[-*+]\s+(\[[ x]\]\s+)?)"#, options: .regularExpression) {
            let prefix = String(currentLine[match])
            let cleanPrefix = prefix.replacingOccurrences(of: "[x]", with: "[ ]")
            super.insertNewline(sender)
            self.insertText(cleanPrefix, replacementRange: self.selectedRange())
            return
        }

        if let match = currentLine.range(of: #"^(\s*(\d+)\.\s+)"#, options: .regularExpression) {
            let prefix = String(currentLine[match])
            let numStr = prefix.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ".", with: "")
            if let num = Int(numStr) {
                let leadingSpaces = prefix.prefix(while: { $0 == " " || $0 == "\t" })
                let nextPrefix = "\(leadingSpaces)\(num + 1). "
                super.insertNewline(sender)
                self.insertText(nextPrefix, replacementRange: self.selectedRange())
                return
            }
        }

        super.insertNewline(sender)
    }

    public override func insertTab(_ sender: Any?) {
        // Insert 2 spaces instead of hard tab
        self.insertText("  ", replacementRange: self.selectedRange())
    }
}

// MARK: - Editor Helper for Toolbar Actions
public final class SourceEditorHelper: ObservableObject {
    public weak var textView: CustomTextView?

    public init() {}

    public func insertWrap(prefix: String, suffix: String, placeholder: String = "") {
        guard let tv = textView else { return }
        let selectedRange = tv.selectedRange()
        let text = tv.string as NSString

        if selectedRange.length > 0 {
            let selectedText = text.substring(with: selectedRange)
            let replacement = "\(prefix)\(selectedText)\(suffix)"
            if tv.shouldChangeText(in: selectedRange, replacementString: replacement) {
                tv.replaceCharacters(in: selectedRange, with: replacement)
                tv.didChangeText()
                tv.setSelectedRange(NSRange(location: selectedRange.location + prefix.count, length: selectedText.count))
            }
        } else {
            let replacement = "\(prefix)\(placeholder)\(suffix)"
            if tv.shouldChangeText(in: selectedRange, replacementString: replacement) {
                tv.replaceCharacters(in: selectedRange, with: replacement)
                tv.didChangeText()
                if placeholder.isEmpty {
                    tv.setSelectedRange(NSRange(location: selectedRange.location + prefix.count, length: 0))
                } else {
                    tv.setSelectedRange(NSRange(location: selectedRange.location + prefix.count, length: placeholder.count))
                }
            }
        }
    }

    public func insertHeading(level: Int) {
        guard let tv = textView else { return }
        let text = tv.string as NSString
        let selectedRange = tv.selectedRange()
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = text.substring(with: lineRange)

        let hashes = String(repeating: "#", count: level) + " "
        let cleanedLine = currentLine.replacingOccurrences(of: #"^#{1,6}\s*"#, with: "", options: .regularExpression)
        let newLine = "\(hashes)\(cleanedLine)"

        if tv.shouldChangeText(in: lineRange, replacementString: newLine) {
            tv.replaceCharacters(in: lineRange, with: newLine)
            tv.didChangeText()
        }
    }

    public func insertBlock(blockContent: String) {
        guard let tv = textView else { return }
        let selectedRange = tv.selectedRange()
        if tv.shouldChangeText(in: selectedRange, replacementString: blockContent) {
            tv.replaceCharacters(in: selectedRange, with: blockContent)
            tv.didChangeText()
        }
    }

    public func insertTable() {
        let sampleTable = """

| Column 1 | Column 2 | Column 3 |
| :--- | :---: | ---: |
| Item 1 | Details | $10.00 |
| Item 2 | Details | $20.00 |

"""
        insertBlock(blockContent: sampleTable)
    }

    public func insertCallout(type: String = "NOTE") {
        let callout = """

> [!\(type)] Important Title
> Add description or details here.

"""
        insertBlock(blockContent: callout)
    }
}

// MARK: - Line Number Ruler View
public final class LineNumberRulerView: NSRulerView {
    private weak var customTextView: CustomTextView?

    public init(textView: CustomTextView) {
        self.customTextView = textView
        super.init(scrollView: textView.enclosingScrollView, orientation: .verticalRuler)
        self.clientView = textView
        self.ruleThickness = 36
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func drawHashMarksAndLabels(in rect: NSRect) {
        guard let textView = customTextView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else {
            return
        }

        // Draw ruler background
        let isDark = textView.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark ? NSColor(white: 0.12, alpha: 1.0) : NSColor(white: 0.96, alpha: 1.0)
        let textColor = isDark ? NSColor(white: 0.45, alpha: 1.0) : NSColor(white: 0.60, alpha: 1.0)
        let dividerColor = isDark ? NSColor(white: 0.2, alpha: 1.0) : NSColor(white: 0.88, alpha: 1.0)

        bgColor.setFill()
        rect.fill()

        // Draw separator border line
        let separatorRect = NSRect(x: bounds.width - 0.5, y: rect.origin.y, width: 0.5, height: rect.height)
        dividerColor.setFill()
        separatorRect.fill()

        let visibleRect = scrollView?.contentView.bounds ?? textView.visibleRect
        let visibleGlyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let text = textView.string as NSString

        let font = NSFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        var lineNumber = 1
        var index = 0

        // Calculate starting line number
        while index < visibleGlyphRange.location && index < text.length {
            let lineRange = text.lineRange(for: NSRange(location: index, length: 0))
            lineNumber += 1
            index = NSMaxRange(lineRange)
        }

        index = visibleGlyphRange.location
        while index <= NSMaxRange(visibleGlyphRange) && index <= text.length {
            let charIndex = layoutManager.characterIndexForGlyph(at: min(index, layoutManager.numberOfGlyphs > 0 ? layoutManager.numberOfGlyphs - 1 : 0))
            let lineRange = text.lineRange(for: NSRange(location: charIndex, length: 0))
            let glyphRange = layoutManager.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            var lineRect = layoutManager.lineFragmentRect(forGlyphAt: glyphRange.location, effectiveRange: nil)
            lineRect.origin.y += textView.textContainerInset.height

            let yPos = lineRect.origin.y - visibleRect.origin.y
            let lineStr = "\(lineNumber)" as NSString
            let stringSize = lineStr.size(withAttributes: attributes)
            let drawPoint = NSPoint(x: bounds.width - stringSize.width - 6, y: yPos + (lineRect.height - stringSize.height) / 2)

            lineStr.draw(at: drawPoint, withAttributes: attributes)

            lineNumber += 1
            let nextIndex = NSMaxRange(glyphRange)
            if nextIndex <= index { break }
            index = nextIndex
        }
    }
}
