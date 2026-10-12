import RoutineCore
import SwiftUI

struct HistoryMonthGridView: View {
    let weeks: [HistoryCalendarWeek]
    let displayedMonth: RoutineDay
    let routineCalendar: RoutineCalendar
    let isDisplayingCurrentMonth: Bool
    let pickerYears: ClosedRange<Int>
    let monthsInYear: (Int) -> ClosedRange<Int>
    let isPickerOpen: Bool
    let slideEdge: Edge
    let usesCrossFade: Bool
    let onTogglePicker: () -> Void
    let onShowMonth: (Int) -> Void
    let onAdjustMonth: (Int) -> Void
    let onSelectMonth: (Int, Int) -> Void
    let onShowToday: () -> Void
    let onTapDay: (HistoryCalendarDay) -> Void
    let popoverIsPresented: (String) -> Binding<Bool>
    let onConfirmDay: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var frozenWheelYears: ClosedRange<Int>?

    private var monthTitle: String {
        routineCalendar.historyMonthTitle(for: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        routineCalendar.orderedWeekdaySymbols
    }

    private var monthTransition: AnyTransition {
        usesCrossFade ? .opacity : .push(from: slideEdge)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            ZStack {
                if isPickerOpen {
                    wheels
                } else {
                    monthGrid
                }
            }
            .clipped()
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
        .onChange(of: isPickerOpen) { _, isOpen in
            frozenWheelYears = isOpen ? openingWheelYears : nil
        }
    }

    private var header: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    titleButton
                    todayButton
                }
            } else {
                HStack(spacing: 8) {
                    titleButton
                    Spacer(minLength: 8)
                    todayButton
                }
            }
        }
    }

    private var titleButton: some View {
        Button(action: onTogglePicker) {
            HStack(spacing: 6) {
                Text(monthTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.routineLabelPrimary)

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.routineLabelSecondary)
                    .rotationEffect(.degrees(isPickerOpen ? 90 : 0))
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("routine-history-month-title")
        .accessibilityLabel("\(monthTitle), choose month")
        .accessibilityHint(isPickerOpen ? "Shows the month grid" : "Shows month and year wheels")
    }

    @ViewBuilder
    private var todayButton: some View {
        if isDisplayingCurrentMonth == false {
            Button("Today", action: onShowToday)
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
                .tint(Color.routineAccentActive)
                .frame(minHeight: 44)
                .accessibilityIdentifier("routine-history-today-button")
                .accessibilityLabel("Today, show current month")
        }
    }

    private var monthGrid: some View {
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
            .accessibilityValue(monthTitle)
            .accessibilityHint("Swipe up for the next month, swipe down for the previous month")
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    onAdjustMonth(1)
                case .decrement:
                    onAdjustMonth(-1)
                @unknown default:
                    break
                }
            }

            VStack(spacing: 10) {
                ForEach(weeks) { week in
                    weekRow(week)
                }
            }
            .id(String(displayedMonth.key.prefix(7)))
            .transition(monthTransition)
        }
        .contentShape(Rectangle())
        .simultaneousGesture(swipeGesture)
        .accessibilityElement(children: .contain)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                guard let offset = HistoryMonthNavigation.swipeOffset(forTranslation: value.translation) else {
                    return
                }

                onShowMonth(offset)
            }
    }

    private var wheels: some View {
        HStack(spacing: 0) {
            Picker("Month", selection: monthSelection) {
                ForEach(Array(monthsInYear(displayedMonth.year)), id: \.self) { month in
                    Text(monthName(month)).tag(month)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityLabel("Month")
            .accessibilityIdentifier("routine-history-month-wheel")

            Picker("Year", selection: yearSelection) {
                ForEach(Array(wheelYears), id: \.self) { year in
                    Text(verbatim: String(year)).tag(year)
                }
            }
            .pickerStyle(.wheel)
            .accessibilityLabel("Year")
            .accessibilityIdentifier("routine-history-year-wheel")
        }
        .frame(height: 180)
    }

    private var wheelYears: ClosedRange<Int> {
        frozenWheelYears ?? openingWheelYears
    }

    private var openingWheelYears: ClosedRange<Int> {
        min(pickerYears.lowerBound, displayedMonth.year)...pickerYears.upperBound
    }

    private var monthSelection: Binding<Int> {
        Binding(
            get: { displayedMonth.month },
            set: { onSelectMonth(displayedMonth.year, $0) }
        )
    }

    private var yearSelection: Binding<Int> {
        Binding(
            get: { displayedMonth.year },
            set: { onSelectMonth($0, displayedMonth.month) }
        )
    }

    private func monthName(_ month: Int) -> String {
        routineCalendar.calendar.monthSymbols[month - 1]
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
