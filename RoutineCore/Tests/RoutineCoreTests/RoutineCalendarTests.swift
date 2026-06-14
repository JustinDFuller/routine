import Foundation
import XCTest

@testable import RoutineCore

final class RoutineCalendarTests: XCTestCase {
    func testCurrentWeekRangeStartsOnConfiguredMondayForEachWeekday() throws {
        let calendar = testRoutineCalendar(firstWeekday: 2)
        let expectedStart = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3))
        let expectedEnd = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 9))

        var inputs: [RoutineDay] = []
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 4)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 5)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 6)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 7)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 8)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 9)))

        for input in inputs {
            let range = calendar.currentWeekRange(containing: input)
            XCTAssertEqual(range.lowerBound, expectedStart, "Unexpected week start for \(input.key)")
            XCTAssertEqual(range.upperBound, expectedEnd, "Unexpected week end for \(input.key)")
        }
    }

    func testCurrentWeekRangeStartsOnConfiguredSundayForEachWeekday() throws {
        let calendar = testRoutineCalendar(firstWeekday: 1)
        let expectedStart = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))
        let expectedEnd = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 8))

        var inputs: [RoutineDay] = []
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 4)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 5)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 6)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 7)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 8)))

        for input in inputs {
            let range = calendar.currentWeekRange(containing: input)
            XCTAssertEqual(range.lowerBound, expectedStart, "Unexpected week start for \(input.key)")
            XCTAssertEqual(range.upperBound, expectedEnd, "Unexpected week end for \(input.key)")
        }
    }

    func testCurrentWeekRangeStartsOnConfiguredSaturdayForEachWeekday() throws {
        let calendar = testRoutineCalendar(firstWeekday: 7)
        let expectedStart = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 1))
        let expectedEnd = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 7))

        var inputs: [RoutineDay] = []
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 1)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 4)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 5)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 6)))
        inputs.append(try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 7)))

        for input in inputs {
            let range = calendar.currentWeekRange(containing: input)
            XCTAssertEqual(range.lowerBound, expectedStart, "Unexpected week start for \(input.key)")
            XCTAssertEqual(range.upperBound, expectedEnd, "Unexpected week end for \(input.key)")
        }
    }

    func testCurrentWeekRangeCrossesMonthBoundary() throws {
        let calendar = testRoutineCalendar(firstWeekday: 2)
        let input = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 1))
        let expectedStart = try XCTUnwrap(RoutineDay(year: 2024, month: 5, day: 27))
        let expectedEnd = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))

        let range = calendar.currentWeekRange(containing: input)
        XCTAssertEqual(range, expectedStart...expectedEnd)
    }

    func testCurrentWeekRangeCrossesYearBoundary() throws {
        let calendar = testRoutineCalendar()
        let input = try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 1))
        let expectedStart = try XCTUnwrap(RoutineDay(year: 2024, month: 12, day: 30))
        let expectedEnd = try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 5))

        let range = calendar.currentWeekRange(containing: input)
        XCTAssertEqual(range, expectedStart...expectedEnd)
    }

    func testCurrentMonthRangeCoversExpectedMonthLengths() throws {
        let calendar = testRoutineCalendar()
        let januaryStart = try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 1))
        let januaryEnd = try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 31))
        let aprilStart = try XCTUnwrap(RoutineDay(year: 2025, month: 4, day: 1))
        let aprilEnd = try XCTUnwrap(RoutineDay(year: 2025, month: 4, day: 30))
        let february2025Start = try XCTUnwrap(RoutineDay(year: 2025, month: 2, day: 1))
        let february2025End = try XCTUnwrap(RoutineDay(year: 2025, month: 2, day: 28))
        let february2024Start = try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 1))
        let february2024End = try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 29))

        XCTAssertEqual(
            calendar.currentMonthRange(containing: try XCTUnwrap(RoutineDay(year: 2025, month: 1, day: 10))),
            januaryStart...januaryEnd
        )
        XCTAssertEqual(
            calendar.currentMonthRange(containing: try XCTUnwrap(RoutineDay(year: 2025, month: 4, day: 10))),
            aprilStart...aprilEnd
        )
        XCTAssertEqual(
            calendar.currentMonthRange(containing: try XCTUnwrap(RoutineDay(year: 2025, month: 2, day: 10))),
            february2025Start...february2025End
        )
        XCTAssertEqual(
            calendar.currentMonthRange(containing: try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 10))),
            february2024Start...february2024End
        )
    }

    func testDaysInCurrentMonthReturnsEveryDayInOrder() throws {
        let calendar = testRoutineCalendar()
        let days = calendar.daysInCurrentMonth(containing: try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 14)))

        XCTAssertEqual(days.count, 29)
        XCTAssertEqual(days.first, try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 1)))
        XCTAssertEqual(days.last, try XCTUnwrap(RoutineDay(year: 2024, month: 2, day: 29)))
        XCTAssertEqual(days, days.sorted())
    }

    func testDayContainingHandlesDstAdjacentInstantsInNewYork() throws {
        let calendar = testRoutineCalendar()

        let beforeJump = try XCTUnwrap(iso8601Date("2024-03-10T06:30:00Z"))
        let afterJump = try XCTUnwrap(iso8601Date("2024-03-10T07:30:00Z"))

        let expectedDay = try XCTUnwrap(RoutineDay(year: 2024, month: 3, day: 10))
        XCTAssertEqual(calendar.day(containing: beforeJump), expectedDay)
        XCTAssertEqual(calendar.day(containing: afterJump), expectedDay)
    }

    func testWeekdayOffsetIsZeroOnConfiguredWeekStartDay() throws {
        let sunday = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))
        let monday = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3))
        let saturday = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 1))

        let sundayStart = testRoutineCalendar(firstWeekday: 1)
        XCTAssertEqual(sundayStart.weekdayOffset(for: sunday), 0)
        XCTAssertEqual(sundayStart.weekdayOffset(for: monday), 1)

        let mondayStart = testRoutineCalendar(firstWeekday: 2)
        XCTAssertEqual(mondayStart.weekdayOffset(for: monday), 0)
        XCTAssertEqual(mondayStart.weekdayOffset(for: sunday), 6)

        let saturdayStart = testRoutineCalendar(firstWeekday: 7)
        XCTAssertEqual(saturdayStart.weekdayOffset(for: saturday), 0)
        XCTAssertEqual(saturdayStart.weekdayOffset(for: sunday), 1)
    }

    func testOrderedWeekdaySymbolsStartsOnConfiguredWeekStartDay() {
        XCTAssertEqual(
            testRoutineCalendar(firstWeekday: 1).orderedWeekdaySymbols,
            ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        )
        XCTAssertEqual(
            testRoutineCalendar(firstWeekday: 2).orderedWeekdaySymbols,
            ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        )
        XCTAssertEqual(
            testRoutineCalendar(firstWeekday: 7).orderedWeekdaySymbols,
            ["Sat", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri"]
        )
    }

    func testTodayUsesConfiguredCalendarAndTimezone() throws {
        let calendar = testRoutineCalendar()
        let instant = try XCTUnwrap(iso8601Date("2024-06-03T03:30:00Z"))

        XCTAssertEqual(calendar.today(now: instant), try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2)))
    }

    private func testRoutineCalendar(firstWeekday: Int = 2) -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = firstWeekday
        return RoutineCalendar(calendar: calendar)
    }

    private func iso8601Date(_ value: String) -> Date? {
        ISO8601DateFormatter().date(from: value)
    }
}
