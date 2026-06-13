import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineManagementRoutineCreateTests: RoutineManagementServiceTestCase {
    func testCreateRoutineTrimsPersistsAppendsAndAllowsDuplicateNames() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 4),
            group: group,
            into: context
        )
        let service = RoutineManagementService(context: context)
        let now = Date(timeIntervalSinceReferenceDate: 100)

        let createdID = try service.createRoutine(
            RoutineDraft(name: "  Walk  ", targetCount: 5, period: .monthly, groupID: group.id),
            now: now
        )

        let routines = try fetchRoutines(in: context, groupID: group.id)
        let createdRoutine = try XCTUnwrap(try context.routine(id: createdID))

        XCTAssertEqual(routines.map(\.name), ["Walk", "Walk"])
        XCTAssertEqual(routines.map(\.sortOrder), [0, 1])
        XCTAssertEqual(createdRoutine.name, "Walk")
        XCTAssertEqual(createdRoutine.targetCount, 5)
        XCTAssertEqual(createdRoutine.period, .monthly)
        XCTAssertEqual(createdRoutine.groupID, group.id)
        XCTAssertEqual(createdRoutine.group?.id, group.id)
        XCTAssertEqual(createdRoutine.createdAt, now)
        XCTAssertEqual(createdRoutine.updatedAt, now)
    }

    func testCreateRoutineDefaultsToAllDayAvailability() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let service = RoutineManagementService(context: context)

        let createdID = try service.createRoutine(
            RoutineDraft(
                name: "Walk",
                targetCount: 5,
                period: .weekly,
                groupID: group.id,
                availabilityStartMinute: nil,
                availabilityEndMinute: nil
            )
        )

        let routine = try context.routine(id: createdID)
        XCTAssertNil(routine.availabilityStartMinute)
        XCTAssertNil(routine.availabilityEndMinute)
        XCTAssertNil(routine.availabilityWindow)
    }

    func testCreateRoutinePersistsConfiguredAvailabilityWindow() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let service = RoutineManagementService(context: context)

        let createdID = try service.createRoutine(
            RoutineDraft(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                groupID: group.id,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405
            )
        )

        let routine = try context.routine(id: createdID)
        XCTAssertEqual(routine.availabilityStartMinute, 0)
        XCTAssertEqual(routine.availabilityEndMinute, 405)
        XCTAssertEqual(routine.availabilityWindow?.start.minuteOfDay, 0)
        XCTAssertEqual(routine.availabilityWindow?.end.minuteOfDay, 405)
    }

    func testCreateRoutineValidatesEmptyNameAndWeeklyMonthlyTargetBounds() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let service = RoutineManagementService(context: context)

        XCTAssertThrowsError(
            try service.createRoutine(RoutineDraft(name: " \n ", targetCount: 3, period: .weekly, groupID: group.id))
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
            XCTAssertEqual((error as? RoutineValidationError)?.errorDescription, "Name can't be empty.")
        }

        XCTAssertThrowsError(
            try service.createRoutine(RoutineDraft(name: "Walk", targetCount: 0, period: .weekly, groupID: group.id))
        ) { error in
            XCTAssertEqual(
                error as? RoutineValidationError,
                .invalidTargetCount(period: .weekly, min: 1, max: 7)
            )
            XCTAssertEqual(
                (error as? RoutineValidationError)?.errorDescription,
                "Weekly routines must be between 1 and 7."
            )
        }

        XCTAssertThrowsError(
            try service.createRoutine(RoutineDraft(name: "Walk", targetCount: 32, period: .monthly, groupID: group.id))
        ) { error in
            XCTAssertEqual(
                error as? RoutineValidationError,
                .invalidTargetCount(period: .monthly, min: 1, max: 31)
            )
            XCTAssertEqual(
                (error as? RoutineValidationError)?.errorDescription,
                "Monthly routines must be between 1 and 31."
            )
        }
    }

    func testMissingRoutineAndGroupIDsThrowPersistenceErrorsWithUserSafeDescriptions() throws {
        let context = try makeContext()
        let service = RoutineManagementService(context: context)
        let missingRoutineID = UUID()
        let missingGroupID = UUID()

        XCTAssertThrowsError(try service.deleteRoutine(id: missingRoutineID)) { error in
            XCTAssertEqual(error as? PersistenceError, .routineNotFound(missingRoutineID))
            XCTAssertEqual((error as? PersistenceError)?.errorDescription, "Routine not found.")
        }

        XCTAssertThrowsError(
            try service.createRoutine(
                RoutineDraft(name: "Walk", targetCount: 3, period: .weekly, groupID: missingGroupID)
            )
        ) { error in
            XCTAssertEqual(error as? PersistenceError, .groupNotFound(missingGroupID))
            XCTAssertEqual((error as? PersistenceError)?.errorDescription, "Group not found.")
        }
    }

    func testCreateRoutineMapsSaveFailureAndLeavesContextCleanForRetry() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let service = RoutineManagementService(context: context)
        let originalSave = RoutinePersistenceSaveExecutor.save
        defer { RoutinePersistenceSaveExecutor.save = originalSave }

        RoutinePersistenceSaveExecutor.save = { _ in
            throw SimulatedManagementSaveFailure()
        }

        do {
            _ = try service.createRoutine(
                RoutineDraft(name: "Walk", targetCount: 3, period: .weekly, groupID: group.id),
                now: Date(timeIntervalSinceReferenceDate: 400)
            )
            XCTFail("Expected createRoutine to throw.")
        } catch let error as PersistenceError {
            guard case .saveFailed(let diagnostic) = error else {
                return XCTFail("Expected saveFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to save changes.")
            XCTAssertEqual(diagnostic, "simulated management save failure")
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }

        XCTAssertTrue(try fetchRoutines(in: context, groupID: group.id).isEmpty)

        RoutinePersistenceSaveExecutor.save = originalSave

        let retryID = try service.createRoutine(
            RoutineDraft(name: "Walk", targetCount: 3, period: .weekly, groupID: group.id),
            now: Date(timeIntervalSinceReferenceDate: 401)
        )

        XCTAssertEqual(try fetchRoutines(in: context, groupID: group.id).map(\.id), [retryID])
    }
}

@MainActor
final class RoutineManagementRoutineMutationTests: RoutineManagementServiceTestCase {
    func testUpdateRoutineTrimsAndCanChangeGroupNamePeriodAndTargetKeepingGroupSync() throws {
        let context = try makeContext()
        let setup = try makeUpdateRoutineSetup(in: context)
        let now = Date(timeIntervalSinceReferenceDate: 200)

        try RoutineManagementService(context: context).updateRoutine(
            id: setup.routine.id,
            with: RoutineDraft(
                name: "  Evening Walk  ",
                targetCount: 6,
                period: .monthly,
                groupID: setup.destinationGroup.id
            ),
            now: now
        )

        try assertUpdatedRoutineState(
            in: context,
            setup: setup,
            updatedAt: now
        )
    }

    func testUpdateRoutineCanChangeAvailabilityBetweenConfiguredAndAllDay() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 0
            ),
            group: group,
            into: context
        )

        try RoutineManagementService(context: context).updateRoutine(
            id: routine.id,
            with: RoutineDraft(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                groupID: group.id,
                availabilityStartMinute: 1_380,
                availabilityEndMinute: 180
            )
        )

        var updated = try context.routine(id: routine.id)
        XCTAssertEqual(updated.availabilityStartMinute, 1_380)
        XCTAssertEqual(updated.availabilityEndMinute, 180)

        try RoutineManagementService(context: context).updateRoutine(
            id: routine.id,
            with: RoutineDraft(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                groupID: group.id,
                availabilityStartMinute: nil,
                availabilityEndMinute: nil
            )
        )

        updated = try context.routine(id: routine.id)
        XCTAssertNil(updated.availabilityStartMinute)
        XCTAssertNil(updated.availabilityEndMinute)
        XCTAssertNil(updated.availabilityWindow)
    }

    func testDeleteRoutineRemovesRoutineAndCascadesCompletionHistory() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let day = try makeDay(year: 2026, month: 6, day: 7)
        context.insert(
            RoutineCompletion(
                routine: routine,
                day: day,
                completedAt: Date(timeIntervalSinceReferenceDate: 10)
            )
        )
        try context.saveRoutineChanges()

        try RoutineManagementService(context: context).deleteRoutine(id: routine.id)

        XCTAssertThrowsError(try context.routine(id: routine.id)) { error in
            XCTAssertEqual(error as? PersistenceError, .routineNotFound(routine.id))
        }
        XCTAssertTrue(try fetchCompletions(in: context).isEmpty)
        XCTAssertTrue(try fetchRoutines(in: context, groupID: group.id).isEmpty)
    }

    func testDeleteRoutineNormalizesRemainingSiblingSortOrders() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let first = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let second = try insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 3),
            group: group,
            into: context
        )
        let third = try insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 7),
            group: group,
            into: context
        )

        try RoutineManagementService(context: context).deleteRoutine(id: second.id)

        let routines = try fetchRoutines(in: context, groupID: group.id)
        XCTAssertEqual(routines.map(\.id), [first.id, third.id])
        XCTAssertEqual(routines.map(\.sortOrder), [0, 1])
    }

    func testMoveRoutineWithinGroupPersistsRequestedOrderAndContiguousSortOrders() throws {
        let context = try makeContext()
        let group = try insertGroup(name: "Health", sortOrder: 0, into: context)
        let first = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let second = try insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        let third = try insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 2),
            group: group,
            into: context
        )

        try RoutineManagementService(context: context).moveRoutine(id: third.id, toGroupID: group.id, at: 1)

        let routines = try fetchRoutines(in: context, groupID: group.id)
        XCTAssertEqual(routines.map(\.id), [first.id, third.id, second.id])
        XCTAssertEqual(routines.map(\.sortOrder), [0, 1, 2])
        XCTAssertTrue(
            routines.allSatisfy {
                $0.groupID == group.id && $0.group?.id == group.id
            }
        )
    }

    func testMoveRoutineAcrossGroupsUpdatesRelationshipDestinationPositionAndNormalizedSortOrders() throws {
        let context = try makeContext()
        let setup = try makeCrossGroupMoveSetup(in: context)

        try RoutineManagementService(context: context).moveRoutine(
            id: setup.movedRoutine.id,
            toGroupID: setup.destinationGroup.id,
            at: 1
        )

        try assertCrossGroupMoveState(
            in: context,
            setup: setup
        )
    }
}

extension RoutineManagementRoutineMutationTests {
    fileprivate struct UpdateRoutineSetup {
        let sourceGroup: RoutineGroup
        let destinationGroup: RoutineGroup
        let routine: Routine
        let destinationRoutine: Routine
    }

    fileprivate struct CrossGroupMoveSetup {
        let sourceGroup: RoutineGroup
        let destinationGroup: RoutineGroup
        let movedRoutine: Routine
        let sourceSibling: Routine
        let destinationFirst: Routine
        let destinationSecond: Routine
    }

    fileprivate func makeUpdateRoutineSetup(in context: ModelContext) throws -> UpdateRoutineSetup {
        let sourceGroup = try insertGroup(name: "Source", sortOrder: 0, into: context)
        let destinationGroup = try insertGroup(name: "Destination", sortOrder: 1, into: context)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Morning Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: sourceGroup,
            into: context
        )
        _ = try insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 2, period: .weekly, sortOrder: 1),
            group: sourceGroup,
            into: context
        )
        let destinationRoutine = try insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 4, period: .weekly, sortOrder: 0),
            group: destinationGroup,
            into: context
        )

        return UpdateRoutineSetup(
            sourceGroup: sourceGroup,
            destinationGroup: destinationGroup,
            routine: routine,
            destinationRoutine: destinationRoutine
        )
    }

    fileprivate func assertUpdatedRoutineState(
        in context: ModelContext,
        setup: UpdateRoutineSetup,
        updatedAt: Date
    ) throws {
        let updatedRoutine = try context.routine(id: setup.routine.id)
        let sourceRoutines = try fetchRoutines(in: context, groupID: setup.sourceGroup.id)
        let destinationRoutines = try fetchRoutines(in: context, groupID: setup.destinationGroup.id)

        XCTAssertEqual(updatedRoutine.name, "Evening Walk")
        XCTAssertEqual(updatedRoutine.targetCount, 6)
        XCTAssertEqual(updatedRoutine.period, .monthly)
        XCTAssertEqual(updatedRoutine.groupID, setup.destinationGroup.id)
        XCTAssertEqual(updatedRoutine.group?.id, setup.destinationGroup.id)
        XCTAssertEqual(updatedRoutine.updatedAt, updatedAt)

        XCTAssertEqual(sourceRoutines.map(\.name), ["Read"])
        XCTAssertEqual(sourceRoutines.map(\.sortOrder), [0])
        XCTAssertEqual(destinationRoutines.map(\.id), [setup.destinationRoutine.id, setup.routine.id])
        XCTAssertEqual(destinationRoutines.map(\.sortOrder), [0, 1])
        XCTAssertTrue(
            destinationRoutines.allSatisfy {
                $0.groupID == setup.destinationGroup.id && $0.group?.id == setup.destinationGroup.id
            }
        )
    }

    fileprivate func makeCrossGroupMoveSetup(in context: ModelContext) throws -> CrossGroupMoveSetup {
        let sourceGroup = try insertGroup(name: "Source", sortOrder: 0, into: context)
        let destinationGroup = try insertGroup(name: "Destination", sortOrder: 1, into: context)
        let movedRoutine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: sourceGroup,
            into: context
        )
        let sourceSibling = try insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 1),
            group: sourceGroup,
            into: context
        )
        let destinationFirst = try insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 0),
            group: destinationGroup,
            into: context
        )
        let destinationSecond = try insertRoutine(
            seed: RoutineTestSeed(name: "Stretch", targetCount: 2, period: .weekly, sortOrder: 1),
            group: destinationGroup,
            into: context
        )

        return CrossGroupMoveSetup(
            sourceGroup: sourceGroup,
            destinationGroup: destinationGroup,
            movedRoutine: movedRoutine,
            sourceSibling: sourceSibling,
            destinationFirst: destinationFirst,
            destinationSecond: destinationSecond
        )
    }

    fileprivate func assertCrossGroupMoveState(
        in context: ModelContext,
        setup: CrossGroupMoveSetup
    ) throws {
        let refreshedRoutine = try context.routine(id: setup.movedRoutine.id)
        let sourceRoutines = try fetchRoutines(in: context, groupID: setup.sourceGroup.id)
        let destinationRoutines = try fetchRoutines(in: context, groupID: setup.destinationGroup.id)

        XCTAssertEqual(refreshedRoutine.groupID, setup.destinationGroup.id)
        XCTAssertEqual(refreshedRoutine.group?.id, setup.destinationGroup.id)
        XCTAssertEqual(sourceRoutines.map(\.id), [setup.sourceSibling.id])
        XCTAssertEqual(sourceRoutines.map(\.sortOrder), [0])
        XCTAssertEqual(
            destinationRoutines.map(\.id),
            [setup.destinationFirst.id, setup.movedRoutine.id, setup.destinationSecond.id]
        )
        XCTAssertEqual(destinationRoutines.map(\.sortOrder), [0, 1, 2])
        XCTAssertTrue(
            destinationRoutines.allSatisfy {
                $0.groupID == setup.destinationGroup.id && $0.group?.id == setup.destinationGroup.id
            }
        )
    }
}
