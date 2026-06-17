public struct ProgressCalculator: Sendable {
    public let routineCalendar: RoutineCalendar

    public init(routineCalendar: RoutineCalendar = .current) {
        self.routineCalendar = routineCalendar
    }

    public func progress(
        period: RoutinePeriod,
        targetCount: Int,
        completionDays: [RoutineDay],
        today: RoutineDay
    ) -> RoutineProgress {
        let uniqueCompletionDays = uniqueSortedDays(from: completionDays)

        return RoutineProgress(
            period: period,
            targetCount: targetCount,
            completedCount: completionsInCurrentPeriod(
                period: period,
                completionDays: uniqueCompletionDays,
                today: today
            ).count,
            isCompletedToday: uniqueCompletionDays.contains(today),
            lastCompletedDay: lastCompletedDay(from: uniqueCompletionDays)
        )
    }

    public func completionsInCurrentPeriod(
        period: RoutinePeriod,
        completionDays: [RoutineDay],
        today: RoutineDay
    ) -> [RoutineDay] {
        let uniqueCompletionDays = uniqueSortedDays(from: completionDays)
        let currentRange = routineCalendar.currentPeriodRange(for: period, containing: today)

        return uniqueCompletionDays.filter { currentRange.contains($0) }
    }

    public func lastCompletedDay(from completionDays: [RoutineDay]) -> RoutineDay? {
        uniqueSortedDays(from: completionDays).last
    }

    public func completions(
        in range: ClosedRange<RoutineDay>,
        completionDays: [RoutineDay]
    ) -> [RoutineDay] {
        uniqueSortedDays(from: completionDays).filter { range.contains($0) }
    }

    private func uniqueSortedDays(from completionDays: [RoutineDay]) -> [RoutineDay] {
        Array(Set(completionDays)).sorted()
    }
}
