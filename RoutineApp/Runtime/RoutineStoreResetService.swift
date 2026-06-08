import SwiftData

@MainActor
enum RoutineStoreResetService {
    static func resetAllData(in context: ModelContext) throws {
        do {
            try deleteCompletions(in: context)
            try deleteRoutines(in: context)
            try deleteGroups(in: context)
            try deleteMetadata(in: context)
            try context.saveRoutineChanges()
        } catch {
            context.rollback()
            throw error
        }
    }

    private static func deleteCompletions(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<RoutineCompletion>()
        let completions = try RoutinePersistenceFetchExecutor.fetchCompletions(context, descriptor)

        for completion in completions {
            context.delete(completion)
        }
    }

    private static func deleteRoutines(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<Routine>()
        let routines = try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)

        for routine in routines {
            context.delete(routine)
        }
    }

    private static func deleteGroups(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<RoutineGroup>()
        let groups = try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)

        for group in groups {
            context.delete(group)
        }
    }

    private static func deleteMetadata(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<AppMetadata>()
        let metadata = try RoutinePersistenceFetchExecutor.fetchMetadata(context, descriptor)

        for item in metadata {
            context.delete(item)
        }
    }
}
