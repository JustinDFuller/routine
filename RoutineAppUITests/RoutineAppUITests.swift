import XCTest

@MainActor
final class RoutineAppUITests: XCTestCase {
    func testSeededLaunchShowsTodayDashboardAndGroupedRoutines() {
        let app = makeApp()
        app.launch()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Morning yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Movement"].waitForExistence(timeout: 5))
        XCTAssertTrue(managementMenu(in: app).waitForExistence(timeout: 5))
    }

    func testEmptyLaunchStateShowsAddGroupCTAAndReturnsToToday() {
        let app = makeApp(
            seeded: false,
            additionalLaunchArguments: ["-routine-empty-in-memory-store"]
        )
        app.launch()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No groups yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add a group to start organizing your routines."].exists)

        let addGroupButton = app.buttons["today-dashboard-empty-add-group-button"]
        XCTAssertTrue(addGroupButton.waitForExistence(timeout: 5))
        addGroupButton.tap()

        let nameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test Group")
        app.buttons["group-form-save-button"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No routines yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today-dashboard-empty-add-routine-button"].exists)
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
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

    func testCompletedCardTapOpensHistoryWithoutCreatingDuplicateCompletion() {
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

        XCTAssertTrue(app.navigationBars["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1/5 this week"].waitForExistence(timeout: 5))

        let removalButtons = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Remove completion on ")
        )
        XCTAssertTrue(removalButtons.firstMatch.waitForExistence(timeout: 5))
        XCTAssertEqual(removalButtons.count, 1)
    }

    func testViewHistoryOpensForSelectedRoutine() {
        let app = makeApp()
        app.launch()

        let historyButton = app.buttons["routine-card-history-morning-yoga"]
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()

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

    func testChangingWeekStartReordersHistoryWeekdayHeader() {
        let app = makeApp()
        app.launch()

        // UserDefaults persists across launches in the same simulator, so normalize
        // to Sunday before asserting the default ordering.
        setWeekStart("Sunday", in: app)
        assertHistoryWeekdayHeaderPrefix("Sun", in: app)

        setWeekStart("Monday", in: app)
        assertHistoryWeekdayHeaderPrefix("Mon", in: app)
    }

    func testDashboardManagementMenuCanAddRoutineAndReturnsToToday() {
        let app = makeApp()
        app.launch()

        openManagementMenu(in: app)
        app.buttons["Add Routine"].tap()

        let nameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test Routine")
        app.buttons["routine-form-save-button"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: "routine-card-primary-ui-test-routine")
                .firstMatch
                .waitForExistence(timeout: 5)
        )
    }

    func testDashboardCanEditRoutineFromEditModeAndReturnsToToday() {
        let app = makeApp()
        app.launch()

        enterEditMode(in: app)

        let editButton = app.buttons["routine-card-edit-morning-yoga"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["routine-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        clearAndTypeText("Morning yoga updated", into: nameField)
        app.buttons["routine-form-save-button"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
        XCTAssertTrue(
            app.descendants(matching: .any)
                .matching(identifier: "routine-card-primary-morning-yoga-updated")
                .firstMatch
                .waitForExistence(timeout: 5)
        )
    }

    func testDashboardRoutineDeleteFromEditSheetRemovesCard() {
        let app = makeApp()
        app.launch()

        enterEditMode(in: app)

        let editButton = app.buttons["routine-card-edit-morning-yoga"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let deleteButton = app.buttons["routine-form-delete-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let deleteConfirmationSheet = app.sheets["Delete Routine"]
        XCTAssertTrue(deleteConfirmationSheet.waitForExistence(timeout: 5))
        deleteConfirmationSheet.buttons["Delete Routine"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(
            app.descendants(matching: .any)
                .matching(identifier: "routine-card-primary-morning-yoga")
                .firstMatch
                .waitForExistence(timeout: 2)
        )
    }

    func testDashboardGroupEditUpdatesSectionHeader() {
        let app = makeApp()
        app.launch()

        enterEditMode(in: app)

        let editButton = app.buttons["dashboard-group-edit-morning"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let nameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        clearAndTypeText("Sunrise", into: nameField)
        app.buttons["group-form-save-button"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Sunrise"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
    }

    func testDashboardDeleteEmptyGroupHappensOnlyFromEditSheet() {
        let app = makeApp(
            seeded: false,
            additionalLaunchArguments: ["-routine-empty-in-memory-store"]
        )
        app.launch()

        let addGroupButton = app.buttons["today-dashboard-empty-add-group-button"]
        XCTAssertTrue(addGroupButton.waitForExistence(timeout: 5))
        addGroupButton.tap()

        let addNameField = app.textFields["group-form-name-field"]
        XCTAssertTrue(addNameField.waitForExistence(timeout: 5))
        addNameField.tap()
        addNameField.typeText("Archive")
        app.buttons["group-form-save-button"].tap()

        XCTAssertTrue(app.buttons["today-dashboard-empty-add-routine-button"].waitForExistence(timeout: 5))

        enterEditMode(in: app)

        let editButton = app.buttons["dashboard-group-edit-archive"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 5))
        editButton.tap()

        let deleteButton = app.buttons["group-form-delete-button"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let deleteConfirmationSheet = app.sheets["Delete Group"]
        XCTAssertTrue(deleteConfirmationSheet.waitForExistence(timeout: 5))
        deleteConfirmationSheet.buttons["Delete Group"].tap()

        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(editButton.waitForExistence(timeout: 2))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
    }

    func testDashboardManagementEditModeCanBeEnteredAndExitedWithoutManageScreen() {
        let app = makeApp()
        app.launch()

        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
        XCTAssertTrue(app.buttons["routine-card-history-morning-yoga"].waitForExistence(timeout: 5))

        enterEditMode(in: app)
        XCTAssertTrue(dashboardTitle(in: app).exists)
        XCTAssertTrue(app.buttons["routine-card-edit-morning-yoga"].exists)
        XCTAssertFalse(app.buttons["routine-card-history-morning-yoga"].exists)
        XCTAssertFalse(managementMenu(in: app).exists)
        let doneButton = app.buttons["today-dashboard-edit-done-button"]
        XCTAssertTrue(doneButton.exists)
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)

        doneButton.tap()
        XCTAssertTrue(dashboardTitle(in: app).exists)
        XCTAssertFalse(app.buttons["routine-card-edit-morning-yoga"].exists)
        XCTAssertTrue(app.buttons["routine-card-history-morning-yoga"].waitForExistence(timeout: 5))
        XCTAssertTrue(managementMenu(in: app).waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)
    }

    func testDashboardRearrangeGroupsModeShowsGroupRowsAndDoneExit() {
        let app = makeApp()
        app.launch()

        openManagementMenu(in: app)
        app.buttons["Rearrange Groups"].tap()

        let groupRow = identifiedElement("today-dashboard-rearrange-group-morning", in: app)
        XCTAssertTrue(groupRow.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today-dashboard-rearrange-done-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)

        app.buttons["today-dashboard-rearrange-done-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
    }

    func testDashboardRearrangeRoutinesModeShowsRoutineRowsAndDoneExit() {
        let app = makeApp()
        app.launch()

        openManagementMenu(in: app)
        app.buttons["Rearrange Routines"].tap()

        let routineRow = identifiedElement("today-dashboard-rearrange-routine-morning-yoga", in: app)
        XCTAssertTrue(routineRow.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["today-dashboard-rearrange-done-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.navigationBars["Manage Routines"].exists)

        app.buttons["today-dashboard-rearrange-done-button"].tap()
        XCTAssertTrue(dashboardTitle(in: app).waitForExistence(timeout: 5))
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
        XCTAssertFalse(dashboardTitle(in: app).exists)
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
}

extension RoutineAppUITests {
    func testCompletedRoutineCollapsesToMiniRowAndExpandsAndCollapsesOnTap() {
        let app = makeApp(
            additionalLaunchArguments: ["-routine-collapse-completed-enabled"]
        )
        app.launch()

        let incompleteCard = identifiedElement("routine-card-primary-morning-yoga", in: app)
        XCTAssertTrue(incompleteCard.waitForExistence(timeout: 5))
        incompleteCard.tap()

        let miniRow = identifiedElement("routine-completed-row-morning-yoga", in: app)
        XCTAssertTrue(miniRow.waitForExistence(timeout: 5))

        XCTAssertFalse(
            identifiedElement("routine-card-history-morning-yoga", in: app).waitForExistence(timeout: 2)
        )

        miniRow.tap()

        XCTAssertTrue(
            identifiedElement("routine-card-history-morning-yoga", in: app).waitForExistence(timeout: 5)
        )

        let collapseButton = identifiedElement("routine-card-collapse-morning-yoga", in: app)
        XCTAssertTrue(collapseButton.waitForExistence(timeout: 5))
        collapseButton.tap()

        XCTAssertTrue(miniRow.waitForExistence(timeout: 5))
        XCTAssertFalse(
            identifiedElement("routine-card-history-morning-yoga", in: app).waitForExistence(timeout: 2)
        )
    }
}
