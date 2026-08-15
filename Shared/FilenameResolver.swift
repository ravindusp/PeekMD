import Foundation

public final class FilenameResolver: @unchecked Sendable {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Generates the next collision-safe URL in the specified folder.
    ///
    /// If `prefix.ext` does not exist, returns `prefix.ext`.
    /// Otherwise returns `prefix 2.ext`, `prefix 3.ext`, and so on.
    public func nextAvailableMarkdownURL(
        in folderURL: URL,
        prefix: String = SharedConstants.defaultFilePrefix,
        extension ext: String = SharedConstants.defaultExtensionValue
    ) -> URL {
        let cleanPrefix = prefix.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? SharedConstants.defaultFilePrefix
            : prefix.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanExt = ext.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .isEmpty ? SharedConstants.defaultExtensionValue : ext.trimmingCharacters(in: CharacterSet(charactersIn: "."))

        let baseFilename = "\(cleanPrefix).\(cleanExt)"
        let candidateURL = folderURL.appendingPathComponent(baseFilename, isDirectory: false)

        if !fileManager.fileExists(atPath: candidateURL.path) {
            return candidateURL
        }

        var counter = 2
        while true {
            let numberedFilename = "\(cleanPrefix) \(counter).\(cleanExt)"
            let numberedURL = folderURL.appendingPathComponent(numberedFilename, isDirectory: false)
            if !fileManager.fileExists(atPath: numberedURL.path) {
                return numberedURL
            }
            counter += 1
        }
    }

    /// Validates if a target folder is writable.
    public func isFolderWritable(at url: URL) -> Bool {
        return fileManager.isWritableFile(atPath: url.path)
    }
}
