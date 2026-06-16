import RoutineCore
import SwiftUI

enum RoutineSettingsKeys {
    static let weekStartWeekday = "settings.weekStartWeekday"
    static let collapseCompletedToday = "settings.collapseCompletedToday"
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
