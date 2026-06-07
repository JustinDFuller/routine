import XCTest

final class RoutineAppUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
    }
}
