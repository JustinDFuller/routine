import Foundation
import XCTest

@testable import RoutineCore

final class BehindScheduleContentBuilderTests: XCTestCase {
    func testWeeklyRoutineBehindPaceReturnsExactMessage() throws {
        let calendar = testRoutineCalendar()
        let thursday = try routineDay(11)

        let result = try content(
            routines: [
                routine(
                    name: "Walk", targetCount: 3, period: .weekly,
                    completionDays: [
                        try routineDay(8)
                    ])
            ],
            on: thursday,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            .message(
                title: "Behind schedule",
                body: "Walk: 1 of 3 this week. You’re 1 completion behind pace with 4 days left."
            )
        )
    }

    func testDuplicateCompletionDoesNotCreateFalseCatchUp() throws {
        let calendar = testRoutineCalendar()
        let monday = try routineDay(8)
        let thursday = try routineDay(11)

        let result = try content(
            routines: [routine(name: "Walk", targetCount: 3, period: .weekly, completionDays: [monday, monday])],
            on: thursday,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            .message(
                title: "Behind schedule",
                body: "Walk: 1 of 3 this week. You’re 1 completion behind pace with 4 days left."
            )
        )
    }

    func testExactPaceMetTargetEmptyListAndDayOneSuppress() throws {
        let calendar = testRoutineCalendar()
        let monday = try routineDay(8)
        let thursday = try routineDay(11)

        XCTAssertEqual(
            try content(
                routines: [routine(name: "Walk", targetCount: 3, period: .weekly, completionDays: [monday, thursday])],
                on: thursday,
                calendar: calendar
            ),
            .suppress
        )
        XCTAssertEqual(
            try content(
                routines: [routine(name: "Walk", targetCount: 1, period: .weekly, completionDays: [monday])],
                on: thursday,
                calendar: calendar
            ),
            .suppress
        )
        XCTAssertEqual(try content(routines: [], on: thursday, calendar: calendar), .suppress)
        XCTAssertEqual(
            try content(
                routines: [routine(name: "Walk", targetCount: 3, period: .weekly, completionDays: [])],
                on: monday,
                calendar: calendar
            ),
            .suppress
        )
    }

    func testMonthlyMessageUsesCalendarLengthAndPluralization() throws {
        let calendar = testRoutineCalendar()
        let day = try routineDay(20)

        let result = try content(
            routines: [routine(name: "Review", targetCount: 3, period: .monthly, completionDays: [])],
            on: day,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            .message(
                title: "Behind schedule",
                body: "Review: 0 of 3 this month. You’re 2 completions behind pace with 11 days left."
            )
        )
    }

    func testHighestDeficitWinsAndTiesUseCallerOrder() throws {
        let calendar = testRoutineCalendar()
        let day = try routineDay(11)

        XCTAssertEqual(
            try content(
                routines: [
                    routine(
                        name: "First", targetCount: 3, period: .weekly,
                        completionDays: [
                            try routineDay(8)
                        ]),
                    routine(name: "Largest", targetCount: 6, period: .weekly, completionDays: [])
                ],
                on: day,
                calendar: calendar
            ),
            .message(
                title: "Behind schedule",
                body: "Largest: 0 of 6 this week. You’re 3 completions behind pace with 4 days left."
            )
        )
        XCTAssertEqual(
            try content(
                routines: [
                    routine(
                        name: "First", targetCount: 3, period: .weekly,
                        completionDays: [
                            try routineDay(8)
                        ]),
                    routine(
                        name: "Second", targetCount: 3, period: .weekly,
                        completionDays: [
                            try routineDay(8)
                        ])
                ],
                on: day,
                calendar: calendar
            ),
            .message(
                title: "Behind schedule",
                body: "First: 1 of 3 this week. You’re 1 completion behind pace with 4 days left."
            )
        )
    }

    func testImpossibleFinalDayRoutineRemainsReported() throws {
        let calendar = testRoutineCalendar()
        let sunday = try routineDay(14)

        let result = try content(
            routines: [routine(name: "Walk", targetCount: 3, period: .weekly, completionDays: [])],
            on: sunday,
            calendar: calendar
        )

        XCTAssertEqual(
            result,
            .message(
                title: "Behind schedule",
                body: "Walk: 0 of 3 this week. You’re 3 completions behind pace with 1 day left."
            )
        )
    }

    private func content(
        routines: [BehindScheduleRoutineSnapshot],
        on day: RoutineDay,
        calendar: RoutineCalendar
    ) throws -> BehindScheduleContent {
        BehindScheduleContentBuilder().content(
            routines: routines,
            context: BehindScheduleContext(now: try date(for: day, calendar: calendar), calendar: calendar)
        )
    }

    private func routine(
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        completionDays: [RoutineDay]
    ) -> BehindScheduleRoutineSnapshot {
        BehindScheduleRoutineSnapshot(
            name: name,
            targetCount: targetCount,
            period: period,
            completionDays: completionDays
        )
    }

    private func routineDay(_ value: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: 2026, month: 6, day: value))
    }

    private func date(for day: RoutineDay, calendar: RoutineCalendar) throws -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = 7

        return try XCTUnwrap(calendar.calendar.date(from: components))
    }

    private func testRoutineCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        calendar.firstWeekday = 2
        calendar.minimumDaysInFirstWeek = 4
        return RoutineCalendar(calendar: calendar)
    }
}
