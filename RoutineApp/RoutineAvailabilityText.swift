import Foundation
import RoutineCore

enum RoutineAvailabilityText {
    static func cardLabel(
        for window: RoutineAvailabilityWindow,
        isAvailableNow: Bool,
        routineCalendar: RoutineCalendar
    ) -> String {
        if isAvailableNow {
            return "Available until \(timeText(for: window.end, routineCalendar: routineCalendar))"
        }

        return "Available \(compactRangeText(for: window, routineCalendar: routineCalendar))"
    }

    static func manageSummaryText(
        for window: RoutineAvailabilityWindow,
        routineCalendar: RoutineCalendar
    ) -> String {
        "available \(compactRangeText(for: window, routineCalendar: routineCalendar))"
    }

    static func unavailableAccessibilityPhrase(
        for window: RoutineAvailabilityWindow,
        routineCalendar: RoutineCalendar
    ) -> String {
        "unavailable now, available \(expandedRangeText(for: window, routineCalendar: routineCalendar))"
    }

    static func trackingWindowText(
        for window: RoutineAvailabilityWindow,
        routineCalendar: RoutineCalendar
    ) -> String {
        let startText = timeText(for: window.start, routineCalendar: routineCalendar)
        let endText = timeText(for: window.end, routineCalendar: routineCalendar)
        return "between \(startText) and \(endText)"
    }

    private static func compactRangeText(
        for window: RoutineAvailabilityWindow,
        routineCalendar: RoutineCalendar
    ) -> String {
        let startText = timeText(for: window.start, routineCalendar: routineCalendar)
        let endText = timeText(for: window.end, routineCalendar: routineCalendar)
        return "\(startText)-\(endText)"
    }

    private static func expandedRangeText(
        for window: RoutineAvailabilityWindow,
        routineCalendar: RoutineCalendar
    ) -> String {
        let startText = timeText(for: window.start, routineCalendar: routineCalendar)
        let endText = timeText(for: window.end, routineCalendar: routineCalendar)
        return "\(startText) to \(endText)"
    }

    private static func timeText(
        for timeOfDay: RoutineTimeOfDay,
        routineCalendar: RoutineCalendar
    ) -> String {
        var components = DateComponents()
        components.calendar = routineCalendar.calendar
        components.timeZone = routineCalendar.calendar.timeZone
        components.year = 2001
        components.month = 1
        components.day = 1
        components.hour = timeOfDay.hour
        components.minute = timeOfDay.minute

        guard let date = routineCalendar.calendar.date(from: components) else {
            preconditionFailure("Unable to format availability time \(timeOfDay.minuteOfDay).")
        }

        let formatter = DateFormatter()
        formatter.calendar = routineCalendar.calendar
        formatter.timeZone = routineCalendar.calendar.timeZone
        formatter.locale = routineCalendar.calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
            .replacingOccurrences(of: "\u{202F}", with: " ")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
    }
}
