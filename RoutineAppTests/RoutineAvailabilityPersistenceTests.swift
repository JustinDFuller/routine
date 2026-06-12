import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineAvailabilityPersistenceTests: XCTestCase {
    func testRoutineAvailabilityFieldsPersistAndBridgeToWindow() throws {
        let context = try makeContext()
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Wake up early",
            targetCount: 4,
            period: .weekly,
            availabilityStartMinute: 0,
            availabilityEndMinute: 405,
            sortOrder: 0,
            group: group
        )

        context.insert(group)
        context.insert(routine)
        try context.saveRoutineChanges()

        let fetchedRoutine = try context.routine(id: routine.id)
        XCTAssertEqual(fetchedRoutine.availabilityStartMinute, 0)
        XCTAssertEqual(fetchedRoutine.availabilityEndMinute, 405)
        XCTAssertEqual(fetchedRoutine.availabilityWindow?.start.minuteOfDay, 0)
        XCTAssertEqual(fetchedRoutine.availabilityWindow?.end.minuteOfDay, 405)
    }

    func testAllDayRoutinePersistsNilAvailabilityFields() throws {
        let context = try makeContext()
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )

        context.insert(group)
        context.insert(routine)
        try context.saveRoutineChanges()

        let fetchedRoutine = try context.routine(id: routine.id)
        XCTAssertNil(fetchedRoutine.availabilityStartMinute)
        XCTAssertNil(fetchedRoutine.availabilityEndMinute)
        XCTAssertNil(fetchedRoutine.availabilityWindow)
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }
}
