import Foundation
import OSLog
import RoutineCore
import SwiftData
import UserNotifications

@MainActor
protocol BehindScheduleNotificationCenter {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func notificationSettings() async -> UNNotificationSettings
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers identifiers: [String])
    func pendingNotificationRequests() async -> [UNNotificationRequest]
}

extension UNUserNotificationCenter: BehindScheduleNotificationCenter {}

@MainActor
final class BehindScheduleScheduler {
    private static let logger = AppDiagnostics.logger(.notifications)
    private static let identifierPrefix = "behind-schedule."
    private static let retiredIdentifierPrefix = "checkin."
    private static let daysAhead = 2
    private static let defaultMinute = 420

    private let notificationCenter: BehindScheduleNotificationCenter
    private let userDefaults: UserDefaults

    init(
        notificationCenter: BehindScheduleNotificationCenter = UNUserNotificationCenter.current(),
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
        await cancelPendingBehindScheduleAlerts()

        guard userDefaults.bool(forKey: RoutineSettingsKeys.behindScheduleNotificationsEnabled) else {
            Self.logger.info("rescheduleComplete count=0")
            return
        }

        var scheduledCount = 0
        for occurrence in upcomingOccurrences(calendar: calendar, now: now)
        where await scheduleIfNeeded(occurrence: occurrence, snapshots: snapshots, calendar: calendar) {
            scheduledCount += 1
        }

        Self.logger.info("rescheduleComplete count=\(scheduledCount, privacy: .public)")
    }

    func cancelAll() async {
        await cancelPendingBehindScheduleAlerts()
    }

    private func scheduleIfNeeded(
        occurrence: BehindScheduleOccurrence,
        snapshots: [BehindScheduleRoutineSnapshot],
        calendar: RoutineCalendar
    ) async -> Bool {
        let content = BehindScheduleContentBuilder().content(
            routines: snapshots,
            context: BehindScheduleContext(now: occurrence.fireDate, calendar: calendar)
        )

        guard case .message(let title, let body) = content else {
            return false
        }

        do {
            try await schedule(occurrence: occurrence, title: title, body: body)
            return true
        } catch {
            let errorText = String(describing: error)
            Self.logger.error(
                "scheduleFailed identifier=\(occurrence.identifier, privacy: .public) e=\(errorText, privacy: .private)"
            )
            return false
        }
    }

    private func schedule(
        occurrence: BehindScheduleOccurrence,
        title: String,
        body: String
    ) async throws {
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

    private func cancelPendingBehindScheduleAlerts() async {
        let identifiers = await notificationCenter.pendingNotificationRequests()
            .map(\.identifier)
            .filter {
                $0.hasPrefix(Self.identifierPrefix) || $0.hasPrefix(Self.retiredIdentifierPrefix)
            }

        guard identifiers.isEmpty == false else {
            return
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        Self.logger.debug("cancelledPending count=\(identifiers.count, privacy: .public)")
    }

    private func upcomingOccurrences(calendar: RoutineCalendar, now: Date) -> [BehindScheduleOccurrence] {
        let today = calendar.today(now: now)

        return (0..<Self.daysAhead).compactMap { offset in
            guard let day = day(after: offset, from: today, calendar: calendar) else {
                return nil
            }

            return occurrence(on: day, calendar: calendar, now: now)
        }
    }

    private func occurrence(
        on day: RoutineDay,
        calendar: RoutineCalendar,
        now: Date
    ) -> BehindScheduleOccurrence? {
        let minute = storedMinute()
        var components = DateComponents()
        components.year = day.year
        components.month = day.month
        components.day = day.day
        components.hour = minute / 60
        components.minute = minute % 60

        guard let fireDate = calendar.calendar.date(from: components), fireDate > now else {
            return nil
        }

        return BehindScheduleOccurrence(
            fireDate: fireDate,
            fireComponents: components,
            identifier: "\(Self.identifierPrefix)\(day.key)"
        )
    }

    private func storedMinute() -> Int {
        guard userDefaults.object(forKey: RoutineSettingsKeys.behindScheduleNotificationMinute) != nil else {
            return Self.defaultMinute
        }

        return userDefaults.integer(forKey: RoutineSettingsKeys.behindScheduleNotificationMinute)
    }

    private func day(after offset: Int, from today: RoutineDay, calendar: RoutineCalendar) -> RoutineDay? {
        guard offset > 0 else {
            return today
        }

        let components = DateComponents(year: today.year, month: today.month, day: today.day)
        guard
            let todayDate = calendar.calendar.date(from: components),
            let offsetDate = calendar.calendar.date(byAdding: .day, value: offset, to: todayDate)
        else {
            return nil
        }

        return calendar.day(containing: offsetDate)
    }

    private func routineSnapshots(context: ModelContext) throws -> [BehindScheduleRoutineSnapshot] {
        let groups = try fetchGroups(context)
        let routines = try fetchRoutines(context)
        let completions = try fetchCompletions(context)
        let completionDaysByRoutineID = completionDaysByRoutineID(from: completions)

        return orderedRoutines(groups: groups, routines: routines).map { routine in
            BehindScheduleRoutineSnapshot(
                name: routine.name,
                targetCount: routine.targetCount,
                period: routine.period,
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

private struct BehindScheduleOccurrence {
    let fireDate: Date
    let fireComponents: DateComponents
    let identifier: String
}
