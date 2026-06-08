import Foundation

enum AppRoute: Hashable, Sendable {
    case manageRoutines
    case routineHistory(routineID: UUID)
}
