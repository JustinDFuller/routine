import AppIntents
import SwiftData
import WidgetKit

struct CompleteRoutineIntent: AppIntent {
    static var title: LocalizedStringResource { "Complete Routine" }
    static var isDiscoverable: Bool { false }

    @Parameter(title: "Routine ID")
    var routineID: String

    init() {}

    init(routineID: UUID) {
        self.routineID = routineID.uuidString
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: routineID) else {
            return .result()
        }

        let context = ModelContext(try RoutineModelContainer.shared())
        _ = try? RoutineTrackingService(context: context).completeToday(routineID: id)
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
