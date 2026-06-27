import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class DashboardProjectionBuilderBreakTests: ProjectionBuilderTestCase {
    func testRoutineOnBreakIsExcludedFromRemainingCount() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        insertRoutine(
            seed: RoutineTestSeed(
                name: "Break Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        insertRoutine(
            seed: RoutineTestSeed(name: "Active Read", targetCount: 3, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let section = try XCTUnwrap(viewData.sections.first)

        XCTAssertEqual(section.remainingCount, 1)
        let breakCard = try XCTUnwrap(section.routines.first { $0.name == "Break Walk" })
        XCTAssertTrue(breakCard.isOnBreak)
        XCTAssertNotNil(breakCard.breakResumeText)
        XCTAssertEqual(breakCard.breakSource, .routine)
    }

    func testRoutineOnBreakIsPartitionedIntoBreakCollapsedRow() throws {
        let calendar = makeCalendar()
        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let today = try makeDay(year: 2026, month: 6, day: 22)

        let breakCard = RoutineCardViewData(
            id: UUID(),
            name: "Break Walk",
            period: .weekly,
            countText: "0/3",
            periodText: "week",
            lastDoneText: "Never",
            availabilityText: nil,
            accessibilityLabel: "Break Walk",
            unavailableAccessibilityPhrase: nil,
            progressRing: ProgressRingViewData(
                targetCount: 3, completedCount: 0, fillRatio: 0, showsTodayCheckmark: false
            ),
            isAvailableNow: true,
            isCompletedToday: false,
            isTargetMet: false,
            isOverTarget: false,
            isOnBreak: true,
            breakResumeText: calendar.relativeLabel(for: nextMonday, today: today),
            breakSource: .routine
        )
        let activeCard = RoutineCardViewData(
            id: UUID(),
            name: "Active Read",
            period: .weekly,
            countText: "0/3",
            periodText: "week",
            lastDoneText: "Never",
            availabilityText: nil,
            accessibilityLabel: "Active Read",
            unavailableAccessibilityPhrase: nil,
            progressRing: ProgressRingViewData(
                targetCount: 3, completedCount: 0, fillRatio: 0, showsTodayCheckmark: false
            ),
            isAvailableNow: true,
            isCompletedToday: false,
            isTargetMet: false,
            isOverTarget: false,
            isOnBreak: false,
            breakResumeText: nil
        )

        let partition = RoutineSectionViewData.displayPartition(
            collapseCompletedToday: false,
            collapseGoalMetToday: false,
            collapseUnavailableToday: false,
            routines: [breakCard, activeCard]
        )

        XCTAssertEqual(partition.fullCards.map(\.id), [activeCard.id])
        XCTAssertEqual(partition.collapsedRows.count, 1)
        XCTAssertEqual(partition.collapsedRows.first?.style, .onBreak)
        XCTAssertEqual(partition.collapsedRows.first?.id, breakCard.id)
    }

    func testGlobalBreakBannerIsNilWhenNoBreakSet() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        XCTAssertNil(viewData.globalBreak)
    }

    func testGlobalBreakBannerPresentWhenActiveGlobalBreakIsSet() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 6, day: 29), now: now)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        XCTAssertEqual(viewData.globalBreak?.resumeText, "Jun 29, 2026")
    }

    func testGlobalBreakBannerIsNilOnResumeDay() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 29, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 6, day: 29), now: now)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        XCTAssertNil(viewData.globalBreak)
    }

    func testRoutineBreakEndsWhenTodayEqualsResumeDayKey() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 29, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        insertRoutine(
            seed: RoutineTestSeed(
                name: "Resuming Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let section = try XCTUnwrap(viewData.sections.first)
        let card = try XCTUnwrap(section.routines.first { $0.name == "Resuming Walk" })

        XCTAssertFalse(card.isOnBreak)
        XCTAssertNil(card.breakResumeText)
        XCTAssertNil(card.breakSource)
        XCTAssertEqual(section.remainingCount, 1)
    }

    func testGlobalBreakSourceAppliesToRoutineWithoutRoutineBreak() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)
        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 7, day: 1), now: now)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let card = try XCTUnwrap(viewData.sections.first?.routines.first)

        XCTAssertTrue(card.isOnBreak)
        XCTAssertEqual(card.breakSource, .global)
        XCTAssertEqual(card.breakResumeText, "Jul 1, 2026")
        XCTAssertEqual(viewData.sections.first?.remainingCount, 0)
    }

    func testBothBreakSourcesUseLaterResumeDay() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                breakResumeDayKey: try makeDay(year: 2026, month: 7, day: 6).key,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)
        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 7, day: 1), now: now)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let card = try XCTUnwrap(viewData.sections.first?.routines.first)

        XCTAssertTrue(card.isOnBreak)
        XCTAssertEqual(card.breakSource, .both)
        XCTAssertEqual(card.breakResumeText, "Jul 6, 2026")
    }
}
