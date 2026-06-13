import Foundation
import XCTest

@testable import RoutineCore

final class RoutineAvailabilityWindowTests: XCTestCase {
    func testRoutineTimeOfDayRejectsOutOfRangeValues() {
        XCTAssertNil(RoutineTimeOfDay(hour: -1, minute: 0))
        XCTAssertNil(RoutineTimeOfDay(hour: 24, minute: 0))
        XCTAssertNil(RoutineTimeOfDay(hour: 23, minute: 60))
        XCTAssertNil(RoutineTimeOfDay(minuteOfDay: -1))
        XCTAssertNil(RoutineTimeOfDay(minuteOfDay: 1_440))
    }

    func testRoutineTimeOfDayBuildsFromHourMinuteAndMinuteOfDay() throws {
        let direct = try XCTUnwrap(RoutineTimeOfDay(hour: 6, minute: 45))
        let fromMinute = try XCTUnwrap(RoutineTimeOfDay(minuteOfDay: 405))

        XCTAssertEqual(direct.minuteOfDay, 405)
        XCTAssertEqual(fromMinute.hour, 6)
        XCTAssertEqual(fromMinute.minute, 45)
    }

    func testAvailabilityWindowRejectsEqualStartAndEndMinutes() throws {
        XCTAssertNil(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(minuteOfDay: 60)),
                end: try XCTUnwrap(RoutineTimeOfDay(minuteOfDay: 60))
            )
        )

        XCTAssertThrowsError(
            try validatedAvailabilityWindow(startMinute: 60, endMinute: 60)
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .invalidAvailabilityWindow)
        }
    }

    func testSameDayWindowIsStartInclusiveAndEndExclusive() throws {
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 9, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 17, minute: 30))
            )
        )

        XCTAssertFalse(window.spansMidnight)
        XCTAssertTrue(window.contains(minuteOfDay: 9 * 60))
        XCTAssertTrue(window.contains(minuteOfDay: (17 * 60) + 29))
        XCTAssertFalse(window.contains(minuteOfDay: (9 * 60) - 1))
        XCTAssertFalse(window.contains(minuteOfDay: (17 * 60) + 30))
    }

    func testNoonToMidnightWindowIncludesLateEveningButNotMidnight() throws {
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 12, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 0, minute: 0))
            )
        )

        XCTAssertTrue(window.spansMidnight)
        XCTAssertTrue(window.contains(minuteOfDay: 12 * 60))
        XCTAssertTrue(window.contains(minuteOfDay: 1_439))
        XCTAssertFalse(window.contains(minuteOfDay: 0))
        XCTAssertFalse(window.contains(minuteOfDay: (12 * 60) - 1))
    }

    func testMidnightToMorningWindowIncludesMidnightThroughMinuteBeforeEnd() throws {
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 0, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 6, minute: 45))
            )
        )

        XCTAssertFalse(window.spansMidnight)
        XCTAssertTrue(window.contains(minuteOfDay: 0))
        XCTAssertTrue(window.contains(minuteOfDay: 404))
        XCTAssertFalse(window.contains(minuteOfDay: 405))
    }

    func testCrossMidnightWindowIncludesLateNightAndEarlyMorning() throws {
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 23, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 3, minute: 0))
            )
        )

        XCTAssertTrue(window.spansMidnight)
        XCTAssertTrue(window.contains(minuteOfDay: 23 * 60))
        XCTAssertTrue(window.contains(minuteOfDay: 1_439))
        XCTAssertTrue(window.contains(minuteOfDay: 0))
        XCTAssertTrue(window.contains(minuteOfDay: (2 * 60) + 59))
        XCTAssertFalse(window.contains(minuteOfDay: (23 * 60) - 1))
        XCTAssertFalse(window.contains(minuteOfDay: 3 * 60))
    }

    func testRoutineCalendarMinuteOfDayUsesConfiguredTimezoneForNonUTCCalendar() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        guard let timeZone = TimeZone(identifier: "Australia/Sydney") else {
            XCTFail("Expected Australia/Sydney timezone.")
            return
        }
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        let routineCalendar = RoutineCalendar(calendar: calendar)
        let date = makeDate(
            year: 2026,
            month: 6,
            day: 12,
            hourMinute: (22, 5),
            calendar: calendar
        )

        XCTAssertEqual(routineCalendar.minuteOfDay(containing: date), 1_325)
    }

    func testRoutineCalendarMinuteOfDayHandlesDSTAdjacentDates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        guard let timeZone = TimeZone(identifier: "America/New_York") else {
            XCTFail("Expected America/New_York timezone.")
            return
        }
        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        let routineCalendar = RoutineCalendar(calendar: calendar)
        let date = makeDate(
            year: 2026,
            month: 3,
            day: 8,
            hourMinute: (3, 15),
            calendar: calendar
        )

        XCTAssertEqual(routineCalendar.minuteOfDay(containing: date), 195)
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hourMinute: (hour: Int, minute: Int),
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hourMinute.hour
        components.minute = hourMinute.minute

        guard let date = calendar.date(from: components) else {
            preconditionFailure(
                "Unable to construct date for \(year)-\(month)-\(day) \(hourMinute.hour):\(hourMinute.minute)."
            )
        }

        return date
    }
}
