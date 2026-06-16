import Foundation
import OSLog
import RoutineCore
import SwiftData

@MainActor
final class HistoryProjectionBuilder {
    private static let logger = AppDiagnostics.logger(.projection)
    private static let signposter = AppDiagnostics.signposter(.projection)

    private let context: ModelContext
    private let routineCalendar: RoutineCalendar
    private let progressCalculator: ProgressCalculator

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
        progressCalculator = ProgressCalculator(routineCalendar: routineCalendar)
    }

    func build(routineID: UUID, now: Date = .now) throws -> RoutineHistoryProjection {
        let buildSignpost = Self.signposter.beginInterval("buildHistoryProjection")
        defer {
            Self.signposter.endInterval("buildHistoryProjection", buildSignpost)
        }

        guard let routine = try fetchRoutine(id: routineID) else {
            return .notFound(routineID: routineID)
        }

        let completions = try fetchCompletions(routineID: routineID)
        return build(
            routineID: routineID,
            routines: [routine],
            completions: completions,
            now: now
        )
    }

    func build(
        routineID: UUID,
        routines: [Routine],
        completions: [RoutineCompletion],
        now: Date = .now
    ) -> RoutineHistoryProjection {
        guard let routine = routines.first(where: { $0.id == routineID }) else {
            return .notFound(routineID: routineID)
        }

        let filteredCompletions = sortedCompletions(
            completions.filter { $0.routineID == routineID }
        )

        return .found(
            makeViewData(
                routine: routine,
                completions: filteredCompletions,
                now: now
            )
        )
    }
}

@MainActor
extension HistoryProjectionBuilder {
    fileprivate func fetchRoutine(id: UUID) throws -> Routine? {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.id == id
            }
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor).first
        } catch {
            let routineID = id.uuidString
            let errorText = String(describing: error)
            Self.logger.error(
                "fetchRoutineFailed routineID=\(routineID, privacy: .public) e=\(errorText, privacy: .private)"
            )
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func fetchCompletions(routineID: UUID) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.routineID == routineID
            },
            sortBy: [
                SortDescriptor(\RoutineCompletion.dayKey, order: .reverse),
                SortDescriptor(\RoutineCompletion.completedAt, order: .reverse)
            ]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchCompletions(context, descriptor)
        } catch {
            let routineIDText = routineID.uuidString
            let errorText = String(describing: error)
            let details = "routineID=\(routineIDText)"
            Self.logger.error(
                "fetchHistoryCompletionsFailed \(details, privacy: .public) e=\(errorText, privacy: .private)"
            )
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func frequencySummary(targetCount: Int, period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "\(targetCount) per week"
        case .monthly:
            "\(targetCount) per month"
        }
    }

    fileprivate func makeViewData(
        routine: Routine,
        completions: [RoutineCompletion],
        now: Date
    ) -> RoutineHistoryViewData {
        let today = routineCalendar.today(now: now)
        let completionDays = completions.compactMap { RoutineDay(key: $0.dayKey) }
        let progress = progressCalculator.progress(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: completionDays,
            today: today
        )
        let completedDays = Set(completionDays)

        return RoutineHistoryViewData(
            routineID: routine.id,
            routineName: routine.name,
            frequencySummary: frequencySummary(
                targetCount: routine.targetCount,
                period: routine.period
            ),
            progress: progress,
            lastDoneText: routineCalendar.relativeLabel(for: progress.lastCompletedDay, today: today),
            monthDays: buildMonthDays(today: today, completedDays: completedDays),
            recentCompletions: buildRecentCompletionItems(completions: completions, today: today)
        )
    }

    fileprivate func buildMonthDays(
        today: RoutineDay,
        completedDays: Set<RoutineDay>
    ) -> [HistoryCalendarDay] {
        routineCalendar.daysInCurrentMonth(containing: today).map { day in
            HistoryCalendarDay(
                id: day.key,
                day: day,
                label: String(day.day),
                isInDisplayedMonth: true,
                isToday: day == today,
                isCompleted: completedDays.contains(day),
                isFuture: day > today
            )
        }
    }

    fileprivate func buildRecentCompletionItems(
        completions: [RoutineCompletion],
        today: RoutineDay
    ) -> [CompletionListItem] {
        completions.compactMap { completion in
            guard let day = RoutineDay(key: completion.dayKey) else {
                return nil
            }

            return CompletionListItem(
                id: completion.id,
                day: day,
                dateText: routineCalendar.explicitDateLabel(for: day),
                relativeText: relativeTextIfUseful(for: day, today: today)
            )
        }
    }

    fileprivate func relativeTextIfUseful(for day: RoutineDay, today: RoutineDay) -> String? {
        let relativeText = routineCalendar.relativeLabel(for: day, today: today)

        if relativeText == "Today" || relativeText == "Yesterday" || relativeText.hasSuffix("ago") {
            return relativeText
        }

        return nil
    }

    fileprivate func sortedCompletions(_ completions: [RoutineCompletion]) -> [RoutineCompletion] {
        completions.sorted { lhs, rhs in
            if lhs.dayKey != rhs.dayKey {
                return lhs.dayKey > rhs.dayKey
            }

            return lhs.completedAt > rhs.completedAt
        }
    }
}
