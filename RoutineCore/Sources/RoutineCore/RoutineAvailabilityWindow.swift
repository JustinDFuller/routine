import Foundation

public struct RoutineTimeOfDay: Equatable, Hashable, Sendable {
    public let hour: Int
    public let minute: Int

    public var minuteOfDay: Int {
        (hour * 60) + minute
    }

    public init?(hour: Int, minute: Int) {
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            return nil
        }

        self.hour = hour
        self.minute = minute
    }

    public init?(minuteOfDay: Int) {
        guard (0..<1_440).contains(minuteOfDay) else {
            return nil
        }

        let hour = minuteOfDay / 60
        let minute = minuteOfDay % 60
        self.init(hour: hour, minute: minute)
    }
}

public struct RoutineAvailabilityWindow: Equatable, Hashable, Sendable {
    public let start: RoutineTimeOfDay
    public let end: RoutineTimeOfDay

    public var spansMidnight: Bool {
        end.minuteOfDay < start.minuteOfDay
    }

    public init?(start: RoutineTimeOfDay, end: RoutineTimeOfDay) {
        guard start.minuteOfDay != end.minuteOfDay else {
            return nil
        }

        self.start = start
        self.end = end
    }

    public func contains(minuteOfDay: Int) -> Bool {
        guard (0..<1_440).contains(minuteOfDay) else {
            return false
        }

        if spansMidnight {
            return minuteOfDay >= start.minuteOfDay || minuteOfDay < end.minuteOfDay
        }

        return start.minuteOfDay <= minuteOfDay && minuteOfDay < end.minuteOfDay
    }
}
