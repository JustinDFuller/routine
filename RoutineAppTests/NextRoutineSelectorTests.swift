import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class NextRoutineSelectorTests: ProjectionBuilderTestCase {
    func testNextReturnsFirstReadyRoutineAcrossGroupsInOrder() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let morning = insertGroup(name: "Morning", sortOrder: 0, into: context)
        let evening = insertGroup(name: "Evening", sortOrder: 1, into: context)

        let stretch = insertRoutine(
            seed: RoutineTestSeed(name: "Stretch", targetCount: 5, period: .weekly, sortOrder: 0),
            group: morning,
            into: context
        )
        try insertCompletion(routine: stretch, dayKey: "2026-06-10", completedAt: now, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 5, period: .weekly, sortOrder: 1),
            group: morning,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: evening,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.name, "Read")
    }

    func testNextSkipsRoutineCompletedToday() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-10", completedAt: now, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 5, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.name, "Read")
    }

    func testNextSkipsRoutineWithTargetMet() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 1, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-09", completedAt: now, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 5, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.name, "Read")
    }

    func testNextSkipsRoutineOutsideAvailabilityWindow() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.name, "Walk")
    }

    func testNextReturnsNoRoutinesWhenStoreIsEmpty() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        XCTAssertEqual(selection, .noRoutines)
    }

    func testNextReturnsAllCaughtUpWhenNoRoutineIsReady() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-10", completedAt: now, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Wake up early",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 0,
                availabilityEndMinute: 405,
                sortOrder: 1
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        XCTAssertEqual(selection, .allCaughtUp)
    }

    func testReadySnapshotFieldsMatchProgress() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-08", completedAt: now, into: context)
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.routineID, walk.id)
        XCTAssertEqual(snapshot.name, "Walk")
        XCTAssertEqual(snapshot.countText, "1/5")
        XCTAssertEqual(snapshot.periodText, "Week")
        XCTAssertEqual(snapshot.lastDoneText, "2d ago")
        XCTAssertEqual(snapshot.fillRatio, 0.2, accuracy: 0.0001)
        XCTAssertFalse(snapshot.isComplete)
    }

    func testReadySnapshotUsesMonthlyPeriodText() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Declutter", targetCount: 1, period: .monthly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let selection = try NextRoutineSelector.next(context: context, calendar: calendar, now: now)

        guard case .ready(let snapshot) = selection else {
            return XCTFail("Expected a ready routine, got \(selection)")
        }

        XCTAssertEqual(snapshot.periodText, "Month")
        XCTAssertEqual(snapshot.lastDoneText, "Never")
    }

    func testNextRefreshBoundaryDefaultsToNextMidnight() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let boundary = try NextRoutineSelector.nextRefreshBoundary(context: context, calendar: calendar, now: now)
        let expectedMidnight = makeDate(year: 2026, month: 6, day: 11, hour: 0, minute: 0, calendar: calendar.calendar)

        XCTAssertEqual(boundary, expectedMidnight)
    }

    func testNextRefreshBoundaryUsesEarlierAvailabilityWindowEdge() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 8, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Lunch walk",
                targetCount: 5,
                period: .weekly,
                availabilityStartMinute: 420,
                availabilityEndMinute: 600,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let boundary = try NextRoutineSelector.nextRefreshBoundary(context: context, calendar: calendar, now: now)
        let expectedEdge = makeDate(year: 2026, month: 6, day: 10, hour: 10, minute: 0, calendar: calendar.calendar)

        XCTAssertEqual(boundary, expectedEdge)
    }
}
