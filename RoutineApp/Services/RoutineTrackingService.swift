import Foundation
import OSLog
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

enum RoutineTrackingError: LocalizedError, Equatable {
    case unavailable(routineName: String, windowText: String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let routineName, let windowText):
            "\(routineName) is unavailable now. It can only be completed \(windowText)."
        }
    }
}

@MainActor
final class RoutineTrackingService {
    private static let logger = AppDiagnostics.logger(.tracking)

    private let context: ModelContext
    private let routineCalendar: RoutineCalendar

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
    }

    func completeToday(routineID: UUID, now: Date = .now) throws -> CompletionResult {
        let routine = try context.routine(id: routineID)
        let today = routineCalendar.today(now: now)
        let routineIDText = routine.id.uuidString
        let logContext = TrackingLogContext(routineID: routineIDText, dayKey: today.key, count: 1)

        if try context.completion(routineID: routineID, dayKey: today.key) != nil {
            Self.logOutcome(
                operation: "completeToday",
                context: logContext.withCount(0)
            )
            return CompletionResult(
                routineID: routine.id,
                routineName: routine.name,
                day: today,
                didInsert: false
            )
        }

        let currentMinuteOfDay = routineCalendar.minuteOfDay(containing: now)
        if let availabilityWindow = routine.availabilityWindow {
            guard availabilityWindow.contains(minuteOfDay: currentMinuteOfDay) else {
                throw RoutineTrackingError.unavailable(
                    routineName: routine.name,
                    windowText: RoutineAvailabilityText.trackingWindowText(
                        for: availabilityWindow,
                        routineCalendar: routineCalendar
                    )
                )
            }
        }

        let completion = RoutineCompletion(routine: routine, day: today, completedAt: now)
        context.insert(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges(insertedCompletionID: completion.id)
            Self.logFailure(
                operation: "completeTodayFailed",
                context: logContext,
                error: error
            )
            throw error
        }

        Self.logOutcome(operation: "completeToday", context: logContext)

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
        let routineIDText = routineID.uuidString
        let logContext = TrackingLogContext(routineID: routineIDText, dayKey: today.key, count: 1)

        guard let completion = try context.completion(routineID: routineID, dayKey: today.key) else {
            Self.logOutcome(operation: "undoToday", context: logContext.withCount(0))
            return UndoResult(routineID: routineID, day: today, didRemove: false)
        }

        context.delete(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            Self.logFailure(
                operation: "undoTodayFailed",
                context: logContext,
                error: error
            )
            throw error
        }

        Self.logOutcome(operation: "undoToday", context: logContext)

        return UndoResult(routineID: routineID, day: today, didRemove: true)
    }

    func removeCompletion(completionID: UUID) throws {
        let completion = try context.completion(id: completionID)
        context.delete(completion)
        let routineID = completion.routineID.uuidString
        let completionIDText = completionID.uuidString
        let logContext = TrackingLogContext(
            routineID: routineID,
            dayKey: completion.dayKey,
            completionID: completionIDText,
            count: 1
        )

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges()
            Self.logFailure(
                operation: "removeCompletionFailed",
                context: logContext,
                error: error
            )
            throw error
        }

        Self.logOutcome(operation: "removeCompletion", context: logContext)
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

    private static func logOutcome(operation: String, context: TrackingLogContext) {
        let details = context.publicDetails
        logger.debug(
            "operation=\(operation, privacy: .public) \(details, privacy: .public)"
        )
    }

    private static func logFailure(operation: String, context: TrackingLogContext, error: Error) {
        let details = context.publicDetails
        let errorText = String(describing: error)
        logger.error(
            "operation=\(operation, privacy: .public) \(details, privacy: .public) e=\(errorText, privacy: .private)"
        )
    }
}

private struct TrackingLogContext {
    let routineID: String
    let dayKey: String
    let completionID: String?
    let count: Int

    init(routineID: String, dayKey: String, completionID: String? = nil, count: Int) {
        self.routineID = routineID
        self.dayKey = dayKey
        self.completionID = completionID
        self.count = count
    }

    var publicDetails: String {
        if let completionID {
            return
                "completionID=\(completionID) routineID=\(routineID) "
                + "dayKey=\(dayKey) count=\(count)"
        }

        return "routineID=\(routineID) dayKey=\(dayKey) count=\(count)"
    }

    func withCount(_ count: Int) -> Self {
        TrackingLogContext(
            routineID: routineID,
            dayKey: dayKey,
            completionID: completionID,
            count: count
        )
    }
}
