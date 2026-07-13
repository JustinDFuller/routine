import Foundation
import SwiftData
import WidgetKit

struct WidgetCompletionRestoration: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
}

enum RoutineWidgetBridge {
    static let completedRoutineIDKey = "widgetCompletedRoutineID"
    static let openAppOnWidgetCompletionKey = "settings.openAppOnWidgetCompletion"

    nonisolated(unsafe) static let appGroupDefaults: UserDefaults =
        UserDefaults(suiteName: RoutineModelContainer.appGroupID) ?? .standard

    @MainActor
    static var reloadAllTimelines: @MainActor () -> Void = {
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func shouldOpenAppOnWidgetCompletion(
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) -> Bool {
        guard let userDefaults,
            userDefaults.object(forKey: openAppOnWidgetCompletionKey) != nil
        else {
            return true
        }
        return userDefaults.bool(forKey: openAppOnWidgetCompletionKey)
    }

    static func recordCompletedRoutineID(
        _ routineID: UUID,
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) {
        userDefaults?.set(routineID.uuidString, forKey: completedRoutineIDKey)
    }

    static func clearCompletedRoutineID(
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) {
        userDefaults?.removeObject(forKey: completedRoutineIDKey)
    }

    @MainActor
    static func restoration(
        context: ModelContext,
        userDefaults: UserDefaults? = UserDefaults(suiteName: RoutineModelContainer.appGroupID)
    ) -> WidgetCompletionRestoration? {
        guard let userDefaults else {
            return nil
        }

        guard let rawValue = userDefaults.string(forKey: completedRoutineIDKey) else {
            return nil
        }

        guard let routineID = UUID(uuidString: rawValue) else {
            clearCompletedRoutineID(userDefaults: userDefaults)
            return nil
        }

        do {
            let routine = try context.routine(id: routineID)
            clearCompletedRoutineID(userDefaults: userDefaults)
            return WidgetCompletionRestoration(routineID: routineID, routineName: routine.name)
        } catch let error as PersistenceError {
            guard case .routineNotFound = error else {
                return nil
            }

            clearCompletedRoutineID(userDefaults: userDefaults)
            return nil
        } catch {
            return nil
        }
    }
}
