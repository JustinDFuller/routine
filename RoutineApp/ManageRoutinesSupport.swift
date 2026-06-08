import Foundation

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

    var id: String {
        switch self {
        case .routine(let presentation):
            "routine-\(presentation.id)"
        case .group(let presentation):
            "group-\(presentation.id)"
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
            "Rename Group"
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
}

struct PendingGroupDeletion: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
}
