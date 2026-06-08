import SwiftData
import SwiftUI

struct TodayDashboardView: View {
    @Binding var path: [AppRoute]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
    )
    private var groups: [RoutineGroup]

    @Query(
        sort: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
    )
    private var routines: [Routine]

    @Query(
        sort: [
            SortDescriptor(\RoutineCompletion.routineID),
            SortDescriptor(\RoutineCompletion.dayKey),
            SortDescriptor(\RoutineCompletion.completedAt)
        ]
    )
    private var completions: [RoutineCompletion]

    @State private var selectedCard: SelectedRoutineCard?
    @State private var undoBanner: UndoBannerPresentation?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var errorAlert: DashboardErrorAlert?

    private var viewData: TodayDashboardViewData {
        DashboardProjectionBuilder(context: modelContext).build(
            groups: groups,
            routines: routines,
            completions: completions
        )
    }

    private var bannerTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .move(edge: .bottom).combined(with: .opacity)
    }

    private var bannerAnimation: Animation? {
        reduceMotion ? nil : .easeInOut(duration: 0.2)
    }

    var body: some View {
        ZStack {
            Color.routineCanvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(viewData.dateLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.routineLabelSecondary)

                    if viewData.isEmpty {
                        emptyState
                    } else {
                        sectionsContent
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle(viewData.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Manage") {
                    path.append(.manageRoutines(editingRoutineID: nil))
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let undoBanner {
                UndoBannerView(viewData: undoBanner.viewData) {
                    undoCompletion(routineID: undoBanner.routineID)
                }
                .accessibilityIdentifier("today-dashboard-undo-banner")
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(bannerTransition)
            }
        }
        .confirmationDialog(
            selectedCard?.name ?? "Routine Actions",
            isPresented: selectedCardIsPresented,
            titleVisibility: .visible,
            presenting: selectedCard
        ) { selectedCard in
            Button("View History") {
                self.selectedCard = nil
                path.append(.routineHistory(routineID: selectedCard.id))
            }

            Button("Edit Routine") {
                self.selectedCard = nil
                path.append(.manageRoutines(editingRoutineID: selectedCard.id))
            }

            if selectedCard.isCompletedToday {
                Button("Undo Today's Completion") {
                    self.selectedCard = nil
                    undoCompletion(routineID: selectedCard.id)
                }
            }

            Button("Cancel", role: .cancel) {
                self.selectedCard = nil
            }
        }
        .alert(
            errorAlert?.title ?? "Routine could not be updated.",
            isPresented: errorAlertIsPresented,
            presenting: errorAlert
        ) { _ in
            Button("OK", role: .cancel) {
                errorAlert = nil
            }
        } message: { errorAlert in
            Text(errorAlert.message)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-dashboard-root")
        .onDisappear {
            undoDismissTask?.cancel()
        }
    }

    private var sectionsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewData.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.routineLabelSecondary)

                    VStack(spacing: 12) {
                        ForEach(section.routines) { routine in
                            RoutineCardView(
                                viewData: routine,
                                onTap: {
                                    handlePrimaryTap(for: routine)
                                },
                                onMore: {
                                    selectedCard = SelectedRoutineCard(from: routine)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No routines yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text("Add your first routine to start tracking")
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)

            Button("Manage") {
                path.append(.manageRoutines(editingRoutineID: nil))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.routineAccentActive)
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .center)
        .accessibilityIdentifier("today-dashboard-empty-state")
    }

    private var selectedCardIsPresented: Binding<Bool> {
        Binding(
            get: { selectedCard != nil },
            set: { isPresented in
                if isPresented == false {
                    selectedCard = nil
                }
            }
        )
    }

    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { errorAlert != nil },
            set: { isPresented in
                if isPresented == false {
                    errorAlert = nil
                }
            }
        )
    }

    private func handlePrimaryTap(for routine: RoutineCardViewData) {
        if routine.isCompletedToday {
            selectedCard = SelectedRoutineCard(from: routine)
            return
        }

        do {
            let result = try RoutineTrackingService(context: modelContext).completeToday(routineID: routine.id)
            guard result.didInsert else {
                return
            }

            showUndoBanner(
                routineID: result.routineID,
                message: "Completed \(result.routineName)"
            )
        } catch {
            presentUpdateError(error)
        }
    }

    private func undoCompletion(routineID: UUID) {
        do {
            let result = try RoutineTrackingService(context: modelContext).undoToday(routineID: routineID)
            clearUndoBanner()

            guard result.didRemove else {
                return
            }
        } catch {
            presentUpdateError(error)
        }
    }

    private func showUndoBanner(routineID: UUID, message: String) {
        undoDismissTask?.cancel()

        let presentation = UndoBannerPresentation(
            routineID: routineID,
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

    private func presentUpdateError(_ error: Error) {
        clearUndoBanner()
        errorAlert = DashboardErrorAlert(message: error.localizedDescription)
    }
}

private struct SelectedRoutineCard: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isCompletedToday: Bool

    init(from viewData: RoutineCardViewData) {
        id = viewData.id
        name = viewData.name
        isCompletedToday = viewData.isCompletedToday
    }
}

private struct UndoBannerPresentation: Identifiable, Equatable {
    let id = UUID()
    let routineID: UUID
    let viewData: UndoBannerViewData
}

private struct DashboardErrorAlert: Equatable {
    let title: String
    let message: String

    init(
        title: String = "Routine could not be updated.",
        message: String
    ) {
        self.title = title
        self.message = message
    }
}

struct RoutineHistoryPlaceholderView: View {
    let routineID: UUID

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Routine history is coming in a later milestone.")
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)

            Text(routineID.uuidString)
                .font(.footnote.monospaced())
                .foregroundStyle(Color.routineLabelSecondary)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
        .background(Color.routineCanvas.ignoresSafeArea())
        .navigationTitle("History")
    }
}
