import Foundation
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class ManageProjectionBuilderTests: ProjectionBuilderTestCase {
    func testBuildIncludesOrderedGroupSectionsOrderedRoutineRowsAndEmptyGroups() throws {
        let context = try makeContext()
        let bravo = insertGroup(name: "Bravo", sortOrder: 1, into: context)
        let alpha = insertGroup(name: "Alpha", sortOrder: 1, into: context)
        let first = insertGroup(name: "First", sortOrder: 0, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Earlier", targetCount: 3, period: .weekly, sortOrder: 0),
            group: first,
            createdAt: makeDate(year: 2026, month: 6, day: 1, hour: 8),
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Later", targetCount: 2, period: .weekly, sortOrder: 0),
            group: first,
            createdAt: makeDate(year: 2026, month: 6, day: 2, hour: 8),
            into: context
        )

        try saveChanges(in: context)

        let viewData = try ManageProjectionBuilder(context: context).build()

        XCTAssertEqual(viewData.sections.map(\.name), ["First", "Alpha", "Bravo"])
        XCTAssertEqual(viewData.groupChoices.map(\.name), ["First", "Alpha", "Bravo"])
        XCTAssertEqual(viewData.groupChoices.map(\.id), [first.id, alpha.id, bravo.id])
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
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let monthly = insertRoutine(
            seed: RoutineTestSeed(name: "Budget", targetCount: 2, period: .monthly, sortOrder: 1),
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
        XCTAssertEqual(rowsByName["Walk"]?.targetCount, 5)
        XCTAssertEqual(rowsByName["Walk"]?.period, .weekly)
        XCTAssertEqual(rowsByName["Walk"]?.groupID, group.id)
        XCTAssertEqual(rowsByName["Budget"]?.summaryText, "2 per month")
        XCTAssertEqual(rowsByName["Budget"]?.targetCount, 2)
        XCTAssertEqual(rowsByName["Budget"]?.period, .monthly)
        XCTAssertEqual(rowsByName["Budget"]?.groupID, group.id)
    }

    func testBuildPlacesMissingGroupRoutinesInUngroupedSectionWithoutFallbackGroupChoice() throws {
        let context = try makeContext()
        let sourceGroup = insertGroup(name: "Temporary", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Loose Task", targetCount: 1, period: .weekly, sortOrder: 0),
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
        XCTAssertEqual(viewData.groupChoices.map(\.name), ["Temporary"])
    }

    func testBuildPureOverloadUsesProvidedArrays() throws {
        let context = ModelContext(try RoutineModelContainer.inMemory())
        let builder = ManageProjectionBuilder(context: context)
        let first = RoutineGroup(name: "First", sortOrder: 0)
        let second = RoutineGroup(name: "Second", sortOrder: 1)
        let routine = Routine(
            name: "Walk",
            targetCount: 4,
            period: .weekly,
            sortOrder: 0,
            group: second
        )

        let viewData = builder.build(groups: [first, second], routines: [routine])

        XCTAssertEqual(viewData.groupChoices.map { $0.name }, ["First", "Second"])
        XCTAssertEqual(viewData.sections.map { $0.name }, ["First", "Second"])
        XCTAssertTrue(viewData.sections[0].routines.isEmpty)
        XCTAssertEqual(viewData.sections[1].routines.map { $0.name }, ["Walk"])
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
