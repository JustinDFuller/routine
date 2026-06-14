import Foundation
import RoutineCore
import SwiftData
import SwiftUI

struct RoutineHistoryView: View {
    let routineID: UUID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineRuntimeConfiguration) private var runtime
    @Environment(\.routineCalendar) private var routineCalendar

    @Query private var routines: [Routine]
    @Query private var completions: [RoutineCompletion]

    @State private var pendingRemoval: CompletionListItem?
    @State private var removalAlert: HistoryRemovalAlert?

    init(routineID: UUID) {
        self.routineID = routineID

        _routines = Query(
            filter: #Predicate<Routine> { routine in
                routine.id == routineID
            }
        )

        _completions = Query(
            filter: #Predicate<RoutineCompletion> { completion in
                completion.routineID == routineID
            },
            sort: [
                SortDescriptor(\RoutineCompletion.dayKey, order: .reverse),
                SortDescriptor(\RoutineCompletion.completedAt, order: .reverse)
            ]
        )
    }

    private var projection: RoutineHistoryProjection {
        HistoryProjectionBuilder(context: modelContext, routineCalendar: routineCalendar).build(
            routineID: routineID,
            routines: routines,
            completions: completions,
            now: runtime.now
        )
    }

    private func pendingRemovalIsPresented(for completionID: UUID) -> Binding<Bool> {
        Binding(
            get: { pendingRemoval?.id == completionID },
            set: { isPresented in
                if isPresented == false, pendingRemoval?.id == completionID {
                    pendingRemoval = nil
                }
            }
        )
    }

    private var removalAlertIsPresented: Binding<Bool> {
        Binding(
            get: { removalAlert != nil },
            set: { isPresented in
                if isPresented == false {
                    removalAlert = nil
                }
            }
        )
    }

    var body: some View {
        ZStack {
            Color.routineCanvas
                .ignoresSafeArea()

            content
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            removalAlert?.title ?? "Could not remove completion.",
            isPresented: removalAlertIsPresented,
            presenting: removalAlert
        ) { _ in
            Button("OK", role: .cancel) {
                removalAlert = nil
            }
        } message: { alert in
            Text(alert.message)
        }
        .accessibilityIdentifier("routine-history-root")
    }

    @ViewBuilder
    private var content: some View {
        switch projection {
        case .found(let viewData):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryHeader(viewData)
                    HistoryMonthGridView(monthDays: viewData.monthDays, routineCalendar: routineCalendar)
                    recentCompletionsSection(viewData)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        case .notFound:
            notFoundState
        }
    }

    private func summaryHeader(_ viewData: RoutineHistoryViewData) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    summaryRing(for: viewData)
                    summaryText(for: viewData)
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .center, spacing: 16) {
                        summaryRing(for: viewData)
                        summaryText(for: viewData)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        summaryRing(for: viewData)
                        summaryText(for: viewData)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.routineSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.5), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("routine-history-summary")
    }

    private func recentCompletionsSection(_ viewData: RoutineHistoryViewData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent completions")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            if viewData.recentCompletions.isEmpty {
                Text("No recent completions")
                    .font(.body)
                    .foregroundStyle(Color.routineLabelSecondary)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("routine-history-empty-recent-completions")
            } else {
                VStack(spacing: 12) {
                    ForEach(viewData.recentCompletions) { item in
                        CompletionListRow(item: item) {
                            pendingRemoval = item
                        }
                        .confirmationDialog(
                            "Remove completion?",
                            isPresented: pendingRemovalIsPresented(for: item.id),
                            titleVisibility: .visible
                        ) {
                            Button("Remove Completion", role: .destructive) {
                                confirmRemoval(item)
                            }

                            Button("Cancel", role: .cancel) {
                                pendingRemoval = nil
                            }
                        } message: {
                            Text(item.dateText)
                        }
                    }
                }
            }
        }
        .accessibilityIdentifier("routine-history-recent-list")
    }

    private var notFoundState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Routine not found")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text("This routine may have been deleted.")
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)

            Button("Back") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.routineAccentActive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(24)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("routine-history-not-found")
    }

    private func currentPeriodProgressText(for progress: RoutineProgress) -> String {
        let periodText =
            switch progress.period {
            case .weekly:
                "this week"
            case .monthly:
                "this month"
            }

        return "\(progress.completedCount)/\(progress.targetCount) \(periodText)"
    }

    private func lastDoneDisplayText(for lastDoneText: String) -> String {
        switch lastDoneText {
        case "Never":
            "No completions yet"
        case "Today":
            "Done today"
        case "Yesterday":
            "Last done yesterday"
        default:
            "Last done \(lastDoneText)"
        }
    }

    private func summaryAccessibilityLabel(for viewData: RoutineHistoryViewData) -> String {
        [
            viewData.routineName,
            viewData.frequencySummary,
            currentPeriodProgressText(for: viewData.progress),
            lastDoneDisplayText(for: viewData.lastDoneText)
        ].joined(separator: ", ")
    }

    private func confirmRemoval(_ item: CompletionListItem) {
        pendingRemoval = nil

        do {
            try RoutineTrackingService(context: modelContext, routineCalendar: routineCalendar)
                .removeCompletion(completionID: item.id)
        } catch {
            removalAlert = HistoryRemovalAlert(message: error.localizedDescription)
        }
    }

    private func summaryRing(for viewData: RoutineHistoryViewData) -> some View {
        ProgressRingView(
            viewData: ProgressRingViewData(
                targetCount: viewData.progress.targetCount,
                completedCount: viewData.progress.completedCount,
                fillRatio: viewData.progress.fillRatio,
                showsTodayCheckmark: viewData.progress.isCompletedToday
            ),
            size: 72,
            lineWidth: 7,
            accentColor: viewData.progress.isCompletedToday || viewData.progress.isTargetMet
                ? .routineAccentComplete
                : .routineAccentActive,
            accessibilityLabel: summaryAccessibilityLabel(for: viewData)
        )
        .accessibilityHidden(true)
    }

    private func summaryText(for viewData: RoutineHistoryViewData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewData.routineName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text(viewData.frequencySummary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.routineLabelSecondary)

            Text(currentPeriodProgressText(for: viewData.progress))
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text(lastDoneDisplayText(for: viewData.lastDoneText))
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct HistoryMonthGridView: View {
    let monthDays: [HistoryCalendarDay]
    let routineCalendar: RoutineCalendar

    private var monthTitle: String {
        guard let firstDay = monthDays.first else {
            return "This month"
        }

        let formatter = DateFormatter()
        formatter.calendar = routineCalendar.calendar
        formatter.timeZone = routineCalendar.calendar.timeZone
        formatter.locale = routineCalendar.calendar.locale ?? Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date(for: firstDay.day))
    }

    private var leadingPlaceholderCount: Int {
        guard let firstDay = monthDays.first else {
            return 0
        }

        return routineCalendar.weekdayOffset(for: firstDay.day)
    }

    private var weekdaySymbols: [String] {
        routineCalendar.orderedWeekdaySymbols
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(monthTitle)
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.routineLabelSecondary)
                        .frame(maxWidth: .infinity)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityIdentifier("routine-history-weekday-header")
                .accessibilityLabel(weekdaySymbols.joined(separator: " "))

                ForEach(0..<leadingPlaceholderCount, id: \.self) { _ in
                    Color.clear
                        .frame(height: 36)
                        .accessibilityHidden(true)
                }

                ForEach(monthDays) { day in
                    dayCell(day)
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

    private func dayCell(_ day: HistoryCalendarDay) -> some View {
        ZStack {
            Circle()
                .fill(day.isCompleted ? Color.routineAccentComplete.opacity(0.22) : .clear)

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
        .accessibilityLabel(accessibilityLabel(for: day))
    }

    private func accessibilityLabel(for day: HistoryCalendarDay) -> String {
        let dateText = explicitDateLabel(for: day.day)
        let todayText = day.isToday ? "today" : "not today"
        let completionText = day.isCompleted ? "completed" : "not completed"
        return "\(dateText), \(todayText), \(completionText)"
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

private struct CompletionListRow: View {
    let item: CompletionListItem
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.dateText)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.routineLabelPrimary)

                if let relativeText = item.relativeText {
                    Text(relativeText)
                        .font(.caption)
                        .foregroundStyle(Color.routineLabelSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint("Shows when this completion was recorded.")

            Spacer(minLength: 12)

            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "trash")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(Color.routineAccentDestructive)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityIdentifier("history-remove-completion-\(item.id.uuidString)")
            .accessibilityLabel("Remove completion on \(item.dateText)")
            .accessibilityHint("Removes this completion after confirmation.")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.routineSurfaceElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.5), lineWidth: 1)
        )
    }

    private var accessibilityLabel: String {
        if let relativeText = item.relativeText {
            return "\(item.dateText), \(relativeText)"
        }

        return item.dateText
    }
}

private struct HistoryRemovalAlert: Equatable {
    let title: String
    let message: String

    init(
        title: String = "Could not remove completion.",
        message: String
    ) {
        self.title = title
        self.message = message
    }
}
