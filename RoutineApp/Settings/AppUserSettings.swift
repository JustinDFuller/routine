import Foundation
import RoutineCore

struct AppUserSettings {
    static let weekStartDayKey = "weekStartDay"

    static func weekStartDay() -> WeekStartDay {
        let raw = UserDefaults.standard.integer(forKey: weekStartDayKey)
        return WeekStartDay(rawValue: raw) ?? .sunday
    }

    static func setWeekStartDay(_ day: WeekStartDay) {
        UserDefaults.standard.set(day.rawValue, forKey: weekStartDayKey)
    }

    static func routineCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        calendar.firstWeekday = weekStartDay().rawValue
        return RoutineCalendar(calendar: calendar)
    }
}
