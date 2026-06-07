import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineManagementServiceGroupTests: RoutineManagementServiceTestCase {
    func testCreateGroupTrimsAppendsNormalizesAndRejectsEmptyOrDuplicateNames() throws {
        let context = try makeContext()
        _ = try insertGroup(name: "Home", sortOrder: 2, into: context)
        let workGroup = try insertGroup(name: "Work", sortOrder: 7, into: context)
        let service = RoutineManagementService(context: context)

        let createdID = try service.createGroup(
            name: "  Fitness  ",
            now: Date(timeIntervalSinceReferenceDate: 300)
        )
        let groups = try fetchGroups(in: context)

        XCTAssertEqual(groups.map(\.name), ["Home", "Work", "Fitness"])
        XCTAssertEqual(groups.map(\.sortOrder), [0, 1, 2])
        XCTAssertEqual(try context.group(id: createdID).name, "Fitness")
        XCTAssertEqual(workGroup.sortOrder, 1)

        XCTAssertThrowsError(try service.createGroup(name: " \t ")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
        }

        XCTAssertThrowsError(try service.createGroup(name: " home ")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .duplicateGroupName)
            XCTAssertEqual(
                (error as? RoutineValidationError)?.errorDescription,
                "A group with that name already exists."
            )
        }
    }

    func testRenameGroupTrimsAllowsSelfEquivalentNamesAndRejectsDuplicatesAgainstOtherGroups() throws {
        let context = try makeContext()
        let homeGroup = try insertGroup(name: "Home", sortOrder: 0, into: context)
        _ = try insertGroup(name: "Work", sortOrder: 1, into: context)
        let service = RoutineManagementService(context: context)

        XCTAssertNoThrow(try service.renameGroup(id: homeGroup.id, name: "  home  "))
        XCTAssertEqual(try context.group(id: homeGroup.id).name, "home")

        XCTAssertThrowsError(try service.renameGroup(id: homeGroup.id, name: " WORK ")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .duplicateGroupName)
        }
    }

    func testDeleteEmptyGroupSucceedsAndNormalizesRemainingGroups() throws {
        let context = try makeContext()
        let first = try insertGroup(name: "Home", sortOrder: 0, into: context)
        let deleted = try insertGroup(name: "Work", sortOrder: 3, into: context)
        let third = try insertGroup(name: "Fitness", sortOrder: 7, into: context)

        try RoutineManagementService(context: context).deleteGroup(id: deleted.id)

        let groups = try fetchGroups(in: context)
        XCTAssertEqual(groups.map(\.id), [first.id, third.id])
        XCTAssertEqual(groups.map(\.sortOrder), [0, 1])
        XCTAssertThrowsError(try context.group(id: deleted.id)) { error in
            XCTAssertEqual(error as? PersistenceError, .groupNotFound(deleted.id))
        }
    }

    func testDeleteNonEmptyGroupThrowsWithoutOrphaningOrMovingRoutines() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Home", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group,
            into: context
        )

        XCTAssertThrowsError(try RoutineManagementService(context: context).deleteGroup(id: group.id)) { error in
            XCTAssertEqual(error as? RoutineManagementError, .nonEmptyGroup(group.id))
            XCTAssertEqual(
                (error as? RoutineManagementError)?.errorDescription,
                "Delete the routines in this group first."
            )
        }

        let persistedRoutine = try context.routine(id: routine.id)
        XCTAssertEqual(persistedRoutine.groupID, group.id)
        XCTAssertEqual(persistedRoutine.group?.id, group.id)
        XCTAssertEqual(try fetchGroups(in: context).map(\.id), [group.id])
    }

    func testMoveGroupPersistsRequestedOrderAndContiguousSortOrders() throws {
        let context = try makeContext()
        let first = try insertGroup(name: "Home", sortOrder: 0, into: context)
        let second = try insertGroup(name: "Work", sortOrder: 1, into: context)
        let third = try insertGroup(name: "Fitness", sortOrder: 2, into: context)

        try RoutineManagementService(context: context).moveGroup(id: third.id, to: 1)

        let groups = try fetchGroups(in: context)
        XCTAssertEqual(groups.map(\.id), [first.id, third.id, second.id])
        XCTAssertEqual(groups.map(\.sortOrder), [0, 1, 2])
    }
}
