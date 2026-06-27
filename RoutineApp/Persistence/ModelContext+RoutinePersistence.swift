import Foundation
import OSLog
import RoutineCore
import SwiftData

private enum PersistenceDiagnostics {
    static let logger = AppDiagnostics.logger(.persistence)
    static let signposter = AppDiagnostics.signposter(.persistence)
}

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
        let saveSignpost = PersistenceDiagnostics.signposter.beginInterval("saveRoutineChanges")
        defer {
            PersistenceDiagnostics.signposter.endInterval("saveRoutineChanges", saveSignpost)
        }

        do {
            try RoutinePersistenceSaveExecutor.save(self)
        } catch {
            PersistenceDiagnostics.logger.error(
                "saveRoutineChangesFailed e=\(String(describing: error), privacy: .private)"
            )
            throw PersistenceError.saveFailed(String(describing: error))
        }
    }

    private static func routineDayKey(routineID: UUID, dayKey: String) -> String {
        "\(routineID.uuidString)|\(dayKey)"
    }

    func globalBreak(routineCalendar: RoutineCalendar) -> GlobalBreak? {
        if let metadata = try? metadata(key: AppMetadataKeys.globalBreak),
            let globalBreak = Self.decodeGlobalBreak(from: metadata.value, routineCalendar: routineCalendar)
        {
            return globalBreak
        }

        guard let legacyMetadata = try? metadata(key: AppMetadataKeys.legacyGlobalPause) else {
            return nil
        }

        return Self.decodeLegacyGlobalPause(from: legacyMetadata.value, routineCalendar: routineCalendar)
    }

    func setGlobalBreak(resumeDay: RoutineDay, now: Date = .now) throws {
        let payload = GlobalBreakPayload(resumeDayKey: resumeDay.key)
        guard let data = try? JSONEncoder().encode(payload),
            let value = String(data: data, encoding: .utf8)
        else {
            throw PersistenceError.saveFailed("Unable to encode global break.")
        }

        if let existing = try? metadata(key: AppMetadataKeys.globalBreak) {
            existing.value = value
            existing.updatedAt = now
        } else {
            insert(AppMetadata(key: AppMetadataKeys.globalBreak, value: value, updatedAt: now))
        }

        if let legacy = try? metadata(key: AppMetadataKeys.legacyGlobalPause) {
            delete(legacy)
        }
    }

    func clearGlobalBreak(now: Date = .now) throws {
        if let existing = try? metadata(key: AppMetadataKeys.globalBreak) {
            existing.updatedAt = now
            delete(existing)
        }

        if let legacy = try? metadata(key: AppMetadataKeys.legacyGlobalPause) {
            legacy.updatedAt = now
            delete(legacy)
        }
    }

    private static func decodeGlobalBreak(
        from value: String,
        routineCalendar: RoutineCalendar
    ) -> GlobalBreak? {
        guard let data = value.data(using: .utf8),
            let payload = try? JSONDecoder().decode(GlobalBreakPayload.self, from: data),
            let resumeDay = RoutineDay(key: payload.resumeDayKey)
        else {
            return decodeLegacyGlobalPause(from: value, routineCalendar: routineCalendar)
        }

        return GlobalBreak(resumeDay: resumeDay)
    }

    private static func decodeLegacyGlobalPause(
        from value: String,
        routineCalendar: RoutineCalendar
    ) -> GlobalBreak? {
        guard let data = value.data(using: .utf8),
            let payload = try? JSONDecoder().decode(LegacyGlobalPausePayload.self, from: data),
            let anchor = RoutineDay(key: payload.anchorDayKey)
        else {
            return nil
        }

        let weeklyStart = routineCalendar.periodStart(for: .weekly, containing: anchor)
        let monthlyStart = routineCalendar.periodStart(for: .monthly, containing: anchor)
        let weeklyResume = routineCalendar.advancingPeriodStart(
            weeklyStart,
            by: payload.skipPeriods,
            period: .weekly
        )
        let monthlyResume = routineCalendar.advancingPeriodStart(
            monthlyStart,
            by: payload.skipPeriods,
            period: .monthly
        )

        return GlobalBreak(resumeDay: max(weeklyResume, monthlyResume))
    }
}

private enum AppMetadataKeys {
    static let globalBreak = "global.break"
    static let legacyGlobalPause = "global.pause"
}

private struct GlobalBreakPayload: Codable {
    let resumeDayKey: String
}

private struct LegacyGlobalPausePayload: Codable {
    let anchorDayKey: String
    let skipPeriods: Int
}
