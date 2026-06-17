import Foundation
import RoutineCore

struct TodayDashboardViewData: Equatable, Sendable {
    let title: String
    let sections: [RoutineSectionViewData]
    let isEmpty: Bool
}

struct RoutineSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let remainingCount: Int
    let routines: [RoutineCardViewData]

    var activeRoutines: [RoutineCardViewData] {
        routines.filter { $0.isCompletedToday == false && $0.isTargetMet == false }
    }
    var collapsedRoutines: [RoutineCardViewData] {
        let doneToday = routines.filter(\.isCompletedToday)
        let goalMet = routines.filter { $0.isCompletedToday == false && $0.isTargetMet }
        return doneToday + goalMet
    }
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
    let summaryText: String
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
