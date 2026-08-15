import SwiftUI

public struct LocationsView: View {
    @ObservedObject var state = AppState.shared
    @State private var locations: [MonitoredLocation] = []

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Monitored Folders & Locations")
                        .font(.largeTitle.weight(.bold))
                    Text("The Finder context menu appears in all directories contained within these monitored root locations.")
                        .foregroundColor(.secondary)
                }

                // Standard Roots
                VStack(alignment: .leading, spacing: 14) {
                    Label("Default Roots", systemImage: "internaldrive")
                        .font(.title3.weight(.semibold))

                    VStack(spacing: 12) {
                        Toggle(isOn: $state.monitorHomeDirectory) {
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text("User Home Directory (~)")
                                        .font(.headline)
                                    Text(FileManager.default.homeDirectoryForCurrentUser.path)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)

                        Divider()

                        Toggle(isOn: $state.monitorExternalVolumes) {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .foregroundColor(.purple)
                                    .frame(width: 24)
                                VStack(alignment: .leading) {
                                    Text("External Drives & Volumes")
                                        .font(.headline)
                                    Text("Automatically monitor mounted USB drives, SD cards, and external storage.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Divider()

                // Custom Folders
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Custom Locations", systemImage: "folder.badge.plus")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Button(action: {
                            state.openFolderPicker()
                            refreshLocations()
                        }) {
                            Label("Add Folder...", systemImage: "plus")
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if SharedPreferences.shared.monitoredFolderPaths.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "folder")
                                .font(.system(size: 32))
                                .foregroundColor(.secondary)
                            Text("No custom folders added yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text("Your Home directory is already monitored, covering Desktop, Documents, Downloads, and Projects.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(28)
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                                .foregroundColor(Color(NSColor.separatorColor))
                        )
                    } else {
                        VStack(spacing: 0) {
                            ForEach(SharedPreferences.shared.monitoredFolderPaths, id: \.self) { path in
                                HStack {
                                    Image(systemName: "folder.fill")
                                        .foregroundColor(.orange)
                                        .frame(width: 24)
                                    VStack(alignment: .leading) {
                                        Text(URL(fileURLWithPath: path).lastPathComponent)
                                            .font(.headline)
                                        Text(path)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        LocationManager.shared.removeCustomFolder(path: path)
                                        refreshLocations()
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding()
                                Divider()
                            }
                        }
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .padding(32)
        }
        .onAppear {
            refreshLocations()
        }
    }

    private func refreshLocations() {
        locations = LocationManager.shared.getLocations()
    }
}
