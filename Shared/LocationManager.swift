import Foundation

public struct MonitoredLocation: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let url: URL
    public let isSystemOrSpecial: Bool
    public let isAvailable: Bool

    public init(id: String = UUID().uuidString, name: String, path: String, url: URL, isSystemOrSpecial: Bool = false, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.path = path
        self.url = url
        self.isSystemOrSpecial = isSystemOrSpecial
        self.isAvailable = isAvailable
    }
}

public final class LocationManager: @unchecked Sendable {
    public static let shared = LocationManager()

    private let preferences: SharedPreferences

    public init(preferences: SharedPreferences = .shared) {
        self.preferences = preferences
    }

    public func getLocations() -> [MonitoredLocation] {
        var locations: [MonitoredLocation] = []

        // 1. Home Directory
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        let homeExists = FileManager.default.fileExists(atPath: homeURL.path)
        locations.append(MonitoredLocation(
            id: "home_directory",
            name: "Home Folder (~)",
            path: homeURL.path,
            url: homeURL,
            isSystemOrSpecial: true,
            isAvailable: homeExists
        ))

        // 2. Custom Folders
        for path in preferences.monitoredFolderPaths {
            let url = URL(fileURLWithPath: path, isDirectory: true)
            var isDir: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDir) && isDir.boolValue
            let name = url.lastPathComponent.isEmpty ? path : url.lastPathComponent
            locations.append(MonitoredLocation(
                id: path,
                name: name,
                path: path,
                url: url,
                isSystemOrSpecial: false,
                isAvailable: exists
            ))
        }

        // 3. External Volumes
        let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
        if let volumes = try? FileManager.default.contentsOfDirectory(
            at: volumesURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) {
            for vol in volumes {
                // Skip root symlink if present
                if vol.path != "/" && vol.path != "/Volumes/Macintosh HD" {
                    locations.append(MonitoredLocation(
                        id: vol.path,
                        name: vol.lastPathComponent,
                        path: vol.path,
                        url: vol,
                        isSystemOrSpecial: true,
                        isAvailable: true
                    ))
                }
            }
        }

        return locations
    }

    public func addCustomFolder(url: URL) -> Bool {
        var paths = preferences.monitoredFolderPaths
        let normalizedPath = url.standardizedFileURL.path
        if !paths.contains(normalizedPath) {
            paths.append(normalizedPath)
            preferences.monitoredFolderPaths = paths
            return true
        }
        return false
    }

    public func removeCustomFolder(path: String) {
        var paths = preferences.monitoredFolderPaths
        paths.removeAll { $0 == path }
        preferences.monitoredFolderPaths = paths
    }
}
