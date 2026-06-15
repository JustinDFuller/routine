import SwiftUI
import WidgetKit

struct RoutineWidget: Widget {
    let kind = "RoutineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RoutineWidgetProvider()) { entry in
            RoutineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next routine")
        .description("Shows the next routine that's ready to complete.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct RoutineWidgetBundle: WidgetBundle {
    var body: some Widget {
        RoutineWidget()
    }
}
