import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineTrackingServiceBreakTests: RoutineTrackingServiceTestCase {
    func testCompletingRoutineOnBreakTodaySucceeds() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.completeToday(routineID: routine.id, now: now)

        XCTAssertTrue(result.didInsert)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testCompletingRoutineOnResumeDaySucceeds() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let resumeDate = makeDate(year: 2026, month: 6, day: 29, hour: 9, calendar: calendar.calendar)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.completeToday(routineID: routine.id, now: resumeDate)
        XCTAssertTrue(result.didInsert)
    }

    func testCompletingRoutineAfterResumeDaySucceeds() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let afterResume = makeDate(year: 2026, month: 7, day: 6, hour: 9, calendar: calendar.calendar)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.completeToday(routineID: routine.id, now: afterResume)
        XCTAssertTrue(result.didInsert)
    }

    func testGlobalBreakDoesNotPreventCompletion() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )

        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 6, day: 29), now: now)

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.completeToday(routineID: routine.id, now: now)

        XCTAssertTrue(result.didInsert)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testClearingRoutineBreakClearsResumeDayKey() throws {
        let context = try makeContext()
        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        try RoutineManagementService(context: context).clearRoutineBreak(id: routine.id)

        let fetched = try context.routine(id: routine.id)
        XCTAssertNil(fetched.breakResumeDayKey)
    }

    func testStartingRoutineBreakStoresResumeDayKey() throws {
        let context = try makeContext()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let resumeDay = try makeDay(year: 2026, month: 6, day: 29)

        try RoutineManagementService(context: context).setRoutineBreak(id: routine.id, resumeDay: resumeDay)

        let fetched = try context.routine(id: routine.id)
        XCTAssertEqual(fetched.breakResumeDayKey, resumeDay.key)
    }
}
