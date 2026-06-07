import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class DashboardProjectionBuilderTests: ProjectionBuilderTestCase {
    func testBuildIncludesOrderedGroupsOrderedRoutinesEmptyGroupCompletedMonthlyAndUngrouped() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        let health = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertGroup(name: "Alpha", sortOrder: 1, into: context)
        let zeta = insertGroup(name: "Zeta", sortOrder: 1, into: context)

        _ = insertRoutine(
            name: "Early Stretch",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: health,
            createdAt: makeDate(year: 2026, month: 6, day: 1, hour: 8, calendar: calendar.calendar),
            into: context
        )
        let secondHealth = insertRoutine(
            name: "Later Stretch",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: health,
            createdAt: makeDate(year: 2026, month: 6, day: 2, hour: 8, calendar: calendar.calendar),
            into: context
        )
        let monthly = insertRoutine(
            name: "Budget Review",
            targetCount: 1,
            period: .monthly,
            sortOrder: 2,
            group: zeta,
            into: context
        )
        let orphanSourceGroup = insertGroup(name: "Temporary", sortOrder: 9, into: context)
        let ungrouped = insertRoutine(
            name: "Loose Task",
            targetCount: 2,
            period: .weekly,
            sortOrder: 0,
            group: orphanSourceGroup,
            into: context
        )

        insertCompletion(
            routine: secondHealth,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )
        insertCompletion(
            routine: monthly,
            day: try makeDay(year: 2026, month: 6, day: 3),
            completedAt: makeDate(year: 2026, month: 6, day: 3, hour: 8, calendar: calendar.calendar),
            into: context
        )

        guard let missingGroupID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE") else {
            preconditionFailure("Expected stable missing-group UUID.")
        }

        ungrouped.group = nil
        ungrouped.groupID = missingGroupID

        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)

        XCTAssertEqual(viewData.title, "Today")
        XCTAssertFalse(viewData.isEmpty)
        XCTAssertEqual(viewData.sections.map(\.name), ["Health", "Alpha", "Zeta", "Temporary", "Ungrouped"])
        XCTAssertEqual(viewData.sections[0].routines.map(\.name), ["Early Stretch", "Later Stretch"])
        XCTAssertTrue(viewData.sections[1].routines.isEmpty)
        XCTAssertEqual(viewData.sections[2].routines.map(\.name), ["Budget Review"])
        XCTAssertTrue(viewData.sections[3].routines.isEmpty)
        XCTAssertEqual(viewData.sections[4].routines.map(\.name), ["Loose Task"])
    }

    func testBuildUsesMondayStartWeekProgressSectionRemainingCountAndLabels() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let walk = insertRoutine(
            name: "Walk",
            targetCount: 5,
            period: .weekly,
            sortOrder: 0,
            group: group,
            into: context
        )
        let read = insertRoutine(
            name: "Read",
            targetCount: 4,
            period: .weekly,
            sortOrder: 1,
            group: group,
            into: context
        )

        insertCompletion(
            routine: walk,
            day: try makeDay(year: 2026, month: 6, day: 8),
            completedAt: makeDate(year: 2026, month: 6, day: 8, hour: 8, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: walk,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )
        insertCompletion(
            routine: walk,
            day: try makeDay(year: 2026, month: 6, day: 7),
            completedAt: makeDate(year: 2026, month: 6, day: 7, hour: 8, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: read,
            day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, hour: 8, calendar: calendar.calendar),
            into: context
        )

        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let section = try XCTUnwrap(viewData.sections.first)
        let walkCard = try XCTUnwrap(section.routines.first { $0.name == "Walk" })
        let readCard = try XCTUnwrap(section.routines.first { $0.name == "Read" })

        XCTAssertEqual(section.remainingCount, 1)

        XCTAssertEqual(walkCard.countText, "2/5")
        XCTAssertEqual(walkCard.periodText, "week")
        XCTAssertEqual(walkCard.lastDoneText, "Today")
        XCTAssertEqual(
            walkCard.accessibilityLabel,
            "Walk, completed today, 2 of 5 this week, last done Today"
        )
        XCTAssertTrue(walkCard.isCompletedToday)

        XCTAssertEqual(readCard.countText, "1/4")
        XCTAssertEqual(readCard.lastDoneText, "Yesterday")
        XCTAssertEqual(
            readCard.accessibilityLabel,
            "Read, not completed today, 1 of 4 this week, last done Yesterday"
        )
        XCTAssertFalse(readCard.isCompletedToday)
    }

    func testBuildUsesCalendarMonthProgressForMonthlyRoutines() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        let group = insertGroup(name: "Home", sortOrder: 0, into: context)
        let routine = insertRoutine(
            name: "Deep Clean",
            targetCount: 3,
            period: .monthly,
            sortOrder: 0,
            group: group,
            into: context
        )

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 5, day: 31),
            completedAt: makeDate(year: 2026, month: 5, day: 31, hour: 8, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 1),
            completedAt: makeDate(year: 2026, month: 6, day: 1, hour: 8, calendar: calendar.calendar),
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: now,
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 7, day: 1),
            completedAt: makeDate(year: 2026, month: 7, day: 1, hour: 8, calendar: calendar.calendar),
            into: context
        )

        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let card = try XCTUnwrap(viewData.sections.first?.routines.first)

        XCTAssertEqual(card.countText, "2/3")
        XCTAssertEqual(card.periodText, "month")
        XCTAssertTrue(card.isCompletedToday)
    }

    func testBuildProducesLastDoneTextAcrossRelativeCases() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Cases", sortOrder: 0, into: context)

        let never = insertRoutine(
            name: "Never", targetCount: 1, period: .weekly, sortOrder: 0, group: group, into: context)
        let todayRoutine = insertRoutine(
            name: "Today", targetCount: 1, period: .weekly, sortOrder: 1, group: group, into: context)
        let yesterdayRoutine = insertRoutine(
            name: "Yesterday", targetCount: 1, period: .weekly, sortOrder: 2, group: group, into: context)
        let recent = insertRoutine(
            name: "Recent", targetCount: 1, period: .weekly, sortOrder: 3, group: group, into: context)
        let currentYear = insertRoutine(
            name: "CurrentYear", targetCount: 1, period: .weekly, sortOrder: 4, group: group, into: context)
        let priorYear = insertRoutine(
            name: "PriorYear", targetCount: 1, period: .weekly, sortOrder: 5, group: group, into: context)

        insertCompletion(
            routine: todayRoutine, day: try makeDay(year: 2026, month: 6, day: 10), completedAt: now, into: context)
        insertCompletion(
            routine: yesterdayRoutine, day: try makeDay(year: 2026, month: 6, day: 9),
            completedAt: makeDate(year: 2026, month: 6, day: 9, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: recent, day: try makeDay(year: 2026, month: 6, day: 7),
            completedAt: makeDate(year: 2026, month: 6, day: 7, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: currentYear, day: try makeDay(year: 2026, month: 1, day: 2),
            completedAt: makeDate(year: 2026, month: 1, day: 2, calendar: calendar.calendar), into: context)
        insertCompletion(
            routine: priorYear, day: try makeDay(year: 2025, month: 6, day: 2),
            completedAt: makeDate(year: 2025, month: 6, day: 2, calendar: calendar.calendar), into: context)

        _ = never
        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let cardsByName = Dictionary(uniqueKeysWithValues: viewData.sections[0].routines.map { ($0.name, $0) })

        XCTAssertEqual(cardsByName["Never"]?.lastDoneText, "Never")
        XCTAssertEqual(cardsByName["Today"]?.lastDoneText, "Today")
        XCTAssertEqual(cardsByName["Yesterday"]?.lastDoneText, "Yesterday")
        XCTAssertEqual(cardsByName["Recent"]?.lastDoneText, "3d ago")
        XCTAssertEqual(cardsByName["CurrentYear"]?.lastDoneText, "Jan 2")
        XCTAssertEqual(cardsByName["PriorYear"]?.lastDoneText, "Jun 2, 2025")
    }

    func testBuildProducesTargetMetOverTargetAndSegmentSwitchAtNine() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 11, hour: 9, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Goals", sortOrder: 0, into: context)

        let met = insertRoutine(name: "Met", targetCount: 3, period: .weekly, sortOrder: 0, group: group, into: context)
        let over = insertRoutine(
            name: "Over", targetCount: 3, period: .weekly, sortOrder: 1, group: group, into: context)
        let nine = insertRoutine(
            name: "Nine", targetCount: 9, period: .monthly, sortOrder: 2, group: group, into: context)

        for day in 9...11 {
            insertCompletion(
                routine: met,
                day: try makeDay(year: 2026, month: 6, day: day),
                completedAt: makeDate(year: 2026, month: 6, day: day, calendar: calendar.calendar),
                into: context
            )
        }

        for day in 8...11 {
            insertCompletion(
                routine: over,
                day: try makeDay(year: 2026, month: 6, day: day),
                completedAt: makeDate(year: 2026, month: 6, day: day, calendar: calendar.calendar),
                into: context
            )
        }

        for day in 1...10 {
            insertCompletion(
                routine: nine,
                day: try makeDay(year: 2026, month: 6, day: day),
                completedAt: makeDate(year: 2026, month: 6, day: day, calendar: calendar.calendar),
                into: context
            )
        }

        try saveChanges(in: context)

        let viewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(now: now)
        let cardsByName = Dictionary(uniqueKeysWithValues: viewData.sections[0].routines.map { ($0.name, $0) })

        let metCard = try XCTUnwrap(cardsByName["Met"])
        XCTAssertTrue(metCard.isTargetMet)
        XCTAssertFalse(metCard.isOverTarget)
        XCTAssertEqual(metCard.countText, "3/3")
        XCTAssertEqual(metCard.progressRing.fillRatio, 1)
        XCTAssertTrue(metCard.progressRing.showsSegments)

        let overCard = try XCTUnwrap(cardsByName["Over"])
        XCTAssertTrue(overCard.isTargetMet)
        XCTAssertTrue(overCard.isOverTarget)
        XCTAssertEqual(overCard.countText, "4/3")
        XCTAssertEqual(overCard.progressRing.completedCount, 4)
        XCTAssertEqual(overCard.progressRing.fillRatio, 1)

        let nineCard = try XCTUnwrap(cardsByName["Nine"])
        XCTAssertEqual(nineCard.countText, "10/9")
        XCTAssertFalse(nineCard.progressRing.showsSegments)
        XCTAssertEqual(nineCard.progressRing.completedCount, 10)
        XCTAssertEqual(nineCard.progressRing.fillRatio, 1)
    }

    func testBuildMapsFetchFailuresToPersistenceError() throws {
        let context = try makeContext()
        let originalFetch = RoutinePersistenceFetchExecutor.fetchGroups
        defer { RoutinePersistenceFetchExecutor.fetchGroups = originalFetch }

        RoutinePersistenceFetchExecutor.fetchGroups = { _, _ in
            throw SimulatedProjectionFetchFailure()
        }

        XCTAssertThrowsError(try DashboardProjectionBuilder(context: context).build()) { error in
            XCTAssertEqual(
                error as? PersistenceError,
                .fetchFailed("simulated projection fetch failure")
            )
        }
    }
}
