import Foundation

public struct GlobalBreak: Equatable, Sendable {
    public let resumeDay: RoutineDay

    public init(resumeDay: RoutineDay) {
        self.resumeDay = resumeDay
    }
}

public enum RoutineBreakSource: Equatable, Sendable {
    case routine
    case global
    case both
}

public struct RoutineBreakStatus: Equatable, Sendable {
    public let resumeDay: RoutineDay
    public let source: RoutineBreakSource

    public init(resumeDay: RoutineDay, source: RoutineBreakSource) {
        self.resumeDay = resumeDay
        self.source = source
    }
}

public enum RoutineBreakPreset: Equatable, Hashable, Sendable, CaseIterable {
    case today
    case thisWeek
    case thisMonth
    case untilDate
}

public enum RoutineBreak {
    public static func status(
        perRoutineResume: RoutineDay?,
        global: GlobalBreak?,
        today: RoutineDay
    ) -> RoutineBreakStatus? {
        let activePerRoutineResume = activeResumeDay(perRoutineResume, today: today)
        let activeGlobalResume = activeResumeDay(global?.resumeDay, today: today)

        switch (activePerRoutineResume, activeGlobalResume) {
        case (nil, nil): return nil
        case (.some(let routineResume), nil):
            return RoutineBreakStatus(resumeDay: routineResume, source: .routine)
        case (nil, .some(let globalResume)):
            return RoutineBreakStatus(resumeDay: globalResume, source: .global)
        case (.some(let routineResume), .some(let globalResume)):
            return RoutineBreakStatus(resumeDay: max(routineResume, globalResume), source: .both)
        }
    }

    public static func isActive(resumeDay: RoutineDay?, today: RoutineDay) -> Bool {
        guard let resumeDay else { return false }
        return today < resumeDay
    }

    public static func resumeDay(
        for preset: RoutineBreakPreset,
        today: RoutineDay,
        calendar: RoutineCalendar,
        explicitDate: Date? = nil
    ) -> RoutineDay {
        switch preset {
        case .today:
            return dayAfter(today, calendar: calendar)
        case .thisWeek:
            let currentWeekStart = calendar.periodStart(for: .weekly, containing: today)
            return calendar.advancingPeriodStart(currentWeekStart, by: 1, period: .weekly)
        case .thisMonth:
            let currentMonthStart = calendar.periodStart(for: .monthly, containing: today)
            return calendar.advancingPeriodStart(currentMonthStart, by: 1, period: .monthly)
        case .untilDate:
            guard let explicitDate else {
                return dayAfter(today, calendar: calendar)
            }

            return max(calendar.day(containing: explicitDate), dayAfter(today, calendar: calendar))
        }
    }

    private static func activeResumeDay(_ resumeDay: RoutineDay?, today: RoutineDay) -> RoutineDay? {
        guard isActive(resumeDay: resumeDay, today: today), let resumeDay else {
            return nil
        }

        return resumeDay
    }

    private static func dayAfter(_ day: RoutineDay, calendar: RoutineCalendar) -> RoutineDay {
        let date = calendar.date(for: day)
        guard let nextDate = calendar.calendar.date(byAdding: .day, value: 1, to: date) else {
            preconditionFailure("Unable to advance routine day \(day.key).")
        }

        return calendar.day(containing: nextDate)
    }
}
