import Foundation

enum ManageReorderIndex {
    static func serviceIndex(
        from source: IndexSet,
        destination: Int,
        itemCount: Int
    ) -> Int? {
        guard source.count == 1, let sourceIndex = source.first else {
            return nil
        }

        guard (0..<itemCount).contains(sourceIndex) else {
            return nil
        }

        let clampedDestination = min(max(destination, 0), itemCount)
        return clampedDestination > sourceIndex ? clampedDestination - 1 : clampedDestination
    }
}

struct ManageAlertPresentation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String?

    static let missingGroup = ManageAlertPresentation(
        title: "A routine needs a group.",
        message: nil
    )

    static let routineNotFound = ManageAlertPresentation(
        title: "This routine no longer exists.",
        message: nil
    )

    static let groupNotFound = ManageAlertPresentation(
        title: "This group no longer exists.",
        message: nil
    )

    static let nonEmptyGroupBlocked = ManageAlertPresentation(
        title: "Delete the routines in this group first.",
        message: nil
    )

    static func routineSaveFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not save routine changes.", message: detail)
    }

    static func routineDeleteFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not delete routine.", message: detail)
    }

    static func groupSaveFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not save group changes.", message: detail)
    }

    static func groupDeleteFailure(detail: String?) -> ManageAlertPresentation {
        ManageAlertPresentation(title: "Could not delete group.", message: detail)
    }
}

enum ManageSheetPresentation: Identifiable, Equatable {
    case routine(RoutineFormPresentation)
    case group(GroupFormPresentation)
    case settings

    var id: String {
        switch self {
        case .routine(let presentation):
            "routine-\(presentation.id)"
        case .group(let presentation):
            "group-\(presentation.id)"
        case .settings:
            "settings"
        }
    }
}

struct GroupFormSnapshot: Equatable, Sendable {
    let groupID: UUID
    let name: String
}

enum GroupFormPresentation: Equatable, Sendable {
    case add
    case rename(GroupFormSnapshot)

    var id: String {
        switch self {
        case .add:
            "add"
        case .rename(let snapshot):
            snapshot.groupID.uuidString
        }
    }

    var title: String {
        switch self {
        case .add:
            "Add Group"
        case .rename:
            "Edit Group"
        }
    }

    var saveTitle: String {
        switch self {
        case .add:
            "Add"
        case .rename:
            "Save"
        }
    }

    var initialName: String {
        switch self {
        case .add:
            ""
        case .rename(let snapshot):
            snapshot.name
        }
    }

    var excludedName: String? {
        switch self {
        case .add:
            nil
        case .rename(let snapshot):
            snapshot.name
        }
    }

    var editingGroupID: UUID? {
        switch self {
        case .add:
            nil
        case .rename(let snapshot):
            snapshot.groupID
        }
    }
}

struct PendingGroupDeletion: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
}
