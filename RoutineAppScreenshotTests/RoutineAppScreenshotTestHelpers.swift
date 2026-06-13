import XCTest

extension RoutineAppScreenshotTests {
    fileprivate enum ScreenshotAppearance: String, CaseIterable {
        case dark
        case light
    }

    fileprivate func makeApp(for appearance: ScreenshotAppearance) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            "-routine-empty-in-memory-store",
            "-routine-screenshot-fixture",
            "full-app",
            "-routine-fixed-date",
            "2026-06-10",
            "-routine-disable-animations",
            "-routine-force-color-scheme",
            appearance.rawValue
        ])
        return app
    }

    fileprivate func captureScreenshot(
        _ slug: String,
        appearance: ScreenshotAppearance,
        anchor: XCUIElement
    ) {
        captureIndex += 1
        XCTAssertTrue(anchor.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = screenshotName(for: slug, appearance: appearance.rawValue)
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    fileprivate func saveConfiguredRoutine(
        in app: XCUIApplication,
        routineNameField: XCUIElement,
        appearance: ScreenshotAppearance
    ) {
        clearAndTypeText("Desk stretch", into: routineNameField)
        let stepperIncrementButton = app.buttons["routine-form-target-stepper-Increment"]
        XCTAssertTrue(stepperIncrementButton.waitForExistence(timeout: 5))
        stepperIncrementButton.tap()
        stepperIncrementButton.tap()
        app.segmentedControls.firstMatch.buttons["Monthly"].tap()

        let allDayToggle = app.switches["routine-form-availability-all-day-toggle"]
        XCTAssertTrue(allDayToggle.waitForExistence(timeout: 5))
        if let toggleValue = allDayToggle.value as? String, toggleValue == "1" {
            allDayToggle.tap()
        }

        dismissKeyboardIfPresent(in: app)
        let saveButton = app.buttons["routine-form-save-button"]
        XCTAssertTrue(saveButton.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        captureScreenshot(
            "add-routine-form-configured",
            appearance: appearance,
            anchor: saveButton
        )

        saveButton.tap()
    }

    fileprivate func screenshotName(
        for slug: String,
        appearance: String
    ) -> String {
        String(format: "%02d-%@-%@", captureIndex, slug, appearance)
    }

    fileprivate func managementMenu(in app: XCUIApplication) -> XCUIElement {
        identifiedElement(identifier: "today-dashboard-management-menu", in: app)
    }

    fileprivate func dashboardTitle(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts["today-dashboard-title"]
    }

    fileprivate func backButton(in app: XCUIApplication) -> XCUIElement {
        app.navigationBars.buttons.firstMatch
    }

    fileprivate func openManagementMenu(in app: XCUIApplication) {
        let menu = managementMenu(in: app)
        XCTAssertTrue(waitForHittable(menu, timeout: 5))
        menu.tap()
    }

    fileprivate func enterEditMode(in app: XCUIApplication) {
        openManagementMenu(in: app)
        app.buttons["Edit"].tap()
    }

    fileprivate func routineCardButton(
        identifier: String,
        statePrefix: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let element = identifiedElement(identifier: identifier, in: app)
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(waitForHittable(element, timeout: 5))
        XCTAssertTrue(element.label.hasPrefix(statePrefix), element.label)
        return element
    }

    fileprivate func identifiedElement(
        identifier: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    fileprivate func scrollToDashboardTop(
        in app: XCUIApplication,
        maxScrolls: Int = 8
    ) {
        let topElement = app.buttons["routine-card-history-morning-yoga"]

        for _ in 0..<maxScrolls {
            if topElement.isHittable {
                return
            }

            app.swipeDown()
        }

        XCTAssertTrue(waitForHittable(topElement, timeout: 5))
    }

    fileprivate func scrollToElement(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maxScrolls: Int = 8
    ) {
        for _ in 0..<maxScrolls {
            if element.exists {
                break
            }

            app.swipeUp()
        }

        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }

    fileprivate func clearAndTypeText(
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

    fileprivate func dismissKeyboardIfPresent(in app: XCUIApplication) {
        guard app.keyboards.firstMatch.exists else {
            return
        }

        if app.toolbars.buttons["Done"].exists {
            app.toolbars.buttons["Done"].tap()
            return
        }

        app.navigationBars.firstMatch.tap()
    }

    fileprivate func deleteConfirmationButton(
        title: String,
        containerTitle: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let sheetButton = app.sheets[containerTitle].buttons[title]
        if sheetButton.exists {
            return sheetButton
        }

        let alertButton = app.alerts[containerTitle].buttons[title]
        if alertButton.exists {
            return alertButton
        }

        return app.buttons[title]
    }

    fileprivate func waitForUndoBanner(
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        let deadline = Date(timeIntervalSinceNow: timeout)

        repeat {
            let hasUndoBanner =
                app.buttons["today-dashboard-undo-button"].exists
                || app.buttons["Undo"].exists
                || app.staticTexts["Completed Morning yoga"].exists
            if hasUndoBanner {
                return
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        } while Date() < deadline
    }

    fileprivate func tapUndoBanner(in app: XCUIApplication) {
        let identifiedButton = app.buttons["today-dashboard-undo-button"]
        if waitForHittable(identifiedButton, timeout: 0.5) {
            identifiedButton.tap()
            return
        }

        let titledButton = app.buttons["Undo"]
        if waitForHittable(titledButton, timeout: 0.5) {
            titledButton.tap()
            return
        }

        let undoText = app.staticTexts["Undo"]
        if waitForHittable(undoText, timeout: 0.5) {
            undoText.tap()
            return
        }
        if undoText.exists {
            undoText.tap()
            return
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.82)).tap()
    }

    fileprivate func waitForHittable(
        _ element: XCUIElement,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date(timeIntervalSinceNow: timeout)

        repeat {
            if element.exists && element.isHittable {
                return true
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        } while Date() < deadline

        return element.exists && element.isHittable
    }
}
