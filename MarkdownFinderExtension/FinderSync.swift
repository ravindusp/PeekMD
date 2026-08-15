import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    private let fileCreator = MarkdownFileCreator()
    private let preferences = SharedPreferences.shared

    override init() {
        super.init()
        updateMonitoredDirectories()
    }

    /// Reloads the monitored directory list from SharedPreferences
    private func updateMonitoredDirectories() {
        let urls = preferences.resolvedMonitoredURLs()
        FIFinderSyncController.default().directoryURLs = urls
        NSLog("[MarkdownFinderExtension] Monitoring %ld directory roots", urls.count)
    }

    // MARK: - Menu and Toolbar Item Management

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        // Handle contextual menu when right-clicking the empty background area inside a Finder window
        if menuKind == .contextualMenuForContainer {
            let menu = NSMenu(title: "")
            let title = "Create New Markdown File"
            let item = NSMenuItem(title: title, action: #selector(createMarkdownFile(_:)), keyEquivalent: "")
            item.target = self
            if let img = NSImage(systemSymbolName: "doc.text.badge.plus", accessibilityDescription: title) {
                item.image = img
            }
            menu.addItem(item)
            return menu
        }

        // Handle contextual menu when right-clicking a folder item
        if menuKind == .contextualMenuForItems {
            guard let selectedURLs = FIFinderSyncController.default().selectedItemURLs(),
                  selectedURLs.count == 1,
                  let targetURL = selectedURLs.first else {
                return nil
            }

            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetURL.path, isDirectory: &isDir), isDir.boolValue {
                let menu = NSMenu(title: "")
                let title = "Create New Markdown File Here"
                let item = NSMenuItem(title: title, action: #selector(createMarkdownFileInSelectedFolder(_:)), keyEquivalent: "")
                item.target = self
                if let img = NSImage(systemSymbolName: "doc.text.badge.plus", accessibilityDescription: title) {
                    item.image = img
                }
                menu.addItem(item)
                return menu
            }
        }

        // Toolbar item menu
        if menuKind == .toolbarItemMenu {
            let menu = NSMenu(title: "")
            let title = "Create New Markdown File"
            let item = NSMenuItem(title: title, action: #selector(createMarkdownFile(_:)), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
            return menu
        }

        return nil
    }

    // MARK: - Actions

    @objc
    private func createMarkdownFile(_ sender: Any?) {
        guard let folderURL = FIFinderSyncController.default().targetedURL() else {
            NSLog("[MarkdownFinderExtension] Error: No targeted URL returned by FinderSyncController")
            return
        }

        performFileCreation(in: folderURL)
    }

    @objc
    private func createMarkdownFileInSelectedFolder(_ sender: Any?) {
        guard let selectedURLs = FIFinderSyncController.default().selectedItemURLs(),
              let targetURL = selectedURLs.first else {
            return
        }

        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: targetURL.path, isDirectory: &isDir), isDir.boolValue {
            performFileCreation(in: targetURL)
        }
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
