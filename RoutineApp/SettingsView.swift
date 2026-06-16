import RoutineCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(RoutineSettingsKeys.weekStartWeekday) private var weekStartRaw = Weekday.sunday.rawValue
    @AppStorage(RoutineSettingsKeys.collapseCompletedToday) private var collapseCompletedToday = true

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Week starts on", selection: weekStart) {
                        ForEach(Weekday.allCases) { weekday in
                            Text(weekday.displayName).tag(weekday)
                        }
                    }
                    .accessibilityIdentifier("settings-week-start-picker")
                } footer: {
                    Text("Controls when your weekly routine progress resets.")
                }

                Section {
                    Toggle("Collapse completed routines", isOn: $collapseCompletedToday)
                        .accessibilityIdentifier("settings-collapse-completed-toggle")
                } footer: {
                    Text(
                        "Completed routines collapse into compact rows so you can focus on what's left. "
                            + "Tap one to expand it."
                    )
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.routineCanvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityIdentifier("settings-done-button")
                }
            }
            .tint(Color.routineAccentActive)
        }
    }

    private var weekStart: Binding<Weekday> {
        Binding(
            get: { Weekday(storageValue: weekStartRaw) },
            set: { weekStartRaw = $0.rawValue }
        )
    }
}
