import Foundation
import OSLog
import RoutineCore
import SwiftData

struct NextRoutineSnapshot: Equatable, Sendable {
    let routineID: UUID
    let name: String
    let countText: String
    let periodText: String
    let lastDoneText: String
    let fillRatio: Double
    let isComplete: Bool
}

enum NextRoutineSelection: Equatable, Sendable {
    case ready(NextRoutineSnapshot)
    case noRoutines
    case allCaughtUp
}

@MainActor
enum NextRoutineSelector {
    private static let logger = AppDiagnostics.logger(.projection)

    static func next(
        context: ModelContext,
        calendar: RoutineCalendar = .current,
        now: Date = .now
    ) throws -> NextRoutineSelection {
        let routines = try fetchRoutines(context)

        guard routines.isEmpty == false else {
            return .noRoutines
        }

        let groups = try fetchGroups(context)
        let completions = try fetchCompletions(context)
        let orderedRoutines = orderedRoutines(groups: groups, routines: routines)

        let today = calendar.today(now: now)
        let currentMinuteOfDay = calendar.minuteOfDay(containing: now)
        let progressCalculator = ProgressCalculator(routineCalendar: calendar)
        let completionDaysByRoutineID = completionDaysByRoutineID(from: completions)
        let globalPause = context.globalPause()

        for routine in orderedRoutines {
            guard isAvailableNow(routine: routine, currentMinuteOfDay: currentMinuteOfDay) else {
                continue
            }

            let perRoutineResume = routine.pauseResumeDayKey.flatMap(RoutineDay.init(key:))
            let resumeDay = RoutinePause.resumeDay(
                perRoutineResume: perRoutineResume,
                global: globalPause,
                period: routine.period,
                calendar: calendar
            )
            guard RoutinePause.isPaused(resumeDay: resumeDay, today: today) == false else {
                continue
            }

            let progress = progressCalculator.progress(
                period: routine.period,
                targetCount: routine.targetCount,
                completionDays: completionDaysByRoutineID[routine.id] ?? [],
                today: today
            )

            guard progress.isCompletedToday == false, progress.isTargetMet == false else {
                continue
            }

            return .ready(snapshot(for: routine, progress: progress, calendar: calendar, today: today))
        }

        return .allCaughtUp
    }

    static func nextRefreshBoundary(
        context: ModelContext,
        calendar: RoutineCalendar = .current,
        now: Date = .now
    ) throws -> Date {
        let routines = try fetchRoutines(context)
        let today = calendar.today(now: now)
        let currentMinuteOfDay = calendar.minuteOfDay(containing: now)
        let globalPause = context.globalPause()

        var candidates: [Date] = []
        if let midnight = calendar.calendar.date(byAdding: .day, value: 1, to: calendar.calendar.startOfDay(for: now)) {
            candidates.append(midnight)
        }

        for routine in routines {
            if let window = routine.availabilityWindow {
                for edge in [window.start.minuteOfDay, window.end.minuteOfDay] where edge > currentMinuteOfDay {
                    if let edgeDate = date(forMinuteOfDay: edge, on: today, calendar: calendar) {
                        candidates.append(edgeDate)
                    }
                }
            }

            let perRoutineResume = routine.pauseResumeDayKey.flatMap(RoutineDay.init(key:))
            let resumeDay = RoutinePause.resumeDay(
                perRoutineResume: perRoutineResume,
                global: globalPause,
                period: routine.period,
                calendar: calendar
            )
            if let resumeDay, RoutinePause.isPaused(resumeDay: resumeDay, today: today) {
                if let resumeDate = date(forMinuteOfDay: 0, on: resumeDay, calendar: calendar) {
                    candidates.append(resumeDate)
                }
            }
        }

        return candidates.min() ?? now.addingTimeInterval(3_600)
    }
}

extension NextRoutineSelector {
    fileprivate static func orderedRoutines(groups: [RoutineGroup], routines: [Routine]) -> [Routine] {
        let routinesByGroupID = Dictionary(grouping: routines, by: \.groupID)
        let knownGroupIDs = Set(groups.map(\.id))

        var ordered = groups.flatMap { routinesByGroupID[$0.id] ?? [] }
        ordered.append(contentsOf: routines.filter { knownGroupIDs.contains($0.groupID) == false })
        return ordered
    }

    fileprivate static func isAvailableNow(routine: Routine, currentMinuteOfDay: Int) -> Bool {
        guard let availabilityWindow = routine.availabilityWindow else {
            return true
        }

        return availabilityWindow.contains(minuteOfDay: currentMinuteOfDay)
    }

    fileprivate static func snapshot(
        for routine: Routine,
        progress: RoutineProgress,
        calendar: RoutineCalendar,
        today: RoutineDay
    ) -> NextRoutineSnapshot {
        NextRoutineSnapshot(
            routineID: routine.id,
            name: routine.name,
            countText: "\(progress.completedCount)/\(routine.targetCount)",
            periodText: periodText(for: routine.period),
            lastDoneText: calendar.relativeLabel(for: progress.lastCompletedDay, today: today),
            fillRatio: progress.fillRatio,
            isComplete: progress.isTargetMet
        )
    }

    fileprivate static func periodText(for period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "Week"
        case .monthly:
            "Month"
        }
    }

    fileprivate static func completionDaysByRoutineID(from completions: [RoutineCompletion]) -> [UUID: [RoutineDay]] {
        completions.reduce(into: [:]) { result, completion in
            guard let day = RoutineDay(key: completion.dayKey) else {
                return
            }

            result[completion.routineID, default: []].append(day)
        }
    }

    fileprivate static func date(forMinuteOfDay minute: Int, on day: RoutineDay, calendar: RoutineCalendar) -> Date? {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = minute / 60
        components.minute = minute % 60
        return calendar.calendar.date(from: components)
    }

    fileprivate static func fetchGroups(_ context: ModelContext) throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)
        } catch {
            logger.error("fetchGroupsFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate static func fetchRoutines(_ context: ModelContext) throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)
        } catch {
            logger.error("fetchRoutinesFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate static func fetchCompletions(_ context: ModelContext) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [
                SortDescriptor(\RoutineCompletion.routineID),
                SortDescriptor(\RoutineCompletion.dayKey),
                SortDescriptor(\RoutineCompletion.completedAt)
            ]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchCompletions(context, descriptor)
        } catch {
            logger.error("fetchCompletionsFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }
}
