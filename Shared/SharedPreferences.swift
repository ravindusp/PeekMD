import Foundation

public final class SharedPreferences: @unchecked Sendable {
    public static let shared = SharedPreferences()

    private let defaults: UserDefaults

    public init(defaults: UserDefaults? = nil) {
        if let customDefaults = defaults {
            self.defaults = customDefaults
        } else if let suiteDefaults = UserDefaults(suiteName: SharedConstants.appGroupIdentifier) {
            self.defaults = suiteDefaults
        } else {
            self.defaults = .standard
        }
    }

    public var defaultFilename: String {
        get {
            defaults.string(forKey: SharedConstants.UserDefaultsKeys.defaultFilename) ?? SharedConstants.defaultFilePrefix
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.defaultFilename)
        }
    }

    public var defaultExtension: String {
        get {
            defaults.string(forKey: SharedConstants.UserDefaultsKeys.defaultExtension) ?? SharedConstants.defaultExtensionValue
        }
        set {
            let clean = newValue.trimmingCharacters(in: CharacterSet(charactersIn: "."))
            defaults.set(clean, forKey: SharedConstants.UserDefaultsKeys.defaultExtension)
        }
    }

    public var selectAfterCreation: Bool {
        get {
            defaults.object(forKey: SharedConstants.UserDefaultsKeys.selectAfterCreation) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.selectAfterCreation)
        }
    }

    public var openAfterCreation: Bool {
        get {
            defaults.bool(forKey: SharedConstants.UserDefaultsKeys.openAfterCreation)
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.openAfterCreation)
        }
    }

    public var preferredEditor: String? {
        get {
            defaults.string(forKey: SharedConstants.UserDefaultsKeys.preferredEditor)
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.preferredEditor)
        }
    }

    public var monitorHomeDirectory: Bool {
        get {
            defaults.object(forKey: SharedConstants.UserDefaultsKeys.monitorHomeDirectory) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.monitorHomeDirectory)
        }
    }

    public var monitorExternalVolumes: Bool {
        get {
            defaults.object(forKey: SharedConstants.UserDefaultsKeys.monitorExternalVolumes) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.monitorExternalVolumes)
        }
    }

    public var monitoredFolderPaths: [String] {
        get {
            defaults.stringArray(forKey: SharedConstants.UserDefaultsKeys.monitoredFolders) ?? []
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.monitoredFolders)
        }
    }

    public var selectedTheme: String {
        get {
            defaults.string(forKey: SharedConstants.UserDefaultsKeys.selectedTheme) ?? "System"
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.selectedTheme)
        }
    }

    public var enableSyntaxHighlighting: Bool {
        get {
            defaults.object(forKey: SharedConstants.UserDefaultsKeys.enableSyntaxHighlighting) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.enableSyntaxHighlighting)
        }
    }

    public var enableMathRendering: Bool {
        get {
            defaults.object(forKey: SharedConstants.UserDefaultsKeys.enableMathRendering) as? Bool ?? true
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.enableMathRendering)
        }
    }

    public var customTemplateContent: String {
        get {
            defaults.string(forKey: SharedConstants.UserDefaultsKeys.customTemplateContent) ?? ""
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.customTemplateContent)
        }
    }

    public var hasCompletedOnboarding: Bool {
        get {
            defaults.bool(forKey: SharedConstants.UserDefaultsKeys.hasCompletedOnboarding)
        }
        set {
            defaults.set(newValue, forKey: SharedConstants.UserDefaultsKeys.hasCompletedOnboarding)
        }
    }

    /// Resolves real user home path outside sandbox container
    public static func realUserHomeDirectory() -> URL {
        if let pw = getpwuid(getuid()), let dir = pw.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: dir), isDirectory: true)
        }
        return FileManager.default.homeDirectoryForCurrentUser
    }

    /// Computes the active set of directory URLs that Finder Sync should monitor.
    public func resolvedMonitoredURLs() -> Set<URL> {
        var urls = Set<URL>()

        // 1. Root and Real Home
        urls.insert(URL(fileURLWithPath: "/", isDirectory: true))
        let realHome = SharedPreferences.realUserHomeDirectory()
        urls.insert(realHome)

        if monitorHomeDirectory {
            urls.insert(realHome.appendingPathComponent("Desktop", isDirectory: true))
            urls.insert(realHome.appendingPathComponent("Documents", isDirectory: true))
            urls.insert(realHome.appendingPathComponent("Downloads", isDirectory: true))
        }

        if monitorExternalVolumes {
            let volumesURL = URL(fileURLWithPath: "/Volumes", isDirectory: true)
            urls.insert(volumesURL)
            if let volumeContents = try? FileManager.default.contentsOfDirectory(
                at: volumesURL,
                includingPropertiesForKeys: [.isVolumeKey],
                options: [.skipsHiddenFiles]
            ) {
                for vol in volumeContents {
                    urls.insert(vol)
                }
            }
        }

        for path in monitoredFolderPaths {
            let folderURL = URL(fileURLWithPath: path, isDirectory: true)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isDir), isDir.boolValue {
                urls.insert(folderURL)
            }
        }

        return urls
    }
}
