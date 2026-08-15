import Foundation
import AppKit

public final class MarkdownFileCreator: @unchecked Sendable {
    private let filenameResolver: FilenameResolver
    private let preferences: SharedPreferences

    public init(filenameResolver: FilenameResolver = FilenameResolver(), preferences: SharedPreferences = .shared) {
        self.filenameResolver = filenameResolver
        self.preferences = preferences
    }

    /// Creates a markdown file in the specified folder URL.
    ///
    /// - Parameters:
    ///   - folderURL: The target directory URL.
    ///   - initialContent: Optional initial text content. If nil, uses customTemplateContent from preferences or empty data.
    /// - Returns: The URL of the created file if successful, or nil on failure.
    @discardableResult
    public func createMarkdownFile(
        in folderURL: URL,
        initialContent: String? = nil
    ) -> URL? {
        let prefix = preferences.defaultFilename
        let ext = preferences.defaultExtension

        let destinationURL = filenameResolver.nextAvailableMarkdownURL(
            in: folderURL,
            prefix: prefix,
            extension: ext
        )

        let contentToWrite = initialContent ?? preferences.customTemplateContent
        let data = contentToWrite.data(using: .utf8) ?? Data()

        do {
            try data.write(to: destinationURL, options: .withoutOverwriting)
            return destinationURL
        } catch {
            NSLog("[MarkdownFinder] Error writing file to %@: %@", destinationURL.path, error.localizedDescription)
            return nil
        }
    }
}
