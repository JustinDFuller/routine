import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
class RoutineTrackingServiceTestCase: XCTestCase {
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
        calendar.firstWeekday = 1
        return RoutineCalendar(calendar: calendar)
    }

    func insertRoutine(
        seed: RoutineTestSeed,
        into context: ModelContext
    ) throws -> Routine {
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            id: seed.id,
            name: seed.name,
            targetCount: seed.targetCount,
            period: seed.period,
            availabilityStartMinute: seed.availabilityStartMinute,
            availabilityEndMinute: seed.availabilityEndMinute,
            sortOrder: seed.sortOrder,
            group: group
        )
        context.insert(group)
        context.insert(routine)
        try context.saveRoutineChanges()
        return routine
    }

    func fetchCompletions(in context: ModelContext) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [SortDescriptor(\RoutineCompletion.dayKey), SortDescriptor(\RoutineCompletion.completedAt)]
        )
        return try context.fetch(descriptor)
    }

    func completionDays(in context: ModelContext, routineID: UUID) throws -> [RoutineDay] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.routineID == routineID
            },
            sortBy: [SortDescriptor(\RoutineCompletion.dayKey)]
        )

        return try context.fetch(descriptor).compactMap { RoutineDay(key: $0.dayKey) }
    }

    func makeProgress(
        for routine: Routine,
        in context: ModelContext,
        today: RoutineDay,
        calculator: ProgressCalculator
    ) throws -> RoutineProgress {
        calculator.progress(
            period: routine.period,
            targetCount: routine.targetCount,
            completionDays: try completionDays(in: context, routineID: routine.id),
            today: today
        )
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
        calendar: Calendar
    ) -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute

        guard let date = calendar.date(from: components) else {
            preconditionFailure("Unable to build date for \(year)-\(month)-\(day) \(hour):\(minute).")
        }

        return date
    }
}

@MainActor
final class RoutineTrackingServiceCompletionTests: RoutineTrackingServiceTestCase {
    func testCompleteTodayInsertsExpectedCompletion() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let day = try makeDay(year: 2026, month: 6, day: 7)
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 9, minute: 15, calendar: calendar.calendar)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)

        let result = try service.completeToday(routineID: routine.id, now: now)
        let completions = try fetchCompletions(in: context)

        XCTAssertEqual(
            result,
            CompletionResult(routineID: routine.id, routineName: "Walk", day: day, didInsert: true)
        )
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions[0].routineID, routine.id)
        XCTAssertEqual(completions[0].dayKey, day.key)
        XCTAssertEqual(completions[0].routineDayKey, "\(routine.id.uuidString)|\(day.key)")
        XCTAssertEqual(completions[0].completedAt, now)
    }

    func testCompleteTodayIsIdempotentForSameRoutineAndLocalDay() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let firstNow = makeDate(year: 2026, month: 6, day: 7, hour: 8, minute: 0, calendar: calendar.calendar)
        let secondNow = makeDate(year: 2026, month: 6, day: 7, hour: 20, minute: 30, calendar: calendar.calendar)

        _ = try service.completeToday(routineID: routine.id, now: firstNow)
        let secondResult = try service.completeToday(routineID: routine.id, now: secondNow)
        let completions = try fetchCompletions(in: context)

        XCTAssertEqual(secondResult.didInsert, false)
        XCTAssertEqual(completions.count, 1)
        XCTAssertEqual(completions[0].completedAt, firstNow)
    }

    func testCompleteTodayCreatesIndependentCompletionsForDifferentRoutines() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let firstRoutine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let secondRoutine = try insertRoutine(
            seed: RoutineTestSeed(name: "Read", targetCount: 4, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 10, minute: 0, calendar: calendar.calendar)

        _ = try service.completeToday(routineID: firstRoutine.id, now: now)
        _ = try service.completeToday(routineID: secondRoutine.id, now: now)

        let completions = try fetchCompletions(in: context)
        XCTAssertEqual(Set(completions.map(\.routineID)), [firstRoutine.id, secondRoutine.id])
        XCTAssertEqual(Set(completions.map(\.dayKey)), ["2026-06-07"])
    }

    func testCompleteTodayCreatesSeparateCompletionsAcrossDays() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)

        _ = try service.completeToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 7, hour: 9, minute: 0, calendar: calendar.calendar)
        )
        _ = try service.completeToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 8, hour: 9, minute: 0, calendar: calendar.calendar)
        )

        let completions = try fetchCompletions(in: context)
        XCTAssertEqual(completions.map(\.dayKey), ["2026-06-07", "2026-06-08"])
    }

    func testUndoTodayRemovesOnlyTodaysCompletion() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let previousDay = try makeDay(year: 2026, month: 6, day: 6)
        let today = try makeDay(year: 2026, month: 6, day: 7)
        let historicalCompletion = RoutineCompletion(
            routine: routine,
            day: previousDay,
            completedAt: makeDate(year: 2026, month: 6, day: 6, hour: 18, minute: 0, calendar: calendar.calendar)
        )
        let todayCompletion = RoutineCompletion(
            routine: routine,
            day: today,
            completedAt: makeDate(year: 2026, month: 6, day: 7, hour: 9, minute: 0, calendar: calendar.calendar)
        )

        context.insert(historicalCompletion)
        context.insert(todayCompletion)
        try context.saveRoutineChanges()

        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let result = try service.undoToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 7, hour: 21, minute: 0, calendar: calendar.calendar)
        )

        let completions = try fetchCompletions(in: context)
        XCTAssertEqual(result, UndoResult(routineID: routine.id, day: today, didRemove: true))
        XCTAssertEqual(completions.map(\.id), [historicalCompletion.id])
        XCTAssertEqual(completions.map(\.dayKey), [previousDay.key])
    }

    func testUndoTodayWithoutExistingCompletionReturnsFalseWithoutThrowing() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let today = try makeDay(year: 2026, month: 6, day: 7)

        let result = try service.undoToday(
            routineID: routine.id,
            now: makeDate(year: 2026, month: 6, day: 7, hour: 12, minute: 0, calendar: calendar.calendar)
        )

        XCTAssertEqual(result, UndoResult(routineID: routine.id, day: today, didRemove: false))
        XCTAssertTrue(try fetchCompletions(in: context).isEmpty)
    }

    func testRemoveCompletionDeletesOnlySelectedHistoricalCompletion() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let firstCompletion = RoutineCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 5),
            completedAt: makeDate(year: 2026, month: 6, day: 5, hour: 9, minute: 0, calendar: calendar.calendar)
        )
        let secondCompletion = RoutineCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 6),
            completedAt: makeDate(year: 2026, month: 6, day: 6, hour: 9, minute: 0, calendar: calendar.calendar)
        )

        context.insert(firstCompletion)
        context.insert(secondCompletion)
        try context.saveRoutineChanges()

        try RoutineTrackingService(context: context, routineCalendar: calendar)
            .removeCompletion(completionID: firstCompletion.id)

        let completions = try fetchCompletions(in: context)
        XCTAssertEqual(completions.map(\.id), [secondCompletion.id])
        XCTAssertEqual(completions.map(\.dayKey), ["2026-06-06"])
    }
}

@MainActor
final class RoutineTrackingServicePersistenceTests: RoutineTrackingServiceTestCase {
    func testCompleteTodayWithMissingRoutineThrowsTypedUserSafeError() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let missingID = UUID()

        XCTAssertThrowsError(
            try RoutineTrackingService(context: context, routineCalendar: calendar).completeToday(routineID: missingID)
        ) { error in
            XCTAssertEqual(error as? PersistenceError, .routineNotFound(missingID))
            XCTAssertEqual((error as? PersistenceError)?.errorDescription, "Routine not found.")
        }
    }

    func testRemoveCompletionWithMissingCompletionThrowsTypedUserSafeError() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let missingID = UUID()

        XCTAssertThrowsError(
            try RoutineTrackingService(context: context, routineCalendar: calendar)
                .removeCompletion(completionID: missingID)
        ) { error in
            XCTAssertEqual(error as? PersistenceError, .completionNotFound(missingID))
            XCTAssertEqual((error as? PersistenceError)?.errorDescription, "Completion not found.")
        }
    }

    func testCompleteTodayMapsSaveFailureAndLeavesContextCleanForRetry() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 9, minute: 0, calendar: calendar.calendar)
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let originalSave = RoutinePersistenceSaveExecutor.save
        defer { RoutinePersistenceSaveExecutor.save = originalSave }

        RoutinePersistenceSaveExecutor.save = { _ in
            throw SimulatedTrackingSaveFailure()
        }

        do {
            _ = try service.completeToday(routineID: routine.id, now: now)
            XCTFail("Expected completeToday to throw.")
        } catch let error as PersistenceError {
            guard case .saveFailed(let diagnostic) = error else {
                return XCTFail("Expected saveFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to save changes.")
            XCTAssertEqual(diagnostic, "simulated tracking save failure")
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }

        XCTAssertTrue(try fetchCompletions(in: context).isEmpty)

        RoutinePersistenceSaveExecutor.save = originalSave

        let retryResult = try service.completeToday(routineID: routine.id, now: now)
        XCTAssertTrue(retryResult.didInsert)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testProgressAfterCompletionAndRemovalMatchesExpectedState() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let routine = try insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            into: context
        )
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let progressCalculator = ProgressCalculator(routineCalendar: calendar)
        try completeDays([8, 9, 10], routineID: routine.id, service: service, calendar: calendar)

        let june10Day = try makeDay(year: 2026, month: 6, day: 10)
        var routineProgress = try makeProgress(
            for: routine,
            in: context,
            today: june10Day,
            calculator: progressCalculator
        )
        try assertProgressState(
            routineProgress,
            today: june10Day,
            expectedCount: 3
        )
        try assertCompletionDays(
            in: context,
            routineID: routine.id,
            expected: try routineDays([8, 9, 10])
        )

        let june9Completion = try XCTUnwrap(
            try fetchCompletions(in: context).first { $0.dayKey == "2026-06-09" }
        )
        try service.removeCompletion(completionID: june9Completion.id)

        routineProgress = try makeProgress(
            for: routine,
            in: context,
            today: june10Day,
            calculator: progressCalculator
        )
        try assertProgressState(
            routineProgress,
            today: june10Day,
            expectedCount: 2
        )
        try assertCompletionDays(
            in: context,
            routineID: routine.id,
            expected: try routineDays([8, 10])
        )
    }

    private func assertProgressState(
        _ progress: RoutineProgress,
        today: RoutineDay,
        expectedCount: Int
    ) throws {
        XCTAssertEqual(progress.completedCount, expectedCount)
        XCTAssertTrue(progress.isCompletedToday)
        XCTAssertEqual(progress.lastCompletedDay, today)
    }

    private func assertCompletionDays(
        in context: ModelContext,
        routineID: UUID,
        expected: [RoutineDay]
    ) throws {
        XCTAssertEqual(try completionDays(in: context, routineID: routineID), expected)
    }

    private func completeDays(
        _ days: [Int],
        routineID: UUID,
        service: RoutineTrackingService,
        calendar: RoutineCalendar
    ) throws {
        for day in days {
            _ = try service.completeToday(
                routineID: routineID,
                now: makeDate(year: 2026, month: 6, day: day, hour: 9, calendar: calendar.calendar)
            )
        }
    }

    private func routineDays(_ days: [Int]) throws -> [RoutineDay] {
        try days.map { try makeDay(year: 2026, month: 6, day: $0) }
    }
}

private struct SimulatedTrackingSaveFailure: Error, CustomStringConvertible {
    let description = "simulated tracking save failure"
}
