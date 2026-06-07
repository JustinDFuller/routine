import Foundation
import XCTest

@testable import RoutineCore

final class RoutineCalendarLabelTests: XCTestCase {
    func testRelativeLabelReturnsToday() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        XCTAssertEqual(calendar.relativeLabel(for: today, today: today), "Today")
    }

    func testRelativeLabelReturnsYesterday() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        let yesterday = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 8))
        XCTAssertEqual(calendar.relativeLabel(for: yesterday, today: today), "Yesterday")
    }

    func testRelativeLabelReturnsRecentDayCountWithinSevenDays() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        let recent = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 6))
        XCTAssertEqual(calendar.relativeLabel(for: recent, today: today), "3d ago")
    }

    func testRelativeLabelReturnsMonthAndDayForOlderCurrentYearDates() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        let older = try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 2))
        XCTAssertEqual(calendar.relativeLabel(for: older, today: today), "Jan 2")
    }

    func testRelativeLabelReturnsYearForPriorYearDates() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        let older = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))
        XCTAssertEqual(calendar.relativeLabel(for: older, today: today), "Jun 2, 2024")
    }

    func testOptionalRelativeLabelReturnsNeverForMissingDate() throws {
        let calendar = testRoutineCalendar()
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        XCTAssertEqual(calendar.relativeLabel(for: nil, today: today), "Never")
    }

    func testExplicitDateLabelIsDeterministicWithFixedLocaleAndTimezone() throws {
        let calendar = testRoutineCalendar()
        let day = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 2))
        XCTAssertEqual(calendar.explicitDateLabel(for: day), "Jun 2, 2025")
    }

    private func testRoutineCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }
}
