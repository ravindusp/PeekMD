import SwiftUI

public struct OnboardingView: View {
    @ObservedObject var state = AppState.shared
    @State private var creationSuccessMessage: String?

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        Text("Quick Setup Guide")
                            .font(.largeTitle.weight(.bold))
                    }
                    Text("Follow these 3 simple steps to get Finder integration and Spacebar previews running.")
                        .foregroundColor(.secondary)
                }

                // Step 1: Enable Extension
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("1")
                            .font(.title2.weight(.bold))
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())

                        Text("Enable Finder Extension & Relaunch Finder")
                            .font(.title3.weight(.semibold))
                    }

                    Text("Click **Open Extensions Settings** and ensure **PeekMD Extension** is toggled ON under Finder Extensions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Button(action: {
                            state.openSystemExtensionSettings()
                        }) {
                            Label("Open Extensions Settings...", systemImage: "arrow.up.forward.app")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Step 2: Finder Right-Click
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("2")
                            .font(.title2.weight(.bold))
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())

                        Text("Right-Click Any Blank Area in Finder")
                            .font(.title3.weight(.semibold))
                    }

                    Text("Navigate into any folder in Finder (like Desktop, Documents, or your workspace), right-click the empty background space, and click **Create New Markdown File**.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    HStack {
                        Button(action: {
                            testCreateMarkdownFile()
                        }) {
                            Label("Test Create in ~/Documents", systemImage: "doc.badge.plus")
                        }
                        .buttonStyle(.bordered)

                        if let msg = creationSuccessMessage {
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                // Step 3: Quick Look Preview
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 12) {
                        Text("3")
                            .font(.title2.weight(.bold))
                            .frame(width: 32, height: 32)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Circle())

                        Text("Press Spacebar to Preview")
                            .font(.title3.weight(.semibold))
                    }

                    Text("Select any `.md` or `.markdown` file in Finder and hit **Spacebar** to see a fast, formatted Quick Look preview with full tables, syntax highlighting, and Obsidian callouts.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(32)
        }
    }

    private func testCreateMarkdownFile() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.homeDirectoryForCurrentUser
        let creator = MarkdownFileCreator()
        if let createdURL = creator.createMarkdownFile(in: docs, initialContent: "# Test Markdown File\n\nCreated successfully via PeekMD!") {
            creationSuccessMessage = "✓ Created \(createdURL.lastPathComponent)"
            NSWorkspace.shared.activateFileViewerSelecting([createdURL])
        }
    }
}
