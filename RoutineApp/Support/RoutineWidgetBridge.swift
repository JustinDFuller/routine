import Foundation
import WidgetKit

struct WidgetCompletionRestoration: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
}

enum RoutineWidgetBridge {
    static let completedRoutineIDKey = "widgetCompletedRoutineID"

    @MainActor
    static var reloadAllTimelines: @MainActor () -> Void = {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func recordCompletedRoutineID(
        _ routineID: UUID,
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) {
        userDefaults?.set(routineID.uuidString, forKey: completedRoutineIDKey)
    }

    static func takeCompletedRoutineID(
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) -> UUID? {
        guard let userDefaults else {
            return nil
        }

        defer {
            userDefaults.removeObject(forKey: completedRoutineIDKey)
        }

        guard let rawValue = userDefaults.string(forKey: completedRoutineIDKey) else {
            return nil
        }

        return UUID(uuidString: rawValue)
    }

    static func restoration(
        for routines: [Routine],
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) -> WidgetCompletionRestoration? {
        guard
            let routineID = takeCompletedRoutineID(userDefaults: userDefaults),
            let routine = routines.first(where: { $0.id == routineID })
        else {
            return nil
        }

        return WidgetCompletionRestoration(routineID: routineID, routineName: routine.name)
    }
}
