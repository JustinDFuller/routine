import Foundation
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineDebugLaunchConfigurationTests: ProjectionBuilderTestCase {
    func testSeededInMemoryLaunchConfigurationUsesCanonicalUITestMode() {
        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"],
            calendar: makeCalendar().calendar
        )

        XCTAssertEqual(configuration.storeMode, .inMemory)
        XCTAssertFalse(configuration.resetsStore)
        XCTAssertFalse(configuration.runtime.skipsStarterSeeding)
        XCTAssertFalse(configuration.runtime.disablesAnimations)
        XCTAssertEqual(configuration.runtime.starterSeedVersion, StarterDataService.seedMetadataValue)
        XCTAssertNil(configuration.runtime.fixedNow)
        XCTAssertNil(configuration.launchRoute)
    }

    func testEmptyInMemoryLaunchConfigurationParsesResetAnimationAndSeedVersionFlags() {
        let configuration = RoutineDebugLaunchConfiguration(
            arguments: [
                "Routine",
                "-routine-empty-in-memory-store",
                "-routine-reset-store",
                "-routine-disable-animations",
                "-routine-starter-seed-version",
                "ui-tests"
            ],
            calendar: makeCalendar().calendar
        )

        XCTAssertEqual(configuration.storeMode, .inMemory)
        XCTAssertTrue(configuration.resetsStore)
        XCTAssertTrue(configuration.runtime.skipsStarterSeeding)
        XCTAssertTrue(configuration.runtime.disablesAnimations)
        XCTAssertEqual(configuration.runtime.starterSeedVersion, "ui-tests")
        XCTAssertNil(configuration.runtime.fixedNow)
    }

    func testFixedDateParsingUsesLocalNoon() throws {
        let calendar = makeCalendar().calendar
        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-fixed-date", "2026-06-10"],
            calendar: calendar
        )

        let fixedNow = try XCTUnwrap(configuration.runtime.fixedNow)
        XCTAssertEqual(
            fixedNow,
            makeDate(year: 2026, month: 6, day: 10, hour: 12, minute: 0, calendar: calendar)
        )
    }

    func testLaunchRouteHooksRemainAvailable() {
        let missingHistoryConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-open-missing-history-route"],
            calendar: makeCalendar().calendar
        )
        let precompletedHistoryConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-open-morning-yoga-history-with-completion"],
            calendar: makeCalendar().calendar
        )

        XCTAssertEqual(missingHistoryConfiguration.launchRoute, .missingHistory)
        XCTAssertEqual(
            missingHistoryConfiguration.initialPath,
            [.routineHistory(routineID: RoutineDebugLaunchConfiguration.missingHistoryRoutineID)]
        )

        XCTAssertEqual(
            precompletedHistoryConfiguration.launchRoute,
            .morningYogaHistoryWithCompletion
        )
        XCTAssertTrue(precompletedHistoryConfiguration.opensMorningYogaHistoryWithCompletion)
        XCTAssertTrue(precompletedHistoryConfiguration.initialPath.isEmpty)
    }

    func testScreenshotFixtureArgumentParsesKnownFixtureAndIgnoresUnknownValue() {
        let configuredFixture = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-screenshot-fixture", "full-app"],
            calendar: makeCalendar().calendar
        )
        let unknownFixture = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-screenshot-fixture", "unknown"],
            calendar: makeCalendar().calendar
        )

        XCTAssertEqual(configuredFixture.runtime.screenshotFixture, .fullApp)
        XCTAssertNil(unknownFixture.runtime.screenshotFixture)
    }

    func testMalformedOrMissingFixedDateFallsBackSafely() {
        let missingDateValue = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-fixed-date"],
            calendar: makeCalendar().calendar
        )
        let malformedDate = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-fixed-date", "2026-06"],
            calendar: makeCalendar().calendar
        )
        let invalidDate = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-fixed-date", "2026-02-31"],
            calendar: makeCalendar().calendar
        )

        XCTAssertNil(missingDateValue.runtime.fixedNow)
        XCTAssertNil(malformedDate.runtime.fixedNow)
        XCTAssertNil(invalidDate.runtime.fixedNow)
    }
}

@MainActor
final class RoutineStoreResetServiceTests: ProjectionBuilderTestCase {
    func testResetAllDataClearsStartupModelsBeforeStarterSeedingRuns() throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Reset Me", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: makeDate(year: 2026, month: 6, day: 10, calendar: calendar.calendar),
            into: context
        )
        context.insert(
            AppMetadata(
                key: StarterDataService.seedMetadataKey,
                value: "old",
                updatedAt: makeDate(year: 2026, month: 6, day: 10, calendar: calendar.calendar)
            )
        )
        try saveChanges(in: context)

        try RoutineStoreResetService.resetAllData(in: context)

        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineCompletion>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Routine>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineGroup>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<AppMetadata>()).isEmpty)

        try StarterDataService(context: context).seedIfNeeded(
            now: makeDate(year: 2026, month: 6, day: 10, calendar: calendar.calendar)
        )

        XCTAssertEqual(try context.fetch(FetchDescriptor<RoutineGroup>()).count, 6)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Routine>()).count, 20)
        XCTAssertEqual(try context.fetch(FetchDescriptor<AppMetadata>()).count, 1)
    }
}
