import RoutineCore
import SwiftData
import SwiftUI
import UIKit

private enum SettingsDestination: Hashable {
    case factoryReset
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.routineCalendar) private var routineCalendar
    @Environment(\.behindScheduleRescheduleCoordinator) private var behindScheduleRescheduleCoordinator

    @AppStorage(RoutineSettingsKeys.weekStartWeekday) private var weekStartRaw = Weekday.sunday.rawValue
    @AppStorage(RoutineSettingsKeys.collapseCompletedToday) private var collapseCompletedToday = true
    @AppStorage(RoutineSettingsKeys.collapseGoalMetToday) private var collapseGoalMetToday = true
    @AppStorage(RoutineSettingsKeys.collapseUnavailableToday) private var collapseUnavailableToday = true

    @AppStorage(RoutineSettingsKeys.behindScheduleNotificationsEnabled)
    private var behindScheduleNotificationsEnabled = false
    @AppStorage(RoutineSettingsKeys.behindScheduleNotificationMinute)
    private var behindScheduleNotificationMinute = 420

    @AppStorage(RoutineSettingsKeys.openAppOnWidgetCompletion, store: RoutineWidgetBridge.appGroupDefaults)
    private var openAppOnWidgetCompletion = true

    @State private var isNotificationAccessDenied = false
    @State private var behindScheduleTimeChangeTask: Task<Void, Never>?

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

                behindScheduleSection

                Section {
                    Toggle("Open app when completing from widget", isOn: $openAppOnWidgetCompletion)
                        .accessibilityIdentifier("settings-widget-open-app-toggle")
                        .onChange(of: openAppOnWidgetCompletion) {
                            RoutineWidgetBridge.reloadAllTimelines()
                        }
                } header: {
                    Text("Widget")
                } footer: {
                    Text(
                        "When off, tapping Done on the widget completes the routine and updates "
                            + "the widget without opening Routine."
                    )
                }

                Section {
                    NavigationLink(value: SettingsDestination.factoryReset) {
                        Text("Factory Reset")
                            .foregroundStyle(.red)
                    }
                    .accessibilityIdentifier("settings-factory-reset-link")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.routineCanvas.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsDestination.self) { destination in
                switch destination {
                case .factoryReset:
                    FactoryResetView()
                }
            }
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

    private var behindScheduleSection: some View {
        Section {
            Toggle("Alert me when I fall behind", isOn: $behindScheduleNotificationsEnabled)
                .accessibilityIdentifier("settings-behind-schedule-toggle")
                .onChange(of: behindScheduleNotificationsEnabled) { oldValue, newValue in
                    behindScheduleTimeChangeTask?.cancel()
                    handleBehindScheduleChange(justEnabled: oldValue == false && newValue)
                }

            DatePicker(
                "Time",
                selection: timeBinding(minute: $behindScheduleNotificationMinute),
                displayedComponents: .hourAndMinute
            )
            .disabled(behindScheduleNotificationsEnabled == false)
            .accessibilityIdentifier("settings-behind-schedule-time")
            .onChange(of: behindScheduleNotificationMinute) {
                guard behindScheduleNotificationsEnabled else {
                    return
                }

                behindScheduleTimeChangeTask?.cancel()
                behindScheduleTimeChangeTask = Task {
                    try? await Task.sleep(nanoseconds: 300_000_000)

                    guard Task.isCancelled == false else {
                        return
                    }

                    handleBehindScheduleChange(justEnabled: false)
                }
            }
        } header: {
            Text("Behind-schedule alerts")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text(
                    "An alert arrives once per day only when current progress is behind the pace "
                        + "needed to meet the goal."
                )

                if isNotificationAccessDenied {
                    Text("Notifications are turned off for Routine in system Settings.")

                    Button("Open Settings") {
                        openSystemSettings()
                    }
                    .accessibilityIdentifier("settings-behind-schedule-open-system-settings-button")
                }
            }
        }
    }

    private func handleBehindScheduleChange(justEnabled: Bool) {
        Task {
            if justEnabled {
                await behindScheduleRescheduleCoordinator.requestAuthorizationIfNeeded()
            }

            await rescheduleBehindScheduleAlerts(
                coordinator: behindScheduleRescheduleCoordinator,
                context: modelContext,
                calendar: routineCalendar,
                now: .now,
                logLabel: "settingsRescheduleFailed"
            )
            await refreshNotificationAccessStatus()
        }
    }

    private func refreshNotificationAccessStatus() async {
        isNotificationAccessDenied = await BehindScheduleScheduler().isAuthorizationDenied()
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        UIApplication.shared.open(url)
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
