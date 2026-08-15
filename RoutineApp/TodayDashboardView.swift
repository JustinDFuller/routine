import RoutineCore
import SwiftData
import SwiftUI

struct TodayDashboardView: View {
    @Binding var path: [AppRoute]

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.modelContext) var modelContext
    @Environment(\.routineRuntimeConfiguration) var runtime
    @Environment(\.routineCalendar) var routineCalendar
    @Environment(\.behindScheduleRescheduleCoordinator) var behindScheduleRescheduleCoordinator

    @Query(
        sort: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
    )
    var groups: [RoutineGroup]

    @Query(
        sort: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
    )
    var routines: [Routine]

    @Query(
        sort: [
            SortDescriptor(\RoutineCompletion.routineID),
            SortDescriptor(\RoutineCompletion.dayKey),
            SortDescriptor(\RoutineCompletion.completedAt)
        ]
    )
    var completions: [RoutineCompletion]

    @AppStorage(RoutineSettingsKeys.collapseCompletedToday) private var collapseCompletedToday = true
    @AppStorage(RoutineSettingsKeys.collapseGoalMetToday) private var collapseGoalMetToday = true
    @AppStorage(RoutineSettingsKeys.collapseUnavailableToday) private var collapseUnavailableToday = true

    @State var mode: DashboardMode = .tracking
    @State var sheetPresentation: ManageSheetPresentation?
    @State var undoBanner: UndoBannerPresentation?
    @State var undoDismissTask: Task<Void, Never>?
    @State var alertPresentation: DashboardAlertPresentation?
    @State var expandedCollapsedRoutineIDs: Set<UUID> = []

    var collapsesCompleted: Bool { collapseCompletedToday && mode == .tracking }
    var collapsesGoalMet: Bool { collapseGoalMetToday && mode == .tracking }
    var collapsesUnavailable: Bool { collapseUnavailableToday && mode == .tracking }

    var viewData: TodayDashboardViewData {
        DashboardProjectionBuilder(context: modelContext, routineCalendar: routineCalendar).build(
            groups: groups,
            routines: routines,
            completions: completions,
            now: runtime.now
        )
    }

    var managementViewData: ManageRoutinesViewData {
        ManageProjectionBuilder(context: modelContext, routineCalendar: routineCalendar).build(
            groups: groups,
            routines: routines
        )
    }

    var editableGroupIDs: Set<UUID> {
        Set(managementViewData.groupChoices.map(\.id))
    }

    var editableSections: [ManageGroupSectionViewData] {
        managementViewData.sections.filter { editableGroupIDs.contains($0.id) }
    }

    var fallbackSections: [ManageGroupSectionViewData] {
        managementViewData.sections.filter { editableGroupIDs.contains($0.id) == false }
    }

    var hasRealGroups: Bool {
        managementViewData.groupChoices.isEmpty == false
    }

    var bannerTransition: AnyTransition {
        if animationsAreDisabled {
            return .opacity
        }

        return .move(edge: .bottom).combined(with: .opacity)
    }

    var bannerAnimation: Animation? {
        animationsAreDisabled ? nil : .easeInOut(duration: 0.2)
    }

    var animationsAreDisabled: Bool {
        reduceMotion || runtime.disablesAnimations
    }

    var body: some View {
        ZStack {
            Color.routineCanvas
                .ignoresSafeArea()

            if mode.isRearranging {
                rearrangeContent
            } else {
                trackingContent
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar(mode.isRearranging ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if mode.isRearranging {
                    Button("Done") {
                        exitRearrangeMode()
                    }
                    .accessibilityIdentifier("today-dashboard-rearrange-done-button")
                }
            }
        }
        .sheet(item: $sheetPresentation) { presentation in
            switch presentation {
            case .routine(let routinePresentation):
                AddEditRoutineView(
                    presentation: routinePresentation,
                    groupChoices: managementViewData.groupChoices
                )
            case .group(let groupPresentation):
                AddEditGroupView(
                    presentation: groupPresentation,
                    existingNames: managementViewData.groupChoices.map(\.name)
                )
            case .settings:
                SettingsView()
            }
        }
        .safeAreaInset(edge: .bottom) {
            if mode.isRearranging == false, let undoBanner {
                UndoBannerView(viewData: undoBanner.viewData) {
                    undoCompletion(routineID: undoBanner.routineID)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .transition(bannerTransition)
            }
        }
        .alert(
            alertPresentation?.title ?? "",
            isPresented: alertIsPresented,
            presenting: alertPresentation
        ) { _ in
            Button("OK", role: .cancel) {
                alertPresentation = nil
            }
        } message: { alert in
            if let message = alert.message {
                Text(message)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today-dashboard-root")
        .task {
            handlePendingWidgetCompletion()
        }
        .onDisappear {
            undoDismissTask?.cancel()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                handlePendingWidgetCompletion()
            }
        }
    }

    var navigationTitle: String {
        mode.navigationTitle ?? viewData.title
    }
}
