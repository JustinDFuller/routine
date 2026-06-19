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
                title: "Morning check-in",
                body: "Next routine: Stretch. You need 3 more completions to reach this week's goal."
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
                title: "Morning check-in",
                body: "Next routine: Journal. You need 5 more completions to reach this week's goal."
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
                title: "Afternoon check-in",
                body:
                    "You've completed 1 routine today. Next routine: Read. "
                    + "You need 2 more completions to reach this week's goal."
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
                title: "Evening check-in",
                body: "You've completed 1 routine today. 1 of 3 goals is met, and 2 goals are still open."
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
                title: "Morning check-in",
                body: "Next routine: Stretch. You need 1 more completion to reach this week's goal."
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
            .message(
                title: "All caught up",
                body: "You've met all of your current goals. There's nothing left to do right now."
            )
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
                title: "Morning check-in",
                body: "Next routine: Meditate. You need 1 more completion to reach this week's goal."
            )
        )
    }

    func testRoutineSpecificMessagesUseExplicitRoutineLabelFormat() throws {
        let routine = CheckInRoutineSnapshot(
            name: "Read",
            targetCount: 2,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 8, routines: [routine])

        guard case .message(_, let body) = content else {
            return XCTFail("Expected notification content message.")
        }

        XCTAssertTrue(body.contains("Next routine: Read."))
    }

    func testAfternoonPluralizesCompletedRoutineCountForMultipleRoutines() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let completedRoutineA = CheckInRoutineSnapshot(
            name: "Meditate",
            targetCount: 1,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: [today]
        )
        let completedRoutineB = CheckInRoutineSnapshot(
            name: "Journal",
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

        let content = try content(
            slot: .afternoon,
            slotHour: 14,
            routines: [completedRoutineA, completedRoutineB, openRoutine]
        )

        XCTAssertEqual(
            content,
            .message(
                title: "Afternoon check-in",
                body:
                    "You've completed 2 routines today. Next routine: Read. "
                    + "You need 2 more completions to reach this week's goal."
            )
        )
    }

    func testMorningUsesMonthlyGoalWordingForMonthlyRoutine() throws {
        let routine = CheckInRoutineSnapshot(
            name: "Budget review",
            targetCount: 1,
            period: .monthly,
            availabilityWindow: nil,
            completionDays: []
        )

        let content = try content(slot: .morning, slotHour: 8, routines: [routine])

        XCTAssertEqual(
            content,
            .message(
                title: "Morning check-in",
                body: "Next routine: Budget review. You need 1 more completion to reach this month's goal."
            )
        )
    }

    func testEveningUsesSingularGoalPhrasingWhenOneGoalRemainsOpen() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let metRoutine = CheckInRoutineSnapshot(
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

        let content = try content(slot: .evening, slotHour: 20, routines: [metRoutine, openRoutine])

        XCTAssertEqual(
            content,
            .message(
                title: "Evening check-in",
                body: "You've completed 1 routine today. 1 of 2 goals is met, and 1 goal is still open."
            )
        )
    }

    func testEveningAggregateMessageStaysPeriodNeutralForMixedPeriods() throws {
        let today = try XCTUnwrap(RoutineDay(year: 2025, month: 6, day: 4))
        let weeklyOpenRoutine = CheckInRoutineSnapshot(
            name: "Stretch",
            targetCount: 3,
            period: .weekly,
            availabilityWindow: nil,
            completionDays: []
        )
        let monthlyMetRoutine = CheckInRoutineSnapshot(
            name: "Budget review",
            targetCount: 1,
            period: .monthly,
            availabilityWindow: nil,
            completionDays: [today]
        )

        let content = try content(
            slot: .evening,
            slotHour: 20,
            routines: [weeklyOpenRoutine, monthlyMetRoutine]
        )

        XCTAssertEqual(
            content,
            .message(
                title: "Evening check-in",
                body: "You've completed 1 routine today. 1 of 2 goals is met, and 1 goal is still open."
            )
        )

        guard case .message(_, let body) = content else {
            return XCTFail("Expected notification content message.")
        }

        XCTAssertFalse(body.localizedCaseInsensitiveContains("week"))
        XCTAssertFalse(body.localizedCaseInsensitiveContains("month"))
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
