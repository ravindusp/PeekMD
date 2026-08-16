import Foundation

public enum SharedConstants {
    public static let appGroupIdentifier = "7PMBK2ZW83.group.com.oneloop.markdownfinder"
    public static let appBundleIdentifier = "com.oneloop.PeekMD"
    public static let finderExtensionIdentifier = "com.oneloop.PeekMD.FinderSync"
    public static let quickLookExtensionIdentifier = "com.oneloop.PeekMD.QuickLook"

    public enum UserDefaultsKeys {
        public static let defaultFilename = "defaultFilename"
        public static let defaultExtension = "defaultExtension"
        public static let selectAfterCreation = "selectAfterCreation"
        public static let openAfterCreation = "openAfterCreation"
        public static let preferredEditor = "preferredEditor"
        public static let monitoredFolders = "monitoredFolders"
        public static let monitorHomeDirectory = "monitorHomeDirectory"
        public static let monitorExternalVolumes = "monitorExternalVolumes"
        public static let selectedTheme = "selectedTheme"
        public static let enableSyntaxHighlighting = "enableSyntaxHighlighting"
        public static let enableMathRendering = "enableMathRendering"
        public static let hasCompletedOnboarding = "hasCompletedOnboarding"
        public static let customTemplateContent = "customTemplateContent"
    }

    public static let defaultFilePrefix = "Untitled"
    public static let defaultExtensionValue = "md"
    public static let supportedExtensions = ["md", "markdown", "mdown", "mkd"]
}
