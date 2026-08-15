import SwiftUI
import AppKit

// MARK: - Custom Flipped ClipView
public final class FlippedClipView: NSClipView {
    public override var isFlipped: Bool { true }
}

// MARK: - Editor Container View (Gutter + ScrollView + TextView)
public final class EditorContainerView: NSView {
    public let gutterView: LineNumberGutterView
    public let scrollView: NSScrollView
    public let textView: CustomTextView

    public init(font: NSFont, isEditable: Bool) {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: 500, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        self.textView = CustomTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 400), textContainer: textContainer)
        self.textView.minSize = NSSize(width: 0, height: 0)
        self.textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        self.textView.isVerticallyResizable = true
        self.textView.isHorizontallyResizable = false
        self.textView.autoresizingMask = [.width]
        self.textView.isRichText = false
        self.textView.importsGraphics = false
        self.textView.allowsUndo = true
        self.textView.isEditable = isEditable
        self.textView.isSelectable = true
        self.textView.font = font
        self.textView.textColor = NSColor.textColor
        self.textView.backgroundColor = .clear
        self.textView.drawsBackground = false
        self.textView.textContainerInset = NSSize(width: 14, height: 14)

        // Turn off smart substitution that can interfere with markdown syntax
        self.textView.isAutomaticQuoteSubstitutionEnabled = false
        self.textView.isAutomaticDashSubstitutionEnabled = false
        self.textView.isAutomaticTextReplacementEnabled = false
        self.textView.isAutomaticSpellingCorrectionEnabled = false

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        self.textView.defaultParagraphStyle = paragraphStyle
        self.textView.typingAttributes = [
            .font: font,
            .foregroundColor: NSColor.textColor,
            .paragraphStyle: paragraphStyle
        ]

        self.scrollView = NSScrollView(frame: .zero)
        let clipView = FlippedClipView()
        clipView.drawsBackground = false
        self.scrollView.contentView = clipView
        self.scrollView.drawsBackground = false
        self.scrollView.borderType = .noBorder
        self.scrollView.hasVerticalScroller = true
        self.scrollView.hasHorizontalScroller = false
        self.scrollView.autohidesScrollers = true
        self.scrollView.documentView = self.textView

        self.gutterView = LineNumberGutterView(textView: self.textView, scrollView: self.scrollView)

        super.init(frame: NSRect(x: 0, y: 0, width: 600, height: 400))

        self.addSubview(self.gutterView)
        self.addSubview(self.scrollView)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var isFlipped: Bool { true }

    public override func resizeSubviews(withOldSize oldSize: NSSize) {
        super.resizeSubviews(withOldSize: oldSize)
        layoutSubviews()
    }

    public override func layout() {
        super.layout()
        layoutSubviews()
    }

    private func layoutSubviews() {
        let gutterWidth: CGFloat = 46
        gutterView.frame = NSRect(x: 0, y: 0, width: gutterWidth, height: bounds.height)
        scrollView.frame = NSRect(x: gutterWidth, y: 0, width: max(0, bounds.width - gutterWidth), height: bounds.height)
    }
}

// MARK: - SwiftUI NSViewRepresentable Wrapper
public struct SourceTextEditor: NSViewRepresentable {
    @Binding public var text: String
    public var font: NSFont
    public var isEditable: Bool
    public var onTextChange: ((String) -> Void)?
    public var editorHelper: SourceEditorHelper?

    public init(
        text: Binding<String>,
        font: NSFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
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

    public func makeNSView(context: Context) -> EditorContainerView {
        let container = EditorContainerView(font: font, isEditable: isEditable)
        container.textView.delegate = context.coordinator
        container.textView.string = text

        context.coordinator.containerView = container
        context.coordinator.textView = container.textView
        editorHelper?.textView = container.textView

        return container
    }

    public func updateNSView(_ nsView: EditorContainerView, context: Context) {
        context.coordinator.parent = self
        let textView = nsView.textView

        if textView.font != font {
            textView.font = font
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = 4
            textView.defaultParagraphStyle = paragraphStyle
            textView.typingAttributes = [
                .font: font,
                .foregroundColor: NSColor.textColor,
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
            nsView.gutterView.needsDisplay = true
        }

        editorHelper?.textView = textView
    }

    public class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SourceTextEditor
        weak var containerView: EditorContainerView?
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

            containerView?.gutterView.needsDisplay = true
        }
    }
}

// MARK: - Custom TextView with Markdown Shortcuts & Smart Indentation
public final class CustomTextView: NSTextView {
    public override func insertNewline(_ sender: Any?) {
        let text = self.string as NSString
        let selectedRange = self.selectedRange()
        let lineRange = text.lineRange(for: NSRange(location: selectedRange.location, length: 0))
        let currentLine = text.substring(with: lineRange)

        // Check for Markdown list prefixes
        let trimmed = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed == "-" || trimmed == "*" || trimmed == "+" || trimmed == "- [ ]" || trimmed == "- [x]" {
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
        self.insertText("  ", replacementRange: self.selectedRange())
    }
}

// MARK: - Line Number Gutter View
public final class LineNumberGutterView: NSView {
    private weak var textView: NSTextView?
    private weak var scrollView: NSScrollView?

    public init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        self.scrollView = scrollView
        super.init(frame: .zero)
        self.postsFrameChangedNotifications = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(viewDidScroll(_:)),
            name: NSView.boundsDidChangeNotification,
            object: scrollView.contentView
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange(_:)),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func viewDidScroll(_ notification: Notification) {
        self.needsDisplay = true
    }

    @objc private func textDidChange(_ notification: Notification) {
        self.needsDisplay = true
    }

    public override var isFlipped: Bool { true }

    public override func draw(_ dirtyRect: NSRect) {
        let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let bgColor = isDark ? NSColor(white: 0.12, alpha: 1.0) : NSColor(white: 0.96, alpha: 1.0)
        let textColor = isDark ? NSColor(white: 0.45, alpha: 1.0) : NSColor(white: 0.55, alpha: 1.0)
        let dividerColor = isDark ? NSColor(white: 0.22, alpha: 1.0) : NSColor(white: 0.88, alpha: 1.0)

        bgColor.setFill()
        dirtyRect.fill()

        let sepRect = NSRect(x: bounds.width - 0.5, y: dirtyRect.origin.y, width: 0.5, height: dirtyRect.height)
        dividerColor.setFill()
        sepRect.fill()

        guard let tv = textView,
              let lm = tv.layoutManager,
              let tc = tv.textContainer,
              let sv = scrollView else { return }

        let visibleRect = sv.contentView.bounds
        let glyphRange = lm.glyphRange(forBoundingRect: visibleRect, in: tc)
        let str = tv.string as NSString

        let font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        if str.length == 0 {
            let lineStr = "1" as NSString
            let size = lineStr.size(withAttributes: attributes)
            let yPos = tv.textContainerInset.height - visibleRect.origin.y
            lineStr.draw(at: NSPoint(x: bounds.width - size.width - 10, y: yPos), withAttributes: attributes)
            return
        }

        var lineNumber = 1
        var idx = 0

        while idx < glyphRange.location && idx < str.length {
            let lineRange = str.lineRange(for: NSRange(location: idx, length: 0))
            lineNumber += 1
            idx = NSMaxRange(lineRange)
        }

        idx = glyphRange.location
        while idx < NSMaxRange(glyphRange) && idx < str.length {
            let charIdx = lm.characterIndexForGlyph(at: idx)
            let lineRange = str.lineRange(for: NSRange(location: charIdx, length: 0))
            let lineGlyphRange = lm.glyphRange(forCharacterRange: lineRange, actualCharacterRange: nil)

            var lineRect = lm.lineFragmentRect(forGlyphAt: lineGlyphRange.location, effectiveRange: nil)
            lineRect.origin.y += tv.textContainerInset.height

            let yPos = lineRect.origin.y - visibleRect.origin.y
            let lineStr = "\(lineNumber)" as NSString
            let size = lineStr.size(withAttributes: attributes)
            let drawPoint = NSPoint(x: bounds.width - size.width - 10, y: yPos + (lineRect.height - size.height) / 2)

            if drawPoint.y >= -20 && drawPoint.y <= bounds.height + 20 {
                lineStr.draw(at: drawPoint, withAttributes: attributes)
            }

            lineNumber += 1
            let nextIdx = NSMaxRange(lineGlyphRange)
            if nextIdx <= idx { break }
            idx = nextIdx
        }
    }
}

// MARK: - Editor Helper for Toolbar Actions
public final class SourceEditorHelper: ObservableObject {
    public weak var textView: NSTextView?

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
