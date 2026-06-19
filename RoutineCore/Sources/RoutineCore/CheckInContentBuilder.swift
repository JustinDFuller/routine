import Foundation

public enum CheckInSlot: String, CaseIterable, Sendable {
    case morning, afternoon, evening
}

public enum CheckInContent: Equatable, Sendable {
    case message(title: String, body: String)
    case suppress
}

public struct CheckInRoutineSnapshot: Sendable {
    public let name: String
    public let targetCount: Int
    public let period: RoutinePeriod
    public let availabilityWindow: RoutineAvailabilityWindow?
    public let completionDays: [RoutineDay]

    public init(
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        availabilityWindow: RoutineAvailabilityWindow?,
        completionDays: [RoutineDay]
    ) {
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.availabilityWindow = availabilityWindow
        self.completionDays = completionDays
    }
}

public struct CheckInContext: Sendable {
    public let now: Date
    public let calendar: RoutineCalendar
    public let celebrationConsumed: Bool

    public init(now: Date, calendar: RoutineCalendar, celebrationConsumed: Bool) {
        self.now = now
        self.calendar = calendar
        self.celebrationConsumed = celebrationConsumed
    }
}

private typealias RoutineProgressPair = (routine: CheckInRoutineSnapshot, progress: RoutineProgress)

public struct CheckInContentBuilder: Sendable {
    public static let celebrationTitle = "All caught up"

    public init() {}

    public func content(
        slot: CheckInSlot,
        slotMinuteOfDay: Int,
        routines: [CheckInRoutineSnapshot],
        context: CheckInContext
    ) -> CheckInContent {
        let pairs = progressPairs(for: routines, context: context)
        let openGoals = pairs.filter { $0.progress.isTargetMet == false }

        guard openGoals.isEmpty == false else {
            return context.celebrationConsumed ? .suppress : celebrationMessage
        }

        let next = nextActionable(in: openGoals, slotMinuteOfDay: slotMinuteOfDay)
        let doneToday = pairs.filter(\.progress.isCompletedToday).count

        switch slot {
        case .morning:
            return morningContent(next: next)
        case .afternoon:
            return afternoonContent(next: next, doneToday: doneToday)
        case .evening:
            return eveningContent(pairCount: pairs.count, openGoalCount: openGoals.count, doneToday: doneToday)
        }
    }

    private func progressPairs(
        for routines: [CheckInRoutineSnapshot],
        context: CheckInContext
    ) -> [RoutineProgressPair] {
        let today = context.calendar.today(now: context.now)
        let progressCalculator = ProgressCalculator(routineCalendar: context.calendar)

        return routines.map { routine in
            (
                routine: routine,
                progress: progressCalculator.progress(
                    period: routine.period,
                    targetCount: routine.targetCount,
                    completionDays: routine.completionDays,
                    today: today
                )
            )
        }
    }

    private func nextActionable(
        in openGoals: [RoutineProgressPair],
        slotMinuteOfDay: Int
    ) -> RoutineProgressPair? {
        openGoals.first { routine, progress in
            let isAvailable = routine.availabilityWindow?.contains(minuteOfDay: slotMinuteOfDay) ?? true
            return isAvailable && progress.isCompletedToday == false
        }
    }

    private var celebrationMessage: CheckInContent {
        .message(
            title: Self.celebrationTitle,
            body: "You've met all of your current goals. There's nothing left to do right now."
        )
    }

    private func morningContent(next: RoutineProgressPair?) -> CheckInContent {
        guard let next else {
            return .suppress
        }

        return .message(
            title: "Morning check-in",
            body: [
                nextRoutineSentence(for: next.routine.name),
                remainingCompletionsSentence(
                    remainingCount: next.progress.remainingCount,
                    period: next.routine.period
                )
            ].joined(separator: " ")
        )
    }

    private func afternoonContent(next: RoutineProgressPair?, doneToday: Int) -> CheckInContent {
        guard let next else {
            return .suppress
        }

        return .message(
            title: "Afternoon check-in",
            body: [
                completedRoutinesSentence(doneToday),
                nextRoutineSentence(for: next.routine.name),
                remainingCompletionsSentence(
                    remainingCount: next.progress.remainingCount,
                    period: next.routine.period
                )
            ].joined(separator: " ")
        )
    }

    private func eveningContent(pairCount: Int, openGoalCount: Int, doneToday: Int) -> CheckInContent {
        let metCount = pairCount - openGoalCount

        return .message(
            title: "Evening check-in",
            body:
                "\(completedRoutinesSentence(doneToday)) "
                + "\(metGoalsClause(metCount: metCount, totalCount: pairCount)), "
                + "and \(openGoalsClause(openGoalCount))."
        )
    }

    private func nextRoutineSentence(for routineName: String) -> String {
        "Next routine: \(routineName)."
    }

    private func completedRoutinesSentence(_ count: Int) -> String {
        "You've completed \(count) \(count == 1 ? "routine" : "routines") today."
    }

    private func remainingCompletionsSentence(remainingCount: Int, period: RoutinePeriod) -> String {
        "You need \(remainingCount) more \(remainingCount == 1 ? "completion" : "completions") "
            + "to reach \(goalPhrase(for: period))."
    }

    private func metGoalsClause(metCount: Int, totalCount: Int) -> String {
        let goalWord = totalCount == 1 ? "goal" : "goals"
        let verb = totalCount == 1 ? "is" : verb(for: metCount)
        return "\(metCount) of \(totalCount) \(goalWord) \(verb) met"
    }

    private func openGoalsClause(_ count: Int) -> String {
        "\(count) \(count == 1 ? "goal" : "goals") \(verb(for: count)) still open"
    }

    private func goalPhrase(for period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "this week's goal"
        case .monthly:
            "this month's goal"
        }
    }

    private func verb(for count: Int) -> String {
        count == 1 ? "is" : "are"
    }
}
