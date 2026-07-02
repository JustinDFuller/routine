import Foundation
import XCTest

@testable import RoutineCore

final class StreakCalculatorTests: XCTestCase {
    func testWeeklyStreakCountsConsecutiveMetWeeksMondayStart() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 21)))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testWeeklyStreakCountsConsecutiveMetWeeksSundayStart() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 1))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 26)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 19)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20)))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testWeeklyStreakCountsConsecutiveMetWeeksSaturdayStart() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 7))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 25)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 26)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 18)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 19)))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testMonthlyStreakAcrossMonthBoundary() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 7, day: 15))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 10)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 5)))

        let streak = calculator.streak(
            period: .monthly,
            targetCount: 1,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testMonthlyStreakAcrossYearBoundary() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2026, month: 1, day: 15))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 12, day: 20)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 11, day: 5)))

        let streak = calculator.streak(
            period: .monthly,
            targetCount: 1,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testMissedFinalizedPeriodResetsStreakToZero() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        let completionDays = [try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27))]

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 0)
    }

    func testStreakOnlyCountsConsecutiveRunImmediatelyPrecedingToday() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        // Week -1: May 26 - Jun 1 (met)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28)))
        // Week -2: May 19 - May 25 (met)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 21)))
        // Week -3: May 12 - May 18 (missed, only 1 completion)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 13)))
        // Week -4: May 5 - May 11 (met, but further back than the miss)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 6)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 7)))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testCurrentInProgressPeriodExcludedWhenAlreadyMet() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        // Current week: Jun 2 - Jun 8 (already meets target, but must not count)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 3)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4)))
        // Week -1: May 26 - Jun 1 (missed)

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 0)
    }

    func testCurrentInProgressPeriodExcludedWhenNotMet() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        // Current week: Jun 2 - Jun 8 (under target, but must not block prior evaluation)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 3)))
        // Week -1: May 26 - Jun 1 (met)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28)))
        // Week -2: May 19 - May 25 (missed)

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 1)
    }

    func testOverTargetPeriodCountsOnce() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        // Week -1: May 26 - Jun 1 (over target: 5 completions)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 26)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 29)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 30)))
        // Week -2: May 19 - May 25 (exactly met: 2 completions)
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 21)))
        // Week -3: May 12 - May 18 (missed)

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 2)
    }

    func testDuplicateCompletionDaysDedupedBeforeEvaluatingTarget() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let duplicateDay = try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 3,
            completionDays: [duplicateDay, duplicateDay, duplicateDay],
            today: today
        )

        XCTAssertEqual(streak.count, 0)
    }

    func testZeroCompletionsProducesZeroStreak() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 1,
            completionDays: [],
            today: today
        )

        XCTAssertEqual(streak.count, 0)
    }

    func testLoopTerminatesCleanlyAtNaturalStartOfHistory() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        let mondayDays: [(Int, Int)] = [
            (5, 26), (5, 19), (5, 12), (5, 5),
            (4, 28), (4, 21), (4, 14), (4, 7),
            (3, 31), (3, 24)
        ]
        let completionDays = try mondayDays.map { month, day in
            try XCTUnwrap(RoutineDay(year: 2025, month: month, day: day))
        }

        let streak = calculator.streak(
            period: .weekly,
            targetCount: 1,
            completionDays: completionDays,
            today: today
        )

        XCTAssertEqual(streak.count, 10)
    }

    func testNonPositiveTargetCountReturnsZeroImmediately() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        var completionDays: [RoutineDay] = []
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27)))
        completionDays.append(try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20)))

        XCTAssertEqual(
            calculator.streak(period: .weekly, targetCount: 0, completionDays: completionDays, today: today).count,
            0
        )
        XCTAssertEqual(
            calculator.streak(period: .weekly, targetCount: -1, completionDays: completionDays, today: today).count,
            0
        )
    }

    func testHistoricalCorrectionRecomputationLowersStreak() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar(firstWeekday: 2))
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let may27 = try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 27))
        let may28 = try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 28))
        let may20 = try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 20))
        let may21 = try XCTUnwrap(RoutineDay(year: 2025, month: 5, day: 21))

        let beforeRemoval = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: [may27, may28, may20, may21],
            today: today
        )
        let afterRemoval = calculator.streak(
            period: .weekly,
            targetCount: 2,
            completionDays: [may27, may20, may21],
            today: today
        )

        XCTAssertEqual(beforeRemoval.count, 2)
        XCTAssertEqual(afterRemoval.count, 0)
    }

    func testReturnedStreakPeriodMatchesInputPeriodForWeeklyAndMonthly() throws {
        let calculator = StreakCalculator(routineCalendar: testRoutineCalendar())
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))

        XCTAssertEqual(
            calculator.streak(period: .weekly, targetCount: 1, completionDays: [], today: today).period,
            .weekly
        )
        XCTAssertEqual(
            calculator.streak(period: .monthly, targetCount: 1, completionDays: [], today: today).period,
            .monthly
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
