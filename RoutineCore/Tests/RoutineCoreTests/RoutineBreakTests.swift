import Foundation
import XCTest

@testable import RoutineCore

final class RoutineBreakTests: XCTestCase {
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

    // MARK: - RoutineBreak.status

    func testStatusNilWhenNeitherPerRoutineNorGlobalSet() throws {
        let today = try day(2026, 6, 24)
        let result = RoutineBreak.status(perRoutineResume: nil, global: nil, today: today)
        XCTAssertNil(result)
    }

    func testStatusReturnsRoutineSourceWhenOnlyRoutineBreakIsActive() throws {
        let today = try day(2026, 6, 24)
        let perRoutineDay = try day(2026, 6, 29)
        let result = RoutineBreak.status(
            perRoutineResume: perRoutineDay,
            global: nil,
            today: today
        )
        XCTAssertEqual(result, RoutineBreakStatus(resumeDay: perRoutineDay, source: .routine))
    }

    func testStatusReturnsGlobalSourceWhenOnlyGlobalBreakIsActive() throws {
        let today = try day(2026, 6, 24)
        let globalResume = try day(2026, 7, 1)
        let result = RoutineBreak.status(
            perRoutineResume: nil,
            global: GlobalBreak(resumeDay: globalResume),
            today: today
        )
        XCTAssertEqual(result, RoutineBreakStatus(resumeDay: globalResume, source: .global))
    }

    func testStatusReturnsBothWithLaterResumeDayWhenBothBreaksAreActive() throws {
        let today = try day(2026, 6, 24)
        let routineResume = try day(2026, 7, 6)
        let globalResume = try day(2026, 7, 1)
        let result = RoutineBreak.status(
            perRoutineResume: routineResume,
            global: GlobalBreak(resumeDay: globalResume),
            today: today
        )
        XCTAssertEqual(result, RoutineBreakStatus(resumeDay: routineResume, source: .both))
    }

    func testStatusIgnoresInactiveRoutineBreakButKeepsActiveGlobalBreak() throws {
        let today = try day(2026, 6, 24)
        let inactiveRoutineResume = try day(2026, 6, 24)
        let globalResume = try day(2026, 7, 1)
        let result = RoutineBreak.status(
            perRoutineResume: inactiveRoutineResume,
            global: GlobalBreak(resumeDay: globalResume),
            today: today
        )
        XCTAssertEqual(result, RoutineBreakStatus(resumeDay: globalResume, source: .global))
    }

    // MARK: - RoutineBreak.isActive

    func testIsActiveReturnsFalseWhenResumeDayIsNil() throws {
        let today = try day(2026, 6, 24)
        XCTAssertFalse(RoutineBreak.isActive(resumeDay: nil, today: today))
    }

    func testIsActiveReturnsTrueWhenTodayIsBeforeResumeDay() throws {
        let today = try day(2026, 6, 24)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertTrue(RoutineBreak.isActive(resumeDay: resumeDay, today: today))
    }

    func testIsActiveReturnsFalseWhenTodayEqualsResumeDay() throws {
        let today = try day(2026, 6, 29)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertFalse(RoutineBreak.isActive(resumeDay: resumeDay, today: today))
    }

    func testIsActiveReturnsFalseWhenTodayIsAfterResumeDay() throws {
        let today = try day(2026, 7, 1)
        let resumeDay = try day(2026, 6, 29)
        XCTAssertFalse(RoutineBreak.isActive(resumeDay: resumeDay, today: today))
    }

    // MARK: - RoutineBreak.resumeDay

    func testTodayPresetResumesTomorrow() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let today = try day(2026, 6, 24)
        let resumeDay = RoutineBreak.resumeDay(for: .today, today: today, calendar: calendar)
        XCTAssertEqual(resumeDay, try day(2026, 6, 25))
    }

    func testThisWeekPresetResumesOnNextWeekStart() throws {
        let calendar = makeCalendar(firstWeekday: 2)
        let today = try day(2026, 6, 24)
        let resumeDay = RoutineBreak.resumeDay(for: .thisWeek, today: today, calendar: calendar)
        XCTAssertEqual(resumeDay, try day(2026, 6, 29))
    }

    func testThisMonthPresetResumesOnFirstDayOfNextMonth() throws {
        let calendar = makeCalendar()
        let today = try day(2026, 6, 24)
        let resumeDay = RoutineBreak.resumeDay(for: .thisMonth, today: today, calendar: calendar)
        XCTAssertEqual(resumeDay, try day(2026, 7, 1))
    }

    func testUntilDatePresetUsesExplicitDate() throws {
        let calendar = makeCalendar()
        let today = try day(2026, 6, 24)
        let explicitDate = calendar.date(for: try day(2026, 7, 4))
        let resumeDay = RoutineBreak.resumeDay(
            for: .untilDate,
            today: today,
            calendar: calendar,
            explicitDate: explicitDate
        )
        XCTAssertEqual(resumeDay, try day(2026, 7, 4))
    }

    func testUntilDatePresetClampsTodayToTomorrow() throws {
        let calendar = makeCalendar()
        let today = try day(2026, 6, 24)
        let explicitDate = calendar.date(for: today)
        let resumeDay = RoutineBreak.resumeDay(
            for: .untilDate,
            today: today,
            calendar: calendar,
            explicitDate: explicitDate
        )
        XCTAssertEqual(resumeDay, try day(2026, 6, 25))
    }
}
