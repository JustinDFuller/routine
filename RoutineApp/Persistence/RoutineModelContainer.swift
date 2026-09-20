import Foundation
import OSLog
import SwiftData

enum RoutineModelContainer {
    static let appGroupID = "group.com.justinfuller.routines"
    static let schema = Schema([RoutineGroup.self, Routine.self, RoutineCompletion.self, AppMetadata.self])

    private static let migrationLogger = AppDiagnostics.logger(.appLifecycle)
    private static let legacyStoreMigratedKey = "legacyStoreMigratedToAppGroup"
    private static let storeFileSuffixes = ["", "-wal", "-shm"]

    static func shared() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    @MainActor
    static func persistent() throws -> ModelContainer {
        try shared()
    }

    @MainActor
    static func inMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Copies the pre-App-Group SwiftData store into the App Group container the first time the
    /// updated build runs. Idempotent (guarded by a flag in the App Group defaults) and safe
    /// against a widget having created an empty group store first. App-process only: the legacy
    /// store lives in the app's private sandbox and is unreachable from the widget.
    static func migrateLegacyStoreIfNeeded() {
        let defaults = UserDefaults(suiteName: appGroupID)
        guard defaults?.bool(forKey: legacyStoreMigratedKey) != true else {
            return
        }

        let legacyURL = ModelConfiguration(schema: schema).url
        let groupURL = ModelConfiguration(
            schema: schema,
            groupContainer: .identifier(appGroupID)
        ).url

        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: legacyURL.path) {
            do {
                try copyLegacyStore(from: legacyURL, to: groupURL, fileManager: fileManager)
                migrationLogger.info("legacyStoreMigration copied=1")
            } catch {
                migrationLogger.error(
                    "legacyStoreMigration failed e=\(String(describing: error), privacy: .private)"
                )
                return
            }
        } else {
            migrationLogger.info("legacyStoreMigration copied=0 reason=noLegacyStore")
        }

        defaults?.set(true, forKey: legacyStoreMigratedKey)

        // TODO: After this migration has shipped and been verified in a release, delete the
        // legacy store files at `legacyURL` (and its -wal/-shm) and remove this migration code.
        // Kept in place for now as a rollback safety net.
    }

    static func copyLegacyStore(from legacyURL: URL, to groupURL: URL, fileManager: FileManager) throws {
        try fileManager.createDirectory(
            at: groupURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        for suffix in storeFileSuffixes {
            let source = sidecarURL(for: legacyURL, suffix: suffix)
            let destination = sidecarURL(for: groupURL, suffix: suffix)

            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }

            if fileManager.fileExists(atPath: source.path) {
                try fileManager.copyItem(at: source, to: destination)
            }
        }
    }

    private static func sidecarURL(for storeURL: URL, suffix: String) -> URL {
        guard suffix.isEmpty == false else {
            return storeURL
        }

        return
            storeURL
            .deletingLastPathComponent()
            .appendingPathComponent(storeURL.lastPathComponent + suffix)
    }
}
