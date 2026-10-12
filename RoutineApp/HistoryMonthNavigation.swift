import Foundation
import RoutineCore

struct HistoryMonthNavigation {
    let routineCalendar: RoutineCalendar
    let today: RoutineDay

    var currentMonth: RoutineDay {
        firstDay(year: today.year, month: today.month)
    }

    func selection(from displayedMonth: RoutineDay, offset: Int) -> RoutineDay? {
        var range = routineCalendar.currentMonthRange(containing: displayedMonth)

        for _ in 0..<abs(offset) {
            range =
                offset < 0
                ? routineCalendar.previousPeriodRange(for: .monthly, before: range)
                : routineCalendar.nextPeriodRange(for: .monthly, after: range)
        }

        return selection(year: range.lowerBound.year, month: range.lowerBound.month)
    }

    func selection(year: Int, month: Int) -> RoutineDay? {
        let requested = firstDay(year: year, month: month)
        return requested < currentMonth ? requested : nil
    }

    func availableMonths(inYear year: Int) -> ClosedRange<Int> {
        year >= today.year ? 1...today.month : 1...12
    }

    func isSameMonth(_ lhs: RoutineDay, _ rhs: RoutineDay) -> Bool {
        lhs.year == rhs.year && lhs.month == rhs.month
    }

    private func firstDay(year: Int, month: Int) -> RoutineDay {
        guard let day = RoutineDay(year: year, month: month, day: 1) else {
            preconditionFailure("Unable to construct month \(year)-\(month).")
        }

        return day
    }
}

extension RoutineCalendar {
    func historyMonthTitle(for month: RoutineDay) -> String {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = month.year
        components.month = month.month
        components.day = 1
        components.hour = 12

        guard let date = calendar.date(from: components) else {
            preconditionFailure("Unable to construct date for month title.")
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
}
