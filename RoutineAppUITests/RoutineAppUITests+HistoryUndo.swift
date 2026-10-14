import XCTest

extension RoutineAppUITests {
    func testHistoryUndoBannerRestoresBothCompletionAndRemoval() {
        let app = makeApp()
        app.launch()

        let historyButton = app.buttons["routine-card-history-morning-yoga"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))

        let dayID = "history-day-2026-06-02"
        let day = identifiedElement(dayID, in: app)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        let originalLabel = day.label

        confirmToggle(of: "2026-06-02", in: app)
        XCTAssertNotEqual(identifiedElement(dayID, in: app).label, originalLabel)
        undoLastChange(in: app)
        XCTAssertEqual(identifiedElement(dayID, in: app).label, originalLabel)

        confirmToggle(of: "2026-06-02", in: app)
        let toggledLabel = identifiedElement(dayID, in: app).label
        confirmToggle(of: "2026-06-02", in: app)
        XCTAssertEqual(identifiedElement(dayID, in: app).label, originalLabel)
        undoLastChange(in: app)
        XCTAssertEqual(identifiedElement(dayID, in: app).label, toggledLabel)
    }

    private func confirmToggle(of dayKey: String, in app: XCUIApplication) {
        let day = identifiedElement("history-day-\(dayKey)", in: app)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        day.tap()

        let confirm = identifiedElement("history-day-confirm-\(dayKey)", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
    }

    private func undoLastChange(in app: XCUIApplication) {
        let undo = app.buttons["Undo completion"]
        XCTAssertTrue(undo.waitForExistence(timeout: 5))
        undo.tap()
        XCTAssertTrue(undo.waitForNonExistence(timeout: 5))
    }
}
