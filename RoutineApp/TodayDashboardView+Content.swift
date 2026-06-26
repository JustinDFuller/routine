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

            Button("Edit") {
                toggleManagementControls()
            }

            Button("Rearrange Groups") {
                enterRearrangeGroupsMode()
            }

            Button("Rearrange Routines") {
                enterRearrangeRoutinesMode()
            }

            Divider()

            if viewData.globalPause != nil {
                Button("Resume All") {
                    resumeAllRoutines()
                }
                .accessibilityIdentifier("today-dashboard-resume-all-button")
            } else {
                Button("Pause All…") {
                    openGlobalPause()
                }
                .accessibilityIdentifier("today-dashboard-pause-all-button")
            }

            Button("Settings") {
                openSettings()
            }
            .accessibilityIdentifier("today-dashboard-settings-button")
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

    var managementControlsDoneButton: some View {
        Button("Done") {
            toggleManagementControls()
        }
        .font(.body.weight(.semibold))
        .foregroundStyle(Color.routineAccentActive)
        .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
        .contentShape(Rectangle())
        .accessibilityLabel("Done Editing")
        .accessibilityHint("Exits dashboard edit mode.")
        .accessibilityIdentifier("today-dashboard-edit-done-button")
    }

    var dashboardHeader: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(viewData.title)
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("today-dashboard-title")

            Spacer(minLength: 0)

            switch mode {
            case .tracking:
                managementMenu
            case .managementControls:
                managementControlsDoneButton
            case .rearrangeGroups, .rearrangeRoutines:
                EmptyView()
            }
        }
    }

    var trackingContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                dashboardHeader

                if let globalPause = viewData.globalPause {
                    globalPauseBanner(globalPause)
                }

                if showsSectionContent {
                    sectionsContent
                } else {
                    emptyState
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    func globalPauseBanner(_ banner: GlobalPauseBannerViewData) -> some View {
        HStack(spacing: 12) {
            Text("All routines paused · resumes \(banner.resumeText)")
                .font(.subheadline)
                .foregroundStyle(Color.routineLabelPrimary)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button("Resume all") {
                resumeAllRoutines()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.routineAccentActive)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.routineAccentActive.opacity(0.12))
            )
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
            .accessibilityIdentifier("today-dashboard-global-pause-resume-all-button")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.routineSurfaceElevated)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.routineDivider.opacity(0.5), lineWidth: 1)
        }
        .accessibilityIdentifier("today-dashboard-global-pause-banner")
    }

    var sectionsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(viewData.sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    sectionHeader(section)

                    if section.routines.isEmpty {
                        Text("No routines")
                            .font(.subheadline)
                            .foregroundStyle(Color.routineLabelSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else if collapsesCompleted || collapsesGoalMet || collapsesUnavailable ||
                        section.routines.contains(where: \.isPaused) {
                        collapsedSectionContent(section)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(section.routines) { routine in
                                routineCardView(for: routine)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func collapsedSectionContent(_ section: RoutineSectionViewData) -> some View {
        let partition = RoutineSectionViewData.displayPartition(
            collapseCompletedToday: collapsesCompleted,
            collapseGoalMetToday: collapsesGoalMet,
            collapseUnavailableToday: collapsesUnavailable,
            routines: section.routines
        )

        VStack(spacing: 12) {
            ForEach(partition.fullCards) { routine in
                routineCardView(for: routine)
            }
        }

        if partition.collapsedRows.isEmpty == false {
            VStack(spacing: 8) {
                ForEach(partition.collapsedRows) { row in
                    if case .paused = row.style {
                        CollapsedRoutineRowView(
                            viewData: row,
                            onExpand: {},
                            onResume: { resumeRoutine(routineID: row.id) }
                        )
                    } else if expandedCollapsedRoutineIDs.contains(row.id) {
                        routineCardView(for: row.routine, onCollapse: { collapse(row.id) })
                    } else {
                        CollapsedRoutineRowView(viewData: row, onExpand: { expand(row.id) })
                    }
                }
            }
        }
    }

    private func routineCardView(
        for routine: RoutineCardViewData,
        onCollapse: (() -> Void)? = nil
    ) -> some View {
        RoutineCardView(
            viewData: routine,
            onTap: {
                handlePrimaryTap(for: routine)
            },
            onEdit: routineEditAction(for: routine.id),
            onHistory: mode == .tracking
                ? {
                    openHistory(for: routine.id)
                }
                : nil,
            onCollapse: onCollapse
        )
    }

    var showsSectionContent: Bool {
        viewData.isEmpty == false || (mode == .managementControls && viewData.sections.isEmpty == false)
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

    @ViewBuilder
    var rearrangeContent: some View {
        switch mode {
        case .rearrangeGroups:
            rearrangeGroupsContent
        case .rearrangeRoutines:
            rearrangeRoutinesContent
        case .tracking, .managementControls:
            EmptyView()
        }
    }

    var rearrangeGroupsContent: some View {
        List {
            ForEach(editableSections) { section in
                rearrangeGroupRow(section)
            }
            .onMove(perform: moveGroups)
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.routineCanvas)
        .tint(Color.routineAccentActive)
    }

    var rearrangeRoutinesContent: some View {
        List {
            ForEach(editableSections) { section in
                rearrangeRoutineSection(section)
            }
        }
        .environment(\.editMode, .constant(.active))
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.routineCanvas)
        .tint(Color.routineAccentActive)
    }

    func rearrangeGroupRow(_ section: ManageGroupSectionViewData) -> some View {
        Text(section.name)
            .foregroundStyle(Color.routineLabelPrimary)
            .accessibilityIdentifier(
                "today-dashboard-rearrange-group-\(section.name.routineAccessibilityIdentifierComponent)"
            )
    }

    @ViewBuilder
    func rearrangeRoutineSection(_ section: ManageGroupSectionViewData) -> some View {
        Section {
            if section.routines.isEmpty {
                Text("No routines")
                    .font(.subheadline)
                    .foregroundStyle(Color.routineLabelSecondary)
                    .accessibilityIdentifier(
                        "today-dashboard-rearrange-empty-group-\(section.name.routineAccessibilityIdentifierComponent)"
                    )
            } else {
                ForEach(section.routines) { routine in
                    rearrangeRoutineRow(routine)
                }
                .onMove { source, destination in
                    moveRoutines(in: section, from: source, to: destination)
                }
            }
        } header: {
            Text(section.name)
        }
    }

    func rearrangeRoutineRow(_ routine: ManageRoutineRowViewData) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(routine.name)
                .foregroundStyle(Color.routineLabelPrimary)

            Text(routine.summaryText)
                .font(.subheadline)
                .foregroundStyle(Color.routineLabelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(routine.name), \(routine.summaryText)")
        .accessibilityIdentifier(
            "today-dashboard-rearrange-routine-\(routine.name.routineAccessibilityIdentifierComponent)"
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
