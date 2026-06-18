import RoutineCore
import SwiftUI

enum RoutineSettingsKeys {
    static let weekStartWeekday = "settings.weekStartWeekday"
    static let collapseCompletedToday = "settings.collapseCompletedToday"
    static let checkInMorningEnabled = "settings.checkin.morning.enabled"
    static let checkInMorningMinute = "settings.checkin.morning.minute"
    static let checkInAfternoonEnabled = "settings.checkin.afternoon.enabled"
    static let checkInAfternoonMinute = "settings.checkin.afternoon.minute"
    static let checkInEveningEnabled = "settings.checkin.evening.enabled"
    static let checkInEveningMinute = "settings.checkin.evening.minute"
    static let checkInOnboardingShown = "settings.checkin.onboardingShown"
}

private struct RoutineCalendarKey: EnvironmentKey {
    static let defaultValue = RoutineCalendar.current
}

extension EnvironmentValues {
    var routineCalendar: RoutineCalendar {
        get { self[RoutineCalendarKey.self] }
        set { self[RoutineCalendarKey.self] = newValue }
    }
}
