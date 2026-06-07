public struct RoutineProgress: Equatable, Sendable {
    public let period: RoutinePeriod
    public let targetCount: Int
    public let completedCount: Int
    public let isCompletedToday: Bool
    public let lastCompletedDay: RoutineDay?

    public init(
        period: RoutinePeriod,
        targetCount: Int,
        completedCount: Int,
        isCompletedToday: Bool,
        lastCompletedDay: RoutineDay?
    ) {
        self.period = period
        self.targetCount = targetCount
        self.completedCount = completedCount
        self.isCompletedToday = isCompletedToday
        self.lastCompletedDay = lastCompletedDay
    }

    public var remainingCount: Int {
        max(targetCount - completedCount, 0)
    }

    public var isTargetMet: Bool {
        completedCount >= targetCount
    }

    public var isOverTarget: Bool {
        completedCount > targetCount
    }

    public var fillRatio: Double {
        guard targetCount > 0 else {
            return 0
        }

        return min(Double(completedCount) / Double(targetCount), 1)
    }
}
