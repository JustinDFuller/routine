import SwiftData
import SwiftUI

struct AddEditGroupView: View {
    let presentation: GroupFormPresentation
    let existingNames: [String]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var formState: GroupFormState
    @State private var isDeleteConfirmationPresented = false
    @State private var alertPresentation: ManageAlertPresentation?

    init(
        presentation: GroupFormPresentation,
        existingNames: [String]
    ) {
        self.presentation = presentation
        self.existingNames = existingNames
        _formState = State(initialValue: GroupFormState(name: presentation.initialName))
    }

    var body: some View {
        NavigationStack {
            Form {
                if let validationMessage = formState.validationMessage {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(Color.routineAccentDestructive)
                            .accessibilityLabel("Validation message: \(validationMessage)")
                            .accessibilityIdentifier("group-form-validation-message")
                    }
                }

                Section {
                    TextField("Name", text: $formState.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .accessibilityIdentifier("group-form-name-field")
                }

                if case .rename = presentation {
                    Section {
                        Button("Delete Group", role: .destructive) {
                            isDeleteConfirmationPresented = true
                        }
                        .accessibilityHint("Deletes this group after confirmation.")
                        .accessibilityIdentifier("group-form-delete-button")
                        .confirmationDialog(
                            "Delete Group",
                            isPresented: $isDeleteConfirmationPresented,
                            titleVisibility: .visible
                        ) {
                            Button("Delete Group", role: .destructive) {
                                delete()
                            }

                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This deletes the group.")
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
                    .accessibilityIdentifier("group-form-save-button")
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
            let name = try formState.makeName(
                existingNames: existingNames,
                excluding: presentation.excludedName
            )
            let service = RoutineManagementService(context: modelContext)

            switch presentation {
            case .add:
                _ = try service.createGroup(name: name)
            case .rename(let snapshot):
                try service.renameGroup(id: snapshot.groupID, name: name)
            }

            dismiss()
        } catch is GroupFormError {
            return
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

    private func delete() {
        guard let groupID = presentation.editingGroupID else {
            return
        }

        do {
            try RoutineManagementService(context: modelContext).deleteGroup(id: groupID)
            dismiss()
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

    private func userSafeAlertDetail(for error: Error) -> String? {
        error.localizedDescription
    }
}
