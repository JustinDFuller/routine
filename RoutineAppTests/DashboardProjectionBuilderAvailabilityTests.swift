import Foundation
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class DashboardAvailabilityTests: ProjectionBuilderTestCase {
    func testBuildMarksAllDayAndConfiguredAvailabilityStates() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 2, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
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

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let cardsByName = Dictionary(uniqueKeysWithValues: viewData.sections[0].routines.map { ($0.name, $0) })

        XCTAssertNil(cardsByName["Walk"]?.availabilityText)
        XCTAssertEqual(cardsByName["Walk"]?.isAvailableNow, true)
        XCTAssertNil(cardsByName["Wake up early"]?.availabilityText)
        XCTAssertEqual(cardsByName["Wake up early"]?.isAvailableNow, true)
    }

    func testBuildMarksUnavailableConfiguredRoutineAndRemovesItFromRemainingCount() throws {
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

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let section = try XCTUnwrap(viewData.sections.first)
        let unavailableCard = try XCTUnwrap(section.routines.first { $0.name == "Wake up early" })

        XCTAssertEqual(section.remainingCount, 1)
        XCTAssertFalse(unavailableCard.isAvailableNow)
        XCTAssertEqual(unavailableCard.availabilityText, "Available 12:00 AM-6:45 AM")
        XCTAssertEqual(
            unavailableCard.unavailableAccessibilityPhrase,
            "unavailable now, available 12:00 AM to 6:45 AM"
        )
        XCTAssertEqual(
            unavailableCard.accessibilityLabel,
            "Wake up early, unavailable now, available 12:00 AM to 6:45 AM, "
                + "not completed today, 0 of 4 this week, no completions yet"
        )
    }

    func testBuildMarksCrossMidnightRoutineAvailableBeforeMidnight() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 23, minute: 30, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Evening yoga",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 1_380,
                availabilityEndMinute: 180,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let card = try XCTUnwrap(viewData.sections.first?.routines.first)

        XCTAssertTrue(card.isAvailableNow)
        XCTAssertNil(card.availabilityText)
    }

    func testBuildMarksCrossMidnightRoutineAvailableAfterMidnight() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 11, hour: 2, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Evening yoga",
                targetCount: 4,
                period: .weekly,
                availabilityStartMinute: 1_380,
                availabilityEndMinute: 180,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let card = try XCTUnwrap(viewData.sections.first?.routines.first)

        XCTAssertTrue(card.isAvailableNow)
        XCTAssertNil(card.availabilityText)
    }
}
