import RoutineCore
import SwiftData
import SwiftUI

struct FactoryResetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineCalendar) private var routineCalendar

    @State private var selection = RoutineResetSelection(
        routinesAndHistory: true,
        displayPreferences: true,
        behindScheduleAlerts: true
    )
    @State private var isConfirmingReset = false
    @State private var resetError: Error?

    var body: some View {
        Form {
            Section {
                Toggle("Routines & history", isOn: $selection.routinesAndHistory)
                    .accessibilityIdentifier("factory-reset-routines-toggle")
                Toggle("Display preferences", isOn: $selection.displayPreferences)
                    .accessibilityIdentifier("factory-reset-display-toggle")
                Toggle("Behind-schedule alerts", isOn: $selection.behindScheduleAlerts)
                    .accessibilityIdentifier("factory-reset-behind-schedule-toggle")
            } footer: {
                Text("This action is permanent and cannot be undone.")
            }

            Section {
                Button("Reset") {
                    isConfirmingReset = true
                }
                .foregroundStyle(.red)
                .disabled(nothingSelected)
                .accessibilityIdentifier("factory-reset-reset-button")
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.routineCanvas.ignoresSafeArea())
        .navigationTitle("Factory Reset")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Color.routineAccentActive)
        .confirmationDialog(
            "Reset selected data?",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) {
                performReset()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action is permanent and cannot be undone.")
        }
        .alert(
            "Reset failed.",
            isPresented: Binding(
                get: { resetError != nil },
                set: { if !$0 { resetError = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Some data may not have been cleared.")
        }
    }

    private var nothingSelected: Bool {
        !selection.routinesAndHistory && !selection.displayPreferences && !selection.behindScheduleAlerts
    }

    private func performReset() {
        Task {
            do {
                try await RoutineFactoryResetService().reset(
                    selection,
                    in: modelContext,
                    calendar: routineCalendar
                )
                dismiss()
            } catch {
                resetError = error
            }
        }
    }
}
