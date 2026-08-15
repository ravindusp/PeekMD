import SwiftUI
import AppKit

@main
struct MarkdownFinderApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onOpenURL { url in
                    appState.openDocument(from: url)
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .newItem) {
                Button("Open Markdown File...") {
                    let panel = NSOpenPanel()
                    panel.canChooseFiles = true
                    panel.canChooseDirectories = false
                    panel.allowedContentTypes = [.init(filenameExtension: "md")!, .init(filenameExtension: "markdown")!, .plainText]
                    if panel.runModal() == .OK, let url = panel.url {
                        appState.openDocument(from: url)
                    }
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
