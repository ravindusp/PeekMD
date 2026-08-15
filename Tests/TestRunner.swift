import XCTest
import Foundation

@main
struct TestRunner {
    static func main() {
        print("=== Running Markdown Finder Unit Test Suite ===")

        let suite = XCTestSuite(name: "MarkdownFinderCoreTests")
        suite.addTest(FilenameResolverTests.defaultTestSuite)
        suite.addTest(FileCreationTests.defaultTestSuite)
        suite.addTest(SharedPreferencesTests.defaultTestSuite)

        let observer = TestObserver()
        XCTestObservationCenter.shared.addTestObserver(observer)

        suite.run()

        print("\n=== Test Results ===")
        print("Total Executed: \(observer.testCount)")
        print("Failures: \(observer.failureCount)")

        if observer.failureCount > 0 {
            exit(1)
        } else {
            print("✅ All Unit Tests Passed Successfully!\n")
            exit(0)
        }
    }
}

final class TestObserver: NSObject, XCTestObservation {
    var testCount = 0
    var failureCount = 0

    func testCase(_ testCase: XCTestCase, didFailWithDescription description: String, inFile filePath: String?, atLine lineNumber: Int) {
        failureCount += 1
        print("❌ FAIL: \(testCase.name) at line \(lineNumber): \(description)")
    }

    func testCaseDidFinish(_ testCase: XCTestCase) {
        testCount += 1
        if testCase.testRun?.hasSucceeded == true {
            print("✓ PASS: \(testCase.name)")
        }
    }
}
