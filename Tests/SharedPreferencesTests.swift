import XCTest
import Foundation
@testable import MarkdownFinderCore

final class SharedPreferencesTests: XCTestCase {
    var testDefaults: UserDefaults!
    var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "test_shared_prefs_\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: suiteName)!
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testDefaultValues() {
        let prefs = SharedPreferences(defaults: testDefaults)
        XCTAssertEqual(prefs.defaultFilename, SharedConstants.defaultFilePrefix)
        XCTAssertEqual(prefs.defaultExtension, SharedConstants.defaultExtensionValue)
        XCTAssertTrue(prefs.selectAfterCreation)
        XCTAssertFalse(prefs.openAfterCreation)
        XCTAssertTrue(prefs.monitorHomeDirectory)
    }

    func testCustomValuesPersistence() {
        let prefs = SharedPreferences(defaults: testDefaults)
        prefs.defaultFilename = "CustomNote"
        prefs.defaultExtension = ".markdown"
        prefs.selectAfterCreation = false
        prefs.openAfterCreation = true

        let reloaded = SharedPreferences(defaults: testDefaults)
        XCTAssertEqual(reloaded.defaultFilename, "CustomNote")
        XCTAssertEqual(reloaded.defaultExtension, "markdown") // clean extension
        XCTAssertFalse(reloaded.selectAfterCreation)
        XCTAssertTrue(reloaded.openAfterCreation)
    }

    func testMonitoredURLsResolution() {
        let prefs = SharedPreferences(defaults: testDefaults)
        prefs.monitorHomeDirectory = true

        let resolved = prefs.resolvedMonitoredURLs()
        XCTAssertTrue(resolved.contains(FileManager.default.homeDirectoryForCurrentUser))
    }
}
