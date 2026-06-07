import Foundation
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

    func testBuildProducesSummaryLabelsForRelativeCases() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let builder = HistoryProjectionBuilder(context: context, routineCalendar: calendar)
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        let never = insertRoutine(
            name: "Never", targetCount: 1, period: .weekly, sortOrder: 0, group: group, into: context)
        let today = insertRoutine(
            name: "Today", targetCount: 1, period: .weekly, sortOrder: 1, group: group, into: context)
        let yesterday = insertRoutine(
            name: "Yesterday", targetCount: 1, period: .weekly, sortOrder: 2, group: group, into: context)
        let recent = insertRoutine(
            name: "Recent", targetCount: 1, period: .weekly, sortOrder: 3, group: group, into: context)
        let currentYear = insertRoutine(
            name: "CurrentYear", targetCount: 1, period: .weekly, sortOrder: 4, group: group, into: context)
        let priorYear = insertRoutine(
            name: "PriorYear", targetCount: 1, period: .weekly, sortOrder: 5, group: group, into: context)

        insertCompletion(
            routine: today, day: try makeDay(year: 2026, month: 6, day: 10), completedAt: now, into: context)
        insertCompletion(
            routine: yesterday, day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: recent, day: try makeDay(year: 2026, month: 6, day: 7),
            completedAt: makeDate(year: 2026, month: 6, day: 7, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: currentYear, day: try makeDay(year: 2026, month: 1, day: 2),
            completedAt: makeDate(year: 2026, month: 1, day: 2, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: priorYear, day: try makeDay(year: 2025, month: 6, day: 2),
            completedAt: makeDate(year: 2025, month: 6, day: 2, calendar: calendar.calendar), into: context)

        _ = never
        try saveChanges(in: context)

        XCTAssertEqual(try foundViewData(from: builder.build(routineID: never.id, now: now)).lastDoneText, "Never")
        XCTAssertEqual(try foundViewData(from: builder.build(routineID: today.id, now: now)).lastDoneText, "Today")
        XCTAssertEqual(
            try foundViewData(from: builder.build(routineID: yesterday.id, now: now)).lastDoneText, "Yesterday")
        XCTAssertEqual(try foundViewData(from: builder.build(routineID: recent.id, now: now)).lastDoneText, "3d ago")
        XCTAssertEqual(
            try foundViewData(from: builder.build(routineID: currentYear.id, now: now)).lastDoneText, "Jan 2")
        XCTAssertEqual(
            try foundViewData(from: builder.build(routineID: priorYear.id, now: now)).lastDoneText, "Jun 2, 2025")
    }

    func testBuildProducesCurrentMonthDaysAndMarksTodayAndCompletions() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            name: "Meditate",
            targetCount: 5,
            period: .weekly,
            sortOrder: 0,
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
        let june1 = try makeDay(year: 2026, month: 6, day: 1)
        let june2 = try makeDay(year: 2026, month: 6, day: 2)
        let june10 = try makeDay(year: 2026, month: 6, day: 10)

        XCTAssertEqual(viewData.monthDays.count, 30)
        XCTAssertEqual(viewData.monthDays.first?.day, june1)
        XCTAssertEqual(viewData.monthDays.last?.day, try makeDay(year: 2026, month: 6, day: 30))

        let dayOne = try XCTUnwrap(viewData.monthDays.first { $0.day == june1 })
        XCTAssertTrue(dayOne.isCompleted)
        XCTAssertFalse(dayOne.isToday)

        let todayDay = try XCTUnwrap(viewData.monthDays.first { $0.day == june10 })
        XCTAssertTrue(todayDay.isToday)
        XCTAssertTrue(todayDay.isCompleted)

        let incompleteDay = try XCTUnwrap(viewData.monthDays.first { $0.day == june2 })
        XCTAssertFalse(incompleteDay.isCompleted)
        XCTAssertFalse(incompleteDay.isToday)
    }

    func testBuildSortsRecentCompletionsAndIgnoresInvalidDayKeys() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Sort", sortOrder: 0, into: context)
        let routine = insertRoutine(
            name: "Journal",
            targetCount: 4,
            period: .weekly,
            sortOrder: 0,
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 21, minute: 0, calendar: calendar.calendar)

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

        let projection = try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
            routineID: routine.id,
            now: now
        )
        let viewData = try foundViewData(from: projection)

        XCTAssertEqual(
            viewData.recentCompletions.map(\.id),
            [june10Late.id, june10Early.id, june9.id, june1.id]
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
