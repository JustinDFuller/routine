import XCTest

@MainActor
final class RoutineAppUITests: XCTestCase {
    func testLaunch() {
        let app = makeApp(launchArguments: ["-routine-use-in-memory-store"])
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
        XCTAssertTrue(app.staticTexts["Morning"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
    }

    func testLaunchShowsFallbackScreenWhenBootstrapFails() {
        let app = makeApp(launchArguments: ["-routine-force-bootstrap-failure"])
        app.launch()

        XCTAssertTrue(app.staticTexts["Unable to Open Routine"].exists)
        XCTAssertTrue(app.staticTexts["Routine could not open its local data."].exists)
        XCTAssertTrue(app.staticTexts["Try relaunching the app."].exists)
        XCTAssertFalse(app.navigationBars["Today"].exists)
    }

    private func makeApp(launchArguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: launchArguments)
        return app
    }
}
