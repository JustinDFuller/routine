import RoutineCore
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage(RoutineSettingsKeys.weekStartWeekday) private var weekStartRaw = Weekday.sunday.rawValue

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
            }
            .scrollContentBackground(.hidden)
            .background(Color.routineCanvas.ignoresSafeArea())
            .navigationTitle("Week Starts On")
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
