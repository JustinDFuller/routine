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

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
        progressCalculator = ProgressCalculator(routineCalendar: routineCalendar)
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
        let storedGlobalBreak = context.globalBreak(routineCalendar: routineCalendar)
        let globalBreak: GlobalBreak? =
            if RoutineBreak.isActive(resumeDay: storedGlobalBreak?.resumeDay, today: today) {
                storedGlobalBreak
            } else {
                nil
            }
        let buildContext = DashboardBuildContext(
            completionDaysByRoutineID: completionDaysByRoutineID(from: completions),
            today: today,
            currentMinuteOfDay: routineCalendar.minuteOfDay(containing: now),
            globalBreak: globalBreak
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

        let globalBreakBanner = globalBreak.map { globalBreak -> GlobalBreakBannerViewData in
            GlobalBreakBannerViewData(
                resumeText: routineCalendar.relativeLabel(for: globalBreak.resumeDay, today: today)
            )
        }

        return TodayDashboardViewData(
            title: "Today",
            sections: sections,
            isEmpty: routines.isEmpty,
            globalBreak: globalBreakBanner
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
                currentMinuteOfDay: buildContext.currentMinuteOfDay,
                globalBreak: buildContext.globalBreak
            )
        }

        return RoutineSectionViewData(
            id: id,
            name: name,
            remainingCount: cards.filter {
                $0.isOnBreak == false
                    && $0.isCompletedToday == false
                    && $0.isTargetMet == false
                    && $0.isAvailableNow
            }.count,
            routines: cards
        )
    }

    fileprivate func buildCard(
        routine: Routine,
        completionDays: [RoutineDay],
        today: RoutineDay,
        currentMinuteOfDay: Int,
        globalBreak: GlobalBreak?
    ) -> RoutineCardViewData {
        let progress = progressCalculator.progress(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: completionDays,
            today: today
        )
        let periodText = periodUnitText(for: routine.period)
        let lastDoneText = routineCalendar.relativeLabel(for: progress.lastCompletedDay, today: today)
        let availabilityState = availabilityState(
            for: routine,
            currentMinuteOfDay: currentMinuteOfDay
        )
        let perRoutineResume = routine.breakResumeDayKey.flatMap(RoutineDay.init(key:))
        let breakStatus = RoutineBreak.status(
            perRoutineResume: perRoutineResume,
            global: globalBreak,
            today: today
        )
        let breakResumeText = breakStatus.map {
            routineCalendar.relativeLabel(for: $0.resumeDay, today: today)
        }
        let breakAccessibilityPhrase = breakResumeText.map { "off until \($0)" }

        return RoutineCardViewData(
            id: routine.id,
            name: routine.name,
            period: routine.period,
            countText: "\(progress.completedCount)/\(routine.targetCount)",
            periodText: periodText,
            lastDoneText: lastDoneText,
            availabilityText: availabilityState.text,
            accessibilityLabel: accessibilityLabel(
                for: RoutineCardAccessibilityContext(
                    routineName: routine.name,
                    breakAccessibilityPhrase: breakAccessibilityPhrase,
                    unavailableAccessibilityPhrase: availabilityState.unavailableAccessibilityPhrase,
                    progress: progress,
                    periodText: periodText,
                    lastDoneText: lastDoneText
                )
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
            isOverTarget: progress.isOverTarget,
            isOnBreak: breakStatus != nil,
            breakResumeText: breakResumeText,
            breakSource: breakStatus?.source
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

    fileprivate func accessibilityLabel(for context: RoutineCardAccessibilityContext) -> String {
        let completionText =
            if context.progress.isCompletedToday {
                "completed today"
            } else {
                "not completed today"
            }

        let unavailableText =
            if let unavailableAccessibilityPhrase = context.unavailableAccessibilityPhrase {
                "\(unavailableAccessibilityPhrase), "
            } else {
                ""
            }
        let breakText =
            if let breakAccessibilityPhrase = context.breakAccessibilityPhrase {
                "\(breakAccessibilityPhrase), "
            } else {
                ""
            }

        return
            "\(context.routineName), \(breakText)\(unavailableText)\(completionText), "
            + "\(context.progress.completedCount) of \(context.progress.targetCount) this \(context.periodText), "
            + accessibilityLastDoneText(for: context.lastDoneText)
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
    let globalBreak: GlobalBreak?
}

private struct RoutineCardAccessibilityContext {
    let routineName: String
    let breakAccessibilityPhrase: String?
    let unavailableAccessibilityPhrase: String?
    let progress: RoutineProgress
    let periodText: String
    let lastDoneText: String
}

private struct RoutineAvailabilityState {
    let text: String?
    let unavailableAccessibilityPhrase: String?
    let isAvailableNow: Bool
}
