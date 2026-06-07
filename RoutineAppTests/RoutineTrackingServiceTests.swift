import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineTrackingServiceTests: XCTestCase {
    func testCompleteTodayInsertsExpectedCompletion() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let day = try makeDay(year: 2026, month: 6, day: 7)
        let now = makeDate(year: 2026, month: 6, day: 7, hour: 9, minute: 15, calendar: calendar.calendar)
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let firstRoutine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
        let secondRoutine = try insertRoutine(name: "Read", targetCount: 4, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
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
        let routine = try insertRoutine(name: "Walk", targetCount: 3, period: .weekly, into: context)
        let service = RoutineTrackingService(context: context, routineCalendar: calendar)
        let progressCalculator = ProgressCalculator(routineCalendar: calendar)
        let june8 = makeDate(year: 2026, month: 6, day: 8, hour: 9, minute: 0, calendar: calendar.calendar)
        let june9 = makeDate(year: 2026, month: 6, day: 9, hour: 9, minute: 0, calendar: calendar.calendar)
        let june10 = makeDate(year: 2026, month: 6, day: 10, hour: 9, minute: 0, calendar: calendar.calendar)

        _ = try service.completeToday(routineID: routine.id, now: june8)
        _ = try service.completeToday(routineID: routine.id, now: june9)
        _ = try service.completeToday(routineID: routine.id, now: june10)

        let june10Day = try makeDay(year: 2026, month: 6, day: 10)
        var routineProgress = try makeProgress(
            for: routine,
            in: context,
            today: june10Day,
            calculator: progressCalculator
        )
        XCTAssertEqual(routineProgress.completedCount, 3)
        XCTAssertTrue(routineProgress.isCompletedToday)
        XCTAssertEqual(routineProgress.lastCompletedDay, june10Day)
        XCTAssertEqual(
            try completionDays(in: context, routineID: routine.id),
            [
                try makeDay(year: 2026, month: 6, day: 8),
                try makeDay(year: 2026, month: 6, day: 9),
                june10Day,
            ]
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
        XCTAssertEqual(routineProgress.completedCount, 2)
        XCTAssertTrue(routineProgress.isCompletedToday)
        XCTAssertEqual(routineProgress.lastCompletedDay, june10Day)
        XCTAssertEqual(
            try completionDays(in: context, routineID: routine.id),
            [
                try makeDay(year: 2026, month: 6, day: 8),
                june10Day,
            ]
        )
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    private func makeCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }

    private func insertRoutine(
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        into context: ModelContext
    ) throws -> Routine {
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: name,
            targetCount: targetCount,
            period: period,
            sortOrder: 0,
            group: group
        )
        context.insert(group)
        context.insert(routine)
        try context.saveRoutineChanges()
        return routine
    }

    private func fetchCompletions(in context: ModelContext) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [SortDescriptor(\RoutineCompletion.dayKey), SortDescriptor(\RoutineCompletion.completedAt)]
        )
        return try context.fetch(descriptor)
    }

    private func completionDays(in context: ModelContext, routineID: UUID) throws -> [RoutineDay] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            predicate: #Predicate<RoutineCompletion> { completion in
                completion.routineID == routineID
            },
            sortBy: [SortDescriptor(\RoutineCompletion.dayKey)]
        )

        return try context.fetch(descriptor).compactMap { RoutineDay(key: $0.dayKey) }
    }

    private func makeProgress(
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

    private func makeDay(year: Int, month: Int, day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    private func makeDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
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
        return calendar.date(from: components)!
    }
}

private struct SimulatedTrackingSaveFailure: Error, CustomStringConvertible {
    let description = "simulated tracking save failure"
}
