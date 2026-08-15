import XCTest
@testable import MarkdownRenderer

final class ImageResolverTests: XCTestCase {
    func testWebImageURL() {
        let webURL = "https://example.com/image.png"
        let resolved = ImageResolver.resolveImageSource(rawPath: webURL, baseURL: nil)
        XCTAssertEqual(resolved, webURL)
    }

    func testRelativeImageResolution() {
        let base = URL(fileURLWithPath: "/Users/test/Documents")
        let raw = "images/diagram.png"
        let resolved = ImageResolver.resolveImageSource(rawPath: raw, baseURL: base)
        XCTAssertTrue(resolved.contains("diagram.png"))
        XCTAssertTrue(resolved.contains("/Users/test/Documents/images/diagram.png") || resolved.hasPrefix("data:"))
    }

    func testPercentEncodedPathResolution() {
        let base = URL(fileURLWithPath: "/Users/test/Documents")
        let raw = "my%20folder/image.png"
        let resolved = ImageResolver.resolveImageSource(rawPath: raw, baseURL: base)
        XCTAssertTrue(resolved.contains("my folder/image.png") || resolved.contains("my%20folder/image.png"))
    }
}
