import XCTest

extension RoutineAppUITests {
    func testHistoryMonthTitleIsButtonAndTodayIsHiddenOnCurrentMonth() {
        let app = openMorningYogaHistory()

        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "June 2026, choose month")
        XCTAssertFalse(identifiedElement("routine-history-today-button", in: app).exists)
        XCTAssertFalse(app.buttons["Show previous month"].exists)
    }

    func testHistorySwipeRightShowsPreviousMonthAndSwipeLeftReturns() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        monthGrid(in: app).swipeRight()
        waitForTitle("May 2026, choose month", in: title)
        XCTAssertTrue(app.buttons["routine-history-today-button"].waitForExistence(timeout: 5))

        monthGrid(in: app).swipeLeft()
        waitForTitle("June 2026, choose month", in: title)
        XCTAssertFalse(app.buttons["routine-history-today-button"].exists)
    }

    func testHistorySwipeLeftOnCurrentMonthDoesNothing() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        monthGrid(in: app).swipeLeft()

        XCTAssertEqual(title.label, "June 2026, choose month")
        XCTAssertFalse(app.buttons["routine-history-today-button"].exists)
    }

    func testHistorySwipeAcrossYearBoundaryShowsDecember() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        for expected in ["May 2026", "April 2026", "March 2026", "February 2026", "January 2026", "December 2025"] {
            monthGrid(in: app).swipeRight()
            waitForTitle("\(expected), choose month", in: title)
        }
    }

    func testHistoryVerticalDragDoesNotChangeMonth() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        monthGrid(in: app).swipeUp()
        monthGrid(in: app).swipeDown()

        XCTAssertEqual(title.label, "June 2026, choose month")
    }

    func testHistoryTitleOpensWheelsAndYearWheelChangesMonthTitle() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        title.tap()
        let monthWheel = app.pickerWheels.element(boundBy: 0)
        let yearWheel = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(monthWheel.waitForExistence(timeout: 5))
        XCTAssertEqual(monthWheel.value as? String, "June")
        XCTAssertEqual(yearWheel.value as? String, "2026")
        XCTAssertTrue(identifiedElement("routine-history-month-wheel", in: app).exists)
        XCTAssertTrue(identifiedElement("routine-history-year-wheel", in: app).exists)
        XCTAssertFalse(identifiedElement("routine-history-weekday-header", in: app).exists)

        yearWheel.adjust(toPickerWheelValue: "2025")
        waitForTitle("June 2025, choose month", in: title)

        title.tap()
        XCTAssertTrue(identifiedElement("routine-history-weekday-header", in: app).waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "June 2025, choose month")
    }

    func testHistoryMonthWheelOffersOnlyMonthsThroughCurrentMonthInCurrentYear() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        title.tap()
        let monthWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(monthWheel.waitForExistence(timeout: 5))

        monthWheel.adjust(toPickerWheelValue: "January")
        waitForTitle("January 2026, choose month", in: title)
        XCTAssertEqual(monthWheel.value as? String, "January")

        monthWheel.adjust(toPickerWheelValue: "June")
        waitForTitle("June 2026, choose month", in: title)
        monthWheel.swipeUp()
        XCTAssertEqual(title.label, "June 2026, choose month")
    }

    func testHistoryTodayButtonClosesWheelsAndReturnsToCurrentMonth() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        title.tap()
        let yearWheel = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(yearWheel.waitForExistence(timeout: 5))
        yearWheel.adjust(toPickerWheelValue: "2024")
        waitForTitle("June 2024, choose month", in: title)

        let todayButton = app.buttons["routine-history-today-button"]
        XCTAssertTrue(todayButton.waitForExistence(timeout: 5))
        XCTAssertEqual(todayButton.label, "Today, show current month")
        todayButton.tap()

        waitForTitle("June 2026, choose month", in: title)
        XCTAssertTrue(identifiedElement("routine-history-weekday-header", in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.pickerWheels.firstMatch.exists)
        XCTAssertFalse(todayButton.exists)
    }

    func testHistoryCompletingDayInEarlierMonthAfterSwipeRecordsCompletion() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        monthGrid(in: app).swipeRight()
        waitForTitle("May 2026, choose month", in: title)

        let day = identifiedElement("history-day-2026-05-20", in: app)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        XCTAssertTrue(day.label.contains("not completed"), day.label)
        day.tap()

        let confirm = app.buttons["history-day-confirm-2026-05-20"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["Completed May 20, 2026"].waitForExistence(timeout: 5))
        let completedDay = identifiedElement("history-day-2026-05-20", in: app)
        XCTAssertTrue(completedDay.label.contains(", completed"), completedDay.label)
        XCTAssertEqual(title.label, "May 2026, choose month")
    }

    func testHistoryRemovingCompletionInEarlierMonthAfterSwipeUndoesIt() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        monthGrid(in: app).swipeRight()
        waitForTitle("May 2026, choose month", in: title)

        let day = identifiedElement("history-day-2026-05-20", in: app)
        XCTAssertTrue(day.waitForExistence(timeout: 5))
        day.tap()
        let confirm = app.buttons["history-day-confirm-2026-05-20"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(day.label.contains(", completed"), day.label)

        day.tap()
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        let predicate = NSPredicate(format: "label CONTAINS %@", ", not completed")
        expectation(for: predicate, evaluatedWith: day)
        waitForExpectations(timeout: 5)
    }

    func testHistoryYearWheelIncludesYearReachedBySwipingBeforeItsRange() {
        let app = openMorningYogaHistory()
        let title = app.buttons["routine-history-month-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

        title.tap()
        let yearWheel = app.pickerWheels.element(boundBy: 1)
        XCTAssertTrue(yearWheel.waitForExistence(timeout: 5))
        yearWheel.adjust(toPickerWheelValue: "2021")
        waitForTitle("June 2021, choose month", in: title)
        title.tap()

        for _ in 0..<6 {
            monthGrid(in: app).swipeRight()
        }
        waitForTitle("December 2020, choose month", in: title)

        title.tap()
        XCTAssertTrue(yearWheel.waitForExistence(timeout: 5))
        XCTAssertEqual(yearWheel.value as? String, "2020")
    }

    private func openMorningYogaHistory() -> XCUIApplication {
        let app = makeApp()
        app.launch()

        let historyButton = app.buttons["routine-card-history-morning-yoga"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        return app
    }

    private func monthGrid(in app: XCUIApplication) -> XCUIElement {
        let grid = identifiedElement("routine-history-month-grid", in: app)
        XCTAssertTrue(grid.waitForExistence(timeout: 5))
        return grid
    }

    private func waitForTitle(_ label: String, in title: XCUIElement) {
        let predicate = NSPredicate(format: "label == %@", label)
        expectation(for: predicate, evaluatedWith: title)
        waitForExpectations(timeout: 5)
    }
}
