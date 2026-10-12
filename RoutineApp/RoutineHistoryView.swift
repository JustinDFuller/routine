import Foundation
import RoutineCore
import SwiftData
import SwiftUI
import WidgetKit

struct RoutineHistoryView: View {
    let routineID: UUID

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineRuntimeConfiguration) private var runtime
    @Environment(\.routineCalendar) private var routineCalendar
    @Environment(\.behindScheduleRescheduleCoordinator) private var behindScheduleRescheduleCoordinator
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Query private var routines: [Routine]
    @Query private var completions: [RoutineCompletion]

    @State private var pendingRemoval: CompletionListItem?
    @State private var removalAlert: HistoryRemovalAlert?
    @State private var pendingDay: HistoryCalendarDay?
    @State private var undoBanner: HistoryUndoPresentation?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var selectedMonth: RoutineDay?
    @State private var isPickerOpen = false
    @State private var slideEdge: Edge = .trailing

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

    private var today: RoutineDay {
        routineCalendar.today(now: runtime.now)
    }

    private var displayedMonth: RoutineDay {
        selectedMonth ?? today
    }

    private var monthNavigation: HistoryMonthNavigation {
        HistoryMonthNavigation(routineCalendar: routineCalendar, today: today)
    }

    private var projection: RoutineHistoryProjection {
        HistoryProjectionBuilder(context: modelContext, routineCalendar: routineCalendar).build(
            routineID: routineID,
            routines: routines,
            completions: completions,
            displayedMonth: displayedMonth,
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

    private func pendingPopoverIsPresented(for dayID: String) -> Binding<Bool> {
        Binding(
            get: { pendingDay?.id == dayID },
            set: { isPresented in
                if isPresented == false, pendingDay?.id == dayID {
                    pendingDay = nil
                }
            }
        )
    }

    private var bannerTransition: AnyTransition {
        if animationsAreDisabled {
            return .opacity
        }

        return .move(edge: .bottom).combined(with: .opacity)
    }

    private var bannerAnimation: Animation? {
        animationsAreDisabled ? nil : .easeInOut(duration: 0.2)
    }

    private var animationsAreDisabled: Bool {
        reduceMotion || runtime.disablesAnimations
    }

    var body: some View {
        ZStack {
            Color.routineCanvas
                .ignoresSafeArea()

            content
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            if let undoBanner {
                UndoBannerView(viewData: undoBanner.viewData) {
                    undoPendingBanner()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(bannerTransition)
                .accessibilityIdentifier("routine-history-undo-banner")
            }
        }
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
        .onDisappear {
            undoDismissTask?.cancel()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch projection {
        case .found(let viewData):
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    summaryHeader(viewData)
                    HistoryMonthGridView(
                        weeks: viewData.weeks,
                        displayedMonth: displayedMonth,
                        routineCalendar: routineCalendar,
                        isDisplayingCurrentMonth: viewData.isDisplayingCurrentMonth,
                        pickerYears: viewData.pickerYears,
                        monthsInYear: monthNavigation.availableMonths(inYear:),
                        isPickerOpen: isPickerOpen,
                        slideEdge: slideEdge,
                        usesCrossFade: animationsAreDisabled,
                        onTogglePicker: togglePicker,
                        onShowMonth: { showMonth(offset: $0) },
                        onAdjustMonth: adjustMonth,
                        onSelectMonth: { showMonth(year: $0, month: $1) },
                        onShowToday: showToday,
                        onTapDay: tapDay,
                        popoverIsPresented: pendingPopoverIsPresented,
                        onConfirmDay: confirmPendingDay
                    )
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

    private func streakDisplayText(for viewData: RoutineHistoryViewData) -> String {
        viewData.streakSummaryText ?? "No streak yet"
    }

    private func streakAccessibilityDisplayText(for viewData: RoutineHistoryViewData) -> String {
        viewData.streakAccessibilityText ?? "No streak yet"
    }

    private func summaryAccessibilityLabel(for viewData: RoutineHistoryViewData) -> String {
        [
            viewData.routineName,
            viewData.frequencySummary,
            currentPeriodProgressText(for: viewData.progress),
            lastDoneDisplayText(for: viewData.lastDoneText),
            streakAccessibilityDisplayText(for: viewData)
        ].joined(separator: ", ")
    }

    private func confirmRemoval(_ item: CompletionListItem) {
        pendingRemoval = nil

        do {
            try RoutineTrackingService(context: modelContext, routineCalendar: routineCalendar)
                .removeCompletion(completionID: item.id)
            Task {
                await rescheduleBehindScheduleAlerts(
                    coordinator: behindScheduleRescheduleCoordinator,
                    context: modelContext,
                    calendar: routineCalendar,
                    now: runtime.now,
                    logLabel: "historyRescheduleFailed"
                )
            }
        } catch {
            removalAlert = HistoryRemovalAlert(message: error.localizedDescription)
        }
    }

    private var monthAnimation: Animation? {
        runtime.disablesAnimations ? nil : .easeInOut(duration: 0.25)
    }

    private func togglePicker() {
        pendingDay = nil
        isPickerOpen.toggle()
    }

    private func showMonth(offset: Int) {
        let target = monthNavigation.selection(from: displayedMonth, offset: offset)
        moveToMonth(target, edge: offset < 0 ? .leading : .trailing)
    }

    private func showMonth(year: Int, month: Int) {
        let target = monthNavigation.selection(year: year, month: month)
        let edge: Edge = (target ?? today) < displayedMonth ? .leading : .trailing
        moveToMonth(target, edge: edge)
    }

    private func showToday() {
        moveToMonth(nil, edge: .trailing, closesPicker: true)
    }

    private func adjustMonth(offset: Int) {
        let target = monthNavigation.selection(from: displayedMonth, offset: offset)
        moveToMonth(target, edge: offset < 0 ? .leading : .trailing)

        AccessibilityNotification.Announcement(routineCalendar.historyMonthTitle(for: target ?? today)).post()
    }

    private func moveToMonth(_ target: RoutineDay?, edge: Edge, closesPicker: Bool = false) {
        let resolvedTarget = target ?? today
        let changesMonth = monthNavigation.isSameMonth(resolvedTarget, displayedMonth) == false

        guard changesMonth || (closesPicker && isPickerOpen) else {
            return
        }

        pendingDay = nil
        slideEdge = edge

        withAnimation(isPickerOpen && closesPicker == false ? nil : monthAnimation) {
            selectedMonth = target
            if closesPicker {
                isPickerOpen = false
            }
        }
    }

    private func tapDay(_ day: HistoryCalendarDay) {
        guard day.isFuture == false else {
            return
        }

        pendingDay = day
    }

    private func confirmPendingDay() {
        guard let day = pendingDay else {
            return
        }

        pendingDay = nil
        let dateText = routineCalendar.explicitDateLabel(for: day.day)
        let service = RoutineTrackingService(context: modelContext, routineCalendar: routineCalendar)

        do {
            if day.isCompleted {
                let result = try service.removeCompletion(routineID: routineID, day: day.day)
                guard result.didRemove else {
                    return
                }

                Task {
                    await rescheduleBehindScheduleAlerts(
                        coordinator: behindScheduleRescheduleCoordinator,
                        context: modelContext,
                        calendar: routineCalendar,
                        now: runtime.now,
                        logLabel: "historyRescheduleFailed"
                    )
                }

                WidgetCenter.shared.reloadAllTimelines()
                RoutineHaptics.signalUndo()
                showUndoBanner(day: day.day, action: .removed, message: "Removed \(dateText)")
            } else {
                let result = try service.complete(routineID: routineID, day: day.day, now: runtime.now)
                guard result.didInsert else {
                    return
                }

                Task {
                    await rescheduleBehindScheduleAlerts(
                        coordinator: behindScheduleRescheduleCoordinator,
                        context: modelContext,
                        calendar: routineCalendar,
                        now: runtime.now,
                        logLabel: "historyRescheduleFailed"
                    )
                }

                WidgetCenter.shared.reloadAllTimelines()
                RoutineHaptics.signalCompletion()
                showUndoBanner(day: day.day, action: .completed, message: "Completed \(dateText)")
            }
        } catch {
            removalAlert = HistoryRemovalAlert(message: error.localizedDescription)
        }
    }

    private func undoPendingBanner() {
        guard let presentation = undoBanner else {
            return
        }

        let service = RoutineTrackingService(context: modelContext, routineCalendar: routineCalendar)

        do {
            switch presentation.action {
            case .completed:
                let result = try service.removeCompletion(routineID: routineID, day: presentation.day)
                clearUndoBanner()
                guard result.didRemove else {
                    return
                }

                Task {
                    await rescheduleBehindScheduleAlerts(
                        coordinator: behindScheduleRescheduleCoordinator,
                        context: modelContext,
                        calendar: routineCalendar,
                        now: runtime.now,
                        logLabel: "historyRescheduleFailed"
                    )
                }

                WidgetCenter.shared.reloadAllTimelines()
                RoutineHaptics.signalUndo()
            case .removed:
                let result = try service.complete(routineID: routineID, day: presentation.day, now: runtime.now)
                clearUndoBanner()
                guard result.didInsert else {
                    return
                }

                Task {
                    await rescheduleBehindScheduleAlerts(
                        coordinator: behindScheduleRescheduleCoordinator,
                        context: modelContext,
                        calendar: routineCalendar,
                        now: runtime.now,
                        logLabel: "historyRescheduleFailed"
                    )
                }

                WidgetCenter.shared.reloadAllTimelines()
                RoutineHaptics.signalCompletion()
            }
        } catch {
            clearUndoBanner()
            removalAlert = HistoryRemovalAlert(message: error.localizedDescription)
        }
    }

    private func showUndoBanner(day: RoutineDay, action: HistoryDayAction, message: String) {
        undoDismissTask?.cancel()

        let presentation = HistoryUndoPresentation(
            day: day,
            action: action,
            viewData: UndoBannerViewData(message: message)
        )

        withAnimation(bannerAnimation) {
            undoBanner = presentation
        }

        let token = presentation.id
        undoDismissTask = Task {
            try? await Task.sleep(nanoseconds: 5_000_000_000)

            guard Task.isCancelled == false else {
                return
            }

            await MainActor.run {
                guard undoBanner?.id == token else {
                    return
                }

                clearUndoBanner()
            }
        }
    }

    private func clearUndoBanner() {
        undoDismissTask?.cancel()
        undoDismissTask = nil

        withAnimation(bannerAnimation) {
            undoBanner = nil
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

            Text(streakDisplayText(for: viewData))
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

private enum HistoryDayAction: Equatable {
    case completed
    case removed
}

private struct HistoryUndoPresentation: Identifiable, Equatable {
    let id = UUID()
    let day: RoutineDay
    let action: HistoryDayAction
    let viewData: UndoBannerViewData
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
