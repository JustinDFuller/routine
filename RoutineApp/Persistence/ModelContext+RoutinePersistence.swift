import Foundation
import SwiftData

@MainActor
enum RoutinePersistenceSaveExecutor {
    static var save: (ModelContext) throws -> Void = { context in
        try context.save()
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

        guard let routine = try fetch(descriptor).first else {
            throw PersistenceError.routineNotFound(id)
        }

        return routine
    }

    func group(id: UUID) throws -> RoutineGroup {
        let descriptor = FetchDescriptor<RoutineGroup>(
            predicate: #Predicate<RoutineGroup> { group in
                group.id == id
            }
        )

        guard let group = try fetch(descriptor).first else {
            throw PersistenceError.groupNotFound(id)
        }

        return group
    }

    func completion(id: UUID) throws -> RoutineCompletion {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.id == id
            }
        )

        guard let completion = try fetch(descriptor).first else {
            throw PersistenceError.completionNotFound(id)
        }

        return completion
    }

    func metadata(key: String) throws -> AppMetadata {
        let descriptor = FetchDescriptor<AppMetadata>(
            predicate: #Predicate<AppMetadata> { metadata in
                metadata.key == key
            }
        )

        guard let metadata = try fetch(descriptor).first else {
            throw PersistenceError.metadataNotFound(key)
        }

        return metadata
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

        return try fetch(descriptor).first
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
