import SwiftUI
import AppKit
import MarkdownRenderer

public enum EditorViewMode: String, CaseIterable, Identifiable {
    case edit = "Edit"
    case split = "Split"
    case preview = "Preview"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .edit: return "square.and.pencil"
        case .split: return "rectangle.split.2x1"
        case .preview: return "eye"
        }
    }
}

public struct MarkdownEditorView: View {
    @Binding public var document: MarkdownDocument
    public var fileURL: URL?

    @StateObject private var appState = AppState.shared
    @StateObject private var editorHelper = SourceEditorHelper()

    @State private var viewMode: EditorViewMode = .preview
    @State private var selectedTheme: Theme = .system
    @State private var fontSize: CGFloat = 14
    @State private var showCopiedBanner: Bool = false
    @State private var copiedBannerText: String = ""
    @State private var isShowingSettingsSheet: Bool = false

    @Environment(\.openWindow) private var openWindow

    public init(document: Binding<MarkdownDocument>, fileURL: URL? = nil) {
        self._document = document
        self.fileURL = fileURL
        let initialTheme = Theme(rawValue: SharedPreferences.shared.selectedTheme) ?? .system
        self._selectedTheme = State(initialValue: initialTheme)
    }

    private var filename: String {
        fileURL?.lastPathComponent ?? "Untitled.md"
    }

    private var wordCount: Int {
        let words = document.text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    private var lineCount: Int {
        document.text.components(separatedBy: "\n").count
    }

    private var characterCount: Int {
        document.text.count
    }

    private var readingTimeMinutes: Int {
        max(1, Int(ceil(Double(wordCount) / 200.0)))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Editor / Preview Body Area
            ZStack(alignment: .top) {
                mainContentView

                // Toast Banner for Copy actions
                if showCopiedBanner {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(copiedBannerText)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Status Bar at Bottom
            statusBarView
        }
        .frame(minWidth: 700, minHeight: 480)
        .toolbar {
            toolbarItems
        }
        .sheet(isPresented: $isShowingSettingsSheet) {
            SettingsSheetView(isPresented: $isShowingSettingsSheet)
        }
        .background(
            Group {
                Button("") { viewMode = .edit }.keyboardShortcut("e", modifiers: .command).hidden()
                Button("") { viewMode = .split }.keyboardShortcut("d", modifiers: .command).hidden()
                Button("") { viewMode = .preview }.keyboardShortcut("r", modifiers: .command).hidden()
            }
        )
        .onAppear {
            if let savedTheme = Theme(rawValue: SharedPreferences.shared.selectedTheme) {
                selectedTheme = savedTheme
            }
        }
    }

    // MARK: - Main Content View
    @ViewBuilder
    private var mainContentView: some View {
        switch viewMode {
        case .edit:
            // Source Text Editor
            VStack(spacing: 0) {
                formattingToolbar
                Divider()
                SourceTextEditor(
                    text: $document.text,
                    font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                    isEditable: true,
                    editorHelper: editorHelper
                )
                .background(Color(NSColor.textBackgroundColor))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

        case .split:
            // Side-by-Side Split View
            HSplitView {
                VStack(spacing: 0) {
                    formattingToolbar
                    Divider()
                    SourceTextEditor(
                        text: $document.text,
                        font: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular),
                        isEditable: true,
                        editorHelper: editorHelper
                    )
                    .background(Color(NSColor.textBackgroundColor))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(minWidth: 320)

                MarkdownWebView(
                    markdown: document.text,
                    baseURL: fileURL?.deletingLastPathComponent(),
                    theme: selectedTheme,
                    options: RenderOptions(
                        enableSyntaxHighlighting: appState.enableSyntaxHighlighting,
                        enableMath: appState.enableMathRendering,
                        enableCallouts: true,
                        enableFrontmatter: true,
                        enableWikilinks: true
                    )
                )
                .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
            }

        case .preview:
            // Full Rendered HTML Preview
            MarkdownWebView(
                markdown: document.text,
                baseURL: fileURL?.deletingLastPathComponent(),
                theme: selectedTheme,
                options: RenderOptions(
                    enableSyntaxHighlighting: appState.enableSyntaxHighlighting,
                    enableMath: appState.enableMathRendering,
                    enableCallouts: true,
                    enableFrontmatter: true,
                    enableWikilinks: true
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Formatting Toolbar for Editing
    @ViewBuilder
    private var formattingToolbar: some View {
        HStack(spacing: 4) {
            // Heading Menu
            Menu {
                Button("Heading 1 (#)") { editorHelper.insertHeading(level: 1) }
                Button("Heading 2 (##)") { editorHelper.insertHeading(level: 2) }
                Button("Heading 3 (###)") { editorHelper.insertHeading(level: 3) }
                Button("Heading 4 (####)") { editorHelper.insertHeading(level: 4) }
            } label: {
                Image(systemName: "number")
                    .font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
            .help("Heading")

            Divider().frame(height: 16)

            // Bold
            Button(action: { editorHelper.insertWrap(prefix: "**", suffix: "**", placeholder: "bold text") }) {
                Image(systemName: "bold")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Bold (**text**)")

            // Italic
            Button(action: { editorHelper.insertWrap(prefix: "*", suffix: "*", placeholder: "italic text") }) {
                Image(systemName: "italic")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Italic (*text*)")

            // Strikethrough
            Button(action: { editorHelper.insertWrap(prefix: "~~", suffix: "~~", placeholder: "text") }) {
                Image(systemName: "strikethrough")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Strikethrough (~~text~~)")

            Divider().frame(height: 16)

            // Inline Code
            Button(action: { editorHelper.insertWrap(prefix: "`", suffix: "`", placeholder: "code") }) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Inline Code (`code`)")

            // Code Block
            Button(action: { editorHelper.insertWrap(prefix: "```\n", suffix: "\n```", placeholder: "// Code block") }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Code Block (```)")

            // Link
            Button(action: { editorHelper.insertWrap(prefix: "[", suffix: "](https://)", placeholder: "link text") }) {
                Image(systemName: "link")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Hyperlink [text](url)")

            Divider().frame(height: 16)

            // Bullet List
            Button(action: { editorHelper.insertWrap(prefix: "- ", suffix: "", placeholder: "List item") }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Bullet List (- )")

            // Task List Checklist
            Button(action: { editorHelper.insertWrap(prefix: "- [ ] ", suffix: "", placeholder: "Todo item") }) {
                Image(systemName: "checklist")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Task List (- [ ] )")

            // Table
            Button(action: { editorHelper.insertTable() }) {
                Image(systemName: "tablecells")
                    .font(.system(size: 12))
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 24)
            .help("Insert Table")

            // Obsidian Callout
            Menu {
                Button("Note") { editorHelper.insertCallout(type: "NOTE") }
                Button("Tip") { editorHelper.insertCallout(type: "TIP") }
                Button("Important") { editorHelper.insertCallout(type: "IMPORTANT") }
                Button("Warning") { editorHelper.insertCallout(type: "WARNING") }
                Button("Caution") { editorHelper.insertCallout(type: "CAUTION") }
            } label: {
                Image(systemName: "bubble.left.and.exclamationmark.bubble.right")
                    .font(.system(size: 12))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)
            .help("Obsidian / GitHub Callout Box")

            Spacer()

            // Font Size adjustment
            HStack(spacing: 2) {
                Button(action: { if fontSize > 10 { fontSize -= 1 } }) {
                    Image(systemName: "textformat.size.smaller")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 20)

                Text("\(Int(fontSize))pt")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 32)

                Button(action: { if fontSize < 28 { fontSize += 1 } }) {
                    Image(systemName: "textformat.size.larger")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .frame(width: 22, height: 20)
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Toolbar Items
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItemGroup(placement: .principal) {
            // View Mode Switcher: Edit / Split / Preview
            Picker("View Mode", selection: $viewMode) {
                ForEach(EditorViewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.systemIcon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 230)
            .help("Switch between Normal Editor, Split View, and Rendered Preview (Cmd+E / Cmd+D / Cmd+R)")
        }

        ToolbarItemGroup(placement: .primaryAction) {
            // Theme Switcher
            Menu {
                ForEach(Theme.allCases, id: \.self) { t in
                    Button(action: {
                        selectedTheme = t
                        SharedPreferences.shared.selectedTheme = t.rawValue
                    }) {
                        HStack {
                            Text(t.rawValue)
                            if selectedTheme == t {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label(selectedTheme.rawValue, systemImage: "paintbrush")
            }
            .help("Change Markdown Theme")

            // Copy Menu
            Menu {
                Button("Copy Rendered HTML") {
                    let html = MarkdownRenderer.renderHTMLFragment(markdown: document.text)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(html, forType: .string)
                    showBanner("Rendered HTML copied to clipboard")
                }
                Button("Copy Markdown Source") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(document.text, forType: .string)
                    showBanner("Markdown source copied to clipboard")
                }
            } label: {
                Image(systemName: "doc.on.doc")
            }
            .help("Copy HTML or Source")

            // Reveal in Finder
            if let url = fileURL {
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }) {
                    Image(systemName: "arrow.up.forward.square")
                }
                .help("Reveal in Finder")
            }

            // Settings & Extension Manager Button
            Button(action: {
                isShowingSettingsSheet = true
            }) {
                Image(systemName: "gearshape")
            }
            .help("Markdown Finder Settings & Monitored Folders")
        }
    }

    // MARK: - Status Bar View
    private var statusBarView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text(filename)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 12) {
                Text("\(wordCount) words")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary.opacity(0.5))

                Text("\(lineCount) lines")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary.opacity(0.5))

                Text("\(characterCount) chars")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary.opacity(0.5))

                Text("~\(readingTimeMinutes) min read")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                Text("•")
                    .foregroundColor(.secondary.opacity(0.5))

                Text("UTF-8")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func showBanner(_ message: String) {
        copiedBannerText = message
        withAnimation(.easeInOut(duration: 0.2)) {
            showCopiedBanner = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.2)) {
                showCopiedBanner = false
            }
        }
    }
}

// MARK: - Settings Sheet View
struct SettingsSheetView: View {
    @Binding var isPresented: Bool
    @ObservedObject var state = AppState.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Markdown Finder Settings")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            ContentView()
        }
        .frame(minWidth: 780, minHeight: 520)
    }
}
