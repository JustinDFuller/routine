import Foundation
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineScreenshotFixtureSeederTests: ProjectionBuilderTestCase {
    func testFullAppFixtureResetsStoreAndSeedsDeterministicCounts() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 12, minute: 0, calendar: calendar.calendar)

        let staleGroup = insertGroup(name: "Stale", sortOrder: 0, into: context)
        let staleRoutine = insertRoutine(
            seed: RoutineTestSeed(name: "Stale Routine", targetCount: 1, period: .weekly, sortOrder: 0),
            group: staleGroup,
            into: context
        )
        insertCompletion(
            routine: staleRoutine,
            day: try makeDay(year: 2026, month: 6, day: 1),
            completedAt: makeDate(year: 2026, month: 6, day: 1, calendar: calendar.calendar),
            into: context
        )
        context.insert(
            AppMetadata(
                key: "stale.metadata.key",
                value: "stale",
                updatedAt: now
            )
        )
        try saveChanges(in: context)

        try RoutineScreenshotFixtureSeeder(
            context: context,
            routineCalendar: calendar
        ).seed(.fullApp, now: now)

        XCTAssertEqual(
            try fetchGroups(in: context).map(\.name),
            [
                "Today Focus",
                "Progress Edges",
                "Monthly Maintenance",
                "Archive"
            ])
        XCTAssertEqual(try fetchRoutines(in: context).count, RoutineScreenshotFixtureSeeder.fullAppRoutineCount)
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<RoutineCompletion>()).count,
            RoutineScreenshotFixtureSeeder.fullAppCompletionCount
        )
        XCTAssertEqual(
            try context.fetch(FetchDescriptor<RoutineGroup>()).count,
            RoutineScreenshotFixtureSeeder.fullAppGroupCount
        )
        XCTAssertTrue(try context.fetch(FetchDescriptor<AppMetadata>()).isEmpty)
    }

    func testFullAppFixtureSeedsExpectedRoutineAvailabilityAndHistory() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 12, minute: 0, calendar: calendar.calendar)

        try RoutineScreenshotFixtureSeeder(
            context: context,
            routineCalendar: calendar
        ).seed(.fullApp, now: now)

        let archive = try XCTUnwrap(try group(named: "Archive", in: context))
        let lunchWalk = try XCTUnwrap(try routine(named: "Lunch walk", in: context))
        let wakeUpEarly = try XCTUnwrap(try routine(named: "Wake up early", in: context))
        let eveningYoga = try XCTUnwrap(try routine(named: "Evening yoga", in: context))
        let walkTheDog = try XCTUnwrap(try routine(named: "Walk the dog", in: context))

        XCTAssertEqual(archive.routines.count, 0)
        XCTAssertEqual(lunchWalk.availabilityStartMinute, 11 * 60)
        XCTAssertEqual(lunchWalk.availabilityEndMinute, 14 * 60)
        XCTAssertEqual(wakeUpEarly.availabilityStartMinute, 0)
        XCTAssertEqual(wakeUpEarly.availabilityEndMinute, 6 * 60 + 45)
        XCTAssertEqual(eveningYoga.availabilityStartMinute, 23 * 60)
        XCTAssertEqual(eveningYoga.availabilityEndMinute, 3 * 60)
        XCTAssertEqual(wakeUpEarly.availabilityBlockMode, .soft)
        XCTAssertEqual(eveningYoga.availabilityBlockMode, .hard)
        XCTAssertEqual(
            try completionDays(for: walkTheDog, in: context),
            [
                "2026-05-30",
                "2026-06-02",
                "2026-06-04",
                "2026-06-06",
                "2026-06-08",
                "2026-06-09",
                "2026-06-10"
            ])
    }

    private func fetchGroups(in context: ModelContext) throws -> [RoutineGroup] {
        try context.fetch(
            FetchDescriptor<RoutineGroup>(
                sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
            )
        )
    }

    private func fetchRoutines(in context: ModelContext) throws -> [Routine] {
        try context.fetch(
            FetchDescriptor<Routine>(
                sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
            )
        )
    }

    private func group(
        named name: String,
        in context: ModelContext
    ) throws -> RoutineGroup? {
        try context.fetch(
            FetchDescriptor<RoutineGroup>(
                predicate: #Predicate<RoutineGroup> { group in
                    group.name == name
                }
            )
        ).first
    }

    private func routine(
        named name: String,
        in context: ModelContext
    ) throws -> Routine? {
        try context.fetch(
            FetchDescriptor<Routine>(
                predicate: #Predicate<Routine> { routine in
                    routine.name == name
                }
            )
        ).first
    }

    private func completionDays(
        for routine: Routine,
        in context: ModelContext
    ) throws -> [String] {
        let routineID = routine.id
        return try context.fetch(
            FetchDescriptor<RoutineCompletion>(
                predicate: #Predicate<RoutineCompletion> { completion in
                    completion.routineID == routineID
                },
                sortBy: [SortDescriptor(\RoutineCompletion.dayKey)]
            )
        ).map(\.dayKey)
    }
}
