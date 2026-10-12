import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class HistoryMonthNavigationProjectionTests: ProjectionBuilderTestCase {
    func testPickerYearsForNewRoutineSpanFiveYearsBeforeCurrentYear() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar)

        let viewData = try buildViewData(context: context, routine: routine, calendar: calendar, now: now)

        XCTAssertEqual(viewData.pickerYears, 2021...2026)
    }

    func testPickerYearsStartAtEarliestCompletionYear() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar)
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2017, month: 3, day: 4),
            completedAt: makeDate(year: 2017, month: 3, day: 4, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2025, month: 3, day: 4),
            completedAt: makeDate(year: 2025, month: 3, day: 4, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try buildViewData(context: context, routine: routine, calendar: calendar, now: now)

        XCTAssertEqual(viewData.pickerYears, 2017...2026)
    }

    func testPickerYearsStartAtCreationYearWhenOlderThanFiveYears() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let createdAt = makeDate(year: 2019, month: 6, day: 1, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: createdAt, calendar: calendar)

        let viewData = try buildViewData(context: context, routine: routine, calendar: calendar, now: now)

        XCTAssertEqual(viewData.pickerYears, 2019...2026)
    }

    func testPickerYearsDoNotDependOnDisplayedMonth() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar)

        let viewData = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2022, month: 2, day: 1)
        )

        XCTAssertEqual(viewData.pickerYears, 2021...2026)
        XCTAssertFalse(viewData.isDisplayingCurrentMonth)
    }

    func testIsDisplayingCurrentMonthIsTrueOnlyForTodaysMonth() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar)

        let defaultMonth = try buildViewData(context: context, routine: routine, calendar: calendar, now: now)
        let sameMonthDifferentDay = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2026, month: 10, day: 1)
        )
        let previousMonth = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2026, month: 9, day: 30)
        )
        let sameMonthPriorYear = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 10, day: 12)
        )

        XCTAssertTrue(defaultMonth.isDisplayingCurrentMonth)
        XCTAssertTrue(sameMonthDifferentDay.isDisplayingCurrentMonth)
        XCTAssertFalse(previousMonth.isDisplayingCurrentMonth)
        XCTAssertFalse(sameMonthPriorYear.isDisplayingCurrentMonth)
    }

    func testPastDisplayedMonthMarksOnlyItsCompletionsAndNoToday() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar)
        let completedDays = [(2025, 8, 3), (2025, 8, 4), (2025, 8, 20), (2025, 9, 1), (2026, 10, 12)]
        for (year, month, day) in completedDays {
            insertCompletion(
                routine: routine,
                day: try makeDay(year: year, month: month, day: day),
                completedAt: makeDate(year: year, month: month, day: day, calendar: calendar.calendar),
                into: context
            )
        }
        try saveChanges(in: context)

        let viewData = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 8, day: 1)
        )

        let days = viewData.weeks.flatMap(\.days)
        XCTAssertEqual(days.count, 31)
        XCTAssertEqual(days.filter(\.isCompleted).map(\.day.key), ["2025-08-03", "2025-08-04", "2025-08-20"])
        XCTAssertTrue(days.allSatisfy { $0.isToday == false })
        XCTAssertTrue(days.allSatisfy { $0.isFuture == false })
        XCTAssertEqual(viewData.recentCompletions.count, 5)
        XCTAssertEqual(viewData.progress.completedCount, 1)
        XCTAssertEqual(viewData.progress.lastCompletedDay, try makeDay(year: 2026, month: 10, day: 12))
    }

    func testPastDisplayedMonthComputesWeeklyGoalMetForItsWeeks() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar, targetCount: 2, period: .weekly)
        for day in [5, 7, 20] {
            insertCompletion(
                routine: routine,
                day: try makeDay(year: 2025, month: 8, day: day),
                completedAt: makeDate(year: 2025, month: 8, day: day, calendar: calendar.calendar),
                into: context
            )
        }
        try saveChanges(in: context)

        let viewData = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 8, day: 1)
        )

        let goalMetFirstDays = viewData.weeks.filter(\.isGoalMet).compactMap { $0.days.first?.day.key }
        XCTAssertEqual(goalMetFirstDays, ["2025-08-04"])
    }

    func testPastDisplayedMonthComputesMonthlyGoalMetForWholeMonth() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar, targetCount: 2, period: .monthly)
        for day in [5, 20] {
            insertCompletion(
                routine: routine,
                day: try makeDay(year: 2025, month: 8, day: day),
                completedAt: makeDate(year: 2025, month: 8, day: day, calendar: calendar.calendar),
                into: context
            )
        }
        try saveChanges(in: context)

        let augustViewData = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 8, day: 1)
        )
        let septemberViewData = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 9, day: 1)
        )

        XCTAssertTrue(augustViewData.weeks.allSatisfy(\.isGoalMet))
        XCTAssertTrue(septemberViewData.weeks.allSatisfy { $0.isGoalMet == false })
    }

    func testSummaryAndRecentCompletionsIgnoreDisplayedMonth() throws {
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 10, day: 12, hour: 9, minute: 0, calendar: calendar.calendar)
        let (context, routine) = try makeRoutine(createdAt: now, calendar: calendar, targetCount: 5, period: .weekly)
        for day in [5, 6, 12] {
            insertCompletion(
                routine: routine,
                day: try makeDay(year: 2026, month: 10, day: day),
                completedAt: makeDate(year: 2026, month: 10, day: day, calendar: calendar.calendar),
                into: context
            )
        }
        try saveChanges(in: context)

        let current = try buildViewData(context: context, routine: routine, calendar: calendar, now: now)
        let past = try buildViewData(
            context: context,
            routine: routine,
            calendar: calendar,
            now: now,
            displayedMonth: try makeDay(year: 2025, month: 1, day: 1)
        )

        XCTAssertEqual(past.progress, current.progress)
        XCTAssertEqual(past.recentCompletions, current.recentCompletions)
        XCTAssertEqual(past.streakSummaryText, current.streakSummaryText)
        XCTAssertEqual(past.lastDoneText, current.lastDoneText)
    }

    private func foundViewData(from projection: RoutineHistoryProjection) throws -> RoutineHistoryViewData {
        guard case .found(let viewData) = projection else {
            XCTFail("Expected found projection.")
            throw XCTSkip("Expected found projection.")
        }

        return viewData
    }

    private func makeRoutine(
        createdAt: Date,
        calendar: RoutineCalendar,
        targetCount: Int = 3,
        period: RoutinePeriod = .weekly
    ) throws -> (ModelContext, Routine) {
        let context = try makeContext()
        let group = insertGroup(name: "History", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: targetCount, period: period, sortOrder: 0),
            group: group,
            createdAt: createdAt,
            into: context
        )
        try saveChanges(in: context)
        return (context, routine)
    }

    private func buildViewData(
        context: ModelContext,
        routine: Routine,
        calendar: RoutineCalendar,
        now: Date,
        displayedMonth: RoutineDay? = nil
    ) throws -> RoutineHistoryViewData {
        try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                displayedMonth: displayedMonth,
                now: now
            )
        )
    }
}
