import Foundation

public enum BehindScheduleContent: Equatable, Sendable {
    case message(title: String, body: String)
    case suppress
}

public struct BehindScheduleRoutineSnapshot: Sendable {
    public let name: String
    public let targetCount: Int
    public let period: RoutinePeriod
    public let completionDays: [RoutineDay]

    public init(
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        completionDays: [RoutineDay]
    ) {
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.completionDays = completionDays
    }
}

public struct BehindScheduleContext: Sendable {
    public let now: Date
    public let calendar: RoutineCalendar

    public init(now: Date, calendar: RoutineCalendar) {
        self.now = now
        self.calendar = calendar
    }
}

private struct BehindScheduleDeficit {
    let routine: BehindScheduleRoutineSnapshot
    let completedCount: Int
    let deficit: Int
    let daysRemaining: Int
}

public struct BehindScheduleContentBuilder: Sendable {
    public init() {}

    public func content(
        routines: [BehindScheduleRoutineSnapshot],
        context: BehindScheduleContext
    ) -> BehindScheduleContent {
        let today = context.calendar.today(now: context.now)
        let progressCalculator = ProgressCalculator(routineCalendar: context.calendar)
        var mostBehind: BehindScheduleDeficit?

        for routine in routines {
            let periodRange = context.calendar.currentPeriodRange(for: routine.period, containing: today)
            guard
                let elapsedDays = inclusiveDayCount(
                    from: periodRange.lowerBound,
                    through: today,
                    calendar: context.calendar.calendar
                ),
                let periodDays = inclusiveDayCount(
                    from: periodRange.lowerBound,
                    through: periodRange.upperBound,
                    calendar: context.calendar.calendar
                )
            else {
                continue
            }

            let completedCount = progressCalculator.progress(
                period: routine.period,
                targetCount: routine.targetCount,
                completionDays: routine.completionDays,
                today: today
            ).completedCount
            let expectedCount = Int(
                (Double(routine.targetCount) * Double(elapsedDays) / Double(periodDays)).rounded(
                    .toNearestOrAwayFromZero)
            )
            let deficit = expectedCount - completedCount

            guard deficit > 0 else {
                continue
            }

            let daysRemaining = periodDays - elapsedDays + 1
            guard let currentMostBehind = mostBehind else {
                mostBehind = BehindScheduleDeficit(
                    routine: routine,
                    completedCount: completedCount,
                    deficit: deficit,
                    daysRemaining: daysRemaining
                )
                continue
            }

            if deficit > currentMostBehind.deficit {
                mostBehind = BehindScheduleDeficit(
                    routine: routine,
                    completedCount: completedCount,
                    deficit: deficit,
                    daysRemaining: daysRemaining
                )
            }
        }

        guard let mostBehind else {
            return .suppress
        }

        return .message(
            title: "Behind schedule",
            body:
                "\(mostBehind.routine.name): \(mostBehind.completedCount) of \(mostBehind.routine.targetCount) "
                + "this \(periodLabel(for: mostBehind.routine.period)). You’re \(mostBehind.deficit) "
                + "\(pluralizedCompletion(mostBehind.deficit)) behind pace with \(mostBehind.daysRemaining) "
                + "\(pluralizedDay(mostBehind.daysRemaining)) left."
        )
    }

    private func inclusiveDayCount(
        from start: RoutineDay,
        through end: RoutineDay,
        calendar: Calendar
    ) -> Int? {
        guard let startDate = localMidnight(for: start, calendar: calendar),
            let endDate = localMidnight(for: end, calendar: calendar),
            let dayCount = calendar.dateComponents([.day], from: startDate, to: endDate).day
        else {
            return nil
        }

        return dayCount + 1
    }

    private func localMidnight(for day: RoutineDay, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day))
    }

    private func periodLabel(for period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "week"
        case .monthly:
            "month"
        }
    }

    private func pluralizedCompletion(_ count: Int) -> String {
        count == 1 ? "completion" : "completions"
    }

    private func pluralizedDay(_ count: Int) -> String {
        count == 1 ? "day" : "days"
    }
}
