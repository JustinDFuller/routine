import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class StarterDataServiceTests: XCTestCase {
    func testEmptyStoreSeedsExpectedGroupRoutineAndMetadataCounts() throws {
        let context = try makeContext()
        let now = Date(timeIntervalSinceReferenceDate: 123_456)

        try StarterDataService(context: context).seedIfNeeded(now: now)

        XCTAssertEqual(try fetchGroups(in: context).count, 6)
        XCTAssertEqual(try fetchRoutines(in: context).count, 20)
        XCTAssertEqual(try fetchMetadata(in: context).count, 1)

        let metadata = try XCTUnwrap(try fetchMetadata(in: context).first)
        XCTAssertEqual(metadata.key, StarterDataService.seedMetadataKey)
        XCTAssertEqual(metadata.value, StarterDataService.seedMetadataValue)
        XCTAssertEqual(metadata.updatedAt, now)

        XCTAssertTrue(try fetchGroups(in: context).allSatisfy { $0.createdAt == now && $0.updatedAt == now })
        XCTAssertTrue(try fetchRoutines(in: context).allSatisfy { $0.createdAt == now && $0.updatedAt == now })
    }

    func testCallingSeedTwiceDoesNotDuplicateStarterData() throws {
        let context = try makeContext()
        let service = StarterDataService(context: context)

        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 1))
        let firstGroups = try fetchGroups(in: context)
        let firstRoutines = try fetchRoutines(in: context)
        let firstMetadata = try fetchMetadata(in: context)

        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 2))

        XCTAssertEqual(try fetchGroups(in: context).count, firstGroups.count)
        XCTAssertEqual(try fetchRoutines(in: context).count, firstRoutines.count)
        XCTAssertEqual(try fetchMetadata(in: context).count, firstMetadata.count)
    }

    func testExistingSeedMetadataPreventsReseedingWhenStoreHasNoGroupsOrRoutines() throws {
        let context = try makeContext()
        context.insert(
            AppMetadata(
                key: StarterDataService.seedMetadataKey,
                value: StarterDataService.seedMetadataValue,
                updatedAt: Date(timeIntervalSinceReferenceDate: 10)
            )
        )
        try context.saveRoutineChanges()

        try StarterDataService(context: context).seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 20))

        XCTAssertTrue(try fetchGroups(in: context).isEmpty)
        XCTAssertTrue(try fetchRoutines(in: context).isEmpty)
        XCTAssertEqual(try fetchMetadata(in: context).count, 1)
    }

    func testSeededGroupsAndRoutinesMatchExpectedDefinitionsAndSortOrders() throws {
        let context = try makeContext()

        try StarterDataService(context: context).seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 42))

        let groups = try fetchGroups(in: context)
        XCTAssertEqual(groups.map(\.name), ExpectedSeed.groups.map(\.name))
        XCTAssertEqual(groups.map(\.sortOrder), ExpectedSeed.groups.map(\.sortOrder))

        let routinesByGroup = Dictionary(grouping: try fetchRoutines(in: context)) { $0.group?.name ?? "" }

        for expectedGroup in ExpectedSeed.groups {
            let actualRoutines = try XCTUnwrap(routinesByGroup[expectedGroup.name])
                .sorted(using: KeyPathComparator(\Routine.sortOrder))

            XCTAssertEqual(actualRoutines.map(\.name), expectedGroup.routines.map(\.name))
            XCTAssertEqual(actualRoutines.map(\.sortOrder), expectedGroup.routines.map(\.sortOrder))
            XCTAssertEqual(actualRoutines.map(\.targetCount), expectedGroup.routines.map(\.targetCount))
            XCTAssertEqual(actualRoutines.map(\.period), expectedGroup.routines.map(\.period))
            XCTAssertTrue(actualRoutines.allSatisfy { $0.groupID == $0.group?.id })
            XCTAssertTrue(
                actualRoutines.allSatisfy {
                    $0.availabilityStartMinute == nil && $0.availabilityEndMinute == nil
                }
            )
        }
    }

    func testSeededDataRemainsEditableAndMetadataPreventsRecreation() throws {
        let context = try makeContext()
        let service = StarterDataService(context: context)

        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 100))

        let wakeUpRoutine = try XCTUnwrap(try routine(named: "Wake up early", in: context))
        wakeUpRoutine.name = "Wake up earlier"

        let basketballRoutine = try XCTUnwrap(try routine(named: "Basketball", in: context))
        let basketballID = basketballRoutine.id
        context.delete(basketballRoutine)

        try context.saveRoutineChanges()
        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 200))

        XCTAssertEqual(try fetchRoutines(in: context).count, 19)
        XCTAssertEqual(try routine(named: "Wake up earlier", in: context)?.id, wakeUpRoutine.id)
        XCTAssertNil(try routine(named: "Wake up early", in: context))
        XCTAssertThrowsError(try context.routine(id: basketballID)) { error in
            XCTAssertEqual(error as? PersistenceError, .routineNotFound(basketballID))
        }
    }

    func testCustomSeedMetadataValueIsStored() throws {
        let context = try makeContext()
        let now = Date(timeIntervalSinceReferenceDate: 333)

        try StarterDataService(context: context, seedMetadataValue: "ui-tests").seedIfNeeded(now: now)

        let metadata = try XCTUnwrap(try fetchMetadata(in: context).first)
        XCTAssertEqual(metadata.key, StarterDataService.seedMetadataKey)
        XCTAssertEqual(metadata.value, "ui-tests")
        XCTAssertEqual(metadata.updatedAt, now)
    }

    func testCustomSeedMetadataValueDoesNotChangeSeedOnceBehavior() throws {
        let context = try makeContext()
        let service = StarterDataService(context: context, seedMetadataValue: "v2")

        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 10))
        try StarterDataService(context: context, seedMetadataValue: "v3").seedIfNeeded(
            now: Date(timeIntervalSinceReferenceDate: 20)
        )

        XCTAssertEqual(try fetchGroups(in: context).count, 6)
        XCTAssertEqual(try fetchRoutines(in: context).count, 20)
        XCTAssertEqual(try fetchMetadata(in: context).count, 1)
        XCTAssertEqual(try fetchMetadata(in: context).first?.value, "v2")
    }

    func testSeedIfNeededMapsSaveFailureToPersistenceError() throws {
        let context = try makeContext()
        let originalSave = RoutinePersistenceSaveExecutor.save
        defer { RoutinePersistenceSaveExecutor.save = originalSave }

        RoutinePersistenceSaveExecutor.save = { _ in
            throw SimulatedStarterDataSaveFailure()
        }

        do {
            try StarterDataService(context: context).seedIfNeeded()
            XCTFail("Expected seedIfNeeded() to throw.")
        } catch let error as PersistenceError {
            guard case .saveFailed(let diagnostic) = error else {
                return XCTFail("Expected saveFailed, got \(error).")
            }

            XCTAssertEqual(error.errorDescription, "Unable to save changes.")
            XCTAssertEqual(diagnostic, "simulated starter data save failure")
        } catch {
            XCTFail("Expected PersistenceError, got \(error).")
        }

        XCTAssertTrue(try fetchGroups(in: context).isEmpty)
        XCTAssertTrue(try fetchRoutines(in: context).isEmpty)
        XCTAssertTrue(try fetchMetadata(in: context).isEmpty)
    }

    func testSeedIfNeededCanRetryAfterSaveFailureLeavesContextClean() throws {
        let context = try makeContext()
        let service = StarterDataService(context: context)
        let originalSave = RoutinePersistenceSaveExecutor.save
        defer { RoutinePersistenceSaveExecutor.save = originalSave }

        RoutinePersistenceSaveExecutor.save = { _ in
            throw SimulatedStarterDataSaveFailure()
        }

        XCTAssertThrowsError(try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 10)))
        XCTAssertTrue(try fetchGroups(in: context).isEmpty)
        XCTAssertTrue(try fetchRoutines(in: context).isEmpty)
        XCTAssertTrue(try fetchMetadata(in: context).isEmpty)

        RoutinePersistenceSaveExecutor.save = originalSave

        try service.seedIfNeeded(now: Date(timeIntervalSinceReferenceDate: 20))

        XCTAssertEqual(try fetchGroups(in: context).count, 6)
        XCTAssertEqual(try fetchRoutines(in: context).count, 20)
        XCTAssertEqual(try fetchMetadata(in: context).count, 1)

        let metadata = try XCTUnwrap(try fetchMetadata(in: context).first)
        XCTAssertEqual(metadata.key, StarterDataService.seedMetadataKey)
        XCTAssertEqual(metadata.value, StarterDataService.seedMetadataValue)
    }

    private func makeContext() throws -> ModelContext {
        ModelContext(try RoutineModelContainer.inMemory())
    }

    private func fetchGroups(in context: ModelContext) throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )
        return try context.fetch(descriptor)
    }

    private func fetchRoutines(in context: ModelContext) throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [
                SortDescriptor(\Routine.groupID),
                SortDescriptor(\Routine.sortOrder),
                SortDescriptor(\Routine.name)
            ]
        )
        return try context.fetch(descriptor)
    }

    private func fetchMetadata(in context: ModelContext) throws -> [AppMetadata] {
        try context.fetch(FetchDescriptor<AppMetadata>())
    }

    private func routine(named name: String, in context: ModelContext) throws -> Routine? {
        let descriptor = FetchDescriptor<Routine>(
            predicate: #Predicate<Routine> { routine in
                routine.name == name
            }
        )
        return try context.fetch(descriptor).first
    }
}

private enum ExpectedSeed {
    static let groups: [ExpectedGroup] = [
        ExpectedGroup(
            name: "Morning",
            sortOrder: 0,
            routines: [
                ExpectedRoutine(name: "Wake up early", targetCount: 4, period: .weekly, sortOrder: 0),
                ExpectedRoutine(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 1)
            ]
        ),
        ExpectedGroup(
            name: "Movement",
            sortOrder: 1,
            routines: [
                ExpectedRoutine(name: "Functional workout", targetCount: 5, period: .weekly, sortOrder: 0),
                ExpectedRoutine(name: "Walk the dog", targetCount: 5, period: .weekly, sortOrder: 1),
                ExpectedRoutine(name: "Basketball", targetCount: 3, period: .weekly, sortOrder: 2)
            ]
        ),
        ExpectedGroup(
            name: "Family / Home",
            sortOrder: 2,
            routines: [
                ExpectedRoutine(name: "Mist plants", targetCount: 6, period: .weekly, sortOrder: 0),
                ExpectedRoutine(name: "Play with kids", targetCount: 5, period: .weekly, sortOrder: 1),
                ExpectedRoutine(name: "Do something nice for my wife", targetCount: 1, period: .weekly, sortOrder: 2),
                ExpectedRoutine(name: "Water plants", targetCount: 1, period: .weekly, sortOrder: 3),
                ExpectedRoutine(name: "Run razor cleaner", targetCount: 1, period: .weekly, sortOrder: 4)
            ]
        ),
        ExpectedGroup(
            name: "Learning / Creative",
            sortOrder: 3,
            routines: [
                ExpectedRoutine(name: "Learn math", targetCount: 3, period: .weekly, sortOrder: 0),
                ExpectedRoutine(name: "Duolingo", targetCount: 6, period: .weekly, sortOrder: 1),
                ExpectedRoutine(name: "Read a book", targetCount: 4, period: .weekly, sortOrder: 2),
                ExpectedRoutine(name: "Write something", targetCount: 3, period: .weekly, sortOrder: 3),
                ExpectedRoutine(name: "Practice piano", targetCount: 3, period: .weekly, sortOrder: 4),
                ExpectedRoutine(name: "Practice leetcode", targetCount: 3, period: .weekly, sortOrder: 5)
            ]
        ),
        ExpectedGroup(
            name: "Evening",
            sortOrder: 4,
            routines: [
                ExpectedRoutine(name: "Evening yoga", targetCount: 4, period: .weekly, sortOrder: 0)
            ]
        ),
        ExpectedGroup(
            name: "Monthly Maintenance",
            sortOrder: 5,
            routines: [
                ExpectedRoutine(name: "Clean air purifiers", targetCount: 1, period: .monthly, sortOrder: 0),
                ExpectedRoutine(name: "Rotate plants", targetCount: 1, period: .monthly, sortOrder: 1),
                ExpectedRoutine(name: "Whiten teeth", targetCount: 1, period: .monthly, sortOrder: 2)
            ]
        )
    ]
}

private struct ExpectedGroup {
    let name: String
    let sortOrder: Int
    let routines: [ExpectedRoutine]
}

private struct ExpectedRoutine {
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let sortOrder: Int
}

private struct SimulatedStarterDataSaveFailure: Error, CustomStringConvertible {
    let description = "simulated starter data save failure"
}
