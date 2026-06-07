import Foundation
import RoutineCore

struct TodayDashboardViewData: Equatable, Sendable {
    let title: String
    let dateLabel: String
    let sections: [RoutineSectionViewData]
    let isEmpty: Bool
}

struct RoutineSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let remainingCount: Int
    let routines: [RoutineCardViewData]
}

struct RoutineCardViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let period: RoutinePeriod
    let countText: String
    let periodText: String
    let lastDoneText: String
    let accessibilityLabel: String
    let progressRing: ProgressRingViewData
    let isCompletedToday: Bool
    let isTargetMet: Bool
    let isOverTarget: Bool
}

struct ProgressRingViewData: Equatable, Sendable {
    let targetCount: Int
    let completedCount: Int
    let fillRatio: Double
    let showsSegments: Bool
    let showsTodayCheckmark: Bool
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
    let monthDays: [HistoryCalendarDay]
    let recentCompletions: [CompletionListItem]
}

struct HistoryCalendarDay: Identifiable, Equatable, Sendable {
    let id: String
    let day: RoutineDay
    let label: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isCompleted: Bool
}

struct CompletionListItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let day: RoutineDay
    let dateText: String
    let relativeText: String?
}

struct ManageRoutinesViewData: Equatable, Sendable {
    let sections: [ManageGroupSectionViewData]
    let isEmpty: Bool
}

struct ManageGroupSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let routines: [ManageRoutineRowViewData]
}

struct ManageRoutineRowViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
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
