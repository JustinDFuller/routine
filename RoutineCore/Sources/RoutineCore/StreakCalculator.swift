public struct RoutineStreak: Equatable, Sendable {
    public let count: Int
    public let period: RoutinePeriod
}

public struct StreakCalculator: Sendable {
    public let routineCalendar: RoutineCalendar

    public init(routineCalendar: RoutineCalendar = .current) {
        self.routineCalendar = routineCalendar
    }

    public func streak(
        period: RoutinePeriod,
        targetCount: Int,
        completionDays: [RoutineDay],
        today: RoutineDay
    ) -> RoutineStreak {
        guard targetCount > 0 else {
            return RoutineStreak(count: 0, period: period)
        }

        let uniqueDays = Set(completionDays)
        var range = routineCalendar.currentPeriodRange(for: period, containing: today)
        var count = 0

        while true {
            range = routineCalendar.previousPeriodRange(for: period, before: range)
            let metCount = uniqueDays.filter { range.contains($0) }.count
            guard metCount >= targetCount else { break }
            count += 1
        }

        return RoutineStreak(count: count, period: period)
    }
}
