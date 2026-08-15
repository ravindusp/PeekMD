import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            for window in sender.windows {
                if window.identifier?.rawValue == "main-window" || window.title.contains("PeekMD") {
                    window.makeKeyAndOrderFront(nil)
                    return true
                }
            }
        }
        return true
    }
}

@main
struct MarkdownFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        Window("PeekMD", id: "main-window") {
            ContentView()
                .environmentObject(appState)
        }
        .windowToolbarStyle(.unified)
        .commands {
            SidebarCommands()

            CommandGroup(replacing: .appSettings) {
                Button("Settings...") {
                    appState.selectedTab = .settings
                    openMainWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        DocumentGroup(newDocument: MarkdownDocument()) { file in
            MarkdownEditorView(document: file.$document, fileURL: file.fileURL)
                .environmentObject(appState)
        }
        .windowToolbarStyle(.unified)
    }

    private func openMainWindow() {
        for window in NSApp.windows {
            if window.identifier?.rawValue == "main-window" || window.title.contains("PeekMD") {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        NSApp.activate(ignoringOtherApps: true)
    }
}

