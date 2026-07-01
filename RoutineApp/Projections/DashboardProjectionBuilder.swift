import Foundation
import OSLog
import RoutineCore
import SwiftData

@MainActor
final class DashboardProjectionBuilder {
    private static let logger = AppDiagnostics.logger(.projection)
    private static let signposter = AppDiagnostics.signposter(.projection)

    private let context: ModelContext
    private let routineCalendar: RoutineCalendar
    private let progressCalculator: ProgressCalculator
    private let streakCalculator: StreakCalculator

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
        progressCalculator = ProgressCalculator(routineCalendar: routineCalendar)
        streakCalculator = StreakCalculator(routineCalendar: routineCalendar)
    }

    func build(now: Date = .now) throws -> TodayDashboardViewData {
        let buildSignpost = Self.signposter.beginInterval("buildDashboardProjection")
        defer {
            Self.signposter.endInterval("buildDashboardProjection", buildSignpost)
        }

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
        let buildContext = DashboardBuildContext(
            completionDaysByRoutineID: completionDaysByRoutineID(from: completions),
            today: today,
            currentMinuteOfDay: routineCalendar.minuteOfDay(containing: now)
        )
        let routinesByGroupID = Dictionary(grouping: routines, by: \.groupID)

        var sections = groups.map { group in
            buildSection(
                id: group.id,
                name: group.name,
                routines: routinesByGroupID[group.id] ?? [],
                buildContext: buildContext
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
                    buildContext: buildContext
                )
            )
        }

        return TodayDashboardViewData(
            title: "Today",
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
            Self.logger.error(
                "fetchGroupsFailed e=\(String(describing: error), privacy: .private)"
            )
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
            Self.logger.error(
                "fetchRoutinesFailed e=\(String(describing: error), privacy: .private)"
            )
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func fetchCompletions() throws -> [RoutineCompletion] {
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
            Self.logger.error(
                "fetchCompletionsFailed e=\(String(describing: error), privacy: .private)"
            )
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
        buildContext: DashboardBuildContext
    ) -> RoutineSectionViewData {
        let cards = routines.map { routine in
            buildCard(
                routine: routine,
                completionDays: buildContext.completionDaysByRoutineID[routine.id] ?? [],
                today: buildContext.today,
                currentMinuteOfDay: buildContext.currentMinuteOfDay
            )
        }

        return RoutineSectionViewData(
            id: id,
            name: name,
            remainingCount: cards.filter {
                $0.isCompletedToday == false && $0.isTargetMet == false && $0.isAvailableNow
            }.count,
            routines: cards
        )
    }

    fileprivate func buildCard(
        routine: Routine,
        completionDays: [RoutineDay],
        today: RoutineDay,
        currentMinuteOfDay: Int
    ) -> RoutineCardViewData {
        let progress = progressCalculator.progress(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: completionDays,
            today: today
        )
        let periodText = periodUnitText(for: routine.period)
        let lastDoneText = routineCalendar.relativeLabel(for: progress.lastCompletedDay, today: today)
        let streak = streakCalculator.streak(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: completionDays,
            today: today
        )
        let cardStreakText = streakText(for: streak)
        let availabilityState = availabilityState(
            for: routine,
            currentMinuteOfDay: currentMinuteOfDay
        )

        return RoutineCardViewData(
            id: routine.id,
            name: routine.name,
            period: routine.period,
            countText: "\(progress.completedCount)/\(routine.targetCount)",
            periodText: periodText,
            lastDoneText: lastDoneText,
            streakText: cardStreakText,
            availabilityText: availabilityState.text,
            accessibilityLabel: accessibilityLabel(
                routineName: routine.name,
                unavailableAccessibilityPhrase: availabilityState.unavailableAccessibilityPhrase,
                progress: progress,
                lastDoneText: lastDoneText,
                streakText: cardStreakText
            ),
            unavailableAccessibilityPhrase: availabilityState.unavailableAccessibilityPhrase,
            progressRing: ProgressRingViewData(
                targetCount: routine.targetCount,
                completedCount: progress.completedCount,
                fillRatio: progress.fillRatio,
                showsTodayCheckmark: progress.isCompletedToday
            ),
            isAvailableNow: availabilityState.isAvailableNow,
            isCompletedToday: progress.isCompletedToday,
            isTargetMet: progress.isTargetMet,
            isOverTarget: progress.isOverTarget
        )
    }

    fileprivate func availabilityState(
        for routine: Routine,
        currentMinuteOfDay: Int
    ) -> RoutineAvailabilityState {
        guard let availabilityWindow = routine.availabilityWindow else {
            return RoutineAvailabilityState(
                text: nil,
                unavailableAccessibilityPhrase: nil,
                isAvailableNow: true
            )
        }

        let isAvailableNow = availabilityWindow.contains(minuteOfDay: currentMinuteOfDay)
        return RoutineAvailabilityState(
            text: isAvailableNow
                ? nil
                : RoutineAvailabilityText.cardLabel(
                    for: availabilityWindow,
                    isAvailableNow: isAvailableNow,
                    routineCalendar: routineCalendar
                ),
            unavailableAccessibilityPhrase:
                isAvailableNow
                ? nil
                : RoutineAvailabilityText.unavailableAccessibilityPhrase(
                    for: availabilityWindow,
                    routineCalendar: routineCalendar
                ),
            isAvailableNow: isAvailableNow
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

    fileprivate func streakText(for streak: RoutineStreak) -> String? {
        guard streak.count >= 1 else { return nil }
        let unit = periodUnitText(for: streak.period)
        return "\(streak.count) \(unit)\(streak.count == 1 ? "" : "s") in a row"
    }

    fileprivate func accessibilityLabel(
        routineName: String,
        unavailableAccessibilityPhrase: String?,
        progress: RoutineProgress,
        lastDoneText: String,
        streakText: String?
    ) -> String {
        let periodText = periodUnitText(for: progress.period)
        let completionText =
            if progress.isCompletedToday {
                "completed today"
            } else {
                "not completed today"
            }

        let unavailableText =
            if let unavailableAccessibilityPhrase {
                "\(unavailableAccessibilityPhrase), "
            } else {
                ""
            }

        let streakSuffix =
            if let streakText {
                ", \(streakText)"
            } else {
                ""
            }

        return
            "\(routineName), \(unavailableText)\(completionText), "
            + "\(progress.completedCount) of \(progress.targetCount) this \(periodText), "
            + accessibilityLastDoneText(for: lastDoneText)
            + streakSuffix
    }

    fileprivate func accessibilityLastDoneText(for lastDoneText: String) -> String {
        switch lastDoneText {
        case "Never":
            "no completions yet"
        case "Today":
            "last done today"
        case "Yesterday":
            "last done yesterday"
        default:
            "last done \(expandedRelativeDayPhrase(for: lastDoneText))"
        }
    }

    fileprivate func expandedRelativeDayPhrase(for text: String) -> String {
        let suffix = "d ago"
        guard text.hasSuffix(suffix) else {
            return text
        }

        let dayCountText = text.dropLast(suffix.count)
        guard let dayCount = Int(dayCountText) else {
            return text
        }

        let unit = dayCount == 1 ? "day" : "days"
        return "\(dayCount) \(unit) ago"
    }
}

private struct DashboardBuildContext {
    let completionDaysByRoutineID: [UUID: [RoutineDay]]
    let today: RoutineDay
    let currentMinuteOfDay: Int
}

private struct RoutineAvailabilityState {
    let text: String?
    let unavailableAccessibilityPhrase: String?
    let isAvailableNow: Bool
}
