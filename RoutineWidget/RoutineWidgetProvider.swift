import RoutineCore
import SwiftData
import WidgetKit

struct RoutineWidgetEntry: TimelineEntry {
    let date: Date
    let selection: NextRoutineSelection
}

struct RoutineWidgetProvider: TimelineProvider {
    private static let logger = AppDiagnostics.logger(.projection)

    func placeholder(in context: Context) -> RoutineWidgetEntry {
        RoutineWidgetEntry(date: .now, selection: .ready(.placeholder))
    }

    func getSnapshot(in context: Context, completion: @escaping (RoutineWidgetEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
            return
        }

        nonisolated(unsafe) let completion = completion
        Task {
            let (entry, _) = await Self.makeEntry(now: .now)
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RoutineWidgetEntry>) -> Void) {
        nonisolated(unsafe) let completion = completion
        Task {
            let (entry, boundary) = await Self.makeEntry(now: .now)
            completion(Timeline(entries: [entry], policy: .after(boundary)))
        }
    }

    @MainActor
    private static func makeEntry(now: Date) async -> (entry: RoutineWidgetEntry, refreshBoundary: Date) {
        do {
            let context = ModelContext(try RoutineModelContainer.shared())
            let selection = try NextRoutineSelector.next(context: context, now: now)
            let boundary = try NextRoutineSelector.nextRefreshBoundary(context: context, now: now)
            return (RoutineWidgetEntry(date: now, selection: selection), boundary)
        } catch {
            logger.error("makeEntryFailed e=\(String(describing: error), privacy: .private)")
            return (RoutineWidgetEntry(date: now, selection: .noRoutines), now.addingTimeInterval(3_600))
        }
    }
}

extension NextRoutineSnapshot {
    fileprivate static let placeholder = NextRoutineSnapshot(
        routineID: UUID(),
        name: "Morning walk",
        countText: "2/5",
        periodText: "this week",
        lastDoneText: "Yesterday",
        fillRatio: 0.4,
        isComplete: false
    )
}
