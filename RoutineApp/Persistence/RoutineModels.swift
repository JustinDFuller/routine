import Foundation
import RoutineCore
import SwiftData

@Model
final class RoutineGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Routine.group)
    var routines: [Routine]

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        routines: [Routine] = []
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.routines = routines
    }
}

@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetCount: Int
    var periodRawValue: String
    var availabilityStartMinute: Int?
    var availabilityEndMinute: Int?
    var breakResumeDayKey: String?
    var groupID: UUID
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    var group: RoutineGroup?

    @Relationship(deleteRule: .cascade, inverse: \RoutineCompletion.routine)
    var completions: [RoutineCompletion]

    var period: RoutinePeriod {
        get { RoutinePeriod(rawValue: periodRawValue) ?? .weekly }
        set { periodRawValue = newValue.rawValue }
    }

    var availabilityWindow: RoutineAvailabilityWindow? {
        try? validatedAvailabilityWindow(
            startMinute: availabilityStartMinute,
            endMinute: availabilityEndMinute
        )
    }

    init(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        availabilityStartMinute: Int? = nil,
        availabilityEndMinute: Int? = nil,
        breakResumeDayKey: String? = nil,
        sortOrder: Int,
        group: RoutineGroup,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completions: [RoutineCompletion] = []
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.periodRawValue = period.rawValue
        self.availabilityStartMinute = availabilityStartMinute
        self.availabilityEndMinute = availabilityEndMinute
        self.breakResumeDayKey = breakResumeDayKey
        self.groupID = group.id
        self.sortOrder = sortOrder
        self.group = group
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completions = completions
    }
}

@Model
final class RoutineCompletion {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var routineDayKey: String
    var routineID: UUID
    var dayKey: String
    var completedAt: Date

    var routine: Routine?

    init(
        id: UUID = UUID(),
        routine: Routine,
        day: RoutineDay,
        completedAt: Date = .now
    ) {
        self.id = id
        self.routineID = routine.id
        self.dayKey = day.key
        self.routineDayKey = "\(routine.id.uuidString)|\(day.key)"
        self.completedAt = completedAt
        self.routine = routine
    }
}

@Model
final class AppMetadata {
    @Attribute(.unique) var key: String
    var value: String
    var updatedAt: Date

    init(key: String, value: String, updatedAt: Date = .now) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}
