import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineTrackingServicePauseTests: RoutineTrackingServiceTestCase {
    func testCompletingPausedRoutineTodayThrowsPausedError() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                pauseResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        XCTAssertThrowsError(try service.completeToday(routineID: routine.id, now: now)) { error in
            guard case .paused(let name, _) = error as? RoutineTrackingError else {
                return XCTFail("Expected .paused error, got \(error)")
            }
            XCTAssertEqual(name, "Walk")
        }
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
                pauseResumeDayKey: nextMonday.key,
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
                pauseResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.completeToday(routineID: routine.id, now: afterResume)
        XCTAssertTrue(result.didInsert)
    }

    func testGlobalPausePreventsCompletionForAllRoutines() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)
        let anchor = try makeDay(year: 2026, month: 6, day: 22)

        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )

        try context.setGlobalPause(anchor: anchor, skipPeriods: 1, now: now)

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        XCTAssertThrowsError(try service.completeToday(routineID: routine.id, now: now)) { error in
            guard case .paused = error as? RoutineTrackingError else {
                return XCTFail("Expected .paused error, got \(error)")
            }
        }
    }

    func testResumingRoutineClearsPauseResumeDayKey() throws {
        let context = try makeContext()
        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                pauseResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            into: context
        )

        try RoutineManagementService(context: context).resumeRoutine(id: routine.id)

        let fetched = try context.routine(id: routine.id)
        XCTAssertNil(fetched.pauseResumeDayKey)
    }
}
