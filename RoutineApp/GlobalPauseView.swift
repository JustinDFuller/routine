import RoutineCore
import SwiftData
import SwiftUI

struct GlobalPauseView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineCalendar) private var routineCalendar
    @Environment(\.routineRuntimeConfiguration) private var runtime

    @State private var skipPeriods: Int = 1
    @State private var alertPresentation: ManageAlertPresentation?

    private let skipRange: ClosedRange<Int> = 1...52

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Stepper(value: $skipPeriods, in: skipRange) {
                        HStack {
                            Text("Skip")
                            Spacer()
                            Text("\(skipPeriods) period\(skipPeriods == 1 ? "" : "s")")
                                .foregroundStyle(Color.routineLabelSecondary)
                        }
                    }
                    .accessibilityIdentifier("global-pause-skip-stepper")
                } footer: {
                    Text(footerText)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.routineCanvas.ignoresSafeArea())
            .navigationTitle("Pause All Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Pause All") {
                        pauseAll()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.routineAccentActive)
                    .accessibilityIdentifier("global-pause-confirm-button")
                }
            }
            .tint(Color.routineAccentActive)
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
        }
    }

    private var footerText: String {
        let weeks = skipPeriods == 1 ? "1 week" : "\(skipPeriods) weeks"
        let months = skipPeriods == 1 ? "1 month" : "\(skipPeriods) months"
        return "Weekly routines skip \(weeks), monthly routines skip \(months)."
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

    private func pauseAll() {
        let today = routineCalendar.today(now: runtime.now)
        do {
            try RoutineManagementService(context: modelContext)
                .setGlobalPause(skipPeriods: skipPeriods, anchor: today)
            dismiss()
        } catch {
            alertPresentation = ManageAlertPresentation(
                title: "Could not pause routines.",
                message: error.localizedDescription
            )
        }
    }
}
