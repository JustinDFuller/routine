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

    @State private var formPresentation: RoutineFormPresentation?
    @State private var pendingDeletion: ManageRoutineRowViewData?
    @State private var alertPresentation: ManageAlertPresentation?
    @State private var didHandleInitialEditTarget = false

    private var viewData: ManageRoutinesViewData {
        ManageProjectionBuilder(context: modelContext).build(groups: groups, routines: routines)
    }

    private var allRows: [ManageRoutineRowViewData] {
        viewData.sections.flatMap(\.routines)
    }

    var body: some View {
        Group {
            if viewData.isEmpty {
                emptyState
            } else {
                routinesList
            }
        }
        .background(Color.routineCanvas.ignoresSafeArea())
        .navigationTitle("Manage Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openAddRoutine()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Routine")
                .accessibilityIdentifier("manage-routines-add-button")
            }
        }
        .sheet(item: $formPresentation) { presentation in
            AddEditRoutineView(
                presentation: presentation,
                groupChoices: viewData.groupChoices
            )
        }
        .task {
            handleInitialEditTargetIfNeeded()
        }
        .confirmationDialog(
            pendingDeletion?.name ?? "Delete Routine",
            isPresented: pendingDeletionIsPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Routine", role: .destructive) {
                guard let row = pendingDeletion else {
                    return
                }

                deleteRoutine(row)
            }

            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: {
            Text("This deletes the routine and its completion history.")
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

    private var routinesList: some View {
        List {
            ForEach(viewData.sections) { section in
                Section(section.name) {
                    ForEach(section.routines) { routine in
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
                                pendingDeletion = routine
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .tint(Color.routineAccentActive)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No routines yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Color.routineLabelPrimary)

            Text(
                viewData.groupChoices.isEmpty
                    ? "A routine needs a group."
                    : "Add a routine to start organizing your dashboard."
            )
            .font(.body)
            .foregroundStyle(Color.routineLabelSecondary)

            if viewData.groupChoices.isEmpty == false {
                Button("Add Routine") {
                    openAddRoutine()
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.routineAccentActive)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }

    private var pendingDeletionIsPresented: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if isPresented == false {
                    pendingDeletion = nil
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

        formPresentation = .add(initialGroupID: viewData.groupChoices.first?.id)
    }

    private func openEditRoutine(_ row: ManageRoutineRowViewData) {
        formPresentation = .edit(
            RoutineFormSnapshot(
                row: row,
                availableGroupIDs: Set(viewData.groupChoices.map(\.id))
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
            alertPresentation = .notFound
            return
        }

        openEditRoutine(row)
    }

    private func deleteRoutine(_ row: ManageRoutineRowViewData) {
        pendingDeletion = nil

        do {
            try RoutineManagementService(context: modelContext).deleteRoutine(id: row.id)
        } catch let error as PersistenceError {
            if case .routineNotFound = error {
                alertPresentation = .notFound
            } else {
                alertPresentation = .deleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .deleteFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }
}

struct AddEditRoutineView: View {
    let presentation: RoutineFormPresentation
    let groupChoices: [ManageGroupChoiceViewData]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var formState: RoutineFormState
    @State private var isDeleteConfirmationPresented = false
    @State private var alertPresentation: ManageAlertPresentation?

    init(
        presentation: RoutineFormPresentation,
        groupChoices: [ManageGroupChoiceViewData]
    ) {
        self.presentation = presentation
        self.groupChoices = groupChoices
        _formState = State(initialValue: RoutineFormState(presentation: presentation))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage = formState.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(Color.routineAccentDestructive)
                    }
                }

                Section {
                    TextField("Name", text: $formState.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("routine-form-name-field")

                    Stepper(value: $formState.targetCount, in: formState.targetRange) {
                        HStack {
                            Text("Target")
                            Spacer()
                            Text("\(formState.targetCount)")
                                .foregroundStyle(Color.routineLabelSecondary)
                        }
                    }

                    Picker("Period", selection: $formState.period) {
                        Text("Weekly").tag(RoutinePeriod.weekly)
                        Text("Monthly").tag(RoutinePeriod.monthly)
                    }
                    .pickerStyle(.segmented)

                    if groupChoices.isEmpty {
                        LabeledContent("Group") {
                            Text("No groups available")
                                .foregroundStyle(Color.routineLabelSecondary)
                        }
                    } else {
                        Picker("Group", selection: $formState.groupID) {
                            Text("Choose a group").tag(Optional<UUID>.none)

                            ForEach(groupChoices) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                    }
                }

                if case .edit = presentation {
                    Section {
                        Button("Delete Routine", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                        .accessibilityIdentifier("routine-form-delete-button")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.routineCanvas.ignoresSafeArea())
            .navigationTitle(presentation.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(presentation.saveTitle) {
                        save()
                    }
                    .accessibilityIdentifier("routine-form-save-button")
                }
            }
            .confirmationDialog(
                "Delete Routine",
                isPresented: $isDeleteConfirmationPresented,
                titleVisibility: .visible
            ) {
                Button("Delete Routine", role: .destructive) {
                    delete()
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This deletes the routine and its completion history.")
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
            .tint(Color.routineAccentActive)
        }
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

    private func save() {
        do {
            let draft = try formState.makeDraft()
            let service = RoutineManagementService(context: modelContext)

            switch presentation {
            case .add:
                _ = try service.createRoutine(draft)
            case .edit(let snapshot):
                try service.updateRoutine(id: snapshot.routineID, with: draft)
            }

            dismiss()
        } catch is RoutineFormError {
            return
        } catch let error as PersistenceError {
            if case .routineNotFound = error {
                alertPresentation = .notFound
            } else {
                alertPresentation = .saveFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .saveFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func delete() {
        guard let routineID = presentation.editingRoutineID else {
            return
        }

        do {
            try RoutineManagementService(context: modelContext).deleteRoutine(id: routineID)
            dismiss()
        } catch let error as PersistenceError {
            if case .routineNotFound = error {
                alertPresentation = .notFound
            } else {
                alertPresentation = .deleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .deleteFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }
}

private struct ManageAlertPresentation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?

    static let missingGroup = ManageAlertPresentation(
        title: "A routine needs a group.",
        message: nil
    )

    static let notFound = ManageAlertPresentation(
        title: "This routine no longer exists.",
        message: nil
    )

    static func saveFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not save changes.", message: detail)
    }

    static func deleteFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not delete routine.", message: detail)
    }
}
