import XCTest

extension RoutineAppUITests {
    func makeApp(
        seeded: Bool = true,
        additionalLaunchArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            "-routine-disable-animations",
            "-routine-fixed-date",
            "2026-06-10"
        ])

        if seeded {
            app.launchArguments.append("-routine-use-in-memory-store")
        }

        app.launchArguments.append(contentsOf: additionalLaunchArguments)
        return app
    }

    func managementMenu(in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: "today-dashboard-management-menu")
            .firstMatch
    }

    func dashboardTitle(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["today-dashboard-title"]
    }

    func openManagementMenu(in app: XCUIApplication) {
        let menu = managementMenu(in: app)
        XCTAssertTrue(menu.waitForExistence(timeout: 5))
        menu.tap()
    }

    func enterEditMode(in app: XCUIApplication) {
        openManagementMenu(in: app)
        app.buttons["Edit"].tap()
    }

    func setWeekStart(_ weekdayName: String, in app: XCUIApplication) {
        openManagementMenu(in: app)
        app.buttons["today-dashboard-settings-button"].tap()

        let picker = identifiedElement("settings-week-start-picker", in: app)
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()

        let labelPredicate = NSPredicate(format: "label == %@", weekdayName)
        let option = app.descendants(matching: .any).matching(labelPredicate).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()

        app.buttons["settings-done-button"].tap()
    }

    func assertHistoryWeekdayHeaderPrefix(_ prefix: String, in app: XCUIApplication) {
        let historyButton = app.buttons["routine-card-history-morning-yoga"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        let header = identifiedElement("routine-history-weekday-header", in: app)
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        XCTAssertTrue(header.label.hasPrefix(prefix), header.label)

        app.navigationBars["History"].buttons.element(boundBy: 0).tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
    }

    func routineCardButton(
        identifier: String,
        statePrefix: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let element = identifiedElement(identifier, in: app)
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.label.hasPrefix(statePrefix), element.label)
        return element
    }

    func identifiedElement(
        _ identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    func clearAndTypeText(
        _ text: String,
        into element: XCUIElement
    ) {
        element.tap()

        guard let currentValue = element.value as? String else {
            element.typeText(text)
            return
        }

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        element.typeText(deleteString + text)
    }
}
