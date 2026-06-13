import Foundation
import RoutineCore
import SwiftData

enum RoutineScreenshotFixture: String, Equatable, Sendable {
    case fullApp = "full-app"
}

@MainActor
final class RoutineScreenshotFixtureSeeder {
    private let context: ModelContext
    private let routineCalendar: RoutineCalendar

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current) {
        self.context = context
        self.routineCalendar = routineCalendar
    }

    func seed(_ fixture: RoutineScreenshotFixture, now: Date) throws {
        switch fixture {
        case .fullApp:
            try seedFullApp(now: now)
        }
    }

    static var fullAppGroupCount: Int {
        FullAppSeed.groups.count
    }

    static var fullAppRoutineCount: Int {
        FullAppSeed.groups.reduce(into: 0) { count, group in
            count += group.routines.count
        }
    }

    static var fullAppCompletionCount: Int {
        FullAppSeed.completions.count
    }

    private func seedFullApp(now: Date) throws {
        try RoutineStoreResetService.resetAllData(in: context)
        let groups = makeGroups(now: now)
        let routinesByName = try seedRoutines(in: groups, now: now)
        try seedCompletions(for: routinesByName)
        try context.saveRoutineChanges()
    }

    private func makeGroups(now: Date) -> [UUID: RoutineGroup] {
        let groups = FullAppSeed.groups.map { seed in
            RoutineGroup(
                id: seed.id,
                name: seed.name,
                sortOrder: seed.sortOrder,
                createdAt: now,
                updatedAt: now
            )
        }

        for group in groups {
            context.insert(group)
        }

        return Dictionary(uniqueKeysWithValues: groups.map { ($0.id, $0) })
    }

    private func seedRoutines(
        in groupsByID: [UUID: RoutineGroup],
        now: Date
    ) throws -> [String: Routine] {
        var routinesByName: [String: Routine] = [:]

        for groupSeed in FullAppSeed.groups {
            guard let group = groupsByID[groupSeed.id] else {
                throw ScreenshotFixtureSeedError.missingGroup(groupSeed.name)
            }

            for routineSeed in groupSeed.routines {
                let routine = Routine(
                    id: routineSeed.id,
                    name: routineSeed.name,
                    targetCount: routineSeed.targetCount,
                    period: routineSeed.period,
                    availabilityStartMinute: routineSeed.availabilityStartMinute,
                    availabilityEndMinute: routineSeed.availabilityEndMinute,
                    sortOrder: routineSeed.sortOrder,
                    group: group,
                    createdAt: now,
                    updatedAt: now
                )
                context.insert(routine)
                routinesByName[routineSeed.name] = routine
            }
        }

        return routinesByName
    }

    private func seedCompletions(
        for routinesByName: [String: Routine]
    ) throws {
        for completionSeed in FullAppSeed.completions {
            guard let routine = routinesByName[completionSeed.routineName] else {
                throw ScreenshotFixtureSeedError.missingRoutine(completionSeed.routineName)
            }

            context.insert(
                RoutineCompletion(
                    id: completionSeed.id,
                    routine: routine,
                    day: makeDay(
                        year: completionSeed.year,
                        month: completionSeed.month,
                        day: completionSeed.day
                    ),
                    completedAt: makeDate(
                        year: completionSeed.year,
                        month: completionSeed.month,
                        day: completionSeed.day,
                        hour: completionSeed.hour,
                        minute: completionSeed.minute
                    )
                )
            )
        }
    }

    private func makeDay(year: Int, month: Int, day: Int) -> RoutineDay {
        guard let routineDay = RoutineDay(year: year, month: month, day: day) else {
            preconditionFailure("Expected valid screenshot fixture day \(year)-\(month)-\(day).")
        }

        return routineDay
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) -> Date {
        var components = DateComponents()
        components.calendar = routineCalendar.calendar
        components.timeZone = routineCalendar.calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        guard let date = routineCalendar.calendar.date(from: components) else {
            preconditionFailure(
                "Expected valid screenshot fixture date \(year)-\(month)-\(day) \(hour):\(minute)."
            )
        }

        return date
    }
}

private enum FullAppSeed {
    static let groups: [FixtureGroupSeed] = [
        FixtureGroupSeed(
            id: uuid("00000000-0000-0000-0000-000000000201"),
            name: "Today Focus",
            sortOrder: 0,
            routines: [
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000301"),
                    name: "Morning yoga",
                    targetCount: 5,
                    period: .weekly,
                    sortOrder: 0
                ),
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000302"),
                    name: "Walk the dog",
                    targetCount: 5,
                    period: .weekly,
                    sortOrder: 1
                ),
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000303"),
                    name: "Lunch walk",
                    targetCount: 3,
                    period: .weekly,
                    availabilityStartMinute: 11 * 60,
                    availabilityEndMinute: 14 * 60,
                    sortOrder: 2
                ),
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000304"),
                    name: "Wake up early",
                    targetCount: 4,
                    period: .weekly,
                    availabilityStartMinute: 0,
                    availabilityEndMinute: 6 * 60 + 45,
                    sortOrder: 3
                )
            ]
        ),
        FixtureGroupSeed(
            id: uuid("00000000-0000-0000-0000-000000000202"),
            name: "Progress Edges",
            sortOrder: 1,
            routines: [
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000305"),
                    name: "Evening yoga",
                    targetCount: 4,
                    period: .weekly,
                    availabilityStartMinute: 23 * 60,
                    availabilityEndMinute: 3 * 60,
                    sortOrder: 0
                ),
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000306"),
                    name: "Water plants",
                    targetCount: 1,
                    period: .weekly,
                    sortOrder: 1
                ),
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000307"),
                    name: "Run razor cleaner",
                    targetCount: 1,
                    period: .weekly,
                    sortOrder: 2
                )
            ]
        ),
        FixtureGroupSeed(
            id: uuid("00000000-0000-0000-0000-000000000203"),
            name: "Monthly Maintenance",
            sortOrder: 2,
            routines: [
                FixtureRoutineSeed(
                    id: uuid("00000000-0000-0000-0000-000000000308"),
                    name: "Clean air purifiers",
                    targetCount: 1,
                    period: .monthly,
                    sortOrder: 0
                )
            ]
        ),
        FixtureGroupSeed(
            id: uuid("00000000-0000-0000-0000-000000000204"),
            name: "Archive",
            sortOrder: 3,
            routines: []
        )
    ]

    static let completions: [FixtureCompletionSeed] = [
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000401"),
            routineName: "Morning yoga",
            year: 2026,
            month: 6,
            day: 8,
            hour: 7,
            minute: 15
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000402"),
            routineName: "Morning yoga",
            year: 2026,
            month: 6,
            day: 9,
            hour: 7,
            minute: 10
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000403"),
            routineName: "Walk the dog",
            year: 2026,
            month: 5,
            day: 30,
            hour: 9,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000404"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 2,
            hour: 9,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000405"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 4,
            hour: 9,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000406"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 6,
            hour: 9,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000407"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 8,
            hour: 8,
            minute: 10
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000408"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 9,
            hour: 8,
            minute: 5
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000409"),
            routineName: "Walk the dog",
            year: 2026,
            month: 6,
            day: 10,
            hour: 8,
            minute: 15
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000410"),
            routineName: "Lunch walk",
            year: 2026,
            month: 6,
            day: 9,
            hour: 12,
            minute: 30
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000411"),
            routineName: "Wake up early",
            year: 2026,
            month: 6,
            day: 9,
            hour: 6,
            minute: 20
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000412"),
            routineName: "Evening yoga",
            year: 2026,
            month: 6,
            day: 9,
            hour: 23,
            minute: 30
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000413"),
            routineName: "Water plants",
            year: 2026,
            month: 6,
            day: 9,
            hour: 18,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000414"),
            routineName: "Run razor cleaner",
            year: 2026,
            month: 6,
            day: 8,
            hour: 21,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000415"),
            routineName: "Run razor cleaner",
            year: 2026,
            month: 6,
            day: 9,
            hour: 21,
            minute: 0
        ),
        FixtureCompletionSeed(
            id: uuid("00000000-0000-0000-0000-000000000416"),
            routineName: "Clean air purifiers",
            year: 2026,
            month: 6,
            day: 3,
            hour: 10,
            minute: 0
        )
    ]

    private static func uuid(_ rawValue: String) -> UUID {
        guard let id = UUID(uuidString: rawValue) else {
            preconditionFailure("Expected valid screenshot fixture UUID \(rawValue).")
        }

        return id
    }
}

private struct FixtureGroupSeed {
    let id: UUID
    let name: String
    let sortOrder: Int
    let routines: [FixtureRoutineSeed]
}

private struct FixtureRoutineSeed {
    let id: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let availabilityStartMinute: Int?
    let availabilityEndMinute: Int?
    let sortOrder: Int

    init(
        id: UUID,
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        availabilityStartMinute: Int? = nil,
        availabilityEndMinute: Int? = nil,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.availabilityStartMinute = availabilityStartMinute
        self.availabilityEndMinute = availabilityEndMinute
        self.sortOrder = sortOrder
    }
}

private struct FixtureCompletionSeed {
    let id: UUID
    let routineName: String
    let year: Int
    let month: Int
    let day: Int
    let hour: Int
    let minute: Int
}

private enum ScreenshotFixtureSeedError: Error {
    case missingGroup(String)
    case missingRoutine(String)
}
