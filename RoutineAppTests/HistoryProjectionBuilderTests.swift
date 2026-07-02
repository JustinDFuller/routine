import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class HistoryProjectionBuilderTests: ProjectionBuilderTestCase {
    func testBuildReturnsNotFoundForMissingRoutineID() throws {
        let context = try makeContext()
        let projection = try HistoryProjectionBuilder(context: context).build(routineID: UUID())

        guard case .notFound = projection else {
            return XCTFail("Expected notFound projection.")
        }
    }

    func testBuildUsingProvidedModelsSelectsRequestedRoutineAndItsCompletions() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let firstRoutine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let secondRoutine = insertRoutine(
            seed: RoutineTestSeed(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: firstRoutine,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )
        let selectedCompletion = insertCompletion(
            routine: secondRoutine,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, hour: 7, minute: 0, calendar: calendar.calendar),
            into: context
        )

        let projection = HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
            routineID: secondRoutine.id,
            routines: [firstRoutine, secondRoutine],
            completions: secondRoutine.completions + firstRoutine.completions,
            now: now
        )
        let viewData = try foundViewData(from: projection)

        XCTAssertEqual(viewData.routineName, "Morning yoga")
        XCTAssertEqual(viewData.frequencySummary, "5 per week")
        XCTAssertEqual(viewData.recentCompletions.map(\.id), [selectedCompletion.id])
    }

    func testBuildUsingProvidedModelsReturnsNotFoundWhenRoutineIsMissing() throws {
        let context = try makeContext()
        let projection = HistoryProjectionBuilder(context: context).build(
            routineID: UUID(),
            routines: [],
            completions: []
        )

        guard case .notFound = projection else {
            return XCTFail("Expected notFound projection.")
        }
    }

    func testBuildUsingProvidedModelsProducesCurrentPeriodSummaryFields() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)
        let june8 = try makeDay(year: 2026, month: 6, day: 8)
        let june10 = try makeDay(year: 2026, month: 6, day: 10)

        let june8Completion = insertCompletion(
            routine: routine,
            day: june8,
            completedAt: makeDate(year: 2026, month: 6, day: 8, hour: 9, minute: 0, calendar: calendar.calendar),
            into: context
        )
        let june10Completion = insertCompletion(
            routine: routine,
            day: june10,
            completedAt: now,
            into: context
        )

        let viewData = try foundViewData(
            from: HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                routines: [routine],
                completions: [june8Completion, june10Completion],
                now: now
            )
        )

        XCTAssertEqual(viewData.frequencySummary, "5 per week")
        XCTAssertEqual(viewData.progress.completedCount, 2)
        XCTAssertTrue(viewData.progress.isCompletedToday)
        XCTAssertEqual(viewData.lastDoneText, "Today")
        XCTAssertNil(viewData.streakSummaryText)
        XCTAssertNil(viewData.streakAccessibilityText)
    }

    func testBuildProducesStreakSummaryAndAccessibilityTextForConsecutiveMetWeeks() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Streaky", targetCount: 2, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        // Week -1: Jun 1 - Jun 7 (met)
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 2),
            completedAt: makeDate(year: 2026, month: 6, day: 2, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 3),
            completedAt: makeDate(year: 2026, month: 6, day: 3, calendar: calendar.calendar),
            into: context
        )
        // Week -2: May 25 - May 31 (met)
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 5, day: 26),
            completedAt: makeDate(year: 2026, month: 5, day: 26, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 5, day: 27),
            completedAt: makeDate(year: 2026, month: 5, day: 27, calendar: calendar.calendar),
            into: context
        )
        // Week -3: May 18 - May 24 (missed, no completions)

        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        XCTAssertEqual(viewData.streakSummaryText, "2 weeks in a row")
        XCTAssertEqual(viewData.streakAccessibilityText, "2 weeks in a row")
    }

    func testBuildUsingProvidedModelsRefreshesAfterCompletionRemoval() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)
        let june10 = try makeDay(year: 2026, month: 6, day: 10)
        let completion = insertCompletion(
            routine: routine,
            day: june10,
            completedAt: now,
            into: context
        )
        let builder = HistoryProjectionBuilder(context: context, routineCalendar: calendar)

        let beforeRemoval = try foundViewData(
            from: builder.build(
                routineID: routine.id,
                routines: [routine],
                completions: [completion],
                now: now
            )
        )
        let afterRemoval = try foundViewData(
            from: builder.build(
                routineID: routine.id,
                routines: [routine],
                completions: [],
                now: now
            )
        )

        XCTAssertEqual(beforeRemoval.progress.completedCount, 1)
        XCTAssertTrue(beforeRemoval.weeks.flatMap(\.days).contains { $0.day == june10 && $0.isCompleted })
        XCTAssertEqual(afterRemoval.progress.completedCount, 0)
        XCTAssertEqual(afterRemoval.lastDoneText, "Never")
        XCTAssertTrue(afterRemoval.recentCompletions.isEmpty)
        XCTAssertTrue(afterRemoval.weeks.flatMap(\.days).contains { $0.day == june10 && $0.isCompleted == false })
    }

    func testBuildProducesSummaryLabelsForRelativeCases() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let builder = HistoryProjectionBuilder(context: context, routineCalendar: calendar)
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)
        let routineIDs = try seedRelativeSummaryScenario(in: context, calendar: calendar, now: now)

        try assertLastDoneText(builder: builder, routineID: routineIDs.never, now: now, expected: "Never")
        try assertLastDoneText(builder: builder, routineID: routineIDs.today, now: now, expected: "Today")
        try assertLastDoneText(builder: builder, routineID: routineIDs.yesterday, now: now, expected: "Yesterday")
        try assertLastDoneText(builder: builder, routineID: routineIDs.recent, now: now, expected: "3d ago")
        try assertLastDoneText(builder: builder, routineID: routineIDs.currentYear, now: now, expected: "Jan 2")
        try assertLastDoneText(builder: builder, routineID: routineIDs.priorYear, now: now, expected: "Jun 2, 2025")
    }

    func testBuildProducesCurrentMonthDaysAndMarksTodayAndCompletions() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Meditate", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 1),
            completedAt: makeDate(year: 2026, month: 6, day: 1, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )

        try saveChanges(in: context)

        let projection = try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
            routineID: routine.id,
            now: now
        )
        let viewData = try foundViewData(from: projection)
        let monthDays = viewData.weeks.flatMap(\.days)
        let june1 = try makeDay(year: 2026, month: 6, day: 1)
        let june2 = try makeDay(year: 2026, month: 6, day: 2)
        let june10 = try makeDay(year: 2026, month: 6, day: 10)

        XCTAssertEqual(monthDays.count, 30)
        XCTAssertEqual(monthDays.first?.day, june1)
        XCTAssertEqual(monthDays.last?.day, try makeDay(year: 2026, month: 6, day: 30))

        let dayOne = try XCTUnwrap(monthDays.first { $0.day == june1 })
        XCTAssertTrue(dayOne.isCompleted)
        XCTAssertFalse(dayOne.isToday)

        let todayDay = try XCTUnwrap(monthDays.first { $0.day == june10 })
        XCTAssertTrue(todayDay.isToday)
        XCTAssertTrue(todayDay.isCompleted)

        let incompleteDay = try XCTUnwrap(monthDays.first { $0.day == june2 })
        XCTAssertFalse(incompleteDay.isCompleted)
        XCTAssertFalse(incompleteDay.isToday)
    }

    func testBuildMarksFutureDaysAndLeavesPastAndTodayUnmarked() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Meditate", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        let projection = try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
            routineID: routine.id,
            now: now
        )
        let viewData = try foundViewData(from: projection)
        let monthDays = viewData.weeks.flatMap(\.days)
        let june9 = try makeDay(year: 2026, month: 6, day: 9)
        let june10 = try makeDay(year: 2026, month: 6, day: 10)
        let june11 = try makeDay(year: 2026, month: 6, day: 11)

        let pastDay = try XCTUnwrap(monthDays.first { $0.day == june9 })
        let todayDay = try XCTUnwrap(monthDays.first { $0.day == june10 })
        let futureDay = try XCTUnwrap(monthDays.first { $0.day == june11 })

        XCTAssertFalse(pastDay.isFuture)
        XCTAssertFalse(todayDay.isFuture)
        XCTAssertTrue(futureDay.isFuture)
    }

    func testBuildSortsRecentCompletionsAndIgnoresInvalidDayKeys() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 21, minute: 0, calendar: calendar.calendar)
        let scenario = try seedRecentCompletionScenario(in: context, calendar: calendar)

        let projection = try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
            routineID: scenario.routineID,
            now: now
        )
        let viewData = try foundViewData(from: projection)

        XCTAssertEqual(
            viewData.recentCompletions.map(\.id),
            [scenario.june10LateID, scenario.june10EarlyID, scenario.june9ID, scenario.june1ID]
        )
        XCTAssertEqual(viewData.progress.completedCount, 2)
        XCTAssertEqual(viewData.recentCompletions.first?.relativeText, "Today")
        XCTAssertEqual(viewData.recentCompletions[2].relativeText, "Yesterday")
        XCTAssertNil(viewData.recentCompletions.last?.relativeText)
    }

    func testBuildMapsFetchFailuresToPersistenceError() throws {
        let context = try makeContext()
        let originalFetch = RoutinePersistenceFetchExecutor.fetchRoutines
        defer { RoutinePersistenceFetchExecutor.fetchRoutines = originalFetch }

        RoutinePersistenceFetchExecutor.fetchRoutines = { _, _ in
            throw SimulatedProjectionFetchFailure()
        }

        XCTAssertThrowsError(try HistoryProjectionBuilder(context: context).build(routineID: UUID())) { error in
            XCTAssertEqual(
                error as? PersistenceError,
                .fetchFailed("simulated projection fetch failure")
            )
        }
    }

    private func foundViewData(from projection: RoutineHistoryProjection) throws -> RoutineHistoryViewData {
        guard case .found(let viewData) = projection else {
            throw XCTSkip("Expected found projection.")
        }

        return viewData
    }
}

extension HistoryProjectionBuilderTests {
    fileprivate struct RelativeSummaryRoutineIDs {
        let never: UUID
        let today: UUID
        let yesterday: UUID
        let recent: UUID
        let currentYear: UUID
        let priorYear: UUID
    }

    fileprivate struct RelativeSummaryRoutines {
        let never: Routine
        let today: Routine
        let yesterday: Routine
        let recent: Routine
        let currentYear: Routine
        let priorYear: Routine
    }

    fileprivate struct RecentCompletionScenario {
        let routineID: UUID
        let june10LateID: UUID
        let june10EarlyID: UUID
        let june9ID: UUID
        let june1ID: UUID
    }

    fileprivate func seedRelativeSummaryScenario(
        in context: ModelContext,
        calendar: RoutineCalendar,
        now: Date
    ) throws -> RelativeSummaryRoutineIDs {
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let routines = insertRelativeSummaryRoutines(in: context, group: group)

        try insertRelativeSummaryCompletions(
            routines: routines,
            calendar: calendar,
            now: now,
            into: context
        )

        try saveChanges(in: context)

        return RelativeSummaryRoutineIDs(
            never: routines.never.id,
            today: routines.today.id,
            yesterday: routines.yesterday.id,
            recent: routines.recent.id,
            currentYear: routines.currentYear.id,
            priorYear: routines.priorYear.id
        )
    }

    fileprivate func insertRelativeSummaryRoutines(
        in context: ModelContext,
        group: RoutineGroup
    ) -> RelativeSummaryRoutines {
        RelativeSummaryRoutines(
            never: insertRoutine(
                seed: RoutineTestSeed(name: "Never", targetCount: 1, period: .weekly, sortOrder: 0),
                group: group,
                into: context
            ),
            today: insertRoutine(
                seed: RoutineTestSeed(name: "Today", targetCount: 1, period: .weekly, sortOrder: 1),
                group: group,
                into: context
            ),
            yesterday: insertRoutine(
                seed: RoutineTestSeed(name: "Yesterday", targetCount: 1, period: .weekly, sortOrder: 2),
                group: group,
                into: context
            ),
            recent: insertRoutine(
                seed: RoutineTestSeed(name: "Recent", targetCount: 1, period: .weekly, sortOrder: 3),
                group: group,
                into: context
            ),
            currentYear: insertRoutine(
                seed: RoutineTestSeed(name: "CurrentYear", targetCount: 1, period: .weekly, sortOrder: 4),
                group: group,
                into: context
            ),
            priorYear: insertRoutine(
                seed: RoutineTestSeed(name: "PriorYear", targetCount: 1, period: .weekly, sortOrder: 5),
                group: group,
                into: context
            )
        )
    }

    fileprivate func insertRelativeSummaryCompletions(
        routines: RelativeSummaryRoutines,
        calendar: RoutineCalendar,
        now: Date,
        into context: ModelContext
    ) throws {
        insertCompletion(
            routine: routines.today,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )
        insertCompletion(
            routine: routines.yesterday,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routines.recent,
            day: try makeDay(year: 2026, month: 6, day: 7),
            completedAt: makeDate(year: 2026, month: 6, day: 7, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routines.currentYear,
            day: try makeDay(year: 2026, month: 1, day: 2),
            completedAt: makeDate(year: 2026, month: 1, day: 2, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routines.priorYear,
            day: try makeDay(year: 2025, month: 6, day: 2),
            completedAt: makeDate(year: 2025, month: 6, day: 2, calendar: calendar.calendar),
            into: context
        )
    }

    fileprivate func assertLastDoneText(
        builder: HistoryProjectionBuilder,
        routineID: UUID,
        now: Date,
        expected: String
    ) throws {
        XCTAssertEqual(
            try foundViewData(from: builder.build(routineID: routineID, now: now)).lastDoneText,
            expected
        )
    }

    fileprivate func seedRecentCompletionScenario(
        in context: ModelContext,
        calendar: RoutineCalendar
    ) throws -> RecentCompletionScenario {
        let group = insertGroup(name: "Sort", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Journal", targetCount: 4, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )

        let june10Late = try insertCompletion(
            routine: routine,
            dayKey: "2026-06-10",
            routineDayKey: "\(routine.id.uuidString)|2026-06-10|late",
            completedAt: makeDate(year: 2026, month: 6, day: 10, hour: 20, minute: 0, calendar: calendar.calendar),
            into: context
        )
        let june10Early = try insertCompletion(
            routine: routine,
            dayKey: "2026-06-10",
            routineDayKey: "\(routine.id.uuidString)|2026-06-10|early",
            completedAt: makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar),
            into: context
        )
        let june9 = insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, hour: 12, minute: 0, calendar: calendar.calendar),
            into: context
        )
        let june1 = insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 1),
            completedAt: makeDate(year: 2026, month: 6, day: 1, hour: 12, minute: 0, calendar: calendar.calendar),
            into: context
        )
        _ = try insertCompletion(
            routine: routine,
            dayKey: "invalid-day-key",
            completedAt: makeDate(year: 2026, month: 6, day: 11, hour: 12, minute: 0, calendar: calendar.calendar),
            into: context
        )

        try saveChanges(in: context)

        return RecentCompletionScenario(
            routineID: routine.id,
            june10LateID: june10Late.id,
            june10EarlyID: june10Early.id,
            june9ID: june9.id,
            june1ID: june1.id
        )
    }
}
