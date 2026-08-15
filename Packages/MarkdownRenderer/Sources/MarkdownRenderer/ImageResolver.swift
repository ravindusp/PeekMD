import Foundation

public enum ImageResolver {
    public static func resolveImageSource(rawPath: String, baseURL: URL?) -> String {
        let cleanPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)

        // Web URLs or Data URIs are returned directly
        if cleanPath.hasPrefix("http://") ||
            cleanPath.hasPrefix("https://") ||
            cleanPath.hasPrefix("data:") {
            return cleanPath
        }

        // Local or relative path resolution
        let decodedPath = cleanPath.removingPercentEncoding ?? cleanPath

        let targetURL: URL
        if cleanPath.hasPrefix("/") {
            // Absolute path
            targetURL = URL(fileURLWithPath: decodedPath).standardizedFileURL
        } else if let baseURL = baseURL {
            let baseDirPath: String
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: baseURL.path, isDirectory: &isDir) {
                baseDirPath = isDir.boolValue ? baseURL.path : baseURL.deletingLastPathComponent().path
            } else if !baseURL.pathExtension.isEmpty {
                baseDirPath = baseURL.deletingLastPathComponent().path
            } else {
                baseDirPath = baseURL.path
            }
            let baseDirURL = URL(fileURLWithPath: baseDirPath, isDirectory: true)
            targetURL = URL(fileURLWithPath: decodedPath, relativeTo: baseDirURL).standardizedFileURL
        } else {
            targetURL = URL(fileURLWithPath: decodedPath).standardizedFileURL
        }

        // Check if file exists locally
        if FileManager.default.fileExists(atPath: targetURL.path) {
            // Embed small-to-medium local images as Base64 Data URI for robust QuickLook / WebView rendering
            if let attr = try? FileManager.default.attributesOfItem(atPath: targetURL.path),
               let size = attr[.size] as? UInt64, size <= 25_000_000, // 25MB max
               let data = try? Data(contentsOf: targetURL) {
                let mimeType = mimeTypeForPath(targetURL.path)
                let base64 = data.base64EncodedString()
                return "data:\(mimeType);base64,\(base64)"
            }
            return targetURL.absoluteString
        }

        return targetURL.absoluteString
    }

    private static func mimeTypeForPath(_ path: String) -> String {
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
        default: return "image/png"
        }
    }
}
