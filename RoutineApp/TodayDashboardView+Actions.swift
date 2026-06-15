import Foundation
import SwiftData
import SwiftUI
import WidgetKit

extension TodayDashboardView {
    func toggleManagementControls() {
        mode = mode == .managementControls ? .tracking : .managementControls
    }

    func enterRearrangeGroupsMode() {
        clearUndoBanner()
        mode = .rearrangeGroups
    }

    func enterRearrangeRoutinesMode() {
        clearUndoBanner()
        mode = .rearrangeRoutines
    }

    func exitRearrangeMode() {
        mode = .tracking
    }

    func openAddRoutine() {
        guard let initialGroupID = managementViewData.groupChoices.first?.id else {
            presentAlert(.missingGroup)
            return
        }

        sheetPresentation = .routine(.add(initialGroupID: initialGroupID))
    }

    func openAddGroup() {
        sheetPresentation = .group(.add)
    }

    func openSettings() {
        sheetPresentation = .settings
    }

    func openEditRoutine(routineID: UUID) {
        guard let row = managementRow(for: routineID) else {
            presentAlert(.routineNotFound)
            return
        }

        sheetPresentation = .routine(
            .edit(
                RoutineFormSnapshot(
                    row: row,
                    availableGroupIDs: editableGroupIDs
                )
            )
        )
    }

    func openEditGroup(groupID: UUID) {
        guard let section = editableSections.first(where: { $0.id == groupID }) else {
            presentAlert(.groupNotFound)
            return
        }

        sheetPresentation = .group(
            .rename(
                GroupFormSnapshot(
                    groupID: section.id,
                    name: section.name
                )
            )
        )
    }

    func managementRow(for routineID: UUID) -> ManageRoutineRowViewData? {
        managementViewData.sections
            .flatMap(\.routines)
            .first(where: { $0.id == routineID })
    }

    func moveGroups(from source: IndexSet, to destination: Int) {
        guard
            let sourceIndex = source.first,
            let serviceIndex = ManageReorderIndex.serviceIndex(
                from: source,
                destination: destination,
                itemCount: editableSections.count
            ),
            editableSections.indices.contains(sourceIndex)
        else {
            return
        }

        let groupID = editableSections[sourceIndex].id

        do {
            try RoutineManagementService(context: modelContext).moveGroup(
                id: groupID,
                to: serviceIndex
            )
        } catch let error as PersistenceError {
            if case .groupNotFound = error {
                presentAlert(.groupNotFound)
            } else {
                presentAlert(.groupSaveFailure(detail: userSafeAlertDetail(for: error)))
            }
        } catch {
            presentAlert(.groupSaveFailure(detail: userSafeAlertDetail(for: error)))
        }
    }

    func moveRoutines(
        in section: ManageGroupSectionViewData,
        from source: IndexSet,
        to destination: Int
    ) {
        guard
            let sourceIndex = source.first,
            let serviceIndex = ManageReorderIndex.serviceIndex(
                from: source,
                destination: destination,
                itemCount: section.routines.count
            ),
            section.routines.indices.contains(sourceIndex)
        else {
            return
        }

        let routineID = section.routines[sourceIndex].id

        do {
            try RoutineManagementService(context: modelContext).moveRoutine(
                id: routineID,
                toGroupID: section.id,
                at: serviceIndex
            )
        } catch let error as PersistenceError {
            switch error {
            case .routineNotFound:
                presentAlert(.routineNotFound)
            case .groupNotFound:
                presentAlert(.groupNotFound)
            default:
                presentAlert(.routineSaveFailure(detail: userSafeAlertDetail(for: error)))
            }
        } catch {
            presentAlert(.routineSaveFailure(detail: userSafeAlertDetail(for: error)))
        }
    }

    func handlePrimaryTap(for routine: RoutineCardViewData) {
        if routine.isCompletedToday {
            openHistory(for: routine.id)
            return
        }

        do {
            let result = try RoutineTrackingService(
                context: modelContext,
                routineCalendar: routineCalendar
            ).completeToday(
                routineID: routine.id,
                now: runtime.now
            )
            guard result.didInsert else {
                return
            }

            WidgetCenter.shared.reloadAllTimelines()
            RoutineHaptics.signalCompletion()
            showUndoBanner(
                routineID: result.routineID,
                message: "Completed \(result.routineName)"
            )
        } catch {
            presentUpdateError(error)
        }
    }

    func undoCompletion(routineID: UUID) {
        do {
            let result = try RoutineTrackingService(
                context: modelContext,
                routineCalendar: routineCalendar
            ).undoToday(
                routineID: routineID,
                now: runtime.now
            )
            clearUndoBanner()

            guard result.didRemove else {
                return
            }

            WidgetCenter.shared.reloadAllTimelines()
            RoutineHaptics.signalUndo()
        } catch {
            presentUpdateError(error)
        }
    }

    func showUndoBanner(routineID: UUID, message: String) {
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

    func clearUndoBanner() {
        undoDismissTask?.cancel()
        undoDismissTask = nil

        withAnimation(bannerAnimation) {
            undoBanner = nil
        }
    }

    func presentUpdateError(_ error: Error) {
        clearUndoBanner()
        alertPresentation = DashboardAlertPresentation(message: error.localizedDescription)
    }

    func openHistory(for routineID: UUID) {
        path.append(.routineHistory(routineID: routineID))
    }

    func presentAlert(_ alert: ManageAlertPresentation) {
        alertPresentation = DashboardAlertPresentation(alert)
    }

    func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }
}

enum DashboardMode: Equatable {
    case tracking
    case managementControls
    case rearrangeGroups
    case rearrangeRoutines

    var isRearranging: Bool {
        switch self {
        case .rearrangeGroups, .rearrangeRoutines:
            true
        case .tracking, .managementControls:
            false
        }
    }

    var navigationTitle: String? {
        switch self {
        case .rearrangeGroups:
            "Rearrange Groups"
        case .rearrangeRoutines:
            "Rearrange Routines"
        case .tracking, .managementControls:
            nil
        }
    }
}

struct UndoBannerPresentation: Identifiable, Equatable {
    let id = UUID()
    let routineID: UUID
    let viewData: UndoBannerViewData
}

struct DashboardAlertPresentation: Equatable {
    let title: String
    let message: String?

    init(
        title: String = "Routine could not be updated.",
        message: String
    ) {
        self.title = title
        self.message = message
    }

    init(_ alert: ManageAlertPresentation) {
        title = alert.title
        message = alert.message
    }
}
