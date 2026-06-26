import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class DashboardProjectionBuilderPauseTests: ProjectionBuilderTestCase {
    func testPausedRoutineIsExcludedFromRemainingCount() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 22, hour: 9, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)

        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        insertRoutine(
            seed: RoutineTestSeed(
                name: "Paused Walk",
                targetCount: 3,
                period: .weekly,
                pauseResumeDayKey: nextMonday.key,
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
        let pausedCard = try XCTUnwrap(section.routines.first { $0.name == "Paused Walk" })
        XCTAssertTrue(pausedCard.isPaused)
        XCTAssertNotNil(pausedCard.pauseResumeText)
    }

    func testPausedRoutineIsPartitionedIntoPausedCollapsedRow() throws {
        let calendar = makeCalendar()
        let nextMonday = try makeDay(year: 2026, month: 6, day: 29)
        let today = try makeDay(year: 2026, month: 6, day: 22)

        let pausedCard = RoutineCardViewData(
            id: UUID(),
            name: "Paused Walk",
            period: .weekly,
            countText: "0/3",
            periodText: "week",
            lastDoneText: "Never",
            availabilityText: nil,
            accessibilityLabel: "Paused Walk",
            unavailableAccessibilityPhrase: nil,
            progressRing: ProgressRingViewData(
                targetCount: 3, completedCount: 0, fillRatio: 0, showsTodayCheckmark: false
            ),
            isAvailableNow: true,
            isCompletedToday: false,
            isTargetMet: false,
            isOverTarget: false,
            isPaused: true,
            pauseResumeText: calendar.relativeLabel(for: nextMonday, today: today)
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
            isPaused: false,
            pauseResumeText: nil
        )

        let partition = RoutineSectionViewData.displayPartition(
            collapseCompletedToday: false,
            collapseGoalMetToday: false,
            collapseUnavailableToday: false,
            routines: [pausedCard, activeCard]
        )

        XCTAssertEqual(partition.fullCards.map(\.id), [activeCard.id])
        XCTAssertEqual(partition.collapsedRows.count, 1)
        XCTAssertEqual(partition.collapsedRows.first?.style, .paused)
        XCTAssertEqual(partition.collapsedRows.first?.id, pausedCard.id)
    }

    func testGlobalPauseBannerIsNilWhenNoPauseSet() throws {
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
        XCTAssertNil(viewData.globalPause)
    }

    func testGlobalPauseBannerPresentWhenGlobalPauseIsSet() throws {
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

        try context.setGlobalPause(
            anchor: try makeDay(year: 2026, month: 6, day: 22),
            skipPeriods: 1,
            now: now
        )

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        XCTAssertNotNil(viewData.globalPause)
    }

    func testRoutineResumesWhenTodayEqualsPauseResumeDayKey() throws {
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
                pauseResumeDayKey: nextMonday.key,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let section = try XCTUnwrap(viewData.sections.first)
        let card = try XCTUnwrap(section.routines.first { $0.name == "Resuming Walk" })

        XCTAssertFalse(card.isPaused)
        XCTAssertNil(card.pauseResumeText)
        XCTAssertEqual(section.remainingCount, 1)
    }
}
