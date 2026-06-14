import XCTest

@MainActor
final class RoutineAppScreenshotTests: XCTestCase {
    var captureIndex = 0
    private let screenshotAppearances = ScreenshotAppearance.allCases

    func testCaptureFullAppScreenshotsAcrossForcedAppearances() {
        for appearance in screenshotAppearances {
            captureIndex = 0

            let app = makeApp(for: appearance)
            app.launch()

            XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
            captureDashboardScreenshots(in: app, appearance: appearance)
            captureHistoryScreenshots(in: app, appearance: appearance)
            captureRoutineFormScreenshots(in: app, appearance: appearance)
            captureGroupManagementScreenshots(in: app, appearance: appearance)
            captureRearrangeScreenshots(in: app, appearance: appearance)
            captureSettingsScreenshots(in: app, appearance: appearance)
            XCTAssertEqual(captureIndex, 18)
            app.terminate()
        }
    }

    private func captureDashboardScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        captureScreenshot(
            "dashboard-overview",
            appearance: appearance,
            anchor: dashboardTitle(in: app)
        )

        scrollToElement(app.staticTexts["Archive"], in: app)
        captureScreenshot(
            "dashboard-lower-progress",
            appearance: appearance,
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
        captureScreenshot(
            "completion-undo-banner",
            appearance: appearance,
            anchor: completedMorningYogaCard
        )
        tapUndoBanner(in: app)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    }

    private func captureHistoryScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        app.buttons["routine-card-history-walk-the-dog"].tap()
        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["routine-history-month-grid"].waitForExistence(timeout: 5))
        captureScreenshot(
            "history-rich",
            appearance: appearance,
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
        captureScreenshot(
            "history-remove-confirmation",
            appearance: appearance,
            anchor: app.buttons["Remove Completion"]
        )
        app.buttons["Remove Completion"].tap()
        XCTAssertTrue(app.staticTexts["2/5 this week"].waitForExistence(timeout: 5))
        captureScreenshot(
            "history-after-removal",
            appearance: appearance,
            anchor: app.staticTexts["2/5 this week"]
        )

        backButton(in: app).tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
    }

    private func captureRoutineFormScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        openManagementMenu(in: app)
        XCTAssertTrue(app.buttons["Rearrange Routines"].waitForExistence(timeout: 5))
        captureScreenshot(
            "management-menu",
            appearance: appearance,
            anchor: app.buttons["Rearrange Routines"]
        )

        app.buttons["Add Routine"].tap()
        let routineNameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(routineNameField.waitForExistence(timeout: 5))
        captureScreenshot(
            "add-routine-form-default",
            appearance: appearance,
            anchor: routineNameField
        )

        saveConfiguredRoutine(in: app, routineNameField: routineNameField, appearance: appearance)
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        let newRoutineHistoryButton = app.buttons["routine-card-history-desk-stretch"]
        scrollToElement(newRoutineHistoryButton, in: app)
        captureScreenshot(
            "dashboard-after-add-routine",
            appearance: appearance,
            anchor: newRoutineHistoryButton
        )

        scrollToDashboardTop(in: app)
        enterEditMode(in: app)
        let editButton = app.buttons["routine-card-edit-morning-yoga"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        captureScreenshot(
            "dashboard-edit-mode",
            appearance: appearance,
            anchor: editButton
        )
    }

    private func captureGroupManagementScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        app.buttons["today-dashboard-edit-done-button"].tap()
        XCTAssertTrue(managementMenu(in: app).waitForExistence(timeout: 5))

        openManagementMenu(in: app)
        app.buttons["Add Group"].tap()
        let groupNameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(groupNameField.waitForExistence(timeout: 5))
        captureScreenshot(
            "add-group-form",
            appearance: appearance,
            anchor: groupNameField
        )

        clearAndTypeText("Weekend Reset", into: groupNameField)
        dismissKeyboardIfPresent(in: app)
        app.buttons["group-form-save-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        let newGroupHeader = app.staticTexts["Weekend Reset"]
        scrollToElement(newGroupHeader, in: app)
        captureScreenshot(
            "dashboard-after-add-group",
            appearance: appearance,
            anchor: newGroupHeader
        )

        captureGroupEditingFlow(in: app, appearance: appearance)
    }

    private func captureGroupEditingFlow(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
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
        captureScreenshot(
            "edit-group-form",
            appearance: appearance,
            anchor: groupDeleteButton
        )

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
        captureScreenshot(
            "delete-group-confirmation",
            appearance: appearance,
            anchor: deleteGroupConfirmation
        )
        deleteGroupConfirmation.tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))

        let editDoneButton = app.buttons["today-dashboard-edit-done-button"]
        XCTAssertTrue(editDoneButton.waitForExistence(timeout: 5))
        editDoneButton.tap()
    }

    private func captureRearrangeScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        openManagementMenu(in: app)
        app.buttons["Rearrange Groups"].tap()
        let rearrangeDoneButton = app.buttons["today-dashboard-rearrange-done-button"]
        XCTAssertTrue(rearrangeDoneButton.waitForExistence(timeout: 5))
        captureScreenshot(
            "rearrange-groups",
            appearance: appearance,
            anchor: rearrangeDoneButton
        )
        rearrangeDoneButton.tap()

        openManagementMenu(in: app)
        app.buttons["Rearrange Routines"].tap()
        XCTAssertTrue(rearrangeDoneButton.waitForExistence(timeout: 5))
        captureScreenshot(
            "rearrange-routines",
            appearance: appearance,
            anchor: rearrangeDoneButton
        )
        rearrangeDoneButton.tap()
    }

    private func captureSettingsScreenshots(
        in app: XCUIApplication,
        appearance: ScreenshotAppearance
    ) {
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))

        openManagementMenu(in: app)
        app.buttons["Week Starts On"].tap()

        let weekStartPicker = app.buttons["settings-week-start-picker"]
        XCTAssertTrue(weekStartPicker.waitForExistence(timeout: 5))
        captureScreenshot(
            "settings-week-start",
            appearance: appearance,
            anchor: weekStartPicker
        )

        app.buttons["settings-done-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
    }
}
