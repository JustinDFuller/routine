import RoutineCore
import SwiftData
import SwiftUI

struct ManageRoutinesView: View {
    let initialEditRoutineID: UUID?

    @Environment(\.modelContext) private var modelContext

    @Query(
        sort: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
    )
    private var groups: [RoutineGroup]

    @Query(
        sort: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
    )
    private var routines: [Routine]

    @State private var sheetPresentation: ManageSheetPresentation?
    @State private var pendingRoutineDeletion: ManageRoutineRowViewData?
    @State private var pendingGroupDeletion: PendingGroupDeletion?
    @State private var alertPresentation: ManageAlertPresentation?
    @State private var didHandleInitialEditTarget = false

    private var viewData: ManageRoutinesViewData {
        ManageProjectionBuilder(context: modelContext).build(groups: groups, routines: routines)
    }

    private var allRows: [ManageRoutineRowViewData] {
        viewData.sections.flatMap(\.routines)
    }

    private var realGroupIDs: Set<UUID> {
        Set(viewData.groupChoices.map(\.id))
    }

    private var realSections: [ManageGroupSectionViewData] {
        viewData.sections.filter { realGroupIDs.contains($0.id) }
    }

    private var fallbackSections: [ManageGroupSectionViewData] {
        viewData.sections.filter { realGroupIDs.contains($0.id) == false }
    }

    var body: some View {
        Group {
            if viewData.sections.isEmpty {
                emptyState
            } else {
                routinesList
            }
        }
        .background(Color.routineCanvas.ignoresSafeArea())
        .navigationTitle("Manage Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Add Routine") {
                        openAddRoutine()
                    }
                    .disabled(viewData.groupChoices.isEmpty)

                    Button("Add Group") {
                        openAddGroup()
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add")
                .accessibilityIdentifier("manage-routines-add-button")
            }
        }
        .sheet(item: $sheetPresentation) { presentation in
            switch presentation {
            case .routine(let routinePresentation):
                AddEditRoutineView(
                    presentation: routinePresentation,
                    groupChoices: viewData.groupChoices
                )
            case .group(let groupPresentation):
                AddEditGroupView(
                    presentation: groupPresentation,
                    existingNames: viewData.groupChoices.map(\.name)
                )
            }
        }
        .task {
            handleInitialEditTargetIfNeeded()
        }
        .confirmationDialog(
            pendingRoutineDeletion?.name ?? "Delete Routine",
            isPresented: pendingRoutineDeletionIsPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Routine", role: .destructive) {
                guard let row = pendingRoutineDeletion else {
                    return
                }

                deleteRoutine(row)
            }

            Button("Cancel", role: .cancel) {
                pendingRoutineDeletion = nil
            }
        } message: {
            Text("This deletes the routine and its completion history.")
        }
        .confirmationDialog(
            pendingGroupDeletion?.name ?? "Delete Group",
            isPresented: pendingGroupDeletionIsPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Group", role: .destructive) {
                guard let group = pendingGroupDeletion else {
                    return
                }

                deleteGroup(group)
            }

            Button("Cancel", role: .cancel) {
                pendingGroupDeletion = nil
            }
        } message: {
            Text("This deletes the group.")
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
        .accessibilityIdentifier("manage-routines-root")
    }
}

extension ManageRoutinesView {
    private var routinesList: some View {
        List {
            ForEach(realSections) { section in
                manageableGroupSection(section)
            }
            .onMove(perform: moveGroups)

            ForEach(fallbackSections) { section in
                fallbackSection(section)
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tint(Color.routineAccentActive)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No groups yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text("Add a group to start organizing your routines.")
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)

            Button("Add Group") {
                openAddGroup()
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.routineAccentActive)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }

    private var pendingRoutineDeletionIsPresented: Binding<Bool> {
        Binding(
            get: { pendingRoutineDeletion != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingRoutineDeletion = nil
                }
            }
        )
    }

    private var pendingGroupDeletionIsPresented: Binding<Bool> {
        Binding(
            get: { pendingGroupDeletion != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingGroupDeletion = nil
                }
            }
        )
    }

    private var alertIsPresented: Binding<Bool> {
        Binding(
            get: { alertPresentation != nil },
            set: { isPresented in
                if isPresented == false {
                    alertPresentation = nil
                }
            }
        )
    }

    private func openAddRoutine() {
        guard viewData.groupChoices.isEmpty == false else {
            alertPresentation = .missingGroup
            return
        }

        sheetPresentation = .routine(.add(initialGroupID: viewData.groupChoices.first?.id))
    }

    private func openAddGroup() {
        sheetPresentation = .group(.add)
    }

    private func openEditRoutine(_ row: ManageRoutineRowViewData) {
        sheetPresentation = .routine(
            .edit(
                RoutineFormSnapshot(
                    row: row,
                    availableGroupIDs: Set(viewData.groupChoices.map(\.id))
                )
            )
        )
    }

    private func openRenameGroup(_ section: ManageGroupSectionViewData) {
        sheetPresentation = .group(
            .rename(
                GroupFormSnapshot(
                    groupID: section.id,
                    name: section.name
                )
            )
        )
    }

    private func handleInitialEditTargetIfNeeded() {
        guard didHandleInitialEditTarget == false else {
            return
        }

        didHandleInitialEditTarget = true

        guard let initialEditRoutineID else {
            return
        }

        guard let row = allRows.first(where: { $0.id == initialEditRoutineID }) else {
            alertPresentation = .routineNotFound
            return
        }

        openEditRoutine(row)
    }

    private func deleteRoutine(_ row: ManageRoutineRowViewData) {
        pendingRoutineDeletion = nil

        do {
            try RoutineManagementService(context: modelContext).deleteRoutine(id: row.id)
        } catch let error as PersistenceError {
            if case .routineNotFound = error {
                alertPresentation = .routineNotFound
            } else {
                alertPresentation = .routineDeleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .routineDeleteFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func deleteGroup(_ group: PendingGroupDeletion) {
        pendingGroupDeletion = nil

        do {
            try RoutineManagementService(context: modelContext).deleteGroup(id: group.id)
        } catch let error as RoutineManagementError {
            if case .nonEmptyGroup = error {
                alertPresentation = .nonEmptyGroupBlocked
            } else {
                alertPresentation = .groupDeleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch let error as PersistenceError {
            if case .groupNotFound = error {
                alertPresentation = .groupNotFound
            } else {
                alertPresentation = .groupDeleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .groupDeleteFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first, realSections.indices.contains(sourceIndex) else {
            return
        }

        let groupID = realSections[sourceIndex].id

        do {
            try RoutineManagementService(context: modelContext).moveGroup(id: groupID, to: destination)
        } catch let error as PersistenceError {
            if case .groupNotFound = error {
                alertPresentation = .groupNotFound
            } else {
                alertPresentation = .groupSaveFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .groupSaveFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func moveRoutines(
        in section: ManageGroupSectionViewData,
        from source: IndexSet,
        to destination: Int
    ) {
        guard let sourceIndex = source.first, section.routines.indices.contains(sourceIndex) else {
            return
        }

        let routineID = section.routines[sourceIndex].id

        do {
            try RoutineManagementService(context: modelContext).moveRoutine(
                id: routineID,
                toGroupID: section.id,
                at: destination
            )
        } catch let error as PersistenceError {
            switch error {
            case .routineNotFound:
                alertPresentation = .routineNotFound
            case .groupNotFound:
                alertPresentation = .groupNotFound
            default:
                alertPresentation = .routineSaveFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .routineSaveFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }

    @ViewBuilder
    private func manageableGroupSection(_ section: ManageGroupSectionViewData) -> some View {
        Section {
            ForEach(section.routines) { routine in
                routineRow(routine)
            }
            .onMove { source, destination in
                moveRoutines(in: section, from: source, to: destination)
            }
        } header: {
            HStack {
                Text(section.name)

                Spacer()

                Menu {
                    Button("Rename Group") {
                        openRenameGroup(section)
                    }

                    Button("Delete Group", role: .destructive) {
                        pendingGroupDeletion = PendingGroupDeletion(
                            id: section.id,
                            name: section.name
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Color.routineLabelSecondary)
                }
                .accessibilityLabel("\(section.name) Actions")
            }
        }
    }

    @ViewBuilder
    private func fallbackSection(_ section: ManageGroupSectionViewData) -> some View {
        Section(section.name) {
            ForEach(section.routines) { routine in
                routineRow(routine)
            }
        }
    }

    private func routineRow(_ routine: ManageRoutineRowViewData) -> some View {
        Button {
            openEditRoutine(routine)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .foregroundStyle(Color.routineLabelPrimary)

                Text(routine.summaryText)
                    .font(.subheadline)
                    .foregroundStyle(Color.routineLabelSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(routine.name), \(routine.summaryText)")
        .swipeActions {
            Button(role: .destructive) {
                pendingRoutineDeletion = routine
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
