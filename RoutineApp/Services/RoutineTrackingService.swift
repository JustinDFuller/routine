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
    case futureDay(routineName: String)

    var errorDescription: String? {
        switch self {
        case .unavailable(let routineName, let windowText):
            "\(routineName) is unavailable now. It can only be completed \(windowText)."
        case .futureDay(let routineName):
            "\(routineName) cannot be completed for a future day."
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
        try complete(routineID: routineID, day: routineCalendar.today(now: now), now: now)
    }

    func undoToday(routineID: UUID, now: Date = .now) throws -> UndoResult {
        try removeCompletion(routineID: routineID, day: routineCalendar.today(now: now))
    }

    func complete(routineID: UUID, day: RoutineDay, now: Date = .now) throws -> CompletionResult {
        let routine = try context.routine(id: routineID)
        let routineIDText = routine.id.uuidString
        let logContext = TrackingLogContext(routineID: routineIDText, dayKey: day.key, count: 1)

        if try context.completion(routineID: routineID, dayKey: day.key) != nil {
            Self.logOutcome(
                operation: "complete",
                context: logContext.withCount(0)
            )
            return CompletionResult(
                routineID: routine.id,
                routineName: routine.name,
                day: day,
                didInsert: false
            )
        }

        let today = routineCalendar.today(now: now)
        guard day <= today else {
            throw RoutineTrackingError.futureDay(routineName: routine.name)
        }

        if day == today {
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
        }

        let completion = RoutineCompletion(routine: routine, day: day, completedAt: now)
        context.insert(completion)

        do {
            try context.saveRoutineChanges()
        } catch {
            rollbackPendingChanges(insertedCompletionID: completion.id)
            Self.logFailure(
                operation: "completeFailed",
                context: logContext,
                error: error
            )
            throw error
        }

        Self.logOutcome(operation: "complete", context: logContext)

        return CompletionResult(
            routineID: routine.id,
            routineName: routine.name,
            day: day,
            didInsert: true
        )
    }

    func removeCompletion(routineID: UUID, day: RoutineDay) throws -> UndoResult {
        _ = try context.routine(id: routineID)
        let routineIDText = routineID.uuidString
        let logContext = TrackingLogContext(routineID: routineIDText, dayKey: day.key, count: 1)

        guard let completion = try context.completion(routineID: routineID, dayKey: day.key) else {
            Self.logOutcome(operation: "removeCompletion", context: logContext.withCount(0))
            return UndoResult(routineID: routineID, day: day, didRemove: false)
        }

        context.delete(completion)

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

        return UndoResult(routineID: routineID, day: day, didRemove: true)
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
