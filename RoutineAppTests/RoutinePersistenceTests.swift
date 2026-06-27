import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutinePersistenceTests: XCTestCase {
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

    func testInMemoryContainerCreatesAllModels() throws {
        let context = try makeContext()
        let day = try makeDay(year: 2026, month: 6, day: 7)

        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let completion = RoutineCompletion(routine: routine, day: day)
        let metadata = AppMetadata(key: "seedVersion", value: "0")

        context.insert(group)
        context.insert(routine)
        context.insert(completion)
        context.insert(metadata)

        XCTAssertNoThrow(try context.saveRoutineChanges())
    }

    func testFetchesGroupRoutineCompletionAndMetadataByStableIdentity() throws {
        let context = try makeContext()
        let groupID = UUID()
        let routineID = UUID()
        let completionID = UUID()
        let day = try makeDay(year: 2026, month: 6, day: 7)

        let group = RoutineGroup(id: groupID, name: "Health", sortOrder: 0)
        let routine = Routine(
            id: routineID,
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let completion = RoutineCompletion(id: completionID, routine: routine, day: day)
        let metadata = AppMetadata(key: "seedVersion", value: "0")

        context.insert(group)
        context.insert(routine)
        context.insert(completion)
        context.insert(metadata)
        try context.saveRoutineChanges()

        XCTAssertEqual(try context.group(id: groupID).id, groupID)
        XCTAssertEqual(try context.routine(id: routineID).id, routineID)
        XCTAssertEqual(try context.completion(id: completionID).id, completionID)
        XCTAssertEqual(try context.metadata(key: "seedVersion").key, "seedVersion")
    }

    func testRoutineStoresGroupRelationshipAndStableGroupID() throws {
        let context = try makeContext()
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )

        context.insert(group)
        context.insert(routine)
        try context.saveRoutineChanges()

        XCTAssertEqual(routine.groupID, group.id)
        XCTAssertEqual(routine.group?.id, group.id)
    }

    func testRoutinePeriodBridgesToRoutineCoreEnum() {
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )

        XCTAssertEqual(routine.periodRawValue, "weekly")
        XCTAssertEqual(routine.period, .weekly)

        routine.period = .monthly

        XCTAssertEqual(routine.periodRawValue, "monthly")
        XCTAssertEqual(routine.period, .monthly)
    }

    func testCompletionDayIdentityUsesRoutineDayKey() throws {
        let day = try makeDay(year: 2026, month: 6, day: 7)
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let completion = RoutineCompletion(routine: routine, day: day)

        XCTAssertEqual(completion.dayKey, "2026-06-07")
        XCTAssertEqual(completion.routineID, routine.id)
        XCTAssertEqual(completion.routineDayKey, "\(routine.id.uuidString)|2026-06-07")
    }

    func testFetchesCompletionByRoutineDayIdentity() throws {
        let context = try makeContext()
        let day = try makeDay(year: 2026, month: 6, day: 7)
        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let completion = RoutineCompletion(routine: routine, day: day)

        context.insert(group)
        context.insert(routine)
        context.insert(completion)
        try context.saveRoutineChanges()

        let fetchedBySplitKey = try context.completion(routineID: routine.id, dayKey: day.key)
        let fetchedByCombinedKey = try context.completion(routineDayKey: completion.routineDayKey)

        XCTAssertEqual(fetchedBySplitKey?.id, completion.id)
        XCTAssertEqual(fetchedByCombinedKey?.id, completion.id)
    }

    func testDuplicateRoutineDayIsGuardedByHelper() throws {
        let context = try makeContext()
        let day = try makeDay(year: 2026, month: 6, day: 7)
        let otherDay = try makeDay(year: 2026, month: 6, day: 8)

        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let otherRoutine = Routine(
            name: "Read",
            targetCount: 4,
            period: .weekly,
            sortOrder: 1,
            group: group
        )
        let completion = RoutineCompletion(routine: routine, day: day)

        context.insert(group)
        context.insert(routine)
        context.insert(otherRoutine)
        context.insert(completion)
        try context.saveRoutineChanges()

        XCTAssertThrowsError(try context.ensureNoCompletion(routineID: routine.id, dayKey: day.key)) { error in
            XCTAssertEqual(
                error as? PersistenceError,
                .duplicateRoutineCompletion(routineID: routine.id, dayKey: day.key)
            )
        }

        XCTAssertNoThrow(try context.ensureNoCompletion(routineID: routine.id, dayKey: otherDay.key))
        XCTAssertNoThrow(try context.ensureNoCompletion(routineID: otherRoutine.id, dayKey: day.key))
    }

    func testGlobalBreakRoundTripsResumeDayKey() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let resumeDay = try makeDay(year: 2026, month: 6, day: 29)

        try context.setGlobalBreak(resumeDay: resumeDay)

        XCTAssertEqual(context.globalBreak(routineCalendar: calendar), GlobalBreak(resumeDay: resumeDay))
    }

    func testGlobalBreakDecodesLegacyCurrentBranchPayload() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let legacyPayload = #"{"anchorDayKey":"2026-06-22","skipPeriods":1}"#
        context.insert(AppMetadata(key: "global.pause", value: legacyPayload))

        let globalBreak = context.globalBreak(routineCalendar: calendar)

        XCTAssertEqual(globalBreak, GlobalBreak(resumeDay: try makeDay(year: 2026, month: 7, day: 1)))
    }

    func testClearingGlobalBreakRemovesCurrentAndLegacyPayloads() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        try context.setGlobalBreak(resumeDay: try makeDay(year: 2026, month: 6, day: 29))
        context.insert(
            AppMetadata(
                key: "global.pause",
                value: #"{"anchorDayKey":"2026-06-22","skipPeriods":1}"#
            )
        )

        try context.clearGlobalBreak()

        XCTAssertNil(context.globalBreak(routineCalendar: calendar))
    }

    func testSaveRoutineChangesMapsThrownSaveFailure() throws {
        let context = try makeContext()
        let originalSave = RoutinePersistenceSaveExecutor.save
        defer { RoutinePersistenceSaveExecutor.save = originalSave }

        RoutinePersistenceSaveExecutor.save = { _ in
            throw SimulatedSaveFailure()
        }

        do {
            try context.saveRoutineChanges()
            XCTFail("Expected saveRoutineChanges() to throw.")
        } catch let error as PersistenceError {
            guard case .saveFailed(let diagnostic) = error else {
                return XCTFail("Expected saveFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to save changes.")
            XCTAssertEqual(diagnostic, "simulated save failure")
            XCTAssertFalse(diagnostic.isEmpty)
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }
    }

    func testRoutineFetchMapsThrownFetchFailure() throws {
        let context = try makeContext()
        let originalFetch = RoutinePersistenceFetchExecutor.fetchRoutines
        defer { RoutinePersistenceFetchExecutor.fetchRoutines = originalFetch }

        RoutinePersistenceFetchExecutor.fetchRoutines = { _, _ in
            throw SimulatedFetchFailure()
        }

        do {
            _ = try context.routine(id: UUID())
            XCTFail("Expected routine(id:) to throw.")
        } catch let error as PersistenceError {
            guard case .fetchFailed(let diagnostic) = error else {
                return XCTFail("Expected fetchFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to load data.")
            XCTAssertEqual(diagnostic, "simulated fetch failure")
            XCTAssertFalse(diagnostic.isEmpty)
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }
    }

    func testCompletionByRoutineDayMapsThrownFetchFailure() throws {
        let context = try makeContext()
        let originalFetch = RoutinePersistenceFetchExecutor.fetchCompletions
        defer { RoutinePersistenceFetchExecutor.fetchCompletions = originalFetch }

        RoutinePersistenceFetchExecutor.fetchCompletions = { _, _ in
            throw SimulatedFetchFailure()
        }

        do {
            _ = try context.completion(routineID: UUID(), dayKey: "2026-06-07")
            XCTFail("Expected completion(routineID:dayKey:) to throw.")
        } catch let error as PersistenceError {
            guard case .fetchFailed(let diagnostic) = error else {
                return XCTFail("Expected fetchFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to load data.")
            XCTAssertEqual(diagnostic, "simulated fetch failure")
            XCTAssertFalse(diagnostic.isEmpty)
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }
    }

    func testDeletingRoutineCascadesCompletions() throws {
        let context = try makeContext()
        let firstDay = try makeDay(year: 2026, month: 6, day: 7)
        let secondDay = try makeDay(year: 2026, month: 6, day: 8)

        let group = RoutineGroup(name: "Health", sortOrder: 0)
        let routine = Routine(
            name: "Walk",
            targetCount: 3,
            period: .weekly,
            sortOrder: 0,
            group: group
        )
        let firstCompletion = RoutineCompletion(routine: routine, day: firstDay)
        let secondCompletion = RoutineCompletion(routine: routine, day: secondDay)

        context.insert(group)
        context.insert(routine)
        context.insert(firstCompletion)
        context.insert(secondCompletion)
        try context.saveRoutineChanges()

        context.delete(routine)
        try context.saveRoutineChanges()

        XCTAssertThrowsError(try context.completion(id: firstCompletion.id)) { error in
            XCTAssertEqual(error as? PersistenceError, .completionNotFound(firstCompletion.id))
        }
        XCTAssertThrowsError(try context.completion(id: secondCompletion.id)) { error in
            XCTAssertEqual(error as? PersistenceError, .completionNotFound(secondCompletion.id))
        }
    }

    func testMissingStableIDFetchesThrowTypedErrors() throws {
        let context = try makeContext()
        let routineID = UUID()
        let groupID = UUID()
        let completionID = UUID()

        XCTAssertThrowsError(try context.routine(id: routineID)) { error in
            XCTAssertEqual(error as? PersistenceError, .routineNotFound(routineID))
        }
        XCTAssertThrowsError(try context.group(id: groupID)) { error in
            XCTAssertEqual(error as? PersistenceError, .groupNotFound(groupID))
        }
        XCTAssertThrowsError(try context.completion(id: completionID)) { error in
            XCTAssertEqual(error as? PersistenceError, .completionNotFound(completionID))
        }
        XCTAssertThrowsError(try context.metadata(key: "seedVersion")) { error in
            XCTAssertEqual(error as? PersistenceError, .metadataNotFound("seedVersion"))
        }
    }

    func testPersistenceErrorDescriptionsAreUserSafe() {
        XCTAssertEqual(PersistenceError.routineNotFound(UUID()).errorDescription, "Routine not found.")
        XCTAssertEqual(PersistenceError.groupNotFound(UUID()).errorDescription, "Group not found.")
        XCTAssertEqual(PersistenceError.completionNotFound(UUID()).errorDescription, "Completion not found.")
        XCTAssertEqual(PersistenceError.metadataNotFound("seedVersion").errorDescription, "Metadata not found.")
        XCTAssertEqual(
            PersistenceError.duplicateRoutineCompletion(routineID: UUID(), dayKey: "2026-06-07").errorDescription,
            "Completion already exists for that day."
        )
        XCTAssertEqual(PersistenceError.fetchFailed("sqlite busy").errorDescription, "Unable to load data.")
        XCTAssertEqual(PersistenceError.saveFailed("disk full").errorDescription, "Unable to save changes.")
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    private func makeDay(year: Int, month: Int, day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    private func makeCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }
}

private struct SimulatedSaveFailure: Error, CustomStringConvertible {
    let description = "simulated save failure"
}

private struct SimulatedFetchFailure: Error, CustomStringConvertible {
    let description = "simulated fetch failure"
}
