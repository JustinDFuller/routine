import Foundation
import RoutineCore
import SwiftData
import UserNotifications
import XCTest

@testable import Routine

@MainActor
final class FakeCheckInNotificationCenter: CheckInNotificationCenter {
    private(set) var addedRequests: [UNNotificationRequest] = []
    private var pendingIdentifiers: Set<String> = []
    var authorizationStatus: UNAuthorizationStatus = .authorized

    func seedPending(identifier: String) {
        pendingIdentifiers.insert(identifier)
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        true
    }

    func notificationSettings() async -> UNNotificationSettings {
        await FakeNotificationSettingsProvider.settings(authorizationStatus: authorizationStatus)
    }

    func add(_ request: UNNotificationRequest) async throws {
        addedRequests.append(request)
        pendingIdentifiers.insert(request.identifier)
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        for identifier in identifiers {
            pendingIdentifiers.remove(identifier)
        }
        addedRequests.removeAll { identifiers.contains($0.identifier) }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        pendingIdentifiers.map { identifier in
            UNNotificationRequest(
                identifier: identifier,
                content: UNMutableNotificationContent(),
                trigger: nil
            )
        }
    }
}

/// `UNNotificationSettings` has no public initializer. Tests obtain a real instance from the live
/// notification center and use key-value coding to override `authorizationStatus`, since that
/// property is KVC-compliant on the Objective-C class even though it's a `let` in Swift's view.
private enum FakeNotificationSettingsProvider {
    static func settings(authorizationStatus: UNAuthorizationStatus) async -> UNNotificationSettings {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        settings.setValue(authorizationStatus.rawValue, forKey: "authorizationStatus")
        return settings
    }
}

@MainActor
final class CheckInSchedulerTests: ProjectionBuilderTestCase {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "CheckInSchedulerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        guard let defaults else {
            preconditionFailure("Expected to create throwaway UserDefaults suite.")
        }
        return defaults
    }

    func testReschedulesOpenRoutineForEnabledMorningSlot() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)

        let fakeCenter = FakeCheckInNotificationCenter()
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        XCTAssertEqual(fakeCenter.addedRequests.count, 2)
        let identifiers = fakeCenter.addedRequests.map(\.identifier)
        XCTAssertTrue(identifiers.contains("checkin.morning.2026-06-10"))
        XCTAssertTrue(identifiers.contains("checkin.morning.2026-06-11"))

        let request = try XCTUnwrap(
            fakeCenter.addedRequests.first { $0.identifier == "checkin.morning.2026-06-10" }
        )
        XCTAssertFalse(request.content.title.isEmpty)
        XCTAssertFalse(request.content.body.isEmpty)
    }

    func testSlotAlreadyPassedTodayIsSkippedButTomorrowIsScheduled() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 7, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)

        let fakeCenter = FakeCheckInNotificationCenter()
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        let identifiers = fakeCenter.addedRequests.map(\.identifier)
        XCTAssertFalse(identifiers.contains("checkin.morning.2026-06-10"))
        XCTAssertTrue(identifiers.contains("checkin.morning.2026-06-11"))
    }

    func testRescheduleCancelsStalePendingCheckInRequests() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)

        let fakeCenter = FakeCheckInNotificationCenter()
        fakeCenter.seedPending(identifier: "checkin.morning.2026-06-09")
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        let pending = await fakeCenter.pendingNotificationRequests()
        let identifiers = pending.map(\.identifier)
        XCTAssertFalse(identifiers.contains("checkin.morning.2026-06-09"))
        XCTAssertTrue(identifiers.contains("checkin.morning.2026-06-10"))
    }

    func testCelebrationScheduledAndFlagPersistedWhenAllRoutinesMet() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 1, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-09", completedAt: now, into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)
        defaults.set(false, forKey: CheckInScheduler.celebrationConsumedKey)

        let fakeCenter = FakeCheckInNotificationCenter()
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        XCTAssertEqual(fakeCenter.addedRequests.count, 1)
        let request = try XCTUnwrap(fakeCenter.addedRequests.first)
        XCTAssertEqual(request.content.title, CheckInContentBuilder.celebrationTitle)
        XCTAssertTrue(defaults.bool(forKey: CheckInScheduler.celebrationConsumedKey))
    }

    func testNoCelebrationScheduledWhenAlreadyConsumed() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        let walk = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 1, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try insertCompletion(routine: walk, dayKey: "2026-06-09", completedAt: now, into: context)
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(true, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(360, forKey: RoutineSettingsKeys.checkInMorningMinute)
        defaults.set(true, forKey: CheckInScheduler.celebrationConsumedKey)

        let fakeCenter = FakeCheckInNotificationCenter()
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        XCTAssertTrue(fakeCenter.addedRequests.isEmpty)
        XCTAssertTrue(defaults.bool(forKey: CheckInScheduler.celebrationConsumedKey))
    }

    func testDisabledSlotIsNeverScheduled() async throws {
        let context = try makeContext()
        let calendar = makeCalendar()
        let now = makeDate(year: 2026, month: 6, day: 10, hour: 5, minute: 0, calendar: calendar.calendar)
        let group = insertGroup(name: "Health", sortOrder: 0, into: context)
        _ = insertRoutine(
            seed: RoutineTestSeed(name: "Walk", targetCount: 5, period: .weekly, sortOrder: 0),
            group: group,
            into: context
        )
        try saveChanges(in: context)

        let defaults = makeDefaults()
        defaults.set(false, forKey: RoutineSettingsKeys.checkInMorningEnabled)
        defaults.set(false, forKey: RoutineSettingsKeys.checkInAfternoonEnabled)
        defaults.set(false, forKey: RoutineSettingsKeys.checkInEveningEnabled)

        let fakeCenter = FakeCheckInNotificationCenter()
        let scheduler = CheckInScheduler(notificationCenter: fakeCenter, userDefaults: defaults)

        try await scheduler.reschedule(context: context, calendar: calendar, now: now)

        XCTAssertTrue(fakeCenter.addedRequests.isEmpty)
    }
}
