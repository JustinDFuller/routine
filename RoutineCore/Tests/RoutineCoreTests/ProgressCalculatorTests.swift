import Foundation
import XCTest

@testable import RoutineCore

final class ProgressCalculatorTests: XCTestCase {
    func testWeeklyProgressCountsOnlyCurrentConfiguredMondayStartWeek() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 2)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 8)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9)))

        let completions = calculator.completionsInCurrentPeriod(
            period: .weekly,
            completionDays: completionDays,
            today: today
        )

        var expectedCompletions: [RoutineDay] = []
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 2)))
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4)))
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 8)))

        XCTAssertEqual(completions, expectedCompletions)
    }

    func testWeeklyProgressCountsOnlyCurrentConfiguredSundayStartWeek() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 1))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 2)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 8)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9)))

        let completions = calculator.completionsInCurrentPeriod(
            period: .weekly,
            completionDays: completionDays,
            today: today
        )

        var expectedCompletions: [RoutineDay] = []
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 2)))
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4)))

        XCTAssertEqual(completions, expectedCompletions)
    }

    func testMonthlyProgressCountsOnlyCurrentCalendarMonth() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 15))
        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 31)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 1)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 15)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 7, day: 1)))

        var expectedCompletions: [RoutineDay] = []
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 1)))
        expectedCompletions.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 15)))

        XCTAssertEqual(
            calculator.completionsInCurrentPeriod(period: .monthly, completionDays: completionDays, today: today),
            expectedCompletions
        )
    }

    func testDuplicateCompletionDaysDoNotInflateCounts() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let duplicateDay = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        let progress = calculator.progress(
            period: .weekly,
            targetCount: 3,
            completionDays: [duplicateDay, duplicateDay],
            today: today
        )

        XCTAssertEqual(progress.completedCount, 1)
    }

    func testIsCompletedTodayIsTrueOnlyWhenTodayIsPresent() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let otherDay = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 3))

        XCTAssertTrue(
            calculator.progress(
                period: .weekly,
                targetCount: 1,
                completionDays: [today],
                today: today
            ).isCompletedToday
        )
        XCTAssertFalse(
            calculator.progress(
                period: .weekly,
                targetCount: 1,
                completionDays: [otherDay],
                today: today
            ).isCompletedToday
        )
    }

    func testLastCompletedDayUsesAllCompletionDays() throws {
        let calculator = ProgressCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let latestHistoricalDay = try XCTUnwrap(RoutineDay(year: 2025, month: 7, day: 1))

        let progress = calculator.progress(
            period: .weekly,
            targetCount: 2,
            completionDays: [try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28)), latestHistoricalDay],
            today: today
        )

        XCTAssertEqual(progress.lastCompletedDay, latestHistoricalDay)
    }

    func testRemainingCountFloorsAtZeroAndOverTargetBehaviorIsPreserved() {
        let progress = RoutineProgress(
            period: .weekly,
            targetCount: 2,
            completedCount: 4,
            isCompletedToday: true,
            lastCompletedDay: nil
        )

        XCTAssertEqual(progress.remainingCount, 0)
        XCTAssertTrue(progress.isTargetMet)
        XCTAssertTrue(progress.isOverTarget)
    }

    func testFillRatioCapsAtOneAndReturnsZeroForNonPositiveTargets() {
        XCTAssertEqual(
            RoutineProgress(
                period: .monthly,
                targetCount: 3,
                completedCount: 5,
                isCompletedToday: false,
                lastCompletedDay: nil
            ).fillRatio,
            1
        )

        XCTAssertEqual(
            RoutineProgress(
                period: .monthly,
                targetCount: 0,
                completedCount: 5,
                isCompletedToday: false,
                lastCompletedDay: nil
            ).fillRatio,
            0
        )
    }

    private func testRoutineCalendar(firstWeekday: Int = 2) -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = firstWeekday
        return RoutineCalendar(calendar: calendar)
    }
}
