import XCTest
import Foundation
@testable import MarkdownFinderCore

final class FileCreationTests: XCTestCase {
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

    func testAtomicFileCreationWithInitialContent() {
        let testDefaults = UserDefaults(suiteName: "test_suite_\(UUID().uuidString)")!
        let prefs = SharedPreferences(defaults: testDefaults)
        prefs.defaultFilename = "Note"
        prefs.defaultExtension = "md"

        let creator = MarkdownFileCreator(filenameResolver: FilenameResolver(), preferences: prefs)
        let sampleContent = "# Hello World\n\nThis is a test note."

        guard let createdURL = creator.createMarkdownFile(in: tempDirectory, initialContent: sampleContent) else {
            XCTFail("Failed to create file")
            return
        }

        XCTAssertEqual(createdURL.lastPathComponent, "Note.md")
        XCTAssertTrue(FileManager.default.fileExists(atPath: createdURL.path))

        let readBack = try? String(contentsOf: createdURL, encoding: .utf8)
        XCTAssertEqual(readBack, sampleContent)
    }

    func testRapidMultipleCreationsDoNotOverwrite() {
        let testDefaults = UserDefaults(suiteName: "test_suite_\(UUID().uuidString)")!
        let prefs = SharedPreferences(defaults: testDefaults)
        prefs.defaultFilename = "Doc"
        prefs.defaultExtension = "md"

        let creator = MarkdownFileCreator(filenameResolver: FilenameResolver(), preferences: prefs)

        var createdURLs: [URL] = []
        for i in 1...5 {
            if let url = creator.createMarkdownFile(in: tempDirectory, initialContent: "Content \(i)") {
                createdURLs.append(url)
            }
        }

        XCTAssertEqual(createdURLs.count, 5)
        XCTAssertEqual(createdURLs[0].lastPathComponent, "Doc.md")
        XCTAssertEqual(createdURLs[1].lastPathComponent, "Doc 2.md")
        XCTAssertEqual(createdURLs[2].lastPathComponent, "Doc 3.md")
        XCTAssertEqual(createdURLs[3].lastPathComponent, "Doc 4.md")
        XCTAssertEqual(createdURLs[4].lastPathComponent, "Doc 5.md")

        // Verify each file's independent content
        for (index, url) in createdURLs.enumerated() {
            let content = try? String(contentsOf: url, encoding: .utf8)
            XCTAssertEqual(content, "Content \(index + 1)")
        }
    }
}
