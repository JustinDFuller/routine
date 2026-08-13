import Foundation
import OSLog
import RoutineCore
import SwiftData
import UserNotifications

@MainActor
protocol CheckInNotificationCenter {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func notificationSettings() async -> UNNotificationSettings
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: CheckInNotificationCenter {}

private struct CheckInSlotSetting {
    let slot: CheckInSlot
    let enabledKey: String
    let minuteKey: String
    let defaultMinute: Int
}

@MainActor
final class CheckInScheduler {
    static let celebrationConsumedKey = "checkin.celebrationConsumed"

    private static let logger = AppDiagnostics.logger(.notifications)
    private static let identifierPrefix = "checkin."
    private static let daysAhead = 2

    private static let slotSettings: [CheckInSlotSetting] = [
        CheckInSlotSetting(
            slot: .morning,
            enabledKey: RoutineSettingsKeys.checkInMorningEnabled,
            minuteKey: RoutineSettingsKeys.checkInMorningMinute,
            defaultMinute: 360
        ),
        CheckInSlotSetting(
            slot: .afternoon,
            enabledKey: RoutineSettingsKeys.checkInAfternoonEnabled,
            minuteKey: RoutineSettingsKeys.checkInAfternoonMinute,
            defaultMinute: 720
        ),
        CheckInSlotSetting(
            slot: .evening,
            enabledKey: RoutineSettingsKeys.checkInEveningEnabled,
            minuteKey: RoutineSettingsKeys.checkInEveningMinute,
            defaultMinute: 1_080
        )
    ]

    private let notificationCenter: CheckInNotificationCenter
    private let userDefaults: UserDefaults

    init(
        notificationCenter: CheckInNotificationCenter = UNUserNotificationCenter.current(),
        userDefaults: UserDefaults = .standard
    ) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
    }

    func requestAuthorizationIfNeeded() async {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            Self.logger.info("requestAuthorization granted=\(granted, privacy: .public)")
        } catch {
            Self.logger.error(
                "requestAuthorizationFailed e=\(String(describing: error), privacy: .private)"
            )
        }
    }

    func isAuthorizationDenied() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus == .denied
    }

    func reschedule(context: ModelContext, calendar: RoutineCalendar, now: Date = .now) async throws {
        let snapshots = try routineSnapshots(context: context)
        await cancelPendingCheckIns()

        var celebrationConsumed = userDefaults.bool(forKey: Self.celebrationConsumedKey)
        var scheduledCount = 0

        for occurrence in upcomingOccurrences(calendar: calendar, now: now) {
            let scheduled = await scheduleIfNeeded(
                occurrence: occurrence,
                snapshots: snapshots,
                calendar: calendar,
                celebrationConsumed: celebrationConsumed
            )

            guard let scheduled else {
                continue
            }

            celebrationConsumed = scheduled
            scheduledCount += 1
        }

        userDefaults.set(celebrationConsumed, forKey: Self.celebrationConsumedKey)
        Self.logger.info("rescheduleComplete count=\(scheduledCount, privacy: .public)")
    }

    private func scheduleIfNeeded(
        occurrence: CheckInOccurrence,
        snapshots: [CheckInRoutineSnapshot],
        calendar: RoutineCalendar,
        celebrationConsumed: Bool
    ) async -> Bool? {
        let context = CheckInContext(
            now: occurrence.fireDate, calendar: calendar, celebrationConsumed: celebrationConsumed)
        let content = CheckInContentBuilder().content(
            slot: occurrence.setting.slot,
            slotMinuteOfDay: occurrence.minute,
            routines: snapshots,
            context: context
        )

        guard case .message(let title, let body) = content else {
            return nil
        }

        do {
            try await schedule(occurrence: occurrence, title: title, body: body)
            return title == CheckInContentBuilder.celebrationTitle
        } catch {
            let identifier = occurrence.identifier
            let errorText = String(describing: error)
            Self.logger.error(
                "scheduleFailed identifier=\(identifier, privacy: .public) e=\(errorText, privacy: .private)"
            )
            return nil
        }
    }

    private func schedule(occurrence: CheckInOccurrence, title: String, body: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.userInfo["url"] = "routine://today"

        let trigger = UNCalendarNotificationTrigger(dateMatching: occurrence.fireComponents, repeats: false)
        let request = UNNotificationRequest(
            identifier: occurrence.identifier,
            content: content,
            trigger: trigger
        )

        try await notificationCenter.add(request)
        Self.logger.debug("scheduled identifier=\(occurrence.identifier, privacy: .public)")
    }

    func cancelAll() async {
        await cancelPendingCheckIns()
    }

    private func cancelPendingCheckIns() async {
        let pending = await notificationCenter.pendingNotificationRequests()
        let staleIdentifiers =
            pending
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.identifierPrefix) }

        guard staleIdentifiers.isEmpty == false else {
            return
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: staleIdentifiers)
        Self.logger.debug("cancelledPending count=\(staleIdentifiers.count, privacy: .public)")
    }

    private func upcomingOccurrences(calendar: RoutineCalendar, now: Date) -> [CheckInOccurrence] {
        let today = calendar.today(now: now)

        return (0..<Self.daysAhead).flatMap { dayOffset -> [CheckInOccurrence] in
            guard let day = day(after: dayOffset, from: today, calendar: calendar) else {
                return []
            }

            return Self.slotSettings.compactMap { setting in
                occurrence(for: setting, on: day, calendar: calendar, now: now)
            }
        }
    }

    private func occurrence(
        for setting: CheckInSlotSetting,
        on day: RoutineDay,
        calendar: RoutineCalendar,
        now: Date
    ) -> CheckInOccurrence? {
        guard userDefaults.bool(forKey: setting.enabledKey) else {
            return nil
        }

        let minute = storedMinute(for: setting)

        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = minute / 60
        components.minute = minute % 60

        guard let fireDate = calendar.calendar.date(from: components), fireDate > now else {
            return nil
        }

        return CheckInOccurrence(
            setting: setting,
            minute: minute,
            fireDate: fireDate,
            fireComponents: components,
            identifier: "\(Self.identifierPrefix)\(setting.slot.rawValue).\(day.key)"
        )
    }

    private func storedMinute(for setting: CheckInSlotSetting) -> Int {
        guard userDefaults.object(forKey: setting.minuteKey) != nil else {
            return setting.defaultMinute
        }

        return userDefaults.integer(forKey: setting.minuteKey)
    }

    private func day(after offset: Int, from today: RoutineDay, calendar: RoutineCalendar) -> RoutineDay? {
        guard offset > 0 else {
            return today
        }

        var components = DateComponents()
        components.year = today.year
        components.month = today.month
        components.day = today.day

        guard
            let todayDate = calendar.calendar.date(from: components),
            let offsetDate = calendar.calendar.date(byAdding: .day, value: offset, to: todayDate)
        else {
            return nil
        }

        return calendar.day(containing: offsetDate)
    }

    private func routineSnapshots(context: ModelContext) throws -> [CheckInRoutineSnapshot] {
        let groups = try fetchGroups(context)
        let routines = try fetchRoutines(context)
        let completions = try fetchCompletions(context)
        let completionDaysByRoutineID = completionDaysByRoutineID(from: completions)

        return orderedRoutines(groups: groups, routines: routines).map { routine in
            CheckInRoutineSnapshot(
                name: routine.name,
                targetCount: routine.targetCount,
                period: routine.period,
                availabilityWindow: routine.availabilityWindow,
                availabilityBlockMode: routine.availabilityBlockMode,
                completionDays: completionDaysByRoutineID[routine.id] ?? []
            )
        }
    }

    private func orderedRoutines(groups: [RoutineGroup], routines: [Routine]) -> [Routine] {
        let routinesByGroupID = Dictionary(grouping: routines, by: \.groupID)
        let knownGroupIDs = Set(groups.map(\.id))

        var ordered = groups.flatMap { routinesByGroupID[$0.id] ?? [] }
        ordered.append(contentsOf: routines.filter { knownGroupIDs.contains($0.groupID) == false })
        return ordered
    }

    private func completionDaysByRoutineID(from completions: [RoutineCompletion]) -> [UUID: [RoutineDay]] {
        completions.reduce(into: [:]) { result, completion in
            guard let day = RoutineDay(key: completion.dayKey) else {
                return
            }

            result[completion.routineID, default: []].append(day)
        }
    }

    private func fetchGroups(_ context: ModelContext) throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)
        } catch {
            Self.logger.error("fetchGroupsFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    private func fetchRoutines(_ context: ModelContext) throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)
        } catch {
            Self.logger.error("fetchRoutinesFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    private func fetchCompletions(_ context: ModelContext) throws -> [RoutineCompletion] {
        let descriptor = FetchDescriptor<RoutineCompletion>(
            sortBy: [
                SortDescriptor(\RoutineCompletion.routineID),
                SortDescriptor(\RoutineCompletion.dayKey),
                SortDescriptor(\RoutineCompletion.completedAt)
            ]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchCompletions(context, descriptor)
        } catch {
            Self.logger.error("fetchCompletionsFailed e=\(String(describing: error), privacy: .private)")
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }
}

private struct CheckInOccurrence {
    let setting: CheckInSlotSetting
    let minute: Int
    let fireDate: Date
    let fireComponents: DateComponents
    let identifier: String
}
