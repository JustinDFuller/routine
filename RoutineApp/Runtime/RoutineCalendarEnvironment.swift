import RoutineCore
import SwiftUI

enum RoutineSettingsKeys {
    static let weekStartWeekday = "settings.weekStartWeekday"
    static let collapseCompletedToday = "settings.collapseCompletedToday"
    static let collapseGoalMetToday = "settings.collapseGoalMetToday"
    static let collapseUnavailableToday = "settings.collapseUnavailableToday"
    static let behindScheduleNotificationsEnabled = "settings.behindScheduleNotifications.enabled"
    static let behindScheduleNotificationMinute = "settings.behindScheduleNotifications.minute"
    static let behindScheduleOnboardingShown = "settings.behindScheduleNotifications.onboardingShown"
    static let openAppOnWidgetCompletion = RoutineWidgetBridge.openAppOnWidgetCompletionKey
}

private struct RoutineCalendarKey: EnvironmentKey {
    static let defaultValue = RoutineCalendar.current
}

private struct BehindScheduleRescheduleCoordinatorKey: EnvironmentKey {
    static let defaultValue = MainActor.assumeIsolated {
        BehindScheduleRescheduleCoordinator()
    }
}

extension EnvironmentValues {
    var routineCalendar: RoutineCalendar {
        get { self[RoutineCalendarKey.self] }
        set { self[RoutineCalendarKey.self] = newValue }
    }
    var behindScheduleRescheduleCoordinator: BehindScheduleRescheduleCoordinator {
        get { self[BehindScheduleRescheduleCoordinatorKey.self] }
        set { self[BehindScheduleRescheduleCoordinatorKey.self] = newValue }
    }
}
