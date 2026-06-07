import XCTest

@testable import RoutineApp

final class RoutineAppTests: XCTestCase {
    func testRootViewExists() {
        XCTAssertNotNil(RootView())
    }
}
