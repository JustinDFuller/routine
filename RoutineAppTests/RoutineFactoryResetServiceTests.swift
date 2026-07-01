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
        context.insert(
            AppMetadata(
                key: "test.key",
                value: "v1",
                updatedAt: makeDate(year: 2026, month: 6, day: 10, calendar: calendar.calendar)
            )
        )
        try saveChanges(in: context)

        let originalReload = RoutineWidgetBridge.reloadAllTimelines
        defer { RoutineWidgetBridge.reloadAllTimelines = originalReload }
        RoutineWidgetBridge.reloadAllTimelines = {}

        try await RoutineFactoryResetService(
            userDefaults: makeDefaults(),
            notificationCenter: FakeCheckInNotificationCenter()
        ).reset(
            RoutineResetSelection(routinesAndHistory: true, displayPreferences: false, checkInReminders: false),
            in: context,
            calendar: calendar
        )

        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineGroup>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Routine>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineCompletion>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<AppMetadata>()).isEmpty)
    }

    func testRoutinesAndHistorySelectionDoesNotTouchDisplayOrCheckInKeys() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)

        let originalReload = RoutineWidgetBridge.reloadAllTimelines
        defer { RoutineWidgetBridge.reloadAllTimelines = originalReload }
        RoutineWidgetBridge.reloadAllTimelines = {}

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            notificationCenter: FakeCheckInNotificationCenter()
        ).reset(
            RoutineResetSelection(routinesAndHistory: true, displayPreferences: false, checkInReminders: false),
            in: context,
            calendar: makeCalendar()
        )

        XCTAssertEqual(defaults.integer(forKey: RoutineSettingsKeys.weekStartWeekday), 2)
        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.checkInMorningEnabled))
    }

    func testDisplayPreferencesSelectionRemovesAllFourPreferenceKeys() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseCompletedToday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseGoalMetToday)
        defaults.set(false, forKey: RoutineSettingsKeys.collapseUnavailableToday)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            notificationCenter: FakeCheckInNotificationCenter()
        ).reset(
            RoutineResetSelection(routinesAndHistory: false, displayPreferences: true, checkInReminders: false),
            in: context,
            calendar: makeCalendar()
        )

        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.weekStartWeekday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseCompletedToday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseGoalMetToday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.collapseUnavailableToday))
        XCTAssertTrue(defaults.bool(forKey: RoutineSettingsKeys.checkInMorningEnabled))
    }

    func testCheckInRemindersSelectionRemovesAllCheckInKeysAndCancelsPendingNotifications() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        let notificationCenter = FakeCheckInNotificationCenter()
        notificationCenter.seedPending(identifier: "checkin.morning.2026-06-10")

        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInAfternoonEnabled)
        defaults.set(720, forKey: RoutineSettingsKeys.checkInAfternoonMinute)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInEveningEnabled)
        defaults.set(1_080, forKey: RoutineSettingsKeys.checkInEveningMinute)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInOnboardingShown)
        defaults.set(true, forKey: CheckInScheduler.celebrationConsumedKey)
        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            notificationCenter: notificationCenter
        ).reset(
            RoutineResetSelection(routinesAndHistory: false, displayPreferences: false, checkInReminders: true),
            in: context,
            calendar: makeCalendar()
        )

        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInMorningEnabled))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInMorningMinute))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInAfternoonEnabled))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInAfternoonMinute))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInEveningEnabled))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInEveningMinute))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInOnboardingShown))
        XCTAssertNil(defaults.object(forKey: CheckInScheduler.celebrationConsumedKey))
        XCTAssertEqual(defaults.integer(forKey: RoutineSettingsKeys.weekStartWeekday), 2)
        let pending = await notificationCenter.pendingNotificationRequests()
        XCTAssertTrue(pending.isEmpty)
    }

    func testAllSelectionsResetEverything() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let defaults = makeDefaults()
        let notificationCenter = FakeCheckInNotificationCenter()

        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)

        let originalReload = RoutineWidgetBridge.reloadAllTimelines
        defer { RoutineWidgetBridge.reloadAllTimelines = originalReload }
        RoutineWidgetBridge.reloadAllTimelines = {}

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            notificationCenter: notificationCenter
        ).reset(
            RoutineResetSelection(routinesAndHistory: true, displayPreferences: true, checkInReminders: true),
            in: context,
            calendar: calendar
        )

        XCTAssertTrue(try context.fetch(FetchDescriptor<RoutineGroup>()).isEmpty)
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.weekStartWeekday))
        XCTAssertNil(defaults.object(forKey: RoutineSettingsKeys.checkInMorningEnabled))
    }

    func testEmptySelectionLeavesEverythingIntact() async throws {
        let context = try makeContext()
        let defaults = makeDefaults()

        let group = insertGroup(name: "Morning", sortOrder: 0, into: context)
        insertRoutine(
            seed: RoutineTestSeed(name: "Yoga", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)
        defaults.set(2, forKey: RoutineSettingsKeys.weekStartWeekday)

        try await RoutineFactoryResetService(
            userDefaults: defaults,
            notificationCenter: FakeCheckInNotificationCenter()
        ).reset(
            RoutineResetSelection(routinesAndHistory: false, displayPreferences: false, checkInReminders: false),
            in: context,
            calendar: makeCalendar()
        )

        XCTAssertFalse(try context.fetch(FetchDescriptor<RoutineGroup>()).isEmpty)
        XCTAssertEqual(defaults.integer(forKey: RoutineSettingsKeys.weekStartWeekday), 2)
    }
}
