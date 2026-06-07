import Foundation
import XCTest

@testable import Routine

@MainActor
final class ManageProjectionBuilderTests: ProjectionBuilderTestCase {
    func testBuildIncludesOrderedGroupSectionsOrderedRoutineRowsAndEmptyGroups() throws {
        let context = try makeContext()
        _ = insertGroup(name: "Bravo", sortOrder: 1, into: context)
        _ = insertGroup(name: "Alpha", sortOrder: 1, into: context)
        let first = insertGroup(name: "First", sortOrder: 0, into: context)

        _ = insertRoutine(
            name: "Earlier",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: first,
            createdAt: makeDate(year: 2026, month: 6, day: 1, hour: 8),
            into: context
        )
        _ = insertRoutine(
            name: "Later",
            targetCount: 2,
            period: .weekly,
            sortOrder: 0,
            group: first,
            createdAt: makeDate(year: 2026, month: 6, day: 2, hour: 8),
            into: context
        )

        try saveChanges(in: context)

        let viewData = try ManageProjectionBuilder(context: context).build()

        XCTAssertEqual(viewData.sections.map(\.name), ["First", "Alpha", "Bravo"])
        XCTAssertEqual(viewData.sections[0].routines.map(\.name), ["Earlier", "Later"])
        XCTAssertTrue(viewData.sections[1].routines.isEmpty)
        XCTAssertTrue(viewData.sections[2].routines.isEmpty)
        XCTAssertFalse(viewData.isEmpty)
    }

    func testBuildUsesWeeklyAndMonthlySummaryStringsAndIgnoresCompletions() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Manage", sortOrder: 0, into: context)
        let weekly = insertRoutine(
            name: "Walk",
            targetCount: 5,
            period: .weekly,
            sortOrder: 0,
            group: group,
            into: context
        )
        let monthly = insertRoutine(
            name: "Budget",
            targetCount: 2,
            period: .monthly,
            sortOrder: 1,
            group: group,
            into: context
        )

        insertCompletion(
            routine: weekly,
            day: try makeDay(year: 2026, month: 6, day: 8),
            completedAt: makeDate(year: 2026, month: 6, day: 8, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: weekly,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: monthly,
            day: try makeDay(year: 2026, month: 6, day: 1),
            completedAt: makeDate(year: 2026, month: 6, day: 1, calendar: calendar.calendar),
            into: context
        )

        try saveChanges(in: context)

        let viewData = try ManageProjectionBuilder(context: context).build()
        let rowsByName = Dictionary(uniqueKeysWithValues: viewData.sections[0].routines.map { ($0.name, $0) })

        XCTAssertEqual(rowsByName["Walk"]?.summaryText, "5 per week")
        XCTAssertEqual(rowsByName["Budget"]?.summaryText, "2 per month")
    }

    func testBuildPlacesMissingGroupRoutinesInUngroupedSection() throws {
        let context = try makeContext()
        let sourceGroup = insertGroup(name: "Temporary", sortOrder: 0, into: context)
        let routine = insertRoutine(
            name: "Loose Task",
            targetCount: 1,
            period: .weekly,
            sortOrder: 0,
            group: sourceGroup,
            into: context
        )

        guard let missingGroupID = UUID(uuidString: "11111111-2222-3333-4444-555555555555") else {
            preconditionFailure("Expected stable missing-group UUID.")
        }

        routine.group = nil
        routine.groupID = missingGroupID

        try saveChanges(in: context)

        let viewData = try ManageProjectionBuilder(context: context).build()

        XCTAssertEqual(viewData.sections.map(\.name), ["Temporary", "Ungrouped"])
        XCTAssertEqual(viewData.sections[1].routines.map(\.name), ["Loose Task"])
    }

    func testBuildMapsFetchFailuresToPersistenceError() throws {
        let context = try makeContext()
        let originalFetch = RoutinePersistenceFetchExecutor.fetchGroups
        defer { RoutinePersistenceFetchExecutor.fetchGroups = originalFetch }

        RoutinePersistenceFetchExecutor.fetchGroups = { _, _ in
            throw SimulatedProjectionFetchFailure()
        }

        XCTAssertThrowsError(try ManageProjectionBuilder(context: context).build()) { error in
            XCTAssertEqual(
                error as? PersistenceError,
                .fetchFailed("simulated projection fetch failure")
            )
        }
    }
}
