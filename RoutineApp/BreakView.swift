import RoutineCore
import SwiftData
import SwiftUI

struct BreakView: View {
    let presentation: BreakSheetPresentation

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineCalendar) private var routineCalendar
    @Environment(\.routineRuntimeConfiguration) private var runtime

    @State private var selectedPreset: RoutineBreakPreset = .today
    @State private var untilDate: Date
    @State private var alertPresentation: ManageAlertPresentation?

    init(presentation: BreakSheetPresentation, routineCalendar: RoutineCalendar = .current, now: Date = .now) {
        self.presentation = presentation
        let today = routineCalendar.today(now: now)
        let defaultResumeDay = RoutineBreak.resumeDay(for: .today, today: today, calendar: routineCalendar)
        _untilDate = State(initialValue: routineCalendar.date(for: defaultResumeDay))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Off until", selection: $selectedPreset) {
                        Text("Today").tag(RoutineBreakPreset.today)
                        Text("This week").tag(RoutineBreakPreset.thisWeek)
                        Text("This month").tag(RoutineBreakPreset.thisMonth)
                        Text("Until date").tag(RoutineBreakPreset.untilDate)
                    }
                    .accessibilityIdentifier("break-preset-picker")

                    if selectedPreset == .untilDate {
                        DatePicker(
                            "Resume",
                            selection: $untilDate,
                            in: minimumUntilDate...,
                            displayedComponents: .date
                        )
                        .accessibilityIdentifier("break-until-date-picker")
                    }
                } footer: {
                    Text(footerText)
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
                    Button("Start Break") {
                        startBreak()
                    }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color.routineAccentActive)
                    .accessibilityIdentifier("break-confirm-button")
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
        "Off until \(resumeText)."
    }

    private var resumeDay: RoutineDay {
        RoutineBreak.resumeDay(
            for: selectedPreset,
            today: today,
            calendar: routineCalendar,
            explicitDate: untilDate
        )
    }

    private var resumeText: String {
        routineCalendar.relativeLabel(for: resumeDay, today: today)
    }

    private var today: RoutineDay {
        routineCalendar.today(now: runtime.now)
    }

    private var minimumUntilDate: Date {
        let minimumDay = RoutineBreak.resumeDay(for: .today, today: today, calendar: routineCalendar)
        return routineCalendar.date(for: minimumDay)
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

    private func startBreak() {
        do {
            let service = RoutineManagementService(context: modelContext)
            switch presentation.target {
            case .all:
                try service.setGlobalBreak(resumeDay: resumeDay)
            case .routine(let id, _):
                try service.setRoutineBreak(id: id, resumeDay: resumeDay)
            }
            dismiss()
        } catch {
            alertPresentation = ManageAlertPresentation(
                title: "Could not start break.",
                message: error.localizedDescription
            )
        }
    }
}
