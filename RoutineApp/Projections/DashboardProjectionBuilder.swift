import Foundation
import RoutineCore
import SwiftData

@MainActor
final class DashboardProjectionBuilder {
    private let context: ModelContext
    private let routineCalendar: RoutineCalendar
    private let progressCalculator: ProgressCalculator

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
        progressCalculator = ProgressCalculator(routineCalendar: routineCalendar)
    }

    func build(now: Date = .now) throws -> TodayDashboardViewData {
        let groups = try fetchGroups()
        let routines = try fetchRoutines()
        let completions = try fetchCompletions()
        return build(groups: groups, routines: routines, completions: completions, now: now)
    }

    func build(
        groups: [RoutineGroup],
        routines: [Routine],
        completions: [RoutineCompletion],
        now: Date = .now
    ) -> TodayDashboardViewData {
        let today = routineCalendar.today(now: now)
        let completionDaysByRoutineID = completionDaysByRoutineID(from: completions)
        let routinesByGroupID = Dictionary(grouping: routines, by: \.groupID)

        var sections = groups.map { group in
            buildSection(
                id: group.id,
                name: group.name,
                routines: routinesByGroupID[group.id] ?? [],
                completionDaysByRoutineID: completionDaysByRoutineID,
                today: today
            )
        }

        let knownGroupIDs = Set(groups.map(\.id))
        let ungroupedRoutines = routines.filter { knownGroupIDs.contains($0.groupID) == false }

        if ungroupedRoutines.isEmpty == false {
            sections.append(
                buildSection(
                    id: ProjectionFallbackSection.ungrouped.id,
                    name: ProjectionFallbackSection.ungrouped.name,
                    routines: ungroupedRoutines,
                    completionDaysByRoutineID: completionDaysByRoutineID,
                    today: today
                )
            )
        }

        return TodayDashboardViewData(
            title: "Today",
            dateLabel: dashboardDateLabel(for: now),
            sections: sections,
            isEmpty: routines.isEmpty
        )
    }
}

@MainActor
extension DashboardProjectionBuilder {
    fileprivate func fetchGroups() throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func fetchRoutines() throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func fetchCompletions() throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [
                SortDescriptor(\RoutineCompletion.routineID),
                SortDescriptor(\RoutineCompletion.dayKey),
                SortDescriptor(\RoutineCompletion.completedAt),
            ]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchCompletions(context, descriptor)
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func completionDaysByRoutineID(
        from completions: [RoutineCompletion]
    ) -> [UUID: [RoutineDay]] {
        completions.reduce(into: [:]) { result, completion in
            guard let day = RoutineDay(key: completion.dayKey) else {
                return
            }

            result[completion.routineID, default: []].append(day)
        }
    }

    fileprivate func buildSection(
        id: UUID,
        name: String,
        routines: [Routine],
        completionDaysByRoutineID: [UUID: [RoutineDay]],
        today: RoutineDay
    ) -> RoutineSectionViewData {
        let cards = routines.map { routine in
            buildCard(
                routine: routine,
                completionDays: completionDaysByRoutineID[routine.id] ?? [],
                today: today
            )
        }

        return RoutineSectionViewData(
            id: id,
            name: name,
            remainingCount: cards.filter { $0.isCompletedToday == false }.count,
            routines: cards
        )
    }

    fileprivate func buildCard(
        routine: Routine,
        completionDays: [RoutineDay],
        today: RoutineDay
    ) -> RoutineCardViewData {
        let progress = progressCalculator.progress(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: completionDays,
            today: today
        )
        let periodText = periodUnitText(for: routine.period)
        let lastDoneText = routineCalendar.relativeLabel(for: progress.lastCompletedDay, today: today)

        return RoutineCardViewData(
            id: routine.id,
            name: routine.name,
            period: routine.period,
            countText: "\(progress.completedCount)/\(routine.targetCount)",
            periodText: periodText,
            lastDoneText: lastDoneText,
            accessibilityLabel: accessibilityLabel(
                routineName: routine.name,
                progress: progress,
                periodText: periodText,
                lastDoneText: lastDoneText
            ),
            progressRing: ProgressRingViewData(
                targetCount: routine.targetCount,
                completedCount: progress.completedCount,
                fillRatio: progress.fillRatio,
                showsSegments: (1...8).contains(routine.targetCount),
                showsTodayCheckmark: progress.isCompletedToday
            ),
            isCompletedToday: progress.isCompletedToday,
            isTargetMet: progress.isTargetMet,
            isOverTarget: progress.isOverTarget
        )
    }

    fileprivate func periodUnitText(for period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "week"
        case .monthly:
            "month"
        }
    }

    fileprivate func accessibilityLabel(
        routineName: String,
        progress: RoutineProgress,
        periodText: String,
        lastDoneText: String
    ) -> String {
        let completionText =
            if progress.isCompletedToday {
                "completed today"
            } else {
                "not completed today"
            }

        return
            "\(routineName), \(completionText), \(progress.completedCount) of \(progress.targetCount) "
            + "this \(periodText), "
            + "last done \(lastDoneText)"
    }

    fileprivate func dashboardDateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = routineCalendar.calendar
        formatter.timeZone = routineCalendar.calendar.timeZone
        formatter.locale = routineCalendar.calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}
