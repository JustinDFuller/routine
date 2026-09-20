import Foundation
import RoutineCore
import SwiftData
import XCTest

@testable import Routine

@MainActor
final class RoutineFactoryResetServiceTests: ProjectionBuilderTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "RoutineFactoryResetServiceTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Expected to create throwaway UserDefaults suite.")
        }
        return defaults
    }

    private func makeCoordinator(
        notificationCenter: FakeBehindScheduleNotificationCenter,
        userDefaults: UserDefaults
    ) -> BehindScheduleRescheduleCoordinator {
        BehindScheduleRescheduleCoordinator(
            scheduler: BehindScheduleScheduler(
                notificationCenter: notificationCenter,
                userDefaults: userDefaults
            )
        )
    }

    private func selection(
        routinesAndHistory: Bool = false,
        displayPreferences: Bool = false,
        behindScheduleAlerts: Bool = false
    ) -> RoutineResetSelection {
        RoutineResetSelection(
            routinesAndHistory: routinesAndHistory,
            displayPreferences: displayPreferences,
            behindScheduleAlerts: behindScheduleAlerts
        )
    }

    func testRoutinesAndHistorySelectionDeletesAllSwiftDataModels() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        let routine = insertRoutine(
            seed: RoutineTestSeed(name: "Yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 10),
            completedAt: makeDate(year: 2026, month: 6, day: 10, calendar: calendar.calendar),
            into: context
        )
        context.insert(AppMetadata(key: "test.key", value: "v1", updatedAt: .now))
        try saveChanges(in: context)

        let originalReload = RoutineWidgetBridge.reloadAllTimelines
        defer { RoutineWidgetBridge.reloadAllTimelines = originalReload }
        RoutineWidgetBridge.reloadAllTimelines = {}

        let defaults = makeDefaults()
        let notificationCenter = FakeBehindScheduleNotificationCenter()
        try await RoutineFactoryResetService(
            userDefaults: defaults,
            behindScheduleRescheduleCoordinator: makeCoordinator(
                notificationCenter: notificationCenter,
                userDefaults: defaults
            )
        ).reset(selection(routinesAndHistory: true), in: context, calendar: calendar)

        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineGroup>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Routine>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineCompletion>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<AppMetadata>()).isEmpty)
    }

    func testDisplayPreferencesSelectionRemovesOnlyDisplayPreferences() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseCompletedToday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseGoalMetToday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseUnavailableToday)
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)

        let notificationCenter = FakeBehindScheduleNotificationCenter()
        try await RoutineFactoryResetService(
            userDefaults: defaults,
            behindScheduleRescheduleCoordinator: makeCoordinator(
                notificationCenter: notificationCenter,
                userDefaults: defaults
            )
        ).reset(selection(displayPreferences: true), in: context, calendar: makeCalendar())

        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.weekStartWeekday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseCompletedToday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseGoalMetToday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseUnavailableToday))
        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled))
    }

    func testBehindScheduleAlertsSelectionRemovesNewAndRetiredKeysAndCancelsRequests() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        let notificationCenter = FakeBehindScheduleNotificationCenter()
        notificationCenter.seedPending(identifier: "checkin.morning.2026-06-10")
        notificationCenter.seedPending(identifier: "behind-schedule.2026-06-10")
        let keys = [
            RoutineSettingsKeys.behindScheduleNotificationsEnabled,
            RoutineSettingsKeys.behindScheduleNotificationMinute,
            RoutineSettingsKeys.behindScheduleOnboardingShown,
            "settings.checkin.morning.enabled",
            "settings.checkin.morning.minute",
            "settings.checkin.afternoon.enabled",
            "settings.checkin.afternoon.minute",
            "settings.checkin.evening.enabled",
            "settings.checkin.evening.minute",
            "settings.checkin.onboardingShown",
            "checkin.celebrationConsumed"
        ]
        for key in keys {
            defaults.set(true, forKey: key)
        }

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            behindScheduleRescheduleCoordinator: makeCoordinator(
                notificationCenter: notificationCenter,
                userDefaults: defaults
            )
        ).reset(selection(behindScheduleAlerts: true), in: context, calendar: makeCalendar())

        for key in keys {
            XCTAssertNil(defaults.object(forKey: key))
        }
        let pendingRequests = await notificationCenter.pendingNotificationRequests()
        XCTAssertTrue(pendingRequests.isEmpty)
    }

    func testEmptySelectionLeavesEverythingIntact() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)

        let notificationCenter = FakeBehindScheduleNotificationCenter()
        try await RoutineFactoryResetService(
            userDefaults: defaults,
            behindScheduleRescheduleCoordinator: makeCoordinator(
                notificationCenter: notificationCenter,
                userDefaults: defaults
            )
        ).reset(selection(), in: context, calendar: makeCalendar())

        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled))
    }
}
