import SwiftData
import SwiftUI

struct TodayDashboardView: View {
    @Binding var path: [AppRoute]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineRuntimeConfiguration) private var runtime

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

    @State private var selectedRoutineID: UUID?
    @State private var undoBanner: UndoBannerPresentation?
    @State private var undoDismissTask: Task<Void, Never>?
    @State private var errorAlert: DashboardErrorAlert?

    private var viewData: TodayDashboardViewData {
        DashboardProjectionBuilder(context: modelContext).build(
            groups: groups,
            routines: routines,
            completions: completions,
            now: runtime.now
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
                .accessibilityHint("Opens routine management.")
                .accessibilityIdentifier("today-dashboard-manage-button")
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let undoBanner {
                UndoBannerView(viewData: undoBanner.viewData) {
                    undoCompletion(routineID: undoBanner.routineID)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(bannerTransition)
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
                                    selectedRoutineID = routine.id
                                }
                            )
                            .confirmationDialog(
                                routine.name,
                                isPresented: actionDialogIsPresented(for: routine.id),
                                titleVisibility: .visible
                            ) {
                                Button("View History") {
                                    selectedRoutineID = nil
                                    path.append(.routineHistory(routineID: routine.id))
                                }

                                Button("Edit Routine") {
                                    selectedRoutineID = nil
                                    path.append(.manageRoutines(editingRoutineID: routine.id))
                                }

                                if routine.isCompletedToday {
                                    Button("Undo Today's Completion") {
                                        selectedRoutineID = nil
                                        undoCompletion(routineID: routine.id)
                                    }
                                }

                                Button("Cancel", role: .cancel) {
                                    selectedRoutineID = nil
                                }
                            }
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
            .accessibilityHint("Opens routine management.")
            .accessibilityIdentifier("today-dashboard-empty-manage-button")
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .center)
    }

    private func actionDialogIsPresented(for routineID: UUID) -> Binding<Bool> {
        Binding(
            get: { selectedRoutineID == routineID },
            set: { isPresented in
                if isPresented == false {
                    if selectedRoutineID == routineID {
                        selectedRoutineID = nil
                    }
                } else {
                    selectedRoutineID = routineID
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
            selectedRoutineID = routine.id
            return
        }

        do {
            let result = try RoutineTrackingService(context: modelContext).completeToday(
                routineID: routine.id,
                now: runtime.now
            )
            guard result.didInsert else {
                return
            }

            RoutineHaptics.signalCompletion()
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
            let result = try RoutineTrackingService(context: modelContext).undoToday(
                routineID: routineID,
                now: runtime.now
            )
            clearUndoBanner()

            guard result.didRemove else {
                return
            }

            RoutineHaptics.signalUndo()
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
