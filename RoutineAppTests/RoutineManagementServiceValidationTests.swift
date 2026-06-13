import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineManagementServiceValidationTests: RoutineManagementServiceTestCase {
    func testUpdateRoutineWithWhitespaceOnlyNameThrowsAndLeavesRoutineUnchanged() throws {
        let context = try makeContext()
        let sourceGroup = try insertGroup(name: "Source", sortOrder: 0, into: context)
        let destinationGroup = try insertGroup(name: "Destination", sortOrder: 1, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Morning Walk", targetCount: 3, period: .weekly, sortOrder: 2),
            group: sourceGroup,
            into: context
        )
        let service = RoutineManagementService(context: context)

        XCTAssertThrowsError(
            try service.updateRoutine(
                id: routine.id,
                with: RoutineDraft(
                    name: " \n ",
                    targetCount: 6,
                    period: .monthly,
                    groupID: destinationGroup.id
                )
            )
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
        }

        let unchangedRoutine = try context.routine(id: routine.id)
        XCTAssertEqual(unchangedRoutine.name, "Morning Walk")
        XCTAssertEqual(unchangedRoutine.targetCount, 3)
        XCTAssertEqual(unchangedRoutine.period, .weekly)
        XCTAssertEqual(unchangedRoutine.groupID, sourceGroup.id)
        XCTAssertEqual(unchangedRoutine.group?.id, sourceGroup.id)
        XCTAssertEqual(unchangedRoutine.sortOrder, 2)
    }

    func testUpdateRoutineWithMissingDestinationGroupThrowsAndLeavesRoutineUnchanged() throws {
        let context = try makeContext()
        let sourceGroup = try insertGroup(name: "Source", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Morning Walk", targetCount: 3, period: .weekly, sortOrder: 2),
            group: sourceGroup,
            into: context
        )
        let service = RoutineManagementService(context: context)
        let missingGroupID = UUID()

        XCTAssertThrowsError(
            try service.updateRoutine(
                id: routine.id,
                with: RoutineDraft(
                    name: "Evening Walk",
                    targetCount: 6,
                    period: .monthly,
                    groupID: missingGroupID
                )
            )
        ) { error in
            XCTAssertEqual(error as? PersistenceError, .groupNotFound(missingGroupID))
        }

        let unchangedRoutine = try context.routine(id: routine.id)
        XCTAssertEqual(unchangedRoutine.name, "Morning Walk")
        XCTAssertEqual(unchangedRoutine.targetCount, 3)
        XCTAssertEqual(unchangedRoutine.period, .weekly)
        XCTAssertEqual(unchangedRoutine.groupID, sourceGroup.id)
        XCTAssertEqual(unchangedRoutine.group?.id, sourceGroup.id)
        XCTAssertEqual(unchangedRoutine.sortOrder, 2)
    }

    func testRenameGroupWithWhitespaceOnlyNameThrowsAndLeavesGroupUnchanged() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Home", sortOrder: 4, into: context)
        let service = RoutineManagementService(context: context)

        XCTAssertThrowsError(try service.renameGroup(id: group.id, name: " \t ")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
        }

        let unchangedGroup = try context.group(id: group.id)
        XCTAssertEqual(unchangedGroup.name, "Home")
        XCTAssertEqual(unchangedGroup.sortOrder, 4)
    }

    func testCreateRoutineRejectsEqualAvailabilityStartAndEnd() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let service = RoutineManagementService(context: context)

        XCTAssertThrowsError(
            try service.createRoutine(
                RoutineDraft(
                    name: "Wake up early",
                    targetCount: 4,
                    period: .weekly,
                    groupID: group.id,
                    availabilityStartMinute: 60,
                    availabilityEndMinute: 60
                )
            )
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .invalidAvailabilityWindow)
        }
    }

    func testUpdateRoutineRejectsPartialAvailabilityStateAndLeavesRoutineUnchanged() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let service = RoutineManagementService(context: context)

        XCTAssertThrowsError(
            try service.updateRoutine(
                id: routine.id,
                with: RoutineDraft(
                    name: "Walk",
                    targetCount: 3,
                    period: .weekly,
                    groupID: group.id,
                    availabilityStartMinute: 120,
                    availabilityEndMinute: nil
                )
            )
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .invalidAvailabilityWindow)
        }

        let unchangedRoutine = try context.routine(id: routine.id)
        XCTAssertNil(unchangedRoutine.availabilityStartMinute)
        XCTAssertNil(unchangedRoutine.availabilityEndMinute)
    }
}
