import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
class RoutineManagementServiceTestCase: XCTestCase {
    override func tearDown() {
        MainActor.assumeIsolated {
            RoutinePersistenceFetchExecutor.fetchRoutines = { context, descriptor in
                try context.fetch(descriptor)
            }
            RoutinePersistenceFetchExecutor.fetchGroups = { context, descriptor in
                try context.fetch(descriptor)
            }
            RoutinePersistenceSaveExecutor.save = { context in
                try context.save()
            }
        }
        super.tearDown()
    }

    func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    func insertGroup(
        name: String,
        sortOrder: Int,
        into context: ModelContext
    ) throws -> RoutineGroup {
        let group = RoutineGroup(name: name, sortOrder: sortOrder)
        context.insert(group)
        try context.saveRoutineChanges()
        return group
    }

    func insertRoutine(
        seed: RoutineTestSeed,
        group: RoutineGroup,
        into context: ModelContext
    ) throws -> Routine {
        let routine = Routine(
            id: seed.id,
            name: seed.name,
            targetCount: seed.targetCount,
            period: seed.period,
            availabilityStartMinute: seed.availabilityStartMinute,
            availabilityEndMinute: seed.availabilityEndMinute,
            sortOrder: seed.sortOrder,
            group: group
        )
        context.insert(routine)
        try context.saveRoutineChanges()
        return routine
    }

    func fetchGroups(in context: ModelContext) throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchRoutines(in context: ModelContext, groupID: UUID) throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.groupID == groupID
            },
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.name)]
        )
        return try context.fetch(descriptor)
    }

    func fetchCompletions(in context: ModelContext) throws -> [RoutineCompletion] {
        try context.fetch(FetchDescriptor<RoutineCompletion>())
    }

    func makeDay(year: Int, month: Int, day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }
}

struct SimulatedManagementSaveFailure: Error, CustomStringConvertible {
    let description = "simulated management save failure"
}
