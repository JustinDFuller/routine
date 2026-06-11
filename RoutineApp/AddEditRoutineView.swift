import RoutineCore
import SwiftData
import SwiftUI

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
                            .accessibilityLabel("Validation message: \(validationMessage)")
                            .accessibilityIdentifier("routine-form-validation-message")
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
                    .accessibilityIdentifier("routine-form-target-stepper")

                    Picker("Period", selection: $formState.period) {
                        Text("Weekly").tag(RoutinePeriod.weekly)
                        Text("Monthly").tag(RoutinePeriod.monthly)
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("routine-form-period-picker")

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
                        .accessibilityIdentifier("routine-form-group-picker")
                    }
                }

                if case .edit = presentation {
                    Section {
                        Button("Delete Routine", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                        .accessibilityHint("Deletes this routine and its completion history after confirmation.")
                        .accessibilityIdentifier("routine-form-delete-button")
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
                alertPresentation = .routineNotFound
            } else if case .groupNotFound = error {
                alertPresentation = .groupNotFound
            } else {
                alertPresentation = .routineSaveFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .routineSaveFailure(detail: userSafeAlertDetail(for: error))
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
                alertPresentation = .routineNotFound
            } else {
                alertPresentation = .routineDeleteFailure(detail: userSafeAlertDetail(for: error))
            }
        } catch {
            alertPresentation = .routineDeleteFailure(detail: userSafeAlertDetail(for: error))
        }
    }

    private func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }
}
