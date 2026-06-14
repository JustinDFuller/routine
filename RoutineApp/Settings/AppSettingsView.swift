import SwiftUI

struct AppSettingsView: View {
    @AppStorage(AppUserSettings.weekStartDayKey) var weekStartDayRaw: Int = WeekStartDay.sunday.rawValue

    var weekStartDay: WeekStartDay {
        WeekStartDay(rawValue: weekStartDayRaw) ?? .sunday
    }

    var body: some View {
        Form {
            Section("Week") {
                Picker("Week starts on", selection: $weekStartDayRaw) {
                    ForEach(WeekStartDay.allCases) { day in
                        Text(day.displayName).tag(day.rawValue)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}
