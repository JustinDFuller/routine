import Foundation
import XCTest

@testable import RoutineCore

final class CheckInContentBuilderTests: XCTestCase {
    func testMorningActionableOpenRoutineProducesMessageNamingItAndRemainingCount() throws {
        let routine = CheckInRoutineSnapshot(
            name: "Stretch",
            targetCount: 3,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 8, routines: [routine])

        XCTAssertEqual(
            content,
            .message(
                title: "Good morning ☀️",
                body: "Stretch is a nice place to start — 3 more to go this week."
            )
        )
    }

    func testMorningOnlyOpenRoutineOutsideAvailabilityWindowSuppresses() throws {
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 12, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 18, minute: 0))
            )
        )
        let routine = CheckInRoutineSnapshot(
            name: "Evening walk",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: window,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 8, routines: [routine])

        XCTAssertEqual(content, .suppress)
    }

    func testMorningRoutineWithNoAvailabilityWindowIsAlwaysActionable() throws {
        let routine = CheckInRoutineSnapshot(
            name: "Journal",
            targetCount: 5,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 6, routines: [routine])

        XCTAssertEqual(
            content,
            .message(
                title: "Good morning ☀️",
                body: "Journal is a nice place to start — 5 more to go this week."
            )
        )
    }

    func testAfternoonCountsDoneTodayFromADifferentRoutineAndNamesNextActionable() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let completedRoutine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )
        let openRoutine = CheckInRoutineSnapshot(
            name: "Read",
            targetCount: 2,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .afternoon, slotHour: 14, routines: [completedRoutine, openRoutine])

        XCTAssertEqual(
            content,
            .message(
                title: "Nice momentum 👏",
                body: "1 done so far today. Read is there whenever you've got 5 minutes."
            )
        )
    }

    func testAfternoonSuppressesWhenNoActionableRoutineRemains() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let window = try XCTUnwrap(
            RoutineAvailabilityWindow(
                start: try XCTUnwrap(RoutineTimeOfDay(hour: 18, minute: 0)),
                end: try XCTUnwrap(RoutineTimeOfDay(hour: 20, minute: 0))
            )
        )
        let outsideWindowRoutine = CheckInRoutineSnapshot(
            name: "Evening walk",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: window,
            completionDays: []
        )
        let completedTodayRoutine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )

        let content = try content(
            slot: .afternoon,
            slotHour: 14,
            routines: [outsideWindowRoutine, completedTodayRoutine]
        )

        XCTAssertEqual(content, .suppress)
    }

    func testEveningNeverSuppressesWhileGoalsAreOpenAndReportsCorrectFraction() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let metRoutine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )
        let openRoutineA = CheckInRoutineSnapshot(
            name: "Read",
            targetCount: 2,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )
        let openRoutineB = CheckInRoutineSnapshot(
            name: "Stretch",
            targetCount: 3,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .evening, slotHour: 20, routines: [metRoutine, openRoutineA, openRoutineB])

        XCTAssertEqual(
            content,
            .message(
                title: "Evening check-in 🌙",
                body: "1 done today. You're 1 of 3 toward this week's goals."
            )
        )
    }

    func testNextRoutineOrderingPicksFirstActionableInInputOrder() throws {
        let first = CheckInRoutineSnapshot(
            name: "Stretch",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )
        let second = CheckInRoutineSnapshot(
            name: "Read",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 8, routines: [first, second])

        XCTAssertEqual(
            content,
            .message(
                title: "Good morning ☀️",
                body: "Stretch is a nice place to start — 1 more to go this week."
            )
        )
    }

    func testAllRoutinesMetAndCelebrationNotConsumedReturnsCelebrationMessage() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let routine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )

        let content = try content(slot: .evening, slotHour: 20, routines: [routine], celebrationConsumed: false)

        XCTAssertEqual(
            content,
            .message(title: "All caught up 🎉", body: "Every goal met this week. Enjoy the rest of it!")
        )
    }

    func testAllRoutinesMetAndCelebrationConsumedSuppresses() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let routine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )

        let content = try content(slot: .evening, slotHour: 20, routines: [routine], celebrationConsumed: true)

        XCTAssertEqual(content, .suppress)
    }

    func testNewPeriodWithEmptyCompletionsResumesAutomaticallyDespiteCelebrationConsumedFlag() throws {
        // A new week's Monday, with no completions yet recorded for this period —
        // simulates a week boundary reset even though the stale `celebrationConsumed`
        // flag from last week's all-met state is still `true`.
        let newWeekToday = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 9))
        let routine = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(
            slot: .morning,
            slotHour: 8,
            routines: [routine],
            today: newWeekToday,
            celebrationConsumed: true
        )

        XCTAssertEqual(
            content,
            .message(
                title: "Good morning ☀️",
                body: "Meditate is a nice place to start — 1 more to go this week."
            )
        )
    }

    private func content(
        slot: CheckInSlot,
        slotHour: Int,
        routines: [CheckInRoutineSnapshot],
        today: RoutineDay? = nil,
        celebrationConsumed: Bool = false
    ) throws -> CheckInContent {
        let calendar = testRoutineCalendar()
        let resolvedToday = try today ?? XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let now = try date(for: resolvedToday, hour: slotHour, calendar: calendar)

        return CheckInContentBuilder().content(
            slot: slot,
            slotMinuteOfDay: slotHour * 60,
            routines: routines,
            context: CheckInContext(now: now, calendar: calendar, celebrationConsumed: celebrationConsumed)
        )
    }

    private func date(for day: RoutineDay, hour: Int, calendar: RoutineCalendar) throws -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = hour
        components.minute = 0
        return try XCTUnwrap(calendar.calendar.date(from: components))
    }

    private func testRoutineCalendar(firstWeekday: Int = 2) -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = firstWeekday
        return RoutineCalendar(calendar: calendar)
    }
}
