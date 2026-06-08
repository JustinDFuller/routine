import Foundation
import RoutineCore

struct RoutineTestSeed {
    let id: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.sortOrder = sortOrder
    }
}
