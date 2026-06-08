import Foundation
import RoutineCore
import SwiftUI

enum ComponentPreviewFixtures {
    private static let longNameAccessibilityLabel =
        "Practice Leetcode Problem Solving Before The Kids Wake Up, not completed today, 2 of 3 this week, "
        + "last done 3d ago"

    static let incompleteCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000001") ?? UUID(),
        name: "Morning Yoga",
        period: .weekly,
        countText: "1/5",
        periodText: "week",
        lastDoneText: "Yesterday",
        accessibilityLabel: "Morning Yoga, not completed today, 1 of 5 this week, last done Yesterday",
        progressRing: ProgressRingViewData(
            targetCount: 5,
            completedCount: 1,
            fillRatio: 0.2,
            showsSegments: true,
            showsTodayCheckmark: false
        ),
        isCompletedToday: false,
        isTargetMet: false,
        isOverTarget: false
    )

    static let completedTodayCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000002") ?? UUID(),
        name: "Functional Workout",
        period: .weekly,
        countText: "3/5",
        periodText: "week",
        lastDoneText: "Today",
        accessibilityLabel: "Functional Workout, completed today, 3 of 5 this week, last done Today",
        progressRing: ProgressRingViewData(
            targetCount: 5,
            completedCount: 3,
            fillRatio: 0.6,
            showsSegments: true,
            showsTodayCheckmark: true
        ),
        isCompletedToday: true,
        isTargetMet: false,
        isOverTarget: false
    )

    static let targetMetCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000003") ?? UUID(),
        name: "Water Plants",
        period: .weekly,
        countText: "1/1",
        periodText: "week",
        lastDoneText: "2d ago",
        accessibilityLabel: "Water Plants, not completed today, 1 of 1 this week, last done 2d ago",
        progressRing: ProgressRingViewData(
            targetCount: 1,
            completedCount: 1,
            fillRatio: 1,
            showsSegments: true,
            showsTodayCheckmark: false
        ),
        isCompletedToday: false,
        isTargetMet: true,
        isOverTarget: false
    )

    static let overTargetCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000004") ?? UUID(),
        name: "Walk The Dog",
        period: .weekly,
        countText: "6/5",
        periodText: "week",
        lastDoneText: "Yesterday",
        accessibilityLabel: "Walk The Dog, not completed today, 6 of 5 this week, last done Yesterday",
        progressRing: ProgressRingViewData(
            targetCount: 5,
            completedCount: 6,
            fillRatio: 1,
            showsSegments: true,
            showsTodayCheckmark: false
        ),
        isCompletedToday: false,
        isTargetMet: true,
        isOverTarget: true
    )

    static let highTargetCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000005") ?? UUID(),
        name: "Practice Piano",
        period: .monthly,
        countText: "9/12",
        periodText: "month",
        lastDoneText: "Today",
        accessibilityLabel: "Practice Piano, completed today, 9 of 12 this month, last done Today",
        progressRing: ProgressRingViewData(
            targetCount: 12,
            completedCount: 9,
            fillRatio: 0.75,
            showsSegments: false,
            showsTodayCheckmark: true
        ),
        isCompletedToday: true,
        isTargetMet: false,
        isOverTarget: false
    )

    static let longNameCard = RoutineCardViewData(
        id: UUID(uuidString: "10000000-0000-0000-0000-000000000006") ?? UUID(),
        name: "Practice Leetcode Problem Solving Before The Kids Wake Up",
        period: .weekly,
        countText: "2/3",
        periodText: "week",
        lastDoneText: "3d ago",
        accessibilityLabel: longNameAccessibilityLabel,
        progressRing: ProgressRingViewData(
            targetCount: 3,
            completedCount: 2,
            fillRatio: 0.67,
            showsSegments: true,
            showsTodayCheckmark: false
        ),
        isCompletedToday: false,
        isTargetMet: false,
        isOverTarget: false
    )

    static let undoBanner = UndoBannerViewData(message: "Completed Morning Yoga")
}

struct ComponentPreviewCanvas<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(16)
            .background(Color.routineCanvas)
    }
}
