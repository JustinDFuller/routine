import Foundation

public struct GlobalPause: Equatable, Sendable {
    public let anchor: RoutineDay
    public let skipPeriods: Int

    public init(anchor: RoutineDay, skipPeriods: Int) {
        self.anchor = anchor
        self.skipPeriods = skipPeriods
    }
}

public enum RoutinePause {
    public static func resumeDay(
        perRoutineResume: RoutineDay?,
        global: GlobalPause?,
        period: RoutinePeriod,
        calendar: RoutineCalendar
    ) -> RoutineDay? {
        let globalResume: RoutineDay? = global.map { pause in
            let anchorStart = calendar.periodStart(for: period, containing: pause.anchor)
            return calendar.advancingPeriodStart(anchorStart, by: pause.skipPeriods, period: period)
        }

        switch (perRoutineResume, globalResume) {
        case (nil, nil): return nil
        case (.some(let p), nil): return p
        case (nil, .some(let g)): return g
        case (.some(let p), .some(let g)): return max(p, g)
        }
    }

    public static func isPaused(resumeDay: RoutineDay?, today: RoutineDay) -> Bool {
        guard let resumeDay else { return false }
        return today < resumeDay
    }
}
