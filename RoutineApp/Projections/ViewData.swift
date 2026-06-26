import Foundation
import RoutineCore

struct TodayDashboardViewData: Equatable, Sendable {
    let title: String
    let sections: [RoutineSectionViewData]
    let isEmpty: Bool
    let globalPause: GlobalPauseBannerViewData?
}

struct GlobalPauseBannerViewData: Equatable, Sendable {
    let resumeText: String
}

struct RoutineSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let remainingCount: Int
    let routines: [RoutineCardViewData]

    static func displayPartition(
        collapseCompletedToday: Bool,
        collapseGoalMetToday: Bool,
        collapseUnavailableToday: Bool,
        routines: [RoutineCardViewData]
    ) -> RoutineSectionDisplayPartition {
        let collapsedPaused: [CollapsedRoutineRowViewData] =
            routines.compactMap { routine in
                guard routine.isPaused else { return nil }
                return CollapsedRoutineRowViewData(routine: routine, style: .paused)
            }
        let collapsedUnavailable: [CollapsedRoutineRowViewData] =
            collapseUnavailableToday
            ? routines.compactMap { routine in
                guard
                    routine.isPaused == false,
                    routine.isCompletedToday == false,
                    routine.isAvailableNow == false
                else {
                    return nil
                }

                return CollapsedRoutineRowViewData(routine: routine, style: .unavailable)
            }
            : []
        let collapsedCompleted: [CollapsedRoutineRowViewData] =
            collapseCompletedToday
            ? routines.compactMap { routine in
                guard routine.isPaused == false, routine.isCompletedToday else {
                    return nil
                }

                return CollapsedRoutineRowViewData(routine: routine, style: .completed)
            }
            : []
        let collapsedGoalMet: [CollapsedRoutineRowViewData] =
            collapseGoalMetToday
            ? routines.compactMap { routine in
                guard
                    routine.isPaused == false,
                    routine.isCompletedToday == false,
                    routine.isTargetMet,
                    routine.isAvailableNow
                else {
                    return nil
                }

                return CollapsedRoutineRowViewData(routine: routine, style: .goalMet)
            }
            : []
        let collapsedRoutineIDs = Set(
            collapsedPaused.map(\.id)
                + collapsedUnavailable.map(\.id)
                + collapsedCompleted.map(\.id)
                + collapsedGoalMet.map(\.id)
        )
        let fullCards = routines.filter { collapsedRoutineIDs.contains($0.id) == false }

        return RoutineSectionDisplayPartition(
            fullCards: fullCards,
            collapsedRows: collapsedPaused + collapsedUnavailable + collapsedCompleted + collapsedGoalMet
        )
    }
}

struct RoutineSectionDisplayPartition: Equatable, Sendable {
    let fullCards: [RoutineCardViewData]
    let collapsedRows: [CollapsedRoutineRowViewData]
}

struct CollapsedRoutineRowViewData: Identifiable, Equatable, Sendable {
    enum Style: Equatable, Sendable {
        case paused
        case unavailable
        case completed
        case goalMet
    }

    let routine: RoutineCardViewData
    let style: Style

    var id: UUID { routine.id }
}

struct RoutineCardViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let period: RoutinePeriod
    let countText: String
    let periodText: String
    let lastDoneText: String
    let availabilityText: String?
    let accessibilityLabel: String
    let unavailableAccessibilityPhrase: String?
    let progressRing: ProgressRingViewData
    let isAvailableNow: Bool
    let isCompletedToday: Bool
    let isTargetMet: Bool
    let isOverTarget: Bool
    let isPaused: Bool
    let pauseResumeText: String?

    init(
        id: UUID,
        name: String,
        period: RoutinePeriod,
        countText: String,
        periodText: String,
        lastDoneText: String,
        availabilityText: String?,
        accessibilityLabel: String,
        unavailableAccessibilityPhrase: String?,
        progressRing: ProgressRingViewData,
        isAvailableNow: Bool,
        isCompletedToday: Bool,
        isTargetMet: Bool,
        isOverTarget: Bool,
        isPaused: Bool = false,
        pauseResumeText: String? = nil
    ) {
        self.id = id
        self.name = name
        self.period = period
        self.countText = countText
        self.periodText = periodText
        self.lastDoneText = lastDoneText
        self.availabilityText = availabilityText
        self.accessibilityLabel = accessibilityLabel
        self.unavailableAccessibilityPhrase = unavailableAccessibilityPhrase
        self.progressRing = progressRing
        self.isAvailableNow = isAvailableNow
        self.isCompletedToday = isCompletedToday
        self.isTargetMet = isTargetMet
        self.isOverTarget = isOverTarget
        self.isPaused = isPaused
        self.pauseResumeText = pauseResumeText
    }
}

struct ProgressRingViewData: Equatable, Sendable {
    let targetCount: Int
    let completedCount: Int
    let fillRatio: Double
    let showsTodayCheckmark: Bool
}

struct UndoBannerViewData: Equatable, Sendable {
    let message: String
    let actionTitle: String

    init(message: String, actionTitle: String = "Undo") {
        self.message = message
        self.actionTitle = actionTitle
    }
}

enum RoutineHistoryProjection: Equatable, Sendable {
    case found(RoutineHistoryViewData)
    case notFound(routineID: UUID)
}

struct RoutineHistoryViewData: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
    let frequencySummary: String
    let progress: RoutineProgress
    let lastDoneText: String
    let weeks: [HistoryCalendarWeek]
    let recentCompletions: [CompletionListItem]
}

struct HistoryCalendarWeek: Identifiable, Equatable, Sendable {
    let id: Int
    let days: [HistoryCalendarDay]
    let leadingPlaceholders: Int
    let trailingPlaceholders: Int
    let isGoalMet: Bool
}

struct HistoryCalendarDay: Identifiable, Equatable, Sendable {
    let id: String
    let day: RoutineDay
    let label: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isCompleted: Bool
    let isFuture: Bool
}

struct CompletionListItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let day: RoutineDay
    let dateText: String
    let relativeText: String?
}

struct ManageRoutinesViewData: Equatable, Sendable {
    let groupChoices: [ManageGroupChoiceViewData]
    let sections: [ManageGroupSectionViewData]
    let isEmpty: Bool
}

struct ManageGroupChoiceViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
}

struct ManageGroupSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let routines: [ManageRoutineRowViewData]
}

struct ManageRoutineRowViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let groupID: UUID
    let availabilityStartMinute: Int?
    let availabilityEndMinute: Int?
    let pauseResumeDayKey: String?
    let summaryText: String

    init(
        id: UUID,
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        groupID: UUID,
        availabilityStartMinute: Int?,
        availabilityEndMinute: Int?,
        pauseResumeDayKey: String? = nil,
        summaryText: String
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.groupID = groupID
        self.availabilityStartMinute = availabilityStartMinute
        self.availabilityEndMinute = availabilityEndMinute
        self.pauseResumeDayKey = pauseResumeDayKey
        self.summaryText = summaryText
    }
}

enum ProjectionFallbackSection: String, Equatable, Sendable {
    case ungrouped

    var id: UUID {
        switch self {
        case .ungrouped:
            guard let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001") else {
                preconditionFailure("Invalid ungrouped section UUID.")
            }

            return id
        }
    }

    var name: String {
        switch self {
        case .ungrouped:
            "Ungrouped"
        }
    }
}
