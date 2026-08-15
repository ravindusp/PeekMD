import XCTest
import Foundation
@testable import MarkdownFinderCore

final class FilenameResolverTests: XCTestCase {
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDown() {
        if let temp = tempDirectory {
            try? FileManager.default.removeItem(at: temp)
        }
        super.tearDown()
    }

    func testFirstFileIsUntitledMD() {
        let resolver = FilenameResolver()
        let url = resolver.nextAvailableMarkdownURL(in: tempDirectory)
        XCTAssertEqual(url.lastPathComponent, "Untitled.md")
    }

    func testConsecutiveNumberingWhenFileExists() {
        let resolver = FilenameResolver()

        // Create Untitled.md
        let firstFile = tempDirectory.appendingPathComponent("Untitled.md")
        FileManager.default.createFile(atPath: firstFile.path, contents: Data(), attributes: nil)

        let secondURL = resolver.nextAvailableMarkdownURL(in: tempDirectory)
        XCTAssertEqual(secondURL.lastPathComponent, "Untitled 2.md")

        // Create Untitled 2.md
        FileManager.default.createFile(atPath: secondURL.path, contents: Data(), attributes: nil)

        let thirdURL = resolver.nextAvailableMarkdownURL(in: tempDirectory)
        XCTAssertEqual(thirdURL.lastPathComponent, "Untitled 3.md")
    }

    func testCustomPrefixAndExtension() {
        let resolver = FilenameResolver()
        let url = resolver.nextAvailableMarkdownURL(in: tempDirectory, prefix: "Daily Note", extension: ".markdown")
        XCTAssertEqual(url.lastPathComponent, "Daily Note.markdown")

        // Create the file
        FileManager.default.createFile(atPath: url.path, contents: Data(), attributes: nil)

        let secondURL = resolver.nextAvailableMarkdownURL(in: tempDirectory, prefix: "Daily Note", extension: "markdown")
        XCTAssertEqual(secondURL.lastPathComponent, "Daily Note 2.markdown")
    }

    func testSpacesAndSpecialCharactersInFolder() {
        let specialDir = tempDirectory.appendingPathComponent("My Documents & Vaults 📚", isDirectory: true)
        try? FileManager.default.createDirectory(at: specialDir, withIntermediateDirectories: true)

        let resolver = FilenameResolver()
        let url = resolver.nextAvailableMarkdownURL(in: specialDir)
        XCTAssertEqual(url.lastPathComponent, "Untitled.md")
        XCTAssertTrue(url.path.contains("My Documents & Vaults 📚"))
    }
}
