import Foundation

enum AppRoute: Hashable, Sendable {
    case manageRoutines(editingRoutineID: UUID?)
    case routineHistory(routineID: UUID)
}
