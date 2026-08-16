import Cocoa
import FinderSync

@objc(FinderSync)
final class FinderSync: FIFinderSync {
    private let fileCreator = MarkdownFileCreator()
    private let preferences = SharedPreferences.shared

    override init() {
        super.init()
        NSLog("[MarkdownFinderExtension] FinderSync extension initialized")
        updateMonitoredDirectories()
    }

    /// Reloads the monitored directory list
    private func updateMonitoredDirectories() {
        let urls = preferences.resolvedMonitoredURLs()
        FIFinderSyncController.default().directoryURLs = urls
        NSLog("[MarkdownFinderExtension] Monitoring %ld directories: %@", urls.count, urls.map { $0.path }.joined(separator: ", "))
    }

    // MARK: - Directory Observation Callbacks

    override func beginObservingDirectory(at url: URL) {
        NSLog("[MarkdownFinderExtension] beginObservingDirectory: %@", url.path)
    }

    override func endObservingDirectory(at url: URL) {
        NSLog("[MarkdownFinderExtension] endObservingDirectory: %@", url.path)
    }

    // MARK: - Toolbar Item

    override var toolbarItemName: String {
        return "New Markdown"
    }

    override var toolbarItemToolTip: String {
        return "Create a new Markdown file in the current folder"
    }

    override var toolbarItemImage: NSImage {
        if let img = NSImage(systemSymbolName: "doc.badge.plus", accessibilityDescription: "New Markdown") {
            return img
        }
        return NSImage()
    }

    // MARK: - Menu and Contextual Item Management

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        NSLog("[MarkdownFinderExtension] menu(for: %ld) requested", menuKind.rawValue)

        let menu = NSMenu(title: "")
        let title: String
        if menuKind == .contextualMenuForItems {
            title = "Create New Markdown File Here"
        } else {
            title = "Create New Markdown File"
        }

        let item = NSMenuItem(title: title, action: #selector(createMarkdownFile(_:)), keyEquivalent: "")
        item.target = self
        if let img = NSImage(systemSymbolName: "doc.text.badge.plus", accessibilityDescription: title) {
            item.image = img
        }
        menu.addItem(item)
        return menu
    }

    // MARK: - Actions

    @objc
    func createMarkdownFile(_ sender: Any?) {
        NSLog("[MarkdownFinderExtension] createMarkdownFile action triggered")
        var resolvedFolder = FIFinderSyncController.default().targetedURL()

        // 1. Fallback to selected item directory if targetedURL is nil
        if resolvedFolder == nil {
            if let selected = FIFinderSyncController.default().selectedItemURLs(), let first = selected.first {
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: first.path, isDirectory: &isDir), isDir.boolValue {
                    resolvedFolder = first
                } else {
                    resolvedFolder = first.deletingLastPathComponent()
                }
            }
        }

        // 2. Fallback to home documents or desktop if still nil
        if resolvedFolder == nil {
            let docs = SharedPreferences.realUserHomeDirectory().appendingPathComponent("Documents", isDirectory: true)
            resolvedFolder = FileManager.default.fileExists(atPath: docs.path) ? docs : SharedPreferences.realUserHomeDirectory()
        }

        guard let targetURL = resolvedFolder else {
            NSLog("[MarkdownFinderExtension] Error: Could not determine target folder")
            return
        }

        performFileCreation(in: targetURL)
    }

    private func performFileCreation(in folderURL: URL) {
        guard let createdURL = fileCreator.createMarkdownFile(in: folderURL) else {
            NSLog("[MarkdownFinderExtension] Failed to create Markdown file in: %@", folderURL.path)
            return
        }

        NSLog("[MarkdownFinderExtension] Created markdown file at: %@", createdURL.path)

        // 1. Select the newly created file in Finder
        if preferences.selectAfterCreation {
            DispatchQueue.main.async {
                NSWorkspace.shared.activateFileViewerSelecting([createdURL])
            }
        }

        // 2. Optionally open the file if configured
        if preferences.openAfterCreation {
            DispatchQueue.main.async {
                if let editorBundle = self.preferences.preferredEditor, !editorBundle.isEmpty,
                   let editorURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: editorBundle) {
                    let config = NSWorkspace.OpenConfiguration()
                    NSWorkspace.shared.open([createdURL], withApplicationAt: editorURL, configuration: config, completionHandler: nil)
                } else {
                    NSWorkspace.shared.open(createdURL)
                }
            }
        }
    }
}
