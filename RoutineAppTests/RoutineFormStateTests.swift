import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineFormStateTests: RoutineManagementServiceTestCase {
    func testEmptyOrWhitespaceNameBlocksDraftCreationAndExposesValidationMessage() throws {
        let state = RoutineFormState(presentation: .add(initialGroupID: UUID()))
        state.name = " \n "

        XCTAssertThrowsError(try state.makeDraft()) { error in
            XCTAssertEqual(error as? RoutineFormError, .validation(.emptyName))
        }
        XCTAssertEqual(state.validationMessage, "Name can't be empty.")
    }

    func testWeeklyAndMonthlyTargetBoundsFailValidation() throws {
        let state = RoutineFormState(presentation: .add(initialGroupID: UUID()))
        state.name = "Walk"

        state.period = .weekly
        state.targetCount = 8
        XCTAssertThrowsError(try state.makeDraft()) { error in
            XCTAssertEqual(
                error as? RoutineFormError,
                .validation(.invalidTargetCount(period: .weekly, min: 1, max: 7))
            )
        }

        state.period = .monthly
        state.targetCount = 32
        XCTAssertThrowsError(try state.makeDraft()) { error in
            XCTAssertEqual(
                error as? RoutineFormError,
                .validation(.invalidTargetCount(period: .monthly, min: 1, max: 31))
            )
        }
    }

    func testMissingGroupFailsWithChooseAGroupMessage() throws {
        let state = RoutineFormState(presentation: .add(initialGroupID: nil))
        state.name = "Walk"

        XCTAssertThrowsError(try state.makeDraft()) { error in
            XCTAssertEqual(error as? RoutineFormError, .missingGroup)
        }
        XCTAssertEqual(state.validationMessage, "Choose a group.")
    }

    func testEditingDraftMutationsDoNotMutatePersistedRoutineBeforeSaveOrCancel() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let state = RoutineFormState(
            presentation: .edit(
                RoutineFormSnapshot(
                    routineID: routine.id,
                    name: routine.name,
                    targetCount: routine.targetCount,
                    period: routine.period,
                    groupID: routine.groupID
                )
            )
        )

        state.name = "Edited Walk"
        state.targetCount = 6
        state.period = .monthly
        state.groupID = nil

        let persistedRoutine = try context.routine(id: routine.id)
        XCTAssertEqual(persistedRoutine.name, "Walk")
        XCTAssertEqual(persistedRoutine.targetCount, 3)
        XCTAssertEqual(persistedRoutine.period, .weekly)
        XCTAssertEqual(persistedRoutine.groupID, group.id)
    }

    func testPeriodChangesClampTargetCountToValidRange() throws {
        let state = RoutineFormState(presentation: .add(initialGroupID: UUID()))

        state.period = .monthly
        state.targetCount = 31
        state.period = .weekly
        XCTAssertEqual(state.targetCount, 7)

        state.targetCount = 0
        state.period = .monthly
        XCTAssertEqual(state.targetCount, 1)
    }

    func testSnapshotDropsMissingStoredGroupSelection() throws {
        let row = ManageRoutineRowViewData(
            id: UUID(),
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            groupID: UUID(),
            summaryText: "3 per week"
        )
        let snapshot = RoutineFormSnapshot(row: row, availableGroupIDs: [])

        XCTAssertNil(snapshot.groupID)
    }
}
