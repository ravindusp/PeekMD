import SwiftUI
import MarkdownRenderer

public struct SettingsView: View {
    @ObservedObject var state = AppState.shared

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Section: Header / Status
                VStack(alignment: .leading, spacing: 6) {
                    Text("Settings & Preferences")
                        .font(.largeTitle.weight(.bold))
                    Text("Configure Finder context menu behaviors, file defaults, and Markdown preview styles.")
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 12) {
                    StatusBadgeView(
                        title: "Finder Sync Extension",
                        isEnabled: state.isFinderExtensionEnabled,
                        subtitle: state.isFinderExtensionEnabled ? "Context menu is ready to create files in Finder." : "Enable under System Settings > Extensions > Finder Extensions."
                    )

                    HStack(spacing: 12) {
                        Button(action: {
                            state.openSystemExtensionSettings()
                        }) {
                            Label("Extensions Settings...", systemImage: "arrow.up.forward.app")
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            state.restartFinder()
                        }) {
                            Label("Relaunch Finder", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.bordered)

                        Button(action: {
                            state.registerAndFixExtensions()
                        }) {
                            Label("Repair Extension", systemImage: "wrench.and.screwdriver")
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Divider()

                // Section: File Creation
                VStack(alignment: .leading, spacing: 16) {
                    Label("File Creation Defaults", systemImage: "doc.badge.plus")
                        .font(.title3.weight(.semibold))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Default Filename:")
                                .frame(width: 140, alignment: .leading)
                            TextField("Untitled", text: $state.defaultFilename)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 240)
                            Text("e.g. Untitled.md, Untitled 2.md")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("File Extension:")
                                .frame(width: 140, alignment: .leading)
                            Picker("", selection: $state.defaultExtension) {
                                Text(".md (Recommended)").tag("md")
                                Text(".markdown").tag("markdown")
                                Text(".mdown").tag("mdown")
                            }
                            .pickerStyle(.segmented)
                            .frame(maxWidth: 280)
                        }

                        Toggle("Select file in Finder immediately after creation", isOn: $state.selectAfterCreation)
                            .padding(.top, 4)

                        Toggle("Open file in default editor after creation", isOn: $state.openAfterCreation)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider()

                // Section: Quick Look & Theme
                VStack(alignment: .leading, spacing: 16) {
                    Label("Quick Look & Preview Theme", systemImage: "paintbrush")
                        .font(.title3.weight(.semibold))

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Preview Theme:")
                                .frame(width: 140, alignment: .leading)
                            Picker("", selection: $state.viewerTheme) {
                                ForEach(Theme.allCases, id: \.self) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 200)
                            .onChange(of: state.viewerTheme) { newTheme in
                                SharedPreferences.shared.selectedTheme = newTheme.rawValue
                            }
                        }

                        Toggle("Enable Code Block Syntax Highlighting", isOn: $state.enableSyntaxHighlighting)
                        Toggle("Enable LaTeX / Math Formula Rendering", isOn: $state.enableMathRendering)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider()

                // Section: Custom Template
                VStack(alignment: .leading, spacing: 16) {
                    Label("New File Template (Optional)", systemImage: "square.and.pencil")
                        .font(.title3.weight(.semibold))

                    Text("Text or YAML frontmatter to automatically populate into newly created Markdown files.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $state.customTemplate)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                        )
                }
            }
            .padding(32)
        }
    }
}
