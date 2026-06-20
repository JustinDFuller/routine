import AppIntents
import SwiftData
import WidgetKit

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

        RoutineWidgetBridge.recordCompletedRoutineID(id, userDefaults: userDefaults)
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        Self.completeRoutine(routineID: routineID)
        return .result()
    }
}
