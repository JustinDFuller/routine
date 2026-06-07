import Foundation
import SwiftData

@MainActor
enum RoutinePersistenceSaveExecutor {
    static var save: (ModelContext) throws -> Void = { context in
        try context.save()
    }
}

@MainActor
enum RoutinePersistenceFetchExecutor {
    typealias RoutineFetcher = (ModelContext, FetchDescriptor<Routine>) throws -> [Routine]
    typealias GroupFetcher = (ModelContext, FetchDescriptor<RoutineGroup>) throws -> [RoutineGroup]
    typealias CompletionFetcher = (ModelContext, FetchDescriptor<RoutineCompletion>) throws -> [RoutineCompletion]
    typealias MetadataFetcher = (ModelContext, FetchDescriptor<AppMetadata>) throws -> [AppMetadata]

    static var fetchRoutines: RoutineFetcher = { context, descriptor in
        try context.fetch(descriptor)
    }

    static var fetchGroups: GroupFetcher = { context, descriptor in
        try context.fetch(descriptor)
    }

    static var fetchCompletions: CompletionFetcher = { context, descriptor in
        try context.fetch(descriptor)
    }

    static var fetchMetadata: MetadataFetcher = { context, descriptor in
        try context.fetch(descriptor)
    }
}

@MainActor
extension ModelContext {
    func routine(id: UUID) throws -> Routine {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.id == id
            }
        )

        do {
            guard let routine = try RoutinePersistenceFetchExecutor.fetchRoutines(self, descriptor).first else {
                throw PersistenceError.routineNotFound(id)
            }

            return routine
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    func group(id: UUID) throws -> RoutineGroup {
        let descriptor = FetchDescriptor<RoutineGroup>(
            predicate: #Predicate<RoutineGroup> { group in
                group.id == id
            }
        )

        do {
            guard let group = try RoutinePersistenceFetchExecutor.fetchGroups(self, descriptor).first else {
                throw PersistenceError.groupNotFound(id)
            }

            return group
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    func completion(id: UUID) throws -> RoutineCompletion {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.id == id
            }
        )

        do {
            guard let completion = try RoutinePersistenceFetchExecutor.fetchCompletions(self, descriptor).first else {
                throw PersistenceError.completionNotFound(id)
            }

            return completion
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    func metadata(key: String) throws -> AppMetadata {
        let descriptor = FetchDescriptor<AppMetadata>(
            predicate: #Predicate<AppMetadata> { metadata in
                metadata.key == key
            }
        )

        do {
            guard let metadata = try RoutinePersistenceFetchExecutor.fetchMetadata(self, descriptor).first else {
                throw PersistenceError.metadataNotFound(key)
            }

            return metadata
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    func completion(routineID: UUID, dayKey: String) throws -> RoutineCompletion? {
        let routineDayKey = Self.routineDayKey(routineID: routineID, dayKey: dayKey)
        return try completion(routineDayKey: routineDayKey)
    }

    func completion(routineDayKey: String) throws -> RoutineCompletion? {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.routineDayKey == routineDayKey
            }
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchCompletions(self, descriptor).first
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    func ensureNoCompletion(routineID: UUID, dayKey: String) throws {
        let routineDayKey = Self.routineDayKey(routineID: routineID, dayKey: dayKey)
        guard try completion(routineDayKey: routineDayKey) == nil else {
            throw PersistenceError.duplicateRoutineCompletion(routineID: routineID, dayKey: dayKey)
        }
    }

    func saveRoutineChanges() throws {
        do {
            try RoutinePersistenceSaveExecutor.save(self)
        } catch {
            throw PersistenceError.saveFailed(String(describing: error))
        }
    }

    private static func routineDayKey(routineID: UUID, dayKey: String) -> String {
        "\(routineID.uuidString)|\(dayKey)"
    }
}
