import Foundation
import RoutineCore
import SwiftData

struct CompletionResult: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
    let day: RoutineDay
    let didInsert: Bool
}

struct UndoResult: Equatable, Sendable {
    let routineID: UUID
    let day: RoutineDay
    let didRemove: Bool
}

@MainActor
final class RoutineTrackingService {
    private let context: ModelContext
    private let routineCalendar: RoutineCalendar

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
    }

    func completeToday(routineID: UUID, now: Date = .now) throws -> CompletionResult {
        let routine = try context.routine(id: routineID)
        let today = routineCalendar.today(now: now)

        if try context.completion(routineID: routineID, dayKey: today.key) != nil {
            return CompletionResult(
                routineID: routine.id,
                routineName: routine.name,
                day: today,
                didInsert: false
            )
        }

        let completion = RoutineCompletion(routine: routine, day: today, completedAt: now)
        context.insert(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges(insertedCompletionID: completion.id)
            throw error
        }

        return CompletionResult(
            routineID: routine.id,
            routineName: routine.name,
            day: today,
            didInsert: true
        )
    }

    func undoToday(routineID: UUID, now: Date = .now) throws -> UndoResult {
        _ = try context.routine(id: routineID)
        let today = routineCalendar.today(now: now)

        guard let completion = try context.completion(routineID: routineID, dayKey: today.key) else {
            return UndoResult(routineID: routineID, day: today, didRemove: false)
        }

        context.delete(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }

        return UndoResult(routineID: routineID, day: today, didRemove: true)
    }

    func removeCompletion(completionID: UUID) throws {
        let completion = try context.completion(id: completionID)
        context.delete(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            throw error
        }
    }

    private func rollbackPendingChanges(insertedCompletionID: UUID? = nil) {
        context.rollback()

        guard let insertedCompletionID else {
            return
        }

        if let completion = try? context.completion(id: insertedCompletionID) {
            context.delete(completion)
            context.rollback()
        }
    }
}
