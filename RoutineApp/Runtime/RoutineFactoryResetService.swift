import Foundation
import RoutineCore
import SwiftData
import UserNotifications

struct RoutineResetSelection {
    var routinesAndHistory: Bool
    var displayPreferences: Bool
    var checkInReminders: Bool
}

@MainActor
final class RoutineFactoryResetService {
    private let userDefaults: UserDefaults
    private let notificationCenter: CheckInNotificationCenter

    init(
        userDefaults: UserDefaults = .standard,
        notificationCenter: CheckInNotificationCenter = UNUserNotificationCenter.current()
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
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

        if selection.checkInReminders {
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInMorningEnabled)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInMorningMinute)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInAfternoonEnabled)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInAfternoonMinute)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInEveningEnabled)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInEveningMinute)
            userDefaults.removeObject(forKey: RoutineSettingsKeys.checkInOnboardingShown)
            userDefaults.removeObject(forKey: CheckInScheduler.celebrationConsumedKey)
            await CheckInScheduler(
                notificationCenter: notificationCenter,
                userDefaults: userDefaults
            ).cancelAll()
        }
    }
}
