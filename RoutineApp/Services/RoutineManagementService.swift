import Foundation
import RoutineCore
import SwiftData

struct RoutineDraft: Equatable, Sendable {
    var name: String
    var targetCount: Int
    var period: RoutinePeriod
    var groupID: UUID
}

enum RoutineManagementError: LocalizedError, Equatable {
    case nonEmptyGroup(UUID)

    var errorDescription: String? {
        switch self {
        case .nonEmptyGroup:
            "Delete the routines in this group first."
        }
    }
}

@MainActor
final class RoutineManagementService {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func createRoutine(_ draft: RoutineDraft, now: Date = .now) throws -> UUID {
        let name = try trimmedRoutineName(draft.name)
        try validateTargetCount(draft.targetCount, for: draft.period)

        let group = try context.group(id: draft.groupID)
        let existingRoutines = try routines(inGroupID: group.id)
        let routine = Routine(
            name: name,
            targetCount: draft.targetCount,
            period: draft.period,
            sortOrder: existingRoutines.count,
            group: group,
            createdAt: now,
            updatedAt: now
        )

        context.insert(routine)
        normalizeRoutineSortOrders(existingRoutines + [routine], now: now)
        group.updatedAt = now

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges(insertedRoutineIDs: [routine.id])
            throw error
        }

        return routine.id
    }

    func updateRoutine(id: UUID, with draft: RoutineDraft, now: Date = .now) throws {
        let name = try trimmedRoutineName(draft.name)
        try validateTargetCount(draft.targetCount, for: draft.period)

        let routine = try context.routine(id: id)
        let destinationGroup = try context.group(id: draft.groupID)
        let sourceGroupID = routine.groupID

        routine.name = name
        routine.targetCount = draft.targetCount
        routine.period = draft.period
        routine.updatedAt = now

        if sourceGroupID == destinationGroup.id {
            routine.group = destinationGroup
            routine.groupID = destinationGroup.id
        } else {
            let sourceRoutines = try routines(inGroupID: sourceGroupID).filter { $0.id != routine.id }
            let destinationRoutines = try routines(inGroupID: destinationGroup.id)

            routine.group = destinationGroup
            routine.groupID = destinationGroup.id

            normalizeRoutineSortOrders(sourceRoutines, now: now)
            normalizeRoutineSortOrders(destinationRoutines + [routine], now: now)

            if let sourceGroup = try? context.group(id: sourceGroupID) {
                sourceGroup.updatedAt = now
            }
            destinationGroup.updatedAt = now
        }

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    func deleteRoutine(id: UUID, now: Date = .now) throws {
        let routine = try context.routine(id: id)
        let sourceGroupID = routine.groupID
        let remainingRoutines = try routines(inGroupID: sourceGroupID).filter { $0.id != routine.id }

        normalizeRoutineSortOrders(remainingRoutines, now: now)
        if let group = try? context.group(id: sourceGroupID) {
            group.updatedAt = now
        }

        context.delete(routine)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    func moveRoutine(id: UUID, toGroupID: UUID, at index: Int, now: Date = .now) throws {
        let routine = try context.routine(id: id)
        let destinationGroup = try context.group(id: toGroupID)
        let sourceGroupID = routine.groupID

        if sourceGroupID == destinationGroup.id {
            var reorderedRoutines = try routines(inGroupID: sourceGroupID)
            guard let currentIndex = reorderedRoutines.firstIndex(where: { $0.id == routine.id }) else {
                throw PersistenceError.routineNotFound(id)
            }

            let movedRoutine = reorderedRoutines.remove(at: currentIndex)
            reorderedRoutines.insert(movedRoutine, at: clampedInsertionIndex(index, count: reorderedRoutines.count))
            movedRoutine.group = destinationGroup
            movedRoutine.groupID = destinationGroup.id

            normalizeRoutineSortOrders(reorderedRoutines, now: now)
            destinationGroup.updatedAt = now
        } else {
            let sourceRoutines = try routines(inGroupID: sourceGroupID).filter { $0.id != routine.id }
            var destinationRoutines = try routines(inGroupID: destinationGroup.id)

            routine.group = destinationGroup
            routine.groupID = destinationGroup.id
            destinationRoutines.insert(routine, at: clampedInsertionIndex(index, count: destinationRoutines.count))

            normalizeRoutineSortOrders(sourceRoutines, now: now)
            normalizeRoutineSortOrders(destinationRoutines, now: now)

            if let sourceGroup = try? context.group(id: sourceGroupID) {
                sourceGroup.updatedAt = now
            }
            destinationGroup.updatedAt = now
        }

        routine.updatedAt = now

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    func createGroup(name: String, now: Date = .now) throws -> UUID {
        let trimmedName = try trimmedGroupName(name)
        let groups = try orderedGroups()
        try validateUniqueGroupName(trimmedName, existingNames: groups.map(\.name))

        let group = RoutineGroup(
            name: trimmedName,
            sortOrder: groups.count,
            createdAt: now,
            updatedAt: now
        )

        context.insert(group)
        normalizeGroupSortOrders(groups + [group], now: now)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges(insertedGroupIDs: [group.id])
            throw error
        }

        return group.id
    }

    func renameGroup(id: UUID, name: String, now: Date = .now) throws {
        let trimmedName = try trimmedGroupName(name)
        let group = try context.group(id: id)
        let otherGroupNames = try orderedGroups()
            .filter { $0.id != id }
            .map(\.name)

        try validateUniqueGroupName(trimmedName, existingNames: otherGroupNames)

        group.name = trimmedName
        group.updatedAt = now

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    func deleteGroup(id: UUID, now: Date = .now) throws {
        let group = try context.group(id: id)
        let routinesInGroup = try routines(inGroupID: id)

        guard routinesInGroup.isEmpty else {
            throw RoutineManagementError.nonEmptyGroup(id)
        }

        let remainingGroups = try orderedGroups().filter { $0.id != id }
        normalizeGroupSortOrders(remainingGroups, now: now)

        context.delete(group)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    func moveGroup(id: UUID, to index: Int, now: Date = .now) throws {
        var groups = try orderedGroups()
        guard let currentIndex = groups.firstIndex(where: { $0.id == id }) else {
            throw PersistenceError.groupNotFound(id)
        }

        let group = groups.remove(at: currentIndex)
        groups.insert(group, at: clampedInsertionIndex(index, count: groups.count))
        normalizeGroupSortOrders(groups, now: now)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    private func orderedGroups() throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    private func routines(inGroupID groupID: UUID) throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.groupID == groupID
            },
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    private func normalizeRoutineSortOrders(_ routines: [Routine], now: Date) {
        let sortOrders = normalizedSortOrders(for: routines.map(\.id))

        for routine in routines {
            guard let normalizedSortOrder = sortOrders[routine.id] else {
                continue
            }

            if routine.sortOrder != normalizedSortOrder {
                routine.sortOrder = normalizedSortOrder
                routine.updatedAt = now
            }
        }
    }

    private func normalizeGroupSortOrders(_ groups: [RoutineGroup], now: Date) {
        let sortOrders = normalizedSortOrders(for: groups.map(\.id))

        for group in groups {
            guard let normalizedSortOrder = sortOrders[group.id] else {
                continue
            }

            if group.sortOrder != normalizedSortOrder {
                group.sortOrder = normalizedSortOrder
                group.updatedAt = now
            }
        }
    }

    private func clampedInsertionIndex(_ index: Int, count: Int) -> Int {
        min(max(index, 0), count)
    }

    private func rollbackPendingChanges(
        insertedRoutineIDs: [UUID] = [],
        insertedGroupIDs: [UUID] = []
    ) {
        context.rollback()

        for routineID in insertedRoutineIDs {
            if let routine = try? context.routine(id: routineID) {
                context.delete(routine)
            }
        }

        for groupID in insertedGroupIDs {
            if let group = try? context.group(id: groupID) {
                context.delete(group)
            }
        }

        if insertedRoutineIDs.isEmpty == false || insertedGroupIDs.isEmpty == false {
            context.rollback()
        }
    }
}
