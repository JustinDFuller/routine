import SwiftUI

extension TodayDashboardView {
    var managementMenu: some View {
        Menu {
            Button("Add Routine") {
                openAddRoutine()
            }
            .disabled(hasRealGroups == false)

            Button("Add Group") {
                openAddGroup()
            }

            Button(managementControlsMenuTitle) {
                toggleManagementControls()
            }

            Button("Organize Order") {
                enterOrganizeMode()
            }
        } label: {
            Image(systemName: "gearshape")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Management")
        .accessibilityHint("Shows dashboard management actions.")
        .accessibilityIdentifier("today-dashboard-management-menu")
    }

    var managementControlsMenuTitle: String {
        mode == .managementControls ? "Hide Management Controls" : "Show Management Controls"
    }

    var dashboardHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(viewData.title)
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("today-dashboard-title")

            Spacer(minLength: 0)

            managementMenu
        }
    }

    var trackingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                dashboardHeader

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

    var sectionsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewData.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(section)

                    VStack(spacing: 12) {
                        ForEach(section.routines) { routine in
                            RoutineCardView(
                                viewData: routine,
                                onTap: {
                                    handlePrimaryTap(for: routine)
                                },
                                onEdit: routineEditAction(for: routine.id),
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
                                    openEditRoutine(routineID: routine.id)
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

    @ViewBuilder
    func sectionHeader(_ section: RoutineSectionViewData) -> some View {
        HStack(spacing: 12) {
            Text(section.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.routineLabelSecondary)

            Spacer(minLength: 0)

            if mode == .managementControls, editableGroupIDs.contains(section.id) {
                Button {
                    openEditGroup(groupID: section.id)
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color.routineLabelSecondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(section.name)")
                .accessibilityHint("Opens the group editor.")
                .accessibilityIdentifier(
                    "dashboard-group-edit-\(section.name.routineAccessibilityIdentifierComponent)"
                )
            }
        }
    }

    var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(emptyStateTitle)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text(emptyStateMessage)
                .font(.body)
                .foregroundStyle(Color.routineLabelSecondary)

            Button(emptyStateButtonTitle) {
                if hasRealGroups {
                    openAddRoutine()
                } else {
                    openAddGroup()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.routineAccentActive)
            .accessibilityHint(emptyStateButtonHint)
            .accessibilityIdentifier(emptyStateButtonIdentifier)
        }
        .frame(maxWidth: .infinity, minHeight: 280, alignment: .center)
    }

    var emptyStateTitle: String {
        hasRealGroups ? "No routines yet" : "No groups yet"
    }

    var emptyStateMessage: String {
        hasRealGroups
            ? "Add your first routine to start tracking."
            : "Add a group to start organizing your routines."
    }

    var emptyStateButtonTitle: String {
        hasRealGroups ? "Add Routine" : "Add Group"
    }

    var emptyStateButtonHint: String {
        hasRealGroups
            ? "Opens routine creation."
            : "Opens group creation."
    }

    var emptyStateButtonIdentifier: String {
        hasRealGroups
            ? "today-dashboard-empty-add-routine-button"
            : "today-dashboard-empty-add-group-button"
    }

    var organizeContent: some View {
        List {
            ForEach(editableSections) { section in
                organizeSection(section)
            }
            .onMove(perform: moveGroups)

            ForEach(fallbackSections) { section in
                fallbackOrganizeSection(section)
            }
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.routineCanvas)
        .tint(Color.routineAccentActive)
    }

    @ViewBuilder
    func organizeSection(_ section: ManageGroupSectionViewData) -> some View {
        Section {
            if section.routines.isEmpty {
                Text("No routines")
                    .font(.subheadline)
                    .foregroundStyle(Color.routineLabelSecondary)
                    .accessibilityIdentifier(
                        "today-dashboard-organize-empty-group-\(section.name.routineAccessibilityIdentifierComponent)"
                    )
            } else {
                ForEach(section.routines) { routine in
                    organizeRoutineRow(routine)
                }
                .onMove { source, destination in
                    moveRoutines(in: section, from: source, to: destination)
                }
            }
        } header: {
            HStack {
                Text(section.name)

                Spacer()

                Button {
                    openEditGroup(groupID: section.id)
                } label: {
                    Image(systemName: "pencil.circle")
                        .foregroundStyle(Color.routineLabelSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit \(section.name)")
                .accessibilityHint("Opens the group editor.")
                .accessibilityIdentifier(
                    "today-dashboard-organize-group-edit-\(section.name.routineAccessibilityIdentifierComponent)"
                )
            }
        }
    }

    @ViewBuilder
    func fallbackOrganizeSection(_ section: ManageGroupSectionViewData) -> some View {
        Section(section.name) {
            if section.routines.isEmpty {
                Text("No routines")
                    .font(.subheadline)
                    .foregroundStyle(Color.routineLabelSecondary)
            } else {
                ForEach(section.routines) { routine in
                    organizeRoutineRow(routine)
                }
            }
        }
    }

    func organizeRoutineRow(_ routine: ManageRoutineRowViewData) -> some View {
        Button {
            openEditRoutine(routineID: routine.id)
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
        .accessibilityHint("Opens the routine editor.")
        .accessibilityIdentifier(
            "today-dashboard-organize-routine-\(routine.name.routineAccessibilityIdentifierComponent)"
        )
    }

    func actionDialogIsPresented(for routineID: UUID) -> Binding<Bool> {
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

    var alertIsPresented: Binding<Bool> {
        Binding(
            get: { alertPresentation != nil },
            set: { isPresented in
                if isPresented == false {
                    alertPresentation = nil
                }
            }
        )
    }

    func routineEditAction(for routineID: UUID) -> (() -> Void)? {
        guard mode == .managementControls, managementRow(for: routineID) != nil else {
            return nil
        }

        return {
            openEditRoutine(routineID: routineID)
        }
    }
}
