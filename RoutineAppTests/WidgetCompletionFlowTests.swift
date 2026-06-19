import Foundation
import RoutineCore
import SwiftData
import WidgetKit
import XCTest

@testable import Routine

@MainActor
final class WidgetCompletionFlowTests: ProjectionBuilderTestCase {
    override func tearDown() {
        MainActor.assumeIsolated {
            RoutineWidgetBridge.reloadAllTimelines = {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
        super.tearDown()
    }

    func testCompleteRoutineIgnoresInvalidIdentifier() throws {
        let defaults = makeDefaults(suffix: "invalid-id")
        var didBuildContext = false
        var reloadCount = 0

        RoutineWidgetBridge.reloadAllTimelines = {
            reloadCount += 1
        }

        CompleteRoutineIntent.completeRoutine(
            routineID: "not-a-uuid",
            makeContext: {
                didBuildContext = true
                return try self.makeContext()
            },
            userDefaults: defaults
        )

        XCTAssertFalse(didBuildContext)
        XCTAssertEqual(reloadCount, 0)
        XCTAssertNil(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey))
    }

    func testCompleteRoutineStoresPendingBannerOnlyForNewCompletion() throws {
        let defaults = makeDefaults(suffix: "new-completion")
        let context = try makeContext()
        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        var reloadCount = 0
        RoutineWidgetBridge.reloadAllTimelines = {
            reloadCount += 1
        }

        CompleteRoutineIntent.completeRoutine(
            routineID: routine.id.uuidString,
            makeContext: { context },
            userDefaults: defaults
        )

        XCTAssertEqual(reloadCount, 1)
        XCTAssertEqual(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey), routine.id.uuidString)
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testCompleteRoutineTreatsDuplicateCompletionAsNoOp() throws {
        let defaults = makeDefaults(suffix: "duplicate")
        let context = try makeContext()
        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        let now = Date()
        let today = RoutineCalendar.current.today(now: now)
        insertCompletion(routine: routine, day: today, completedAt: now, into: context)
        try saveChanges(in: context)

        var reloadCount = 0
        RoutineWidgetBridge.reloadAllTimelines = {
            reloadCount += 1
        }

        CompleteRoutineIntent.completeRoutine(
            routineID: routine.id.uuidString,
            makeContext: { context },
            userDefaults: defaults
        )

        XCTAssertEqual(reloadCount, 1)
        XCTAssertNil(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey))
        XCTAssertEqual(try fetchCompletions(in: context).count, 1)
    }

    func testTakeCompletedRoutineIDClearsInvalidStoredIdentifier() throws {
        let defaults = makeDefaults(suffix: "invalid-pending")
        defaults.set("bad-value", forKey: RoutineWidgetBridge.completedRoutineIDKey)

        let routineID = RoutineWidgetBridge.takeCompletedRoutineID(userDefaults: defaults)

        XCTAssertNil(routineID)
        XCTAssertNil(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey))
    }

    func testRestorationReturnsBannerPayloadAndClearsStoredIdentifier() throws {
        let defaults = makeDefaults(suffix: "restoration")
        let context = try makeContext()
        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)
        RoutineWidgetBridge.recordCompletedRoutineID(routine.id, userDefaults: defaults)

        let restoration = RoutineWidgetBridge.restoration(for: [routine], userDefaults: defaults)

        XCTAssertEqual(
            restoration,
            WidgetCompletionRestoration(routineID: routine.id, routineName: "Walk")
        )
        XCTAssertNil(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey))
    }

    func testRestorationClearsPendingIdentifierWhenRoutineNoLongerExists() throws {
        let defaults = makeDefaults(suffix: "missing-routine")
        RoutineWidgetBridge.recordCompletedRoutineID(UUID(), userDefaults: defaults)

        let restoration = RoutineWidgetBridge.restoration(for: [], userDefaults: defaults)

        XCTAssertNil(restoration)
        XCTAssertNil(defaults.string(forKey: RoutineWidgetBridge.completedRoutineIDKey))
    }
}

extension WidgetCompletionFlowTests {
    fileprivate func makeDefaults(suffix: String) -> UserDefaults {
        let suiteName = "WidgetCompletionFlowTests.\(suffix).\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Expected test defaults suite.")
        }

        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }

    fileprivate func fetchCompletions(in context: ModelContext) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [SortDescriptor(\RoutineCompletion.dayKey), SortDescriptor(\RoutineCompletion.completedAt)]
        )
        return try context.fetch(descriptor)
    }
}
