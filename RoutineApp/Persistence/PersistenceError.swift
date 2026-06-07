import Foundation

enum PersistenceError: LocalizedError, Equatable {
    case routineNotFound(UUID)
    case groupNotFound(UUID)
    case completionNotFound(UUID)
    case metadataNotFound(String)
    case duplicateRoutineCompletion(routineID: UUID, dayKey: String)
    case fetchFailed(String)
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .routineNotFound:
            "Routine not found."
        case .groupNotFound:
            "Group not found."
        case .completionNotFound:
            "Completion not found."
        case .metadataNotFound:
            "Metadata not found."
        case .duplicateRoutineCompletion:
            "Completion already exists for that day."
        case .fetchFailed:
            "Unable to load data."
        case .saveFailed:
            "Unable to save changes."
        }
    }
}
