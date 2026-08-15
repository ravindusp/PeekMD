import SwiftUI
import UniformTypeIdentifiers

public struct MarkdownDocument: FileDocument {
    public static var readableContentTypes: [UTType] {
        var types: [UTType] = []
        if let md1 = UTType("net.daringfireball.markdown") { types.append(md1) }
        if let md2 = UTType("public.markdown") { types.append(md2) }
        if let mdExt = UTType(filenameExtension: "md") { types.append(mdExt) }
        if let markdownExt = UTType(filenameExtension: "markdown") { types.append(markdownExt) }
        if let mdownExt = UTType(filenameExtension: "mdown") { types.append(mdownExt) }
        types.append(.plainText)
        types.append(.utf8PlainText)
        return types
    }

    public static var writableContentTypes: [UTType] {
        var types: [UTType] = []
        if let md1 = UTType("net.daringfireball.markdown") { types.append(md1) }
        if let mdExt = UTType(filenameExtension: "md") { types.append(mdExt) }
        types.append(.plainText)
        return types
    }

    public var text: String

    public init(text: String = "") {
        if text.isEmpty && !SharedPreferences.shared.customTemplateContent.isEmpty {
            self.text = SharedPreferences.shared.customTemplateContent
        } else {
            self.text = text
        }
    }

    public init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        if let string = String(data: data, encoding: .utf8) {
            self.text = string
        } else if let string = String(data: data, encoding: .isoLatin1) {
            self.text = string
        } else {
            self.text = String(decoding: data, as: UTF8.self)
        }
    }

    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}
