import Foundation
import RoutineCore

struct RoutineTestSeed {
    let id: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let availabilityStartMinute: Int?
    let availabilityEndMinute: Int?
    let pauseResumeDayKey: String?
    let sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        availabilityStartMinute: Int? = nil,
        availabilityEndMinute: Int? = nil,
        pauseResumeDayKey: String? = nil,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.availabilityStartMinute = availabilityStartMinute
        self.availabilityEndMinute = availabilityEndMinute
        self.pauseResumeDayKey = pauseResumeDayKey
        self.sortOrder = sortOrder
    }
}
