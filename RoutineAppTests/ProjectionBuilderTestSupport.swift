import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
class ProjectionBuilderTestCase: XCTestCase {
    override func tearDown() {
        MainActor.assumeIsolated {
            RoutinePersistenceFetchExecutor.fetchRoutines = { context, descriptor in
                try context.fetch(descriptor)
            }
            RoutinePersistenceFetchExecutor.fetchGroups = { context, descriptor in
                try context.fetch(descriptor)
            }
            RoutinePersistenceFetchExecutor.fetchCompletions = { context, descriptor in
                try context.fetch(descriptor)
            }
            RoutinePersistenceFetchExecutor.fetchMetadata = { context, descriptor in
                try context.fetch(descriptor)
            }
        }
        super.tearDown()
    }

    func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    func makeCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        guard let timeZone = TimeZone(identifier: "America/New_York") else {
            preconditionFailure("Expected America/New_York timezone.")
        }

        calendar.timeZone = timeZone
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }

    func saveChanges(in context: ModelContext) throws {
        try context.saveRoutineChanges()
    }

    @discardableResult
    func insertGroup(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        into context: ModelContext
    ) -> RoutineGroup {
        let group = RoutineGroup(
            id: id,
            name: name,
            sortOrder: sortOrder,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        context.insert(group)
        return group
    }

    @discardableResult
    func insertRoutine(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        sortOrder: Int,
        group: RoutineGroup,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        into context: ModelContext
    ) -> Routine {
        let routine = Routine(
            id: id,
            name: name,
            targetCount: targetCount,
            period: period,
            sortOrder: sortOrder,
            group: group,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
        context.insert(routine)
        return routine
    }

    @discardableResult
    func insertCompletion(
        id: UUID = UUID(),
        routine: Routine,
        day: RoutineDay,
        completedAt: Date,
        into context: ModelContext
    ) -> RoutineCompletion {
        let completion = RoutineCompletion(
            id: id,
            routine: routine,
            day: day,
            completedAt: completedAt
        )
        context.insert(completion)
        return completion
    }

    @discardableResult
    func insertCompletion(
        id: UUID = UUID(),
        routine: Routine,
        dayKey: String,
        routineDayKey: String? = nil,
        completedAt: Date,
        into context: ModelContext
    ) throws -> RoutineCompletion {
        let placeholderDay = try makeDay(year: 2026, month: 1, day: 1)
        let completion = RoutineCompletion(
            id: id,
            routine: routine,
            day: placeholderDay,
            completedAt: completedAt
        )
        completion.dayKey = dayKey
        completion.routineDayKey = routineDayKey ?? "\(routine.id.uuidString)|\(dayKey)|\(id.uuidString)"
        context.insert(completion)
        return completion
    }

    func makeDay(year: Int, month: Int, day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 12,
        minute: Int = 0,
        calendar: Calendar? = nil
    ) -> Date {
        let resolvedCalendar = calendar ?? makeCalendar().calendar
        var components = DateComponents()
        components.calendar = resolvedCalendar
        components.timeZone = resolvedCalendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        guard let date = resolvedCalendar.date(from: components) else {
            preconditionFailure("Unable to build date for \(year)-\(month)-\(day) \(hour):\(minute).")
        }

        return date
    }
}

struct SimulatedProjectionFetchFailure: Error, CustomStringConvertible {
    let description = "simulated projection fetch failure"
}
