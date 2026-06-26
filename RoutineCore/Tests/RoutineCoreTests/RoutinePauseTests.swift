import Foundation
import XCTest

@testable import RoutineCore

final class RoutinePauseTests: XCTestCase {
    private func makeCalendar(firstWeekday: Int = 2) -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = firstWeekday
        return RoutineCalendar(calendar: calendar)
    }

    private func day(_ year: Int, _ month: Int, _ day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    // MARK: - periodStart

    func testPeriodStartForWeeklyReturnsMonday() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let wednesday = try day(2026, 6, 24)
        let result = calendar.periodStart(for: .weekly, containing: wednesday)
        XCTAssertEqual(result, try day(2026, 6, 22))
    }

    func testPeriodStartForMonthlyReturnsFirstOfMonth() throws {
        let calendar = makeCalendar()
        let midMonth = try day(2026, 6, 15)
        let result = calendar.periodStart(for: .monthly, containing: midMonth)
        XCTAssertEqual(result, try day(2026, 6, 1))
    }

    func testPeriodStartReturnsSameDayWhenOnBoundary() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let monday = try day(2026, 6, 22)
        XCTAssertEqual(calendar.periodStart(for: .weekly, containing: monday), monday)

        let firstOfMonth = try day(2026, 6, 1)
        XCTAssertEqual(calendar.periodStart(for: .monthly, containing: firstOfMonth), firstOfMonth)
    }

    // MARK: - advancingPeriodStart

    func testAdvancingPeriodStartByOneWeekMovesToNextMonday() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let monday = try day(2026, 6, 22)
        let result = calendar.advancingPeriodStart(monday, by: 1, period: .weekly)
        XCTAssertEqual(result, try day(2026, 6, 29))
    }

    func testAdvancingPeriodStartByTwoWeeksJumpsTwoMondays() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let monday = try day(2026, 6, 22)
        let result = calendar.advancingPeriodStart(monday, by: 2, period: .weekly)
        XCTAssertEqual(result, try day(2026, 7, 6))
    }

    func testAdvancingPeriodStartByOneMonthMovesToFirstOfNextMonth() throws {
        let calendar = makeCalendar()
        let firstOfJune = try day(2026, 6, 1)
        let result = calendar.advancingPeriodStart(firstOfJune, by: 1, period: .monthly)
        XCTAssertEqual(result, try day(2026, 7, 1))
    }

    func testAdvancingPeriodStartByTwoMonthsJumpsTwoMonths() throws {
        let calendar = makeCalendar()
        let firstOfJune = try day(2026, 6, 1)
        let result = calendar.advancingPeriodStart(firstOfJune, by: 2, period: .monthly)
        XCTAssertEqual(result, try day(2026, 8, 1))
    }

    func testAdvancingPeriodStartCrossesYearBoundary() throws {
        let calendar = makeCalendar()
        let firstOfNov = try day(2026, 11, 1)
        let result = calendar.advancingPeriodStart(firstOfNov, by: 3, period: .monthly)
        XCTAssertEqual(result, try day(2027, 2, 1))
    }

    // MARK: - periodCount

    func testPeriodCountWeeklyBetweenAdjacentBoundariesIsOne() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let from = try day(2026, 6, 22)
        let to = try day(2026, 6, 29)
        XCTAssertEqual(calendar.periodCount(from: from, to: to, period: .weekly), 1)
    }

    func testPeriodCountWeeklyTwoWeeksApart() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let from = try day(2026, 6, 22)
        let to = try day(2026, 7, 6)
        XCTAssertEqual(calendar.periodCount(from: from, to: to, period: .weekly), 2)
    }

    func testPeriodCountMonthlyBetweenAdjacentBoundariesIsOne() throws {
        let calendar = makeCalendar()
        let from = try day(2026, 6, 1)
        let to = try day(2026, 7, 1)
        XCTAssertEqual(calendar.periodCount(from: from, to: to, period: .monthly), 1)
    }

    func testPeriodCountReturnsZeroWhenStartEqualsEnd() throws {
        let calendar = makeCalendar()
        let same = try day(2026, 6, 1)
        XCTAssertEqual(calendar.periodCount(from: same, to: same, period: .monthly), 0)
        XCTAssertEqual(calendar.periodCount(from: same, to: same, period: .weekly), 0)
    }

    func testPeriodCountReturnsZeroWhenStartAfterEnd() throws {
        let calendar = makeCalendar()
        let from = try day(2026, 7, 1)
        let to = try day(2026, 6, 1)
        XCTAssertEqual(calendar.periodCount(from: from, to: to, period: .monthly), 0)
    }

    // MARK: - RoutinePause.resumeDay

    func testResumeDayNilWhenNeitherPerRoutineNorGlobalSet() throws {
        let calendar = makeCalendar()
        let result = RoutinePause.resumeDay(
            perRoutineResume: nil,
            global: nil,
            period: .weekly,
            calendar: calendar
        )
        XCTAssertNil(result)
    }

    func testResumeDayReturnsPerRoutineWhenOnlyPerRoutineSet() throws {
        let calendar = makeCalendar()
        let perRoutineDay = try day(2026, 6, 29)
        let result = RoutinePause.resumeDay(
            perRoutineResume: perRoutineDay,
            global: nil,
            period: .weekly,
            calendar: calendar
        )
        XCTAssertEqual(result, perRoutineDay)
    }

    func testResumeDayReturnsGlobalResumeDayWhenOnlyGlobalSet() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let anchor = try day(2026, 6, 22)
        let global = GlobalPause(anchor: anchor, skipPeriods: 1)
        let result = RoutinePause.resumeDay(
            perRoutineResume: nil,
            global: global,
            period: .weekly,
            calendar: calendar
        )
        XCTAssertEqual(result, try day(2026, 6, 29))
    }

    func testResumeDayReturnsMaxOfPerRoutineAndGlobal() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let anchor = try day(2026, 6, 22)
        let global = GlobalPause(anchor: anchor, skipPeriods: 1)

        let laterPerRoutine = try day(2026, 7, 6)
        let resultLater = RoutinePause.resumeDay(
            perRoutineResume: laterPerRoutine,
            global: global,
            period: .weekly,
            calendar: calendar
        )
        XCTAssertEqual(resultLater, try day(2026, 7, 6))

        let earlierPerRoutine = try day(2026, 6, 22)
        let resultEarlier = RoutinePause.resumeDay(
            perRoutineResume: earlierPerRoutine,
            global: global,
            period: .weekly,
            calendar: calendar
        )
        XCTAssertEqual(resultEarlier, try day(2026, 6, 29))
    }

    func testResumeDayForMonthlyRoutineUsesMonthPeriods() throws {
        let calendar = makeCalendar()
        let anchor = try day(2026, 6, 1)
        let global = GlobalPause(anchor: anchor, skipPeriods: 2)
        let result = RoutinePause.resumeDay(
            perRoutineResume: nil,
            global: global,
            period: .monthly,
            calendar: calendar
        )
        XCTAssertEqual(result, try day(2026, 8, 1))
    }

    // MARK: - RoutinePause.isPaused

    func testIsPausedReturnsFalseWhenResumeDayIsNil() throws {
        let today = try day(2026, 6, 24)
        XCTAssertFalse(RoutinePause.isPaused(resumeDay: nil, today: today))
    }

    func testIsPausedReturnsTrueWhenTodayIsBeforeResumeDay() throws {
        let today = try day(2026, 6, 24)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertTrue(RoutinePause.isPaused(resumeDay: resumeDay, today: today))
    }

    func testIsPausedReturnsFalseWhenTodayEqualsResumeDay() throws {
        let today = try day(2026, 6, 29)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertFalse(RoutinePause.isPaused(resumeDay: resumeDay, today: today))
    }

    func testIsPausedReturnsFalseWhenTodayIsAfterResumeDay() throws {
        let today = try day(2026, 7, 1)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertFalse(RoutinePause.isPaused(resumeDay: resumeDay, today: today))
    }
}
