import SwiftUI
import AppKit
import MarkdownRenderer

public struct DocumentViewerView: View {
    @ObservedObject var state = AppState.shared
    @State private var showCopiedAlert = false

    private var wordCount: Int {
        let words = state.currentDocumentContent.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        return words.count
    }

    private var lineCount: Int {
        return state.currentDocumentContent.components(separatedBy: "\n").count
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.currentDocumentURL?.lastPathComponent ?? "Preview Document")
                        .font(.headline)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(lineCount) lines")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Action: Open File
                Button(action: {
                    openFilePicker()
                }) {
                    Label("Open...", systemImage: "folder")
                }
                .buttonStyle(.bordered)

                // Action: Reveal in Finder
                if let url = state.currentDocumentURL {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }) {
                        Label("Reveal", systemImage: "arrow.up.forward.square")
                    }
                    .buttonStyle(.bordered)

                    // Action: Open in External Editor
                    Button(action: {
                        NSWorkspace.shared.open(url)
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                }

                // Action: Copy HTML
                Button(action: {
                    let html = MarkdownRenderer.renderHTMLFragment(markdown: state.currentDocumentContent)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(html, forType: .string)
                    showCopiedAlert = true
                }) {
                    Label("Copy HTML", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)

                // Theme Switcher
                Menu {
                    ForEach(Theme.allCases, id: \.self) { t in
                        Button(action: {
                            state.viewerTheme = t
                        }) {
                            HStack {
                                Text(t.rawValue)
                                if state.viewerTheme == t {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(state.viewerTheme.rawValue, systemImage: "paintbrush")
                }
                .menuStyle(.borderlessButton)
                .frame(width: 100)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Webview Render Area
            MarkdownWebView(
                markdown: state.currentDocumentContent,
                baseURL: state.currentDocumentURL?.deletingLastPathComponent(),
                theme: state.viewerTheme,
                options: RenderOptions(
                    enableSyntaxHighlighting: state.enableSyntaxHighlighting,
                    enableMath: state.enableMathRendering,
                    enableCallouts: true,
                    enableFrontmatter: true,
                    enableWikilinks: true
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .alert("HTML Copied to Clipboard", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!, .plainText]

        if panel.runModal() == .OK, let url = panel.url {
            state.openDocument(from: url)
        }
    }
}
