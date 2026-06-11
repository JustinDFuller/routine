import XCTest

@MainActor
final class RoutineAppUITests: XCTestCase {
    func testSeededLaunchShowsTodayDashboardAndGroupedRoutines() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
        XCTAssertTrue(app.staticTexts["Morning"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Movement"].waitForExistence(timeout: 5))
    }

    func testEmptyLaunchStateShowsEmptyState() {
        let app = makeApp(
            seeded: false,
            additionalLaunchArguments: ["-routine-empty-in-memory-store"]
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["Today"].exists)
        XCTAssertTrue(app.staticTexts["No routines yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add your first routine to start tracking"].exists)

        let manageButton = app.buttons["today-dashboard-empty-manage-button"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()

        XCTAssertTrue(app.navigationBars["Manage Routines"].waitForExistence(timeout: 5))
    }

    func testCompletionAndUndoFlowUpdatesVisibleState() {
        let app = makeApp()
        app.launch()

        let incompleteCard = routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, not completed today, 0 of 5 this week",
            in: app
        )
        XCTAssertTrue(incompleteCard.waitForExistence(timeout: 5))
        incompleteCard.tap()

        let undoButton = app.buttons["today-dashboard-undo-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 2))

        let completedCard = routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, completed today, 1 of 5 this week",
            in: app
        )
        XCTAssertTrue(completedCard.waitForExistence(timeout: 5))
        undoButton.tap()

        let restoredCard = routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, not completed today, 0 of 5 this week",
            in: app
        )
        XCTAssertTrue(restoredCard.waitForExistence(timeout: 5))
    }

    func testCompletedCardTapOpensActionsWithoutCreatingDuplicateCompletion() {
        let app = makeApp()
        app.launch()

        routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, not completed today, 0 of 5 this week",
            in: app
        ).tap()

        let completedCard = routineCardButton(
            identifier: "routine-card-primary-morning-yoga",
            statePrefix: "Morning yoga, completed today, 1 of 5 this week",
            in: app
        )
        XCTAssertTrue(completedCard.waitForExistence(timeout: 5))
        completedCard.tap()

        XCTAssertTrue(app.buttons["View History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Edit Routine"].exists)
        XCTAssertTrue(app.buttons["Undo Today's Completion"].exists)
    }

    func testViewHistoryOpensForSelectedRoutine() {
        let app = makeApp()
        app.launch()

        let moreActionsButton = app.descendants(matching: .any)
            .matching(identifier: "routine-card-more-morning-yoga")
            .firstMatch
        XCTAssertTrue(moreActionsButton.waitForExistence(timeout: 5))
        moreActionsButton.tap()

        let viewHistoryButton = app.buttons["View History"]
        XCTAssertTrue(viewHistoryButton.waitForExistence(timeout: 5))
        viewHistoryButton.tap()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["5 per week"].waitForExistence(timeout: 5))
    }

    func testHistoryDeletionRequiresConfirmationAndRefreshesState() {
        let app = makeApp(
            additionalLaunchArguments: ["-routine-open-morning-yoga-history-with-completion"]
        )
        app.launch()

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["5 per week"].waitForExistence(timeout: 5))

        let completionRowDate = app.staticTexts["Jun 10, 2026"]
        XCTAssertTrue(completionRowDate.waitForExistence(timeout: 5))

        let removeButton = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Remove completion on ")
        ).firstMatch
        XCTAssertTrue(removeButton.exists)
        removeButton.tap()

        XCTAssertTrue(app.buttons["Remove Completion"].waitForExistence(timeout: 5))
        XCTAssertTrue(completionRowDate.exists)
        app.buttons["Remove Completion"].tap()

        XCTAssertTrue(app.staticTexts["No recent completions"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No completions yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0/5 this week"].waitForExistence(timeout: 5))
    }

    func testManageFlowCanAddEditAndDeleteRoutine() {
        let app = makeApp()
        app.launch()

        let manageButton = app.buttons["today-dashboard-manage-button"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()

        XCTAssertTrue(app.navigationBars["Manage Routines"].waitForExistence(timeout: 5))

        app.buttons["manage-routines-add-button"].tap()
        app.buttons["Add Routine"].tap()

        let nameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test Routine")
        app.buttons["routine-form-save-button"].tap()

        let createdRow = manageRoutineButton(labelPrefix: "UI Test Routine,", in: app)
        XCTAssertTrue(createdRow.waitForExistence(timeout: 5))
        createdRow.tap()

        let editNameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 5))
        clearAndTypeText("UI Test Routine Updated", into: editNameField)
        app.buttons["routine-form-save-button"].tap()

        let updatedRow = manageRoutineButton(labelPrefix: "UI Test Routine Updated,", in: app)
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
        updatedRow.tap()

        let deleteButton = app.buttons["routine-form-delete-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let deleteConfirmationSheet = app.sheets["Delete Routine"]
        XCTAssertTrue(deleteConfirmationSheet.waitForExistence(timeout: 5))

        let confirmDeleteButton = deleteConfirmationSheet.buttons["Delete Routine"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        XCTAssertFalse(
            manageRoutineButton(labelPrefix: "UI Test Routine Updated,", in: app)
                .waitForExistence(timeout: 2)
        )
    }

    func testManageFlowCanDeleteGroupThroughGroupActions() {
        let app = makeApp(
            seeded: false,
            additionalLaunchArguments: ["-routine-empty-in-memory-store"]
        )
        app.launch()

        let manageButton = app.buttons["today-dashboard-empty-manage-button"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()

        XCTAssertTrue(app.navigationBars["Manage Routines"].waitForExistence(timeout: 5))

        let addGroupButton = app.buttons["Add Group"]
        XCTAssertTrue(addGroupButton.waitForExistence(timeout: 5))
        addGroupButton.tap()

        let nameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test Group")
        app.buttons["group-form-save-button"].tap()

        let groupActionsButton = app.buttons["UI Test Group Actions"]
        XCTAssertTrue(groupActionsButton.waitForExistence(timeout: 5))
        groupActionsButton.tap()
        app.buttons["Delete Group"].tap()

        let deleteConfirmationSheet = app.sheets["UI Test Group"]
        XCTAssertTrue(deleteConfirmationSheet.waitForExistence(timeout: 5))

        let confirmDeleteButton = deleteConfirmationSheet.buttons["Delete Group"]
        XCTAssertTrue(confirmDeleteButton.waitForExistence(timeout: 5))
        confirmDeleteButton.tap()

        XCTAssertFalse(groupActionsButton.waitForExistence(timeout: 2))
    }

    func testLaunchShowsFallbackScreenWhenBootstrapFails() {
        let app = makeApp(
            seeded: false,
            additionalLaunchArguments: ["-routine-force-bootstrap-failure"]
        )
        app.launch()

        XCTAssertTrue(app.staticTexts["Unable to Open Routine"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Routine could not open its local data."].exists)
        XCTAssertTrue(app.staticTexts["Try relaunching the app."].exists)
        XCTAssertFalse(app.navigationBars["Today"].exists)
    }

    func testMissingHistoryRouteShowsNotFoundState() {
        let app = makeApp(
            additionalLaunchArguments: ["-routine-open-missing-history-route"]
        )
        app.launch()

        XCTAssertTrue(app.staticTexts["Routine not found"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["This routine may have been deleted."].exists)
        XCTAssertTrue(app.buttons["Back"].exists)
    }

    private func makeApp(
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

    private func routineCardButton(
        identifier: String,
        statePrefix: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        let element = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        XCTAssertTrue(element.label.hasPrefix(statePrefix), element.label)
        return element
    }

    private func manageRoutineButton(
        labelPrefix: String,
        in app: XCUIApplication
    ) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", labelPrefix)
        ).firstMatch
    }

    private func clearAndTypeText(
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
