import SwiftUI
import AppKit

@main
struct MarkdownFinderApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownEditorView(document: file.$document, fileURL: file.fileURL)
                .environmentObject(appState)
        }
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Preferences & Extension Setup...") {
                    openSettingsWindow()
                }
            }
        }

        Settings {
            ContentView()
                .environmentObject(appState)
        }
    }

    private func openSettingsWindow() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}
