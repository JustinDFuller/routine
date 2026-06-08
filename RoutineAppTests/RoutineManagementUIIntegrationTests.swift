import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineManagementUIIntegrationTests: XCTestCase {
    func testCreateAndRenameGroupAppearInManageAndDashboardProjections() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        _ = insertGroup(name: "Health", sortOrder: 0, into: context)
        try saveChanges(in: context)

        let createdGroupID = try RoutineManagementService(context: context).createGroup(name: "  Home  ")
        try RoutineManagementService(context: context).renameGroup(id: createdGroupID, name: " Fitness ")

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.groupChoices.map(\.name), ["Health", "Fitness"])
        XCTAssertEqual(manageViewData.sections.map(\.name), ["Health", "Fitness"])
        XCTAssertEqual(dashboardViewData.sections.map(\.name), ["Health", "Fitness"])
    }

    func testCreateRoutineAppearsInManageAndDashboardProjections() throws {
        let context = try makeContext()
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        try saveChanges(in: context)

        _ = try RoutineManagementService(context: context).createRoutine(
            RoutineDraft(name: "Walk", targetCount: 5, period: .weekly, groupID: group.id)
        )

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: makeCalendar()).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: makeCalendar().calendar)
        )

        XCTAssertEqual(manageViewData.sections[0].routines.map(\.name), ["Walk"])
        XCTAssertEqual(manageViewData.sections[0].routines.first?.summaryText, "5 per week")
        XCTAssertEqual(dashboardViewData.sections[0].routines.map(\.name), ["Walk"])
        XCTAssertEqual(dashboardViewData.sections[0].routines.first?.countText, "0/5")
    }

    func testEditRoutineUpdatesManageRowsAndDashboardSections() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let home = insertGroup(name: "Home", sortOrder: 0, into: context)
        let work = insertGroup(name: "Work", sortOrder: 1, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: home,
            into: context
        )
        try saveChanges(in: context)

        try RoutineManagementService(context: context).updateRoutine(
            id: routine.id,
            with: RoutineDraft(name: "Budget Review", targetCount: 2, period: .monthly, groupID: work.id)
        )

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertTrue(manageViewData.sections[0].routines.isEmpty)
        XCTAssertEqual(manageViewData.sections[1].routines.map(\.name), ["Budget Review"])
        XCTAssertEqual(manageViewData.sections[1].routines.first?.summaryText, "2 per month")

        XCTAssertTrue(dashboardViewData.sections[0].routines.isEmpty)
        XCTAssertEqual(dashboardViewData.sections[1].routines.map(\.name), ["Budget Review"])
        XCTAssertEqual(dashboardViewData.sections[1].routines.first?.periodText, "month")
        XCTAssertEqual(dashboardViewData.sections[1].routines.first?.countText, "0/2")
    }

    func testDeleteRoutineRemovesManageAndDashboardRowsAndCascadesHistory() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 8),
            completedAt: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar),
            into: context
        )
        try saveChanges(in: context)

        try RoutineManagementService(context: context).deleteRoutine(id: routine.id)

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 10, calendar: calendar.calendar)
        )
        let completions = try context.fetch(FetchDescriptor<RoutineCompletion>())

        XCTAssertTrue(manageViewData.sections[0].routines.isEmpty)
        XCTAssertTrue(dashboardViewData.sections[0].routines.isEmpty)
        XCTAssertTrue(completions.isEmpty)
    }

    func testDeleteEmptyGroupRemovesSectionFromManageAndDashboardProjections() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        _ = insertGroup(name: "Health", sortOrder: 0, into: context)
        let deletedGroup = insertGroup(name: "Archive", sortOrder: 1, into: context)
        try saveChanges(in: context)

        try RoutineManagementService(context: context).deleteGroup(id: deletedGroup.id)

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections.map(\.name), ["Health"])
        XCTAssertEqual(dashboardViewData.sections.map(\.name), ["Health"])
    }

    func testDeleteNonEmptyGroupIsBlockedWithoutOrphaningOrMovingRoutines() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let health = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertGroup(name: "Home", sortOrder: 1, into: context)
        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: health,
            into: context
        )
        try saveChanges(in: context)

        XCTAssertThrowsError(try RoutineManagementService(context: context).deleteGroup(id: health.id)) { error in
            XCTAssertEqual(error as? RoutineManagementError, .nonEmptyGroup(health.id))
        }

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections.map(\.name), ["Health", "Home"])
        XCTAssertEqual(manageViewData.sections[0].routines.map(\.name), ["Walk"])
        XCTAssertTrue(manageViewData.sections[1].routines.isEmpty)
        XCTAssertEqual(dashboardViewData.sections.map(\.name), ["Health", "Home"])
        XCTAssertEqual(dashboardViewData.sections[0].routines.map(\.name), ["Walk"])
        XCTAssertEqual(try context.routine(id: walk.id).groupID, health.id)
    }

    func testMoveRoutineWithinGroupPersistsManageAndDashboardRowOrder() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        let lift = insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 2),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        try RoutineManagementService(context: context).moveRoutine(id: lift.id, toGroupID: group.id, at: 1)

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections[0].routines.map(\.name), ["Walk", "Lift", "Read"])
        XCTAssertEqual(dashboardViewData.sections[0].routines.map(\.name), ["Walk", "Lift", "Read"])
        XCTAssertEqual(try fetchRoutines(in: context, groupID: group.id).map(\.sortOrder), [0, 1, 2])
    }

    func testMoveGroupPersistsManageAndDashboardSectionOrder() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let health = insertGroup(name: "Health", sortOrder: 0, into: context)
        let home = insertGroup(name: "Home", sortOrder: 1, into: context)
        let work = insertGroup(name: "Work", sortOrder: 2, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: health,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Dishes", targetCount: 4, period: .weekly, sortOrder: 0),
            group: home,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Review", targetCount: 2, period: .monthly, sortOrder: 0),
            group: work,
            into: context
        )
        try saveChanges(in: context)

        try RoutineManagementService(context: context).moveGroup(id: work.id, to: 1)

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections.map(\.name), ["Health", "Work", "Home"])
        XCTAssertEqual(dashboardViewData.sections.map(\.name), ["Health", "Work", "Home"])
        XCTAssertEqual(try fetchGroups(in: context).map(\.sortOrder), [0, 1, 2])
    }

    func testUpdateRoutineGroupThroughManagementPathUpdatesOrderingInBothProjections() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let home = insertGroup(name: "Home", sortOrder: 0, into: context)
        let work = insertGroup(name: "Work", sortOrder: 1, into: context)
        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: home,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 1),
            group: home,
            into: context
        )
        let budget = insertRoutine(
            seed: RoutineTestSeed(name: "Budget", targetCount: 2, period: .monthly, sortOrder: 0),
            group: work,
            into: context
        )
        try saveChanges(in: context)

        try RoutineManagementService(context: context).updateRoutine(
            id: walk.id,
            with: RoutineDraft(name: "Walk", targetCount: 3, period: .weekly, groupID: work.id)
        )

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections[0].routines.map(\.name), ["Read"])
        XCTAssertEqual(manageViewData.sections[1].routines.map(\.name), ["Budget", "Walk"])
        XCTAssertEqual(dashboardViewData.sections[0].routines.map(\.name), ["Read"])
        XCTAssertEqual(dashboardViewData.sections[1].routines.map(\.name), ["Budget", "Walk"])
        XCTAssertEqual(try fetchRoutines(in: context, groupID: home.id).map(\.sortOrder), [0])
        let workRoutines = try fetchRoutines(in: context, groupID: work.id)
        XCTAssertEqual(workRoutines.map(\.name), ["Budget", "Walk"])
        XCTAssertEqual(workRoutines.map(\.sortOrder), [0, 1])
        XCTAssertEqual(try context.routine(id: walk.id).groupID, work.id)
        XCTAssertEqual(try context.routine(id: budget.id).groupID, work.id)
    }
}

@MainActor
extension RoutineManagementUIIntegrationTests {
    fileprivate func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    fileprivate func makeCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        guard let timeZone = TimeZone(identifier: "America/New_York") else {
            preconditionFailure("Expected America/New_York timezone.")
        }

        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }

    @discardableResult
    fileprivate func insertGroup(name: String, sortOrder: Int, into context: ModelContext) -> RoutineGroup {
        let group = RoutineGroup(name: name, sortOrder: sortOrder)
        context.insert(group)
        return group
    }

    @discardableResult
    fileprivate func insertRoutine(
        seed: RoutineTestSeed,
        group: RoutineGroup,
        into context: ModelContext
    ) -> Routine {
        let routine = Routine(
            id: seed.id,
            name: seed.name,
            targetCount: seed.targetCount,
            period: seed.period,
            sortOrder: seed.sortOrder,
            group: group
        )
        context.insert(routine)
        return routine
    }

    @discardableResult
    fileprivate func insertCompletion(
        routine: Routine,
        day: RoutineDay,
        completedAt: Date,
        into context: ModelContext
    ) -> RoutineCompletion {
        let completion = RoutineCompletion(routine: routine, day: day, completedAt: completedAt)
        context.insert(completion)
        return completion
    }

    fileprivate func saveChanges(in context: ModelContext) throws {
        try context.saveRoutineChanges()
    }

    fileprivate func fetchGroups(in context: ModelContext) throws -> [RoutineGroup] {
        try context.fetch(
            FetchDescriptor<RoutineGroup>(
                sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
            )
        )
    }

    fileprivate func fetchRoutines(in context: ModelContext, groupID: UUID) throws -> [Routine] {
        try context.fetch(
            FetchDescriptor<Routine>(
                predicate: #Predicate<Routine> { routine in
                    routine.groupID == groupID
                },
                sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
            )
        )
    }

    fileprivate func makeDay(year: Int, month: Int, day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    fileprivate func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour

        guard let date = calendar.date(from: components) else {
            preconditionFailure("Unable to build date for \(year)-\(month)-\(day) \(hour):00.")
        }

        return date
    }
}
