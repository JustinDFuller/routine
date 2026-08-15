import Foundation
import RoutineCore
import SwiftData

struct RoutineResetSelection {
    var routinesAndHistory: Bool
    var displayPreferences: Bool
    var behindScheduleAlerts: Bool
}

@MainActor
final class RoutineFactoryResetService {
    private static let retiredNotificationPreferenceKeys = [
        "settings.checkin.morning.enabled",
        "settings.checkin.morning.minute",
        "settings.checkin.afternoon.enabled",
        "settings.checkin.afternoon.minute",
        "settings.checkin.evening.enabled",
        "settings.checkin.evening.minute",
        "settings.checkin.onboardingShown",
        "checkin.celebrationConsumed"
    ]

    private let userDefaults: UserDefaults
    private let behindScheduleRescheduleCoordinator: BehindScheduleRescheduleCoordinator

    init(
        userDefaults: UserDefaults = .standard,
        behindScheduleRescheduleCoordinator: BehindScheduleRescheduleCoordinator =
            BehindScheduleRescheduleCoordinator()
    ) {
        self.userDefaults = userDefaults
        self.behindScheduleRescheduleCoordinator = behindScheduleRescheduleCoordinator
    }

    func reset(
        _ selection: RoutineResetSelection,
        in context: ModelContext,
        calendar: RoutineCalendar
    ) async throws {
        if selection.routinesAndHistory {
            try RoutineStoreResetService.resetAllData(in: context)
            RoutineWidgetBridge.clearCompletedRoutineID()
            RoutineWidgetBridge.reloadAllTimelines()
        }

        if selection.displayPreferences {
            userDefaults.removeObject(forKey: RoutineSettingsKeys.weekStartWeekday)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.collapseCompletedToday)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.collapseGoalMetToday)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.collapseUnavailableToday)
        }

        if selection.behindScheduleAlerts {
            userDefaults.removeObject(forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.behindScheduleNotificationMinute)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.behindScheduleOnboardingShown)
            Self.retiredNotificationPreferenceKeys.forEach(userDefaults.removeObject(forKey:))
            await behindScheduleRescheduleCoordinator.cancelAll()
        }

        if selection.routinesAndHistory {
            try await behindScheduleRescheduleCoordinator.reschedule(
                context: context,
                calendar: calendar,
                now: .now
            )
        }
    }
}
