import SwiftUI
import AppKit
import Combine
import MarkdownRenderer

public enum SidebarTab: String, CaseIterable, Identifiable {
    case settings = "Settings"
    case locations = "Monitored Folders"
    case onboarding = "Quick Setup"
    case viewer = "Markdown Viewer"

    public var id: String { rawValue }

    public var systemIcon: String {
        switch self {
        case .settings: return "gearshape.2"
        case .locations: return "folder.badge.gearshape"
        case .onboarding: return "sparkles"
        case .viewer: return "doc.text.magnifyingglass"
        }
    }
}

@MainActor
public final class AppState: ObservableObject {
    public static let shared = AppState()

    @Published public var selectedTab: SidebarTab = .settings
    @Published public var isFinderExtensionEnabled: Bool = true
    @Published public var isQuickLookExtensionEnabled: Bool = true

    // Document Viewer state
    @Published public var currentDocumentURL: URL?
    @Published public var currentDocumentContent: String = ""
    @Published public var viewerTheme: Theme = .system

    // Settings proxies
    @Published public var defaultFilename: String {
        didSet { SharedPreferences.shared.defaultFilename = defaultFilename }
    }
    @Published public var defaultExtension: String {
        didSet { SharedPreferences.shared.defaultExtension = defaultExtension }
    }
    @Published public var selectAfterCreation: Bool {
        didSet { SharedPreferences.shared.selectAfterCreation = selectAfterCreation }
    }
    @Published public var openAfterCreation: Bool {
        didSet { SharedPreferences.shared.openAfterCreation = openAfterCreation }
    }
    @Published public var monitorHomeDirectory: Bool {
        didSet { SharedPreferences.shared.monitorHomeDirectory = monitorHomeDirectory }
    }
    @Published public var monitorExternalVolumes: Bool {
        didSet { SharedPreferences.shared.monitorExternalVolumes = monitorExternalVolumes }
    }
    @Published public var enableSyntaxHighlighting: Bool {
        didSet { SharedPreferences.shared.enableSyntaxHighlighting = enableSyntaxHighlighting }
    }
    @Published public var enableMathRendering: Bool {
        didSet { SharedPreferences.shared.enableMathRendering = enableMathRendering }
    }
    @Published public var customTemplate: String {
        didSet { SharedPreferences.shared.customTemplateContent = customTemplate }
    }

    public init() {
        let prefs = SharedPreferences.shared
        self.defaultFilename = prefs.defaultFilename
        self.defaultExtension = prefs.defaultExtension
        self.selectAfterCreation = prefs.selectAfterCreation
        self.openAfterCreation = prefs.openAfterCreation
        self.monitorHomeDirectory = prefs.monitorHomeDirectory
        self.monitorExternalVolumes = prefs.monitorExternalVolumes
        self.enableSyntaxHighlighting = prefs.enableSyntaxHighlighting
        self.enableMathRendering = prefs.enableMathRendering
        self.customTemplate = prefs.customTemplateContent
        self.viewerTheme = Theme(rawValue: prefs.selectedTheme) ?? .system

        // Load sample content if no file is open
        loadSampleDocument()
        checkExtensionStatus()
    }

    public func checkExtensionStatus() {
        // Run light check
        DispatchQueue.global(qos: .background).async {
            let task = Process()
            task.launchPath = "/usr/bin/pluginkit"
            task.arguments = ["-m", "-i", SharedConstants.finderExtensionIdentifier]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = Pipe()
            try? task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            let finderActive = output.contains(SharedConstants.finderExtensionIdentifier) || task.terminationStatus == 0

            DispatchQueue.main.async {
                self.isFinderExtensionEnabled = finderActive
            }
        }
    }

    public func openSystemExtensionSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }

    public func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = "Monitor Folder"
        panel.message = "Choose folder(s) where you want 'Create New Markdown File' enabled:"

        if panel.runModal() == .OK {
            for url in panel.urls {
                _ = LocationManager.shared.addCustomFolder(url: url)
            }
            objectWillChange.send()
        }
    }

    public func openDocument(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            let content: String
            if let utf8 = String(data: data, encoding: .utf8) {
                content = utf8
            } else {
                content = String(decoding: data, as: UTF8.self)
            }

            self.currentDocumentURL = url
            self.currentDocumentContent = content
            self.selectedTab = .viewer
        } catch {
            NSLog("[MarkdownFinder] Failed to load file at %@: %@", url.path, error.localizedDescription)
        }
    }

    private func loadSampleDocument() {
        let sample = """
        # Welcome to PeekMD 🚀

        A native macOS utility that brings **"Create New Markdown File"** to your Finder background right-click menu and turns Quick Look (Spacebar) into an instant Markdown previewer.

        ---

        ## ✨ Key Capabilities

        - [x] **Right-click empty Finder space** → Instant `.md` file creation
        - [x] **Spacebar in Finder** → Native Quick Look preview
        - [x] **GFM Tables, Code Blocks, Task Lists & Callouts**
        - [x] **Obsidian & GitHub compatibility**
        - [x] **Light & Dark mode aware typography**

        ---

        ## 📊 GFM Table Example

        | Feature | Finder Sync | Quick Look | Viewer App |
        | :--- | :---: | :---: | ---: |
        | Context Menu Creation | ✅ | — | — |
        | Spacebar Preview | — | ✅ | — |
        | Full Window Reading | — | — | ✅ |
        | Speed | Instant | Instant | Sub-millisecond |

        ---

        ## 💡 Obsidian Callouts

        > [!NOTE] Native Apple Experience
        > PeekMD works directly on standard filesystem folders. No vaults, databases, or imports required.

        > [!TIP] Spacebar Previews
        > Simply select any `.md` or `.markdown` file in Finder and press **Space** to see full typography.

        ---

        ## 💻 Code Highlighting

        ```swift
        // Create files without overwriting
        let creator = MarkdownFileCreator()
        let fileURL = creator.createMarkdownFile(in: currentFolder)
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        ```
        """
        self.currentDocumentContent = sample
    }
}
