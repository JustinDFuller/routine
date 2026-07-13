import AppIntents
import SwiftData
import WidgetKit

// `openAppWhenRun` is statically parsed at build time by the AppIntents metadata
// processor, which requires a literal `true`/`false` — it cannot read a live
// setting. To make widget-Done app-opening configurable, the widget button
// chooses between this intent and `CompleteRoutineSilentlyIntent` (see below)
// based on `RoutineWidgetBridge.shouldOpenAppOnWidgetCompletion()`.
struct CompleteRoutineIntent: AppIntent {
    static var title: LocalizedStringResource { "Complete Routine" }
    static var isDiscoverable: Bool { false }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Routine ID")
    var routineID: String

    init() {}

    init(routineID: UUID) {
        self.routineID = routineID.uuidString
    }

    @MainActor
    static func completeRoutine(
        routineID: String,
        makeContext: @MainActor () throws -> ModelContext = {
            ModelContext(try RoutineModelContainer.shared())
        },
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) {
        guard let id = UUID(uuidString: routineID) else {
            return
        }

        guard let context = try? makeContext() else {
            return
        }

        let result = try? RoutineTrackingService(context: context).completeToday(routineID: id)
        RoutineWidgetBridge.reloadAllTimelines()

        guard result?.didInsert == true else {
            return
        }

        guard RoutineWidgetBridge.shouldOpenAppOnWidgetCompletion(userDefaults: userDefaults) else {
            return
        }

        RoutineWidgetBridge.recordCompletedRoutineID(id, userDefaults: userDefaults)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        Self.completeRoutine(routineID: routineID)
        return .result()
    }
}

/// Identical to `CompleteRoutineIntent` except it never opens the app, for use
/// when the user has turned off "Open app when completing from widget".
struct CompleteRoutineSilentlyIntent: AppIntent {
    static var title: LocalizedStringResource { "Complete Routine Silently" }
    static var isDiscoverable: Bool { false }
    static var openAppWhenRun: Bool { false }

    @Parameter(title: "Routine ID")
    var routineID: String

    init() {}

    init(routineID: UUID) {
        self.routineID = routineID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        CompleteRoutineIntent.completeRoutine(routineID: routineID)
        return .result()
    }
}
