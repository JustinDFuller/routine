import SwiftData
import SwiftUI

@MainActor
@main
struct RoutineApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try RoutineModelContainer.persistent()
        } catch {
            fatalError("Failed to create persistent model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
