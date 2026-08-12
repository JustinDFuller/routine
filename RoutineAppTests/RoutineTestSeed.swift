import Foundation
import RoutineCore

struct RoutineTestSeed {
    let id: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let availabilityStartMinute: Int?
    let availabilityEndMinute: Int?
    let availabilityBlockMode: RoutineAvailabilityBlockMode
    let sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        availabilityStartMinute: Int? = nil,
        availabilityEndMinute: Int? = nil,
        availabilityBlockMode: RoutineAvailabilityBlockMode = .soft,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.availabilityStartMinute = availabilityStartMinute
        self.availabilityEndMinute = availabilityEndMinute
        self.availabilityBlockMode = availabilityBlockMode
        self.sortOrder = sortOrder
    }
}
