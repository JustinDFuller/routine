import WidgetKit

struct RoutineWidgetEntry: TimelineEntry {
    let date: Date
}

struct RoutineWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> RoutineWidgetEntry {
        RoutineWidgetEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineWidgetEntry) -> Void) {
        completion(RoutineWidgetEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineWidgetEntry>) -> Void) {
        completion(Timeline(entries: [RoutineWidgetEntry(date: .now)], policy: .atEnd))
    }
}
