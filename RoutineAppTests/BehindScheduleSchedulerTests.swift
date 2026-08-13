import Foundation
import RoutineCore
import SwiftData
import UserNotifications
import XCTest

@testable import Routine

@MainActor
final class FakeBehindScheduleNotificationCenter: BehindScheduleNotificationCenter {
    private(set) var addedRequests: [UNNotificationRequest] = []
    private var pendingRequests: [String: UNNotificationRequest] = [:]
    var authorizationStatus: UNAuthorizationStatus = .authorized

    func seedPending(identifier: String) {
        pendingRequests[identifier] = UNNotificationRequest(
            identifier: identifier,
            content: UNMutableNotificationContent(),
            trigger: nil
        )
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func notificationSettings() async -> UNNotificationSettings {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        settings.setValue(authorizationStatus.rawValue, forKey: "authorizationStatus")
        return settings
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
        pendingRequests[request.identifier] = request
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            pendingRequests.removeValue(forKey: identifier)
        }
        addedRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        Array(pendingRequests.values)
    }
}

@MainActor
final class BehindScheduleSchedulerTests: ProjectionBuilderTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "BehindScheduleSchedulerTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("Expected to create throwaway UserDefaults suite.")
        }
        return defaults
    }

    private func insertBehindRoutine(into context: ModelContext) -> Routine {
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        return insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 3, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
    }

    func testEnabledAlertsScheduleBehindRoutineForTwoLocalDays() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        _ = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        defaults.set(420, forKey: RoutineSettingsKeys.behindScheduleNotificationMinute)
        let fakeCenter = FakeBehindScheduleNotificationCenter()

        try await BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: defaults).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(
            Set(fakeCenter.addedRequests.map(\.identifier)),
            ["behind-schedule.2026-06-10", "behind-schedule.2026-06-11"]
        )
        let request = try XCTUnwrap(
            fakeCenter.addedRequests.first { $0.identifier == "behind-schedule.2026-06-10" }
        )
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertEqual(trigger.dateComponents.hour, 7)
        XCTAssertEqual(trigger.dateComponents.minute, 0)
        XCTAssertEqual(request.content.title, "Behind schedule")
        XCTAssertEqual(
            request.content.body,
            "Walk: 0 of 3 this week. You’re 1 completion behind pace with 5 days left."
        )
    }

    func testAlreadyPassedOccurrenceIsOmitted() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 7, minute: 0, calendar: calendar.calendar)
        _ = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        let fakeCenter = FakeBehindScheduleNotificationCenter()

        try await BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: defaults).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(fakeCenter.addedRequests.map(\.identifier), ["behind-schedule.2026-06-11"])
    }

    func testDisabledAlertsScheduleNothing() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        _ = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let fakeCenter = FakeBehindScheduleNotificationCenter()
        try await BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: makeDefaults()).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        XCTAssertTrue(fakeCenter.addedRequests.isEmpty)
    }

    func testHardAvailabilityWindowDoesNotSuppressBehindAlert() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(
                name: "Walk",
                targetCount: 3,
                period: .weekly,
                availabilityStartMinute: 600,
                availabilityEndMinute: 660,
                availabilityBlockMode: .hard,
                sortOrder: 0
            ),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        let fakeCenter = FakeBehindScheduleNotificationCenter()
        try await BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: defaults).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(fakeCenter.addedRequests.count, 2)
    }

    func testRescheduleCancelsLegacyAndStaleBehindScheduleRequests() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        _ = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        let fakeCenter = FakeBehindScheduleNotificationCenter()
        fakeCenter.seedPending(identifier: "checkin.morning.2026-06-09")
        fakeCenter.seedPending(identifier: "behind-schedule.2026-06-09")

        try await BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: defaults).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        let identifiers = Set((await fakeCenter.pendingNotificationRequests()).map(\.identifier))
        XCTAssertFalse(identifiers.contains("checkin.morning.2026-06-09"))
        XCTAssertFalse(identifiers.contains("behind-schedule.2026-06-09"))
        XCTAssertTrue(identifiers.contains("behind-schedule.2026-06-10"))
    }

    func testCompletionResyncReplacesObsoletePendingRequest() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let routine = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        let fakeCenter = FakeBehindScheduleNotificationCenter()
        let scheduler = BehindScheduleScheduler(notificationCenter: fakeCenter, userDefaults: defaults)
        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        insertCompletion(
            routine: routine,
            day: try makeDay(year: 2026, month: 6, day: 8),
            completedAt: now,
            into: context
        )
        try saveChanges(in: context)
        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        XCTAssertEqual(fakeCenter.addedRequests.map(\.identifier), ["behind-schedule.2026-06-11"])
    }

    func testDefaultUserDefaultsStoreUsesSettingsKeysWrittenByAppStorage() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        _ = insertBehindRoutine(into: context)
        try saveChanges(in: context)

        let defaults = UserDefaults.standard
        let keys = [
            RoutineSettingsKeys.behindScheduleNotificationsEnabled,
            RoutineSettingsKeys.behindScheduleNotificationMinute
        ]
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        defer {
            for key in keys {
                defaults.removeObject(forKey: key)
            }
        }
        defaults.set(true, forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled)
        defaults.set(420, forKey: RoutineSettingsKeys.behindScheduleNotificationMinute)

        let fakeCenter = FakeBehindScheduleNotificationCenter()
        try await BehindScheduleScheduler(notificationCenter: fakeCenter).reschedule(
            context: context,
            calendar: calendar,
            now: now
        )

        XCTAssertEqual(fakeCenter.addedRequests.count, 2)
    }
}
