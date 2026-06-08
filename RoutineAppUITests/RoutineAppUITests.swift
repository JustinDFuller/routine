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

    func testViewHistoryOpensForSelectedRoutine() {
        let app = makeApp(launchArguments: ["-routine-use-in-memory-store"])
        app.launch()

        let moreActionsButton = app.buttons["More actions for Morning yoga"]
        XCTAssertTrue(moreActionsButton.waitForExistence(timeout: 5))
        moreActionsButton.tap()

        let viewHistoryButton = app.buttons["View History"]
        XCTAssertTrue(viewHistoryButton.waitForExistence(timeout: 5))
        viewHistoryButton.tap()

        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["5 per week"].waitForExistence(timeout: 5))
    }

    func testHistoryDeletionRequiresConfirmationAndRefreshesState() {
        let app = makeApp(
            launchArguments: [
                "-routine-use-in-memory-store",
                "-routine-open-morning-yoga-history-with-completion"
            ]
        )
        app.launch()

        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["5 per week"].waitForExistence(timeout: 5))

        let removeButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Remove completion on ")
        ).firstMatch
        XCTAssertTrue(removeButton.waitForExistence(timeout: 5))
        removeButton.tap()

        let removeConfirmationButton = app.buttons["Remove Completion"]
        XCTAssertTrue(removeConfirmationButton.waitForExistence(timeout: 5))
        removeConfirmationButton.tap()

        XCTAssertTrue(app.staticTexts["No recent completions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No completions yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0/5 this week"].waitForExistence(timeout: 5))
    }

    func testMissingHistoryRouteShowsNotFoundState() {
        let app = makeApp(
            launchArguments: [
                "-routine-use-in-memory-store",
                "-routine-open-missing-history-route"
            ]
        )
        app.launch()

        XCTAssertTrue(app.staticTexts["Routine not found"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["This routine may have been deleted."].exists)
        XCTAssertTrue(app.buttons["Back"].exists)
    }

    private func makeApp(launchArguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: launchArguments)
        return app
    }
}
