import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineManagementReorderIntegrationTests: ProjectionBuilderTestCase {
    func testTranslatedNativeRoutineMoveDownOneRowPersistsExpectedOrder() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 1),
            group: group,
            into: context
        )
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 2),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let translatedIndex = try XCTUnwrap(
            ManageReorderIndex.serviceIndex(
                from: IndexSet(integer: 0),
                destination: 2,
                itemCount: 3
            )
        )
        XCTAssertEqual(translatedIndex, 1)

        try RoutineManagementService(context: context).moveRoutine(
            id: walk.id,
            toGroupID: group.id,
            at: translatedIndex
        )

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections[0].routines.map(\.name), ["Read", "Walk", "Lift"])
        XCTAssertEqual(dashboardViewData.sections[0].routines.map(\.name), ["Read", "Walk", "Lift"])
    }

    func testTranslatedNativeGroupMoveDownOneRowPersistsExpectedOrder() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let home = insertGroup(name: "Home", sortOrder: 0, into: context)
        let work = insertGroup(name: "Work", sortOrder: 1, into: context)
        let fitness = insertGroup(name: "Fitness", sortOrder: 2, into: context)
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
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Lift", targetCount: 5, period: .weekly, sortOrder: 0),
            group: fitness,
            into: context
        )
        try saveChanges(in: context)

        let translatedIndex = try XCTUnwrap(
            ManageReorderIndex.serviceIndex(
                from: IndexSet(integer: 0),
                destination: 2,
                itemCount: 3
            )
        )
        XCTAssertEqual(translatedIndex, 1)

        try RoutineManagementService(context: context).moveGroup(id: home.id, to: translatedIndex)

        let manageViewData = try ManageProjectionBuilder(context: context).build()
        let dashboardViewData = try DashboardProjectionBuilder(context: context, routineCalendar: calendar).build(
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, calendar: calendar.calendar)
        )

        XCTAssertEqual(manageViewData.sections.map(\.name), ["Work", "Home", "Fitness"])
        XCTAssertEqual(dashboardViewData.sections.map(\.name), ["Work", "Home", "Fitness"])
    }
}
