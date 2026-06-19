import RoutineCore
import SwiftData
import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineCalendar) private var routineCalendar

    @AppStorage(RoutineSettingsKeys.weekStartWeekday) private var weekStartRaw = Weekday.sunday.rawValue
    @AppStorage(RoutineSettingsKeys.collapseCompletedToday) private var collapseCompletedToday = true
    @AppStorage(RoutineSettingsKeys.collapseGoalMetToday) private var collapseGoalMetToday = true
    @AppStorage(RoutineSettingsKeys.collapseUnavailableToday) private var collapseUnavailableToday = true

    @AppStorage(RoutineSettingsKeys.checkInMorningEnabled) private var checkInMorningEnabled = false
    @AppStorage(RoutineSettingsKeys.checkInMorningMinute) private var checkInMorningMinute = 360
    @AppStorage(RoutineSettingsKeys.checkInAfternoonEnabled) private var checkInAfternoonEnabled = false
    @AppStorage(RoutineSettingsKeys.checkInAfternoonMinute) private var checkInAfternoonMinute = 720
    @AppStorage(RoutineSettingsKeys.checkInEveningEnabled) private var checkInEveningEnabled = false
    @AppStorage(RoutineSettingsKeys.checkInEveningMinute) private var checkInEveningMinute = 1_080

    @State private var isNotificationAccessDenied = false

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
                    Toggle("Collapse goal-met routines", isOn: $collapseGoalMetToday)
                        .accessibilityIdentifier("settings-collapse-goal-met-toggle")
                    Toggle("Collapse unavailable routines", isOn: $collapseUnavailableToday)
                        .accessibilityIdentifier("settings-collapse-unavailable-toggle")
                } footer: {
                    Text(
                        "Completed routines can collapse into compact checkmark rows, goal-met "
                            + "routines can collapse into compact goal-met rows, and unavailable "
                            + "routines can collapse into compact clock rows. Tap a row to expand it."
                    )
                }

                checkInSection
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
            .task {
                await refreshNotificationAccessStatus()
            }
        }
    }

    private var checkInSection: some View {
        Section {
            checkInRow(
                title: "Morning",
                isOn: $checkInMorningEnabled,
                minute: $checkInMorningMinute,
                slotName: "morning",
                range: timeRange(startHour: 5, endHour: 10)
            )
            checkInRow(
                title: "Afternoon",
                isOn: $checkInAfternoonEnabled,
                minute: $checkInAfternoonMinute,
                slotName: "afternoon",
                range: timeRange(startHour: 11, endHour: 15)
            )
            checkInRow(
                title: "Evening",
                isOn: $checkInEveningEnabled,
                minute: $checkInEveningMinute,
                slotName: "evening",
                range: timeRange(startHour: 17, endHour: 21)
            )
        } header: {
            Text("Check-ins")
        } footer: {
            checkInFooter
        }
    }

    private var checkInFooter: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(
                "Choose which check-ins you want and when they should arrive. "
                    + "Routine stops sending them once your current goals are done."
            )

            if isNotificationAccessDenied {
                Text("Notifications are turned off for Routine in system Settings.")

                Button("Open Settings") {
                    openSystemSettings()
                }
                .accessibilityIdentifier("settings-checkin-open-system-settings-button")
            }
        }
    }

    private func checkInRow(
        title: String,
        isOn: Binding<Bool>,
        minute: Binding<Int>,
        slotName: String,
        range: ClosedRange<Date>
    ) -> some View {
        VStack(alignment: .leading) {
            Toggle(title, isOn: isOn)
                .accessibilityIdentifier("settings-checkin-\(slotName)-toggle")
                .onChange(of: isOn.wrappedValue) {
                    handleCheckInChange(turnedOn: isOn.wrappedValue)
                }

            DatePicker(
                "Time",
                selection: timeBinding(minute: minute),
                in: range,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .disabled(isOn.wrappedValue == false)
            .accessibilityIdentifier("settings-checkin-\(slotName)-time")
            .onChange(of: minute.wrappedValue) {
                handleCheckInChange(turnedOn: isOn.wrappedValue)
            }
        }
    }

    private func handleCheckInChange(turnedOn: Bool) {
        Task {
            if turnedOn {
                await CheckInScheduler().requestAuthorizationIfNeeded()
            }

            try? await CheckInScheduler().reschedule(context: modelContext, calendar: routineCalendar)
            await refreshNotificationAccessStatus()
        }
    }

    private func refreshNotificationAccessStatus() async {
        isNotificationAccessDenied = await CheckInScheduler().isAuthorizationDenied()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func timeRange(startHour: Int, endHour: Int) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let start = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today) ?? today
        let end = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: today) ?? today
        return start...end
    }

    private func timeBinding(minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { date(forMinuteOfDay: minute.wrappedValue) },
            set: { minute.wrappedValue = minuteOfDay(for: $0) }
        )
    }

    private func date(forMinuteOfDay minute: Int) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        return calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: today) ?? today
    }

    private func minuteOfDay(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return ((components.hour ?? 0) * 60) + (components.minute ?? 0)
    }

    private var weekStart: Binding<Weekday> {
        Binding(
            get: { Weekday(storageValue: weekStartRaw) },
            set: { weekStartRaw = $0.rawValue }
        )
    }
}
