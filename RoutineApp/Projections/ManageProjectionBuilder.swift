import Foundation
import RoutineCore
import SwiftData

@MainActor
final class ManageProjectionBuilder {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func build() throws -> ManageRoutinesViewData {
        let groups = try fetchGroups()
        let routines = try fetchRoutines()
        return build(groups: groups, routines: routines)
    }

    func build(
        groups: [RoutineGroup],
        routines: [Routine]
    ) -> ManageRoutinesViewData {
        let routinesByGroupID = Dictionary(grouping: routines, by: \.groupID)

        var sections = groups.map { group in
            ManageGroupSectionViewData(
                id: group.id,
                name: group.name,
                routines: (routinesByGroupID[group.id] ?? []).map(buildRow(for:))
            )
        }

        let knownGroupIDs = Set(groups.map(\.id))
        let ungroupedRoutines = routines.filter { knownGroupIDs.contains($0.groupID) == false }

        if ungroupedRoutines.isEmpty == false {
            sections.append(
                ManageGroupSectionViewData(
                    id: ProjectionFallbackSection.ungrouped.id,
                    name: ProjectionFallbackSection.ungrouped.name,
                    routines: ungroupedRoutines.map(buildRow(for:))
                )
            )
        }

        return ManageRoutinesViewData(
            groupChoices: groups.map { ManageGroupChoiceViewData(id: $0.id, name: $0.name) },
            sections: sections,
            isEmpty: routines.isEmpty
        )
    }
}

@MainActor
extension ManageProjectionBuilder {
    fileprivate func fetchGroups() throws -> [RoutineGroup] {
        let descriptor = FetchDescriptor<RoutineGroup>(
            sortBy: [SortDescriptor(\RoutineGroup.sortOrder), SortDescriptor(\RoutineGroup.name)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchGroups(context, descriptor)
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func fetchRoutines() throws -> [Routine] {
        let descriptor = FetchDescriptor<Routine>(
            sortBy: [SortDescriptor(\Routine.sortOrder), SortDescriptor(\Routine.createdAt)]
        )

        do {
            return try RoutinePersistenceFetchExecutor.fetchRoutines(context, descriptor)
        } catch {
            throw PersistenceError.fetchFailed(String(describing: error))
        }
    }

    fileprivate func buildRow(for routine: Routine) -> ManageRoutineRowViewData {
        ManageRoutineRowViewData(
            id: routine.id,
            name: routine.name,
            targetCount: routine.targetCount,
            period: routine.period,
            groupID: routine.groupID,
            summaryText: summaryText(
                targetCount: routine.targetCount,
                period: routine.period
            )
        )
    }

    fileprivate func summaryText(targetCount: Int, period: RoutinePeriod) -> String {
        switch period {
        case .weekly:
            "\(targetCount) per week"
        case .monthly:
            "\(targetCount) per month"
        }
    }
}
