import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class HistoryProjectionBuilderGoalMetTests: ProjectionBuilderTestCase {
    func testBuildMarksWeeklyWeekAsGoalMetWhenTargetIsReached() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 2, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 2),
            completedAt: makeDate(year: 2026, month: 6, day: 2, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 5),
            completedAt: makeDate(year: 2026, month: 6, day: 5, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        let firstWeek = try XCTUnwrap(viewData.weeks.first)
        XCTAssertTrue(firstWeek.isGoalMet)
    }

    func testBuildMarksWeeklyWeekAsNotGoalMetWhenShortOfTarget() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        XCTAssertGreaterThan(viewData.weeks.count, 1)
        let secondWeek = viewData.weeks[1]
        XCTAssertFalse(secondWeek.isGoalMet)
    }

    func testBuildMarksWeeklyWeekAsGoalMetUsingCompletionsOutsideDisplayedMonth() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 29, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 29),
            completedAt: makeDate(year: 2026, month: 6, day: 29, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 7, day: 1),
            completedAt: makeDate(year: 2026, month: 7, day: 1, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 7, day: 2),
            completedAt: makeDate(year: 2026, month: 7, day: 2, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        let lastWeek = try XCTUnwrap(viewData.weeks.last)
        XCTAssertTrue(lastWeek.isGoalMet)
    }

    func testBuildMarksAllWeeksAsGoalMetWhenMonthlyTargetIsReached() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 2, period: .monthly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 3),
            completedAt: makeDate(year: 2026, month: 6, day: 3, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 20),
            completedAt: makeDate(year: 2026, month: 6, day: 20, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        XCTAssertTrue(viewData.weeks.allSatisfy(\.isGoalMet))
        XCTAssertFalse(viewData.weeks.isEmpty)
    }

    func testBuildNeverMarksGoalMetWhenTargetCountIsZero() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Calendar", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Optional", targetCount: 0, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        let viewData = try foundViewData(
            from: try HistoryProjectionBuilder(context: context, routineCalendar: calendar).build(
                routineID: routine.id,
                now: now
            )
        )

        XCTAssertFalse(viewData.weeks.contains { $0.isGoalMet })
    }

    private func foundViewData(from projection: RoutineHistoryProjection) throws -> RoutineHistoryViewData {
        guard case .found(let viewData) = projection else {
            throw XCTSkip("Expected found projection.")
        }

        return viewData
    }
}
