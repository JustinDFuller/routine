import XCTest

@testable import RoutineCore

final class RoutineCorePlaceholderTests: XCTestCase {
    func testPlaceholderVersion() {
        XCTAssertEqual(RoutineCorePlaceholder.version, "M01")
    }
}
