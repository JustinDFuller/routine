import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class AppBootstrapTests: XCTestCase {
    func testResetSettingsForInMemoryStoreIfNeededClearsWeekStartForInMemoryLaunches() throws {
        let suiteName = "AppBootstrapTests.inMemory"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Weekday.monday.rawValue, forKey: RoutineSettingsKeys.weekStartWeekday)

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-empty-in-memory-store"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.weekStartWeekday))
    }

    func testResetSettingsForInMemoryStoreIfNeededLeavesPersistentLaunchesUntouched() throws {
        let suiteName = "AppBootstrapTests.persistent"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set(Weekday.monday.rawValue, forKey: RoutineSettingsKeys.weekStartWeekday)

        let configuration = RoutineDebugLaunchConfiguration(arguments: ["Routine"])

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertEqual(defaults.integer(forKey: RoutineSettingsKeys.weekStartWeekday), Weekday.monday.rawValue)
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesCollapseKeyAsFalseByDefault() throws {
        let suiteName = "AppBootstrapTests.collapseDefault"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertFalse(defaults.bool(forKey: RoutineSettingsKeys.collapseCompletedToday))
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesCollapseKeyAsTrueWhenFlagIsSet() throws {
        let suiteName = "AppBootstrapTests.collapseEnabled"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-completed-enabled"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.collapseCompletedToday))
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesUnavailableCollapseKeyAsTrueByDefault() throws {
        let suiteName = "AppBootstrapTests.unavailableCollapseDefault"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.collapseUnavailableToday))
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesGoalMetCollapseKeyAsTrueByDefault() throws {
        let suiteName = "AppBootstrapTests.goalMetCollapseDefault"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.collapseGoalMetToday))
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesGoalMetCollapseKeyAsFalseWhenDisabled() throws {
        let suiteName = "AppBootstrapTests.goalMetCollapseDisabled"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-goal-met-disabled"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertFalse(defaults.bool(forKey: RoutineSettingsKeys.collapseGoalMetToday))
    }

    func testResetSettingsForInMemoryStoreIfNeededWritesUnavailableCollapseKeyAsFalseWhenDisabled() throws {
        let suiteName = "AppBootstrapTests.unavailableCollapseDisabled"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let configuration = RoutineDebugLaunchConfiguration(
            arguments: ["Routine", "-routine-use-in-memory-store", "-routine-collapse-unavailable-disabled"]
        )

        AppBootstrap.resetSettingsForInMemoryStoreIfNeeded(
            launchConfiguration: configuration,
            userDefaults: defaults
        )

        XCTAssertFalse(defaults.bool(forKey: RoutineSettingsKeys.collapseUnavailableToday))
    }
}
