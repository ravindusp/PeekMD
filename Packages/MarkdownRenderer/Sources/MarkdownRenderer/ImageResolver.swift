import Foundation

public enum ImageResolver {
    public static func resolveImageSource(rawPath: String, baseURL: URL?) -> String {
        let cleanPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)

        // 1. Web URLs or existing Data URIs are returned directly
        if cleanPath.hasPrefix("http://") ||
            cleanPath.hasPrefix("https://") ||
            cleanPath.hasPrefix("data:") {
            return cleanPath
        }

        // 2. Handle file:// URLs
        if cleanPath.hasPrefix("file://") {
            if let fileUrl = URL(string: cleanPath) {
                return embedIfLocal(fileURL: fileUrl.standardizedFileURL) ?? fileUrl.absoluteString
            }
        }

        // 3. Decode percent-encoding (e.g. %20 -> space)
        let decodedPath = cleanPath.removingPercentEncoding ?? cleanPath

        // 4. Determine base directory if baseURL is provided
        let baseDirURL: URL? = {
            guard let baseURL = baseURL else { return nil }
            var isDir: ObjCBool = false
            let baseDirPath: String
            if FileManager.default.fileExists(atPath: baseURL.path, isDirectory: &isDir) {
                baseDirPath = isDir.boolValue ? baseURL.path : baseURL.deletingLastPathComponent().path
            } else if !baseURL.pathExtension.isEmpty {
                baseDirPath = baseURL.deletingLastPathComponent().path
            } else {
                baseDirPath = baseURL.path
            }
            return URL(fileURLWithPath: baseDirPath, isDirectory: true).standardizedFileURL
        }()

        // 5. Try resolving candidate paths
        var candidateURLs: [URL] = []

        if cleanPath.hasPrefix("/") {
            // Absolute path
            candidateURLs.append(URL(fileURLWithPath: decodedPath).standardizedFileURL)
            if decodedPath != cleanPath {
                candidateURLs.append(URL(fileURLWithPath: cleanPath).standardizedFileURL)
            }
        } else if let baseDir = baseDirURL {
            // Relative path to base directory
            candidateURLs.append(URL(fileURLWithPath: decodedPath, relativeTo: baseDir).standardizedFileURL)
            if decodedPath != cleanPath {
                candidateURLs.append(URL(fileURLWithPath: cleanPath, relativeTo: baseDir).standardizedFileURL)
            }
        } else {
            // Relative to current working directory
            candidateURLs.append(URL(fileURLWithPath: decodedPath).standardizedFileURL)
            if decodedPath != cleanPath {
                candidateURLs.append(URL(fileURLWithPath: cleanPath).standardizedFileURL)
            }
        }

        // 6. Check each candidate URL for existence and embed if local
        for targetURL in candidateURLs {
            if let embedded = embedIfLocal(fileURL: targetURL) {
                return embedded
            }
        }

        // If file could not be read or does not exist locally, return the best effort path
        if let baseDir = baseDirURL {
            let relativeResolved = URL(fileURLWithPath: decodedPath, relativeTo: baseDir).standardizedFileURL.path
            return relativeResolved
        } else {
            return cleanPath
        }
    }

    private static func embedIfLocal(fileURL: URL) -> String? {
        let filePath = fileURL.path
        guard FileManager.default.fileExists(atPath: filePath) else {
            return nil
        }

        guard FileManager.default.isReadableFile(atPath: filePath) else {
            return nil
        }

        guard let attr = try? FileManager.default.attributesOfItem(atPath: filePath),
              let size = attr[.size] as? UInt64, size <= 35_000_000, // 35MB limit
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        let mimeType = mimeTypeForPath(filePath)
        let base64 = data.base64EncodedString()
        return "data:\(mimeType);base64,\(base64)"
    }

    public static func mimeTypeForPath(_ path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "svg": return "image/svg+xml"
        case "ico": return "image/x-icon"
        case "tiff", "tif": return "image/tiff"
        case "bmp": return "image/bmp"
        case "avif": return "image/avif"
        case "heic": return "image/heic"
        case "heif": return "image/heif"
        default: return "image/png"
        }
    }
}
