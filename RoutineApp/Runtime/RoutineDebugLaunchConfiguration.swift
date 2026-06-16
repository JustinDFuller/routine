import Foundation

struct RoutineDebugLaunchConfiguration: Equatable, Sendable {
    enum StoreMode: Equatable, Sendable {
        case persistent
        case inMemory
    }

    enum LaunchRoute: Equatable, Sendable {
        case missingHistory
        case morningYogaHistoryWithCompletion
    }

    static let current = RoutineDebugLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    let storeMode: StoreMode
    let resetsStore: Bool
    let forcesBootstrapFailure: Bool
    let runtime: RoutineRuntimeConfiguration
    let launchRoute: LaunchRoute?
    let collapseCompletedEnabled: Bool

    init(
        storeMode: StoreMode = .persistent,
        resetsStore: Bool = false,
        forcesBootstrapFailure: Bool = false,
        runtime: RoutineRuntimeConfiguration = RoutineRuntimeConfiguration(),
        launchRoute: LaunchRoute? = nil,
        collapseCompletedEnabled: Bool = false
    ) {
        self.storeMode = storeMode
        self.resetsStore = resetsStore
        self.forcesBootstrapFailure = forcesBootstrapFailure
        self.runtime = runtime
        self.launchRoute = launchRoute
        self.collapseCompletedEnabled = collapseCompletedEnabled
    }

    init(arguments: [String], calendar: Calendar = .current) {
        #if DEBUG
            let usesSeededInMemoryStore = arguments.contains("-routine-use-in-memory-store")
            let usesEmptyInMemoryStore = arguments.contains("-routine-empty-in-memory-store")
            let starterSeedVersion =
                Self.argumentValue(after: "-routine-starter-seed-version", in: arguments)
                ?? StarterDataService.seedMetadataValue

            self.init(
                storeMode: usesSeededInMemoryStore || usesEmptyInMemoryStore ? .inMemory : .persistent,
                resetsStore: arguments.contains("-routine-reset-store"),
                forcesBootstrapFailure: arguments.contains("-routine-force-bootstrap-failure"),
                runtime: RoutineRuntimeConfiguration(
                    fixedNow: Self.fixedNow(in: arguments, calendar: calendar),
                    disablesAnimations: arguments.contains("-routine-disable-animations"),
                    skipsStarterSeeding: usesEmptyInMemoryStore,
                    starterSeedVersion: starterSeedVersion,
                    screenshotFixture: Self.screenshotFixture(in: arguments),
                    forcedColorScheme: Self.forcedColorScheme(in: arguments)
                ),
                launchRoute: Self.launchRoute(in: arguments),
                collapseCompletedEnabled: arguments.contains("-routine-collapse-completed-enabled")
            )
        #else
            self.init()
        #endif
    }

    var initialPath: [AppRoute] {
        guard let launchRoute else {
            return [AppRoute]()
        }

        switch launchRoute {
        case .missingHistory:
            return [.routineHistory(routineID: Self.missingHistoryRoutineID)]
        case .morningYogaHistoryWithCompletion:
            return [AppRoute]()
        }
    }

    var opensMorningYogaHistoryWithCompletion: Bool {
        launchRoute == .morningYogaHistoryWithCompletion
    }

    static var missingHistoryRoutineID: UUID {
        guard let uuid = UUID(uuidString: "00000000-0000-0000-0000-000000000099") else {
            preconditionFailure("Expected valid missing-history debug UUID.")
        }

        return uuid
    }

    private static func launchRoute(in arguments: [String]) -> LaunchRoute? {
        if arguments.contains("-routine-open-morning-yoga-history-with-completion") {
            return .morningYogaHistoryWithCompletion
        }

        if arguments.contains("-routine-open-missing-history-route") {
            return .missingHistory
        }

        return nil
    }

    private static func screenshotFixture(in arguments: [String]) -> RoutineScreenshotFixture? {
        guard let rawValue = argumentValue(after: "-routine-screenshot-fixture", in: arguments) else {
            return nil
        }

        return RoutineScreenshotFixture(rawValue: rawValue)
    }

    private static func forcedColorScheme(
        in arguments: [String]
    ) -> RoutineRuntimeConfiguration.ForcedColorScheme? {
        guard let rawValue = argumentValue(after: "-routine-force-color-scheme", in: arguments) else {
            return nil
        }

        return RoutineRuntimeConfiguration.ForcedColorScheme(rawValue: rawValue)
    }

    private static func argumentValue(
        after flag: String,
        in arguments: [String]
    ) -> String? {
        guard let index = arguments.firstIndex(of: flag) else {
            return nil
        }

        let valueIndex = arguments.index(after: index)
        guard arguments.indices.contains(valueIndex) else {
            return nil
        }

        let value = arguments[valueIndex]
        guard value.hasPrefix("-") == false else {
            return nil
        }

        return value
    }

    private static func fixedNow(
        in arguments: [String],
        calendar: Calendar
    ) -> Date? {
        guard let value = argumentValue(after: "-routine-fixed-date", in: arguments) else {
            return nil
        }

        let parts = value.split(separator: "-", omittingEmptySubsequences: false)
        guard
            parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }

        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        components.minute = 0
        components.second = 0

        guard let date = calendar.date(from: components) else {
            return nil
        }

        let resolvedComponents = calendar.dateComponents([.year, .month, .day], from: date)
        guard
            resolvedComponents.year == year,
            resolvedComponents.month == month,
            resolvedComponents.day == day
        else {
            return nil
        }

        return date
    }
}
