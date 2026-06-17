import RoutineCore
import SwiftUI

struct HistoryMonthGridView: View {
    let weeks: [HistoryCalendarWeek]
    let routineCalendar: RoutineCalendar

    private var monthTitle: String {
        guard let firstDay = weeks.first(where: { $0.days.isEmpty == false })?.days.first else {
            return "This month"
        }

        let formatter = DateFormatter()
        formatter.calendar = routineCalendar.calendar
        formatter.timeZone = routineCalendar.calendar.timeZone
        formatter.locale = routineCalendar.calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date(for: firstDay.day))
    }

    private var weekdaySymbols: [String] {
        routineCalendar.orderedWeekdaySymbols
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(monthTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    ForEach(weekdaySymbols, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.routineLabelSecondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 6)
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("routine-history-weekday-header")
                .accessibilityLabel(weekdaySymbols.joined(separator: " "))

                ForEach(weeks) { week in
                    weekRow(week)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.routineSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("routine-history-month-grid")
    }

    private func weekRow(_ week: HistoryCalendarWeek) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<week.leadingPlaceholders, id: \.self) { _ in
                Color.clear
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }

            ForEach(week.days) { day in
                dayCell(day, isGoalMetWeek: week.isGoalMet)
            }

            ForEach(0..<week.trailingPlaceholders, id: \.self) { _ in
                Color.clear
                    .frame(height: 36)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
            }
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(week.isGoalMet ? Color.routineAccentComplete.opacity(0.12) : .clear)
        )
    }

    private func dayCell(_ day: HistoryCalendarDay, isGoalMetWeek: Bool) -> some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.routineAccentComplete.opacity(isGoalMetWeek ? 0.45 : 0.22) : .clear)

            Circle()
                .stroke(
                    day.isToday ? Color.routineAccentActive : Color.clear,
                    lineWidth: day.isToday ? 2 : 0
                )

            Text(day.label)
                .font(.subheadline.weight(day.isToday ? .semibold : .regular))
                .foregroundStyle(day.isCompleted ? Color.routineLabelPrimary : Color.routineLabelSecondary)
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel(for: day, isGoalMetWeek: isGoalMetWeek))
    }

    private func accessibilityLabel(for day: HistoryCalendarDay, isGoalMetWeek: Bool) -> String {
        let dateText = explicitDateLabel(for: day.day)
        let todayText = day.isToday ? "today" : "not today"
        let completionText = day.isCompleted ? "completed" : "not completed"
        let goalMetSuffix = isGoalMetWeek ? ", goal met" : ""
        return "\(dateText), \(todayText), \(completionText)\(goalMetSuffix)"
    }

    private func explicitDateLabel(for day: RoutineDay) -> String {
        let formatter = DateFormatter()
        formatter.calendar = routineCalendar.calendar
        formatter.timeZone = routineCalendar.calendar.timeZone
        formatter.locale = routineCalendar.calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date(for: day))
    }

    private func date(for day: RoutineDay) -> Date {
        var components = DateComponents()
        components.calendar = routineCalendar.calendar
        components.timeZone = routineCalendar.calendar.timeZone
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = 12

        guard let date = routineCalendar.calendar.date(from: components) else {
            preconditionFailure("Unable to construct date for month grid.")
        }

        return date
    }
}
