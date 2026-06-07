import XCTest

final class RoutineAppUITests: XCTestCase {
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
    }

    func testLaunchShowsFallbackScreenWhenBootstrapFails() {
        let app = XCUIApplication()
        app.launchArguments.append("-routine-force-bootstrap-failure")
        app.launch()

        XCTAssertTrue(app.staticTexts["Unable to Open Routine"].exists)
        XCTAssertTrue(app.staticTexts["Routine could not open its local data."].exists)
        XCTAssertTrue(app.staticTexts["Try relaunching the app."].exists)
        XCTAssertFalse(app.navigationBars["Today"].exists)
    }
}
