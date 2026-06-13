import XCTest

@MainActor
final class RoutineAppScreenshotTests: XCTestCase {
    private var captureIndex = 0

    func testCaptureFullAppScreenshotsInSingleLaunch() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        captureDashboardScreenshots(in: app)
        captureHistoryScreenshots(in: app)
        captureRoutineFormScreenshots(in: app)
        captureGroupManagementScreenshots(in: app)
        captureRearrangeScreenshots(in: app)
        XCTAssertEqual(captureIndex, 17)
    }

    private func captureDashboardScreenshots(in app: XCUIApplication) {
        capturePair(
            "dashboard-overview",
            anchor: dashboardTitle(in: app)
        )

        scrollToElement(app.staticTexts["Archive"], in: app)
        capturePair(
            "dashboard-lower-progress",
            anchor: app.staticTexts["Archive"]
        )

        scrollToDashboardTop(in: app)
        routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, not completed today, 2 of 5 this week",
            in: app
        ).tap()
        let completedMorningYogaCard = routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, completed today, 3 of 5 this week",
            in: app
        )
        waitForUndoBanner(in: app, timeout: 2)
        capturePair("completion-undo-banner", anchor: completedMorningYogaCard)
        tapUndoBanner(in: app)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    }

    private func captureHistoryScreenshots(in app: XCUIApplication) {
        app.buttons["routine-card-history-walk-the-dog"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["routine-history-month-grid"].waitForExistence(timeout: 5))
        capturePair(
            "history-rich",
            anchor: identifiedElement(
                identifier: "routine-history-recent-list",
                in: app
            )
        )

        let removeCompletionButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Remove completion on ")
        ).firstMatch
        XCTAssertTrue(removeCompletionButton.waitForExistence(timeout: 5))
        removeCompletionButton.tap()
        XCTAssertTrue(app.buttons["Remove Completion"].waitForExistence(timeout: 5))
        capturePair(
            "history-remove-confirmation",
            anchor: app.buttons["Remove Completion"]
        )
        app.buttons["Remove Completion"].tap()
        XCTAssertTrue(app.staticTexts["2/5 this week"].waitForExistence(timeout: 5))
        capturePair("history-after-removal", anchor: app.staticTexts["2/5 this week"])

        backButton(in: app).tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
    }

    private func captureRoutineFormScreenshots(in app: XCUIApplication) {
        openManagementMenu(in: app)
        XCTAssertTrue(app.buttons["Rearrange Routines"].waitForExistence(timeout: 5))
        capturePair("management-menu", anchor: app.buttons["Rearrange Routines"])

        app.buttons["Add Routine"].tap()
        let routineNameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(routineNameField.waitForExistence(timeout: 5))
        capturePair("add-routine-form-default", anchor: routineNameField)

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
        capturePair("add-routine-form-configured", anchor: saveButton)

        saveButton.tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        let newRoutineHistoryButton = app.buttons["routine-card-history-desk-stretch"]
        scrollToElement(newRoutineHistoryButton, in: app)
        capturePair("dashboard-after-add-routine", anchor: newRoutineHistoryButton)

        scrollToDashboardTop(in: app)
        enterEditMode(in: app)
        let editButton = app.buttons["routine-card-edit-morning-yoga"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        capturePair("dashboard-edit-mode", anchor: editButton)
    }

    private func captureGroupManagementScreenshots(in app: XCUIApplication) {
        app.buttons["today-dashboard-edit-done-button"].tap()
        XCTAssertTrue(managementMenu(in: app).waitForExistence(timeout: 5))

        openManagementMenu(in: app)
        app.buttons["Add Group"].tap()
        let groupNameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(groupNameField.waitForExistence(timeout: 5))
        capturePair("add-group-form", anchor: groupNameField)

        clearAndTypeText("Weekend Reset", into: groupNameField)
        dismissKeyboardIfPresent(in: app)
        app.buttons["group-form-save-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        let newGroupHeader = app.staticTexts["Weekend Reset"]
        scrollToElement(newGroupHeader, in: app)
        capturePair("dashboard-after-add-group", anchor: newGroupHeader)

        scrollToDashboardTop(in: app)
        enterEditMode(in: app)
        let archiveEditButton = app.buttons["dashboard-group-edit-archive"]
        scrollToElement(archiveEditButton, in: app)
        archiveEditButton.tap()

        let editGroupNameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(editGroupNameField.waitForExistence(timeout: 5))
        let groupDeleteButton = app.buttons["group-form-delete-button"]
        XCTAssertTrue(groupDeleteButton.waitForExistence(timeout: 5))
        dismissKeyboardIfPresent(in: app)
        capturePair("edit-group-form", anchor: groupDeleteButton)

        clearAndTypeText("Archive Bin", into: editGroupNameField)
        dismissKeyboardIfPresent(in: app)
        app.buttons["group-form-save-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))

        let renamedArchiveEditButton = app.buttons["dashboard-group-edit-archive-bin"]
        scrollToElement(renamedArchiveEditButton, in: app)
        renamedArchiveEditButton.tap()
        XCTAssertTrue(groupDeleteButton.waitForExistence(timeout: 5))
        groupDeleteButton.tap()

        let deleteGroupConfirmation = deleteConfirmationButton(
            title: "Delete Group",
            containerTitle: "Delete Group",
            in: app
        )
        XCTAssertTrue(deleteGroupConfirmation.waitForExistence(timeout: 5))
        capturePair("delete-group-confirmation", anchor: deleteGroupConfirmation)
        deleteGroupConfirmation.tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))

        let editDoneButton = app.buttons["today-dashboard-edit-done-button"]
        XCTAssertTrue(editDoneButton.waitForExistence(timeout: 5))
        editDoneButton.tap()
    }

    private func captureRearrangeScreenshots(in app: XCUIApplication) {
        openManagementMenu(in: app)
        app.buttons["Rearrange Groups"].tap()
        let rearrangeDoneButton = app.buttons["today-dashboard-rearrange-done-button"]
        XCTAssertTrue(rearrangeDoneButton.waitForExistence(timeout: 5))
        capturePair("rearrange-groups", anchor: rearrangeDoneButton)
        rearrangeDoneButton.tap()

        openManagementMenu(in: app)
        app.buttons["Rearrange Routines"].tap()
        XCTAssertTrue(rearrangeDoneButton.waitForExistence(timeout: 5))
        capturePair("rearrange-routines", anchor: rearrangeDoneButton)
    }
}

extension RoutineAppScreenshotTests {
    fileprivate func makeApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments.append(contentsOf: [
            "-routine-empty-in-memory-store",
            "-routine-screenshot-fixture",
            "full-app",
            "-routine-fixed-date",
            "2026-06-10",
            "-routine-disable-animations"
        ])
        return app
    }

    fileprivate func capturePair(
        _ slug: String,
        anchor: XCUIElement
    ) {
        captureIndex += 1

        captureScreenshot(named: screenshotName(for: slug, appearance: "dark"), appearance: .dark, anchor: anchor)
        captureScreenshot(named: screenshotName(for: slug, appearance: "light"), appearance: .light, anchor: anchor)
    }

    fileprivate func captureScreenshot(
        named name: String,
        appearance: XCUIDevice.Appearance,
        anchor: XCUIElement
    ) {
        XCUIDevice.shared.appearance = appearance
        XCTAssertTrue(anchor.waitForExistence(timeout: 5))
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))

        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
