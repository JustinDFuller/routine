import SwiftData

enum RoutineModelContainer {
    static let appGroupID = "group.com.justinfuller.routine"
    static let schema = Schema([RoutineGroup.self, Routine.self, RoutineCompletion.self, AppMetadata.self])

    static func shared() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func persistent() throws -> ModelContainer {
        try shared()
    }

    @MainActor
    static func inMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
