import Foundation

enum WeekStartDay: Int, CaseIterable, Identifiable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    var id: Int { rawValue }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.locale = .current
        return formatter.standaloneWeekdaySymbols[rawValue - 1]
    }
}
