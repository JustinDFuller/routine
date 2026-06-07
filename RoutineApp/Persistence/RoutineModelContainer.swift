import SwiftData

enum RoutineModelContainer {
    static let schema = Schema([RoutineGroup.self, Routine.self, RoutineCompletion.self, AppMetadata.self])

    @MainActor
    static func persistent() throws -> ModelContainer {
        try ModelContainer(for: schema)
    }

    @MainActor
    static func inMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
