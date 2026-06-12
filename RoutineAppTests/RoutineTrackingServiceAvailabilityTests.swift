import Foundation
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineTrackingServiceAvailabilityTests: RoutineTrackingServiceTestCase {
    func testCompleteTodayAllowsConfiguredWindowWhenInsideRange() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 0
            ),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 2, minute: 0, calendar: calendar.calendar)

        let result = try service.completeToday(routineID: routine.id, now: now)

        XCTAssertTrue(result.didInsert)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testCompleteTodayBlocksConfiguredWindowWhenOutsideRange() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 0
            ),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 8, minute: 0, calendar: calendar.calendar)

        XCTAssertThrowsError(try service.completeToday(routineID: routine.id, now: now)) { error in
            XCTAssertEqual(
                error as? RoutineTrackingError,
                .unavailable(routineName: "Wake up early", windowText: "between 12:00 AM and 6:45 AM")
            )
            XCTAssertEqual(
                error.localizedDescription,
                "Wake up early is unavailable now. It can only be completed "
                    + "between 12:00 AM and 6:45 AM."
            )
        }
        XCTAssertTrue(try fetchCompletions(in: context).isEmpty)
    }

    func testDuplicateCompletionRemainsIdempotentOutsideAvailabilityWindow() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 0
            ),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)

        _ = try service.completeToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 7, hour: 2, minute: 0, calendar: calendar.calendar)
        )
        let result = try service.completeToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 7, hour: 8, minute: 0, calendar: calendar.calendar)
        )

        XCTAssertFalse(result.didInsert)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testCrossMidnightCompletionStoresCurrentLocalDayAfterMidnight() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Evening yoga",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 1_380,
                availabilityEndMinute: 180,
                sortOrder: 0
            ),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let now = makeDate(year: 2026, month: 6, day: 8, hour: 2, minute: 0, calendar: calendar.calendar)

        let result = try service.completeToday(routineID: routine.id, now: now)
        let completion = try XCTUnwrap(try fetchCompletions(in: context).first)

        XCTAssertEqual(result.day.key, "2026-06-08")
        XCTAssertEqual(completion.dayKey, "2026-06-08")
    }
}
