import Foundation
import OSLog

enum AppDiagnostics {
    enum Category: String {
        case appLifecycle = "app.lifecycle"
        case persistence
        case starterData = "starter-data"
        case tracking
        case management
        case projection
        case routing
        case ui
    }

    private static let subsystem = Bundle.main.bundleIdentifier ?? "Routine"

    private static let appLifecycleLogger = Logger(
        subsystem: subsystem,
        category: Category.appLifecycle.rawValue
    )
    private static let persistenceLogger = Logger(
        subsystem: subsystem,
        category: Category.persistence.rawValue
    )
    private static let starterDataLogger = Logger(
        subsystem: subsystem,
        category: Category.starterData.rawValue
    )
    private static let trackingLogger = Logger(
        subsystem: subsystem,
        category: Category.tracking.rawValue
    )
    private static let managementLogger = Logger(
        subsystem: subsystem,
        category: Category.management.rawValue
    )
    private static let projectionLogger = Logger(
        subsystem: subsystem,
        category: Category.projection.rawValue
    )
    private static let routingLogger = Logger(
        subsystem: subsystem,
        category: Category.routing.rawValue
    )
    private static let uiLogger = Logger(
        subsystem: subsystem,
        category: Category.ui.rawValue
    )

    private static let appLifecycleSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.appLifecycle.rawValue
    )
    private static let persistenceSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.persistence.rawValue
    )
    private static let starterDataSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.starterData.rawValue
    )
    private static let trackingSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.tracking.rawValue
    )
    private static let managementSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.management.rawValue
    )
    private static let projectionSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.projection.rawValue
    )
    private static let routingSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.routing.rawValue
    )
    private static let uiSignposter = OSSignposter(
        subsystem: subsystem,
        category: Category.ui.rawValue
    )

    static func logger(_ category: Category) -> Logger {
        switch category {
        case .appLifecycle:
            appLifecycleLogger
        case .persistence:
            persistenceLogger
        case .starterData:
            starterDataLogger
        case .tracking:
            trackingLogger
        case .management:
            managementLogger
        case .projection:
            projectionLogger
        case .routing:
            routingLogger
        case .ui:
            uiLogger
        }
    }

    static func signposter(_ category: Category) -> OSSignposter {
        switch category {
        case .appLifecycle:
            appLifecycleSignposter
        case .persistence:
            persistenceSignposter
        case .starterData:
            starterDataSignposter
        case .tracking:
            trackingSignposter
        case .management:
            managementSignposter
        case .projection:
            projectionSignposter
        case .routing:
            routingSignposter
        case .ui:
            uiSignposter
        }
    }
}
