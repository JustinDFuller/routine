import Foundation
import OSLog
import RoutineCore
import SwiftData

@MainActor
final class StarterDataService {
    static let seedMetadataKey = "starterDataSeedVersion"
    static let seedMetadataValue = "1"

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "Routine",
        category: "starter-data"
    )

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func seedIfNeeded(now: Date = .now) throws {
        guard try shouldSeedStarterData() else {
            return
        }

        var insertedGroups: [RoutineGroup] = []
        var insertedRoutines: [Routine] = []
        var insertedMetadata: [AppMetadata] = []

        do {
            let groups = makeGroups(now: now)

            for group in groups {
                context.insert(group)
                insertedGroups.append(group)
            }

            insertedRoutines = try insertRoutines(using: groups, now: now)

            let metadata = AppMetadata(
                key: Self.seedMetadataKey,
                value: Self.seedMetadataValue,
                updatedAt: now
            )
            context.insert(metadata)
            insertedMetadata.append(metadata)

        } catch {
            deleteInsertedSeedData(
                metadata: insertedMetadata,
                routines: insertedRoutines,
                groups: insertedGroups
            )
            throw error
        }

        do {
            try context.saveRoutineChanges()
            Self.logger.info(
                "Starter data seeded with \(insertedGroups.count, privacy: .public) groups and \(StarterSeed.routineCount, privacy: .public) routines."
            )
        } catch {
            deleteInsertedSeedData(
                metadata: insertedMetadata,
                routines: insertedRoutines,
                groups: insertedGroups
            )
            Self.logger.error("Starter data save failed: \(String(describing: error), privacy: .private)")
            throw error
        }
    }

    private func shouldSeedStarterData() throws -> Bool {
        do {
            let metadata = try context.metadata(key: Self.seedMetadataKey)
            Self.logger.info("Starter data already seeded with version \(metadata.value, privacy: .public).")
            return false
        } catch PersistenceError.metadataNotFound {
            Self.logger.info("Starter data metadata not found. Seeding starter data.")
            return true
        } catch {
            Self.logger.error("Starter data metadata fetch failed: \(String(describing: error), privacy: .private)")
            throw error
        }
    }

    private func makeGroups(now: Date) -> [RoutineGroup] {
        StarterSeed.groupSeeds.map {
            RoutineGroup(
                name: $0.name,
                sortOrder: $0.sortOrder,
                createdAt: now,
                updatedAt: now
            )
        }
    }

    private func insertRoutines(using groups: [RoutineGroup], now: Date) throws -> [Routine] {
        let groupsByName = Dictionary(uniqueKeysWithValues: groups.map { ($0.name, $0) })
        var insertedRoutines: [Routine] = []

        for groupSeed in StarterSeed.groupSeeds {
            guard let group = groupsByName[groupSeed.name] else {
                throw MissingStarterGroupError(groupName: groupSeed.name)
            }

            for routineSeed in groupSeed.routines {
                let routine = Routine(
                    name: routineSeed.name,
                    targetCount: routineSeed.targetCount,
                    period: routineSeed.period,
                    sortOrder: routineSeed.sortOrder,
                    group: group,
                    createdAt: now,
                    updatedAt: now
                )
                context.insert(routine)
                insertedRoutines.append(routine)
            }
        }

        return insertedRoutines
    }

    private func deleteInsertedSeedData(
        metadata: [AppMetadata],
        routines: [Routine],
        groups: [RoutineGroup]
    ) {
        for item in metadata {
            context.delete(item)
        }

        for routine in routines {
            context.delete(routine)
        }

        for group in groups {
            context.delete(group)
        }
    }
}

private enum StarterSeed {
    static let routineCount = groupSeeds.reduce(into: 0) { count, group in
        count += group.routines.count
    }

    static let groupSeeds: [GroupSeed] = [
        GroupSeed(
            name: "Morning",
            sortOrder: 0,
            routines: [
                RoutineSeed(name: "Wake up early", targetCount: 4, period: .weekly, sortOrder: 0),
                RoutineSeed(name: "Morning yoga", targetCount: 5, period: .weekly, sortOrder: 1),
            ]
        ),
        GroupSeed(
            name: "Movement",
            sortOrder: 1,
            routines: [
                RoutineSeed(name: "Functional workout", targetCount: 5, period: .weekly, sortOrder: 0),
                RoutineSeed(name: "Walk the dog", targetCount: 5, period: .weekly, sortOrder: 1),
                RoutineSeed(name: "Basketball", targetCount: 3, period: .weekly, sortOrder: 2),
            ]
        ),
        GroupSeed(
            name: "Family / Home",
            sortOrder: 2,
            routines: [
                RoutineSeed(name: "Mist plants", targetCount: 6, period: .weekly, sortOrder: 0),
                RoutineSeed(name: "Play with kids", targetCount: 5, period: .weekly, sortOrder: 1),
                RoutineSeed(name: "Do something nice for my wife", targetCount: 1, period: .weekly, sortOrder: 2),
                RoutineSeed(name: "Water plants", targetCount: 1, period: .weekly, sortOrder: 3),
                RoutineSeed(name: "Run razor cleaner", targetCount: 1, period: .weekly, sortOrder: 4),
            ]
        ),
        GroupSeed(
            name: "Learning / Creative",
            sortOrder: 3,
            routines: [
                RoutineSeed(name: "Learn math", targetCount: 3, period: .weekly, sortOrder: 0),
                RoutineSeed(name: "Duolingo", targetCount: 6, period: .weekly, sortOrder: 1),
                RoutineSeed(name: "Read a book", targetCount: 4, period: .weekly, sortOrder: 2),
                RoutineSeed(name: "Write something", targetCount: 3, period: .weekly, sortOrder: 3),
                RoutineSeed(name: "Practice piano", targetCount: 3, period: .weekly, sortOrder: 4),
                RoutineSeed(name: "Practice leetcode", targetCount: 3, period: .weekly, sortOrder: 5),
            ]
        ),
        GroupSeed(
            name: "Evening",
            sortOrder: 4,
            routines: [
                RoutineSeed(name: "Evening yoga", targetCount: 4, period: .weekly, sortOrder: 0)
            ]
        ),
        GroupSeed(
            name: "Monthly Maintenance",
            sortOrder: 5,
            routines: [
                RoutineSeed(name: "Clean air purifiers", targetCount: 1, period: .monthly, sortOrder: 0),
                RoutineSeed(name: "Rotate plants", targetCount: 1, period: .monthly, sortOrder: 1),
                RoutineSeed(name: "Whiten teeth", targetCount: 1, period: .monthly, sortOrder: 2),
            ]
        ),
    ]
}

private struct GroupSeed {
    let name: String
    let sortOrder: Int
    let routines: [RoutineSeed]
}

private struct RoutineSeed {
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let sortOrder: Int
}

private struct MissingStarterGroupError: Error {
    let groupName: String
}
