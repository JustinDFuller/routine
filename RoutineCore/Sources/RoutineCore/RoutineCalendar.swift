import Foundation

public struct RoutineCalendar: Sendable {
    public let calendar: Calendar

    public static var current: RoutineCalendar {
        current(weekStart: .sunday)
    }

    public static func current(weekStart: Weekday) -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        calendar.firstWeekday = weekStart.rawValue
        return RoutineCalendar(calendar: calendar)
    }

    public init(calendar: Calendar) {
        self.calendar = calendar
    }

    public func day(containing date: Date) -> RoutineDay {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard
            let year = components.year,
            let month = components.month,
            let day = components.day,
            let routineDay = RoutineDay(year: year, month: month, day: day)
        else {
            preconditionFailure("Unable to derive RoutineDay from \(date)")
        }

        return routineDay
    }

    public func today(now: Date = .now) -> RoutineDay {
        day(containing: now)
    }

    public func minuteOfDay(containing date: Date) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else {
            preconditionFailure("Unable to derive minute of day from \(date)")
        }

        return (hour * 60) + minute
    }

    public func currentPeriodRange(
        for period: RoutinePeriod,
        containing day: RoutineDay
    ) -> ClosedRange<RoutineDay> {
        switch period {
        case .weekly:
            currentWeekRange(containing: day)
        case .monthly:
            currentMonthRange(containing: day)
        }
    }

    public func currentWeekRange(containing day: RoutineDay) -> ClosedRange<RoutineDay> {
        let date = date(for: day)
        let offset = weekdayOffset(for: day)

        guard
            let startDate = calendar.date(byAdding: .day, value: -offset, to: date),
            let endDate = calendar.date(byAdding: .day, value: 6, to: startDate)
        else {
            preconditionFailure("Unable to compute current week range for \(day.key)")
        }

        return self.day(containing: startDate)...self.day(containing: endDate)
    }

    public func weekdayOffset(for day: RoutineDay) -> Int {
        let weekday = calendar.component(.weekday, from: date(for: day))
        return (weekday - calendar.firstWeekday + 7) % 7
    }

    public var orderedWeekdaySymbols: [String] {
        let startIndex = calendar.firstWeekday - 1
        let orderedWeekdays = Array(Weekday.allCases[startIndex...] + Weekday.allCases[..<startIndex])
        return orderedWeekdays.map(\.shortSymbol)
    }

    public func currentMonthRange(containing day: RoutineDay) -> ClosedRange<RoutineDay> {
        let date = date(for: day)
        guard let days = calendar.range(of: .day, in: .month, for: date) else {
            preconditionFailure("Unable to compute month range for \(day.key)")
        }

        guard
            let start = RoutineDay(year: day.year, month: day.month, day: 1),
            let end = RoutineDay(year: day.year, month: day.month, day: days.count)
        else {
            preconditionFailure("Unable to create month boundary for \(day.key)")
        }

        return start...end
    }

    public func daysInCurrentMonth(containing day: RoutineDay) -> [RoutineDay] {
        let range = currentMonthRange(containing: day)
        return Array(range.lowerBound.day...range.upperBound.day).compactMap { dayNumber in
            RoutineDay(year: day.year, month: day.month, day: dayNumber)
        }
    }

    public func relativeLabel(for day: RoutineDay, today: RoutineDay) -> String {
        let dayDate = date(for: day)
        let todayDate = date(for: today)
        let dayDifference = calendar.dateComponents([.day], from: dayDate, to: todayDate).day ?? 0

        switch dayDifference {
        case 0:
            return "Today"
        case 1:
            return "Yesterday"
        case 2...7:
            return "\(dayDifference)d ago"
        default:
            if dayDifference < 0 {
                return explicitDateLabel(for: day)
            }

            if day.year == today.year {
                return monthDayLabel(for: day)
            }

            return explicitDateLabel(for: day)
        }
    }

    public func relativeLabel(for day: RoutineDay?, today: RoutineDay) -> String {
        guard let day else {
            return "Never"
        }

        return relativeLabel(for: day, today: today)
    }

    public func explicitDateLabel(for day: RoutineDay) -> String {
        formatter(dateFormat: "MMM d, yyyy").string(from: date(for: day))
    }

    private func monthDayLabel(for day: RoutineDay) -> String {
        formatter(dateFormat: "MMM d").string(from: date(for: day))
    }

    private func formatter(dateFormat: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        return formatter
    }

    private func date(for day: RoutineDay) -> Date {
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = 12

        guard let date = calendar.date(from: components) else {
            preconditionFailure("Unable to construct Date for \(day.key)")
        }

        return date
    }
}
