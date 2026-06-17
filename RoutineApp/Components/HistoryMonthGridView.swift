import RoutineCore
import SwiftUI

struct HistoryMonthGridView: View {
    let weeks: [HistoryCalendarWeek]
    let routineCalendar: RoutineCalendar
    let onTapDay: (HistoryCalendarDay) -> Void
    let popoverIsPresented: (String) -> Binding<Bool>
    let onConfirmDay: () -> Void

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
        Button {
            onTapDay(day)
        } label: {
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
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .disabled(day.isFuture)
        .opacity(day.isFuture ? 0.35 : 1)
        .popover(isPresented: popoverIsPresented(day.id)) {
            DayConfirmationPopover(
                dayID: day.id,
                dateText: explicitDateLabel(for: day.day),
                isCompleted: day.isCompleted,
                onConfirm: onConfirmDay
            )
            .presentationCompactAdaptation(.popover)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("history-day-\(day.id)")
        .accessibilityLabel(accessibilityLabel(for: day, isGoalMetWeek: isGoalMetWeek))
    }

    private func accessibilityLabel(for day: HistoryCalendarDay, isGoalMetWeek: Bool) -> String {
        let dateText = explicitDateLabel(for: day.day)
        let todayText = day.isToday ? "today" : "not today"
        let completionText = day.isCompleted ? "completed" : "not completed"
        let goalMetSuffix = isGoalMetWeek ? ", goal met" : ""

        if day.isFuture {
            return "\(dateText), \(todayText), \(completionText)\(goalMetSuffix), future"
        }

        let actionHint = day.isCompleted ? "double tap to remove completion" : "double tap to mark completed"
        return "\(dateText), \(todayText), \(completionText)\(goalMetSuffix), \(actionHint)"
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

private struct DayConfirmationPopover: View {
    let dayID: String
    let dateText: String
    let isCompleted: Bool
    let onConfirm: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(dateText)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Button(role: isCompleted ? .destructive : nil, action: onConfirm) {
                Text(isCompleted ? "Remove Completion" : "Mark Complete")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(isCompleted ? Color.routineAccentDestructive : Color.routineAccentActive)
            .accessibilityIdentifier("history-day-confirm-\(dayID)")
        }
        .padding(16)
        .frame(minWidth: 200)
    }
}
