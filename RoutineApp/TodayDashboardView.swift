import SwiftData
import SwiftUI

struct TodayDashboardView: View {
    @Binding var path: [AppRoute]

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.modelContext) var modelContext
    @Environment(\.routineRuntimeConfiguration) var runtime

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

    @State var mode: DashboardMode = .tracking
    @State var selectedRoutineID: UUID?
    @State var sheetPresentation: ManageSheetPresentation?
    @State var undoBanner: UndoBannerPresentation?
    @State var undoDismissTask: Task<Void, Never>?
    @State var alertPresentation: DashboardAlertPresentation?

    var viewData: TodayDashboardViewData {
        DashboardProjectionBuilder(context: modelContext).build(
            groups: groups,
            routines: routines,
            completions: completions,
            now: runtime.now
        )
    }

    var managementViewData: ManageRoutinesViewData {
        ManageProjectionBuilder(context: modelContext).build(groups: groups, routines: routines)
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

            if mode == .organize {
                organizeContent
            } else {
                trackingContent
            }
        }
        .navigationTitle(viewData.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if mode == .organize {
                    Button("Done") {
                        exitOrganizeMode()
                    }
                    .accessibilityIdentifier("today-dashboard-organize-done-button")
                } else {
                    managementMenu
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
            }
        }
        .safeAreaInset(edge: .bottom) {
            if mode != .organize, let undoBanner {
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
        .onDisappear {
            undoDismissTask?.cancel()
        }
    }
}
