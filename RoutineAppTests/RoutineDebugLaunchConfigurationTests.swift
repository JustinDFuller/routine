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
        XCTAssertFalse(configuration.runtime.disablesAnimations)
        XCTAssertNil(configuration.runtime.fixedNow)
        XCTAssertNil(configuration.launchRoute)
        XCTAssertTrue(configuration.collapseGoalMetEnabled)
        XCTAssertTrue(configuration.collapseUnavailableEnabled)
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
        XCTAssertTrue(configuration.runtime.disablesAnimations)
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

    func testForcedColorSchemeArgumentParsesKnownValuesAndIgnoresInvalidInput() {
        let darkConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-force-color-scheme", "dark"],
            calendar: makeCalendar().calendar
        )
        let lightConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-force-color-scheme", "light"],
            calendar: makeCalendar().calendar
        )
        let missingValueConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-force-color-scheme"],
            calendar: makeCalendar().calendar
        )
        let unknownValueConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-force-color-scheme", "sepia"],
            calendar: makeCalendar().calendar
        )

        XCTAssertEqual(darkConfiguration.runtime.forcedColorScheme, .dark)
        XCTAssertEqual(lightConfiguration.runtime.forcedColorScheme, .light)
        XCTAssertNil(missingValueConfiguration.runtime.forcedColorScheme)
        XCTAssertNil(unknownValueConfiguration.runtime.forcedColorScheme)
    }

    func testCollapseCompletedEnabledFlagParsesCorrectly() {
        let withFlag = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-completed-enabled"],
            calendar: makeCalendar().calendar
        )
        let withoutFlag = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"],
            calendar: makeCalendar().calendar
        )

        XCTAssertTrue(withFlag.collapseCompletedEnabled)
        XCTAssertFalse(withoutFlag.collapseCompletedEnabled)
    }

    func testCollapseUnavailableEnabledDefaultsToTrueAndCanBeDisabled() {
        let defaultConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"],
            calendar: makeCalendar().calendar
        )
        let disabledConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-unavailable-disabled"],
            calendar: makeCalendar().calendar
        )

        XCTAssertTrue(defaultConfiguration.collapseUnavailableEnabled)
        XCTAssertFalse(disabledConfiguration.collapseUnavailableEnabled)
    }

    func testCollapseGoalMetEnabledDefaultsToTrueAndCanBeDisabled() {
        let defaultConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"],
            calendar: makeCalendar().calendar
        )
        let disabledConfiguration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-goal-met-disabled"],
            calendar: makeCalendar().calendar
        )

        XCTAssertTrue(defaultConfiguration.collapseGoalMetEnabled)
        XCTAssertFalse(disabledConfiguration.collapseGoalMetEnabled)
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
