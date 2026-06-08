import Foundation
import Observation
import RoutineCore

enum RoutineFormError: LocalizedError, Equatable, Sendable {
    case validation(RoutineValidationError)
    case missingGroup

    var errorDescription: String? {
        switch self {
        case .validation(let error):
            error.errorDescription
        case .missingGroup:
            "Choose a group."
        }
    }
}

struct RoutineFormSnapshot: Equatable, Sendable {
    let routineID: UUID
    let name: String
    let targetCount: Int
    let period: RoutinePeriod
    let groupID: UUID?

    init(
        routineID: UUID,
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        groupID: UUID?
    ) {
        self.routineID = routineID
        self.name = name
        self.targetCount = targetCount
        self.period = period
        self.groupID = groupID
    }

    init(
        row: ManageRoutineRowViewData,
        availableGroupIDs: Set<UUID>
    ) {
        self.init(
            routineID: row.id,
            name: row.name,
            targetCount: row.targetCount,
            period: row.period,
            groupID: availableGroupIDs.contains(row.groupID) ? row.groupID : nil
        )
    }
}

enum RoutineFormPresentation: Identifiable, Equatable, Sendable {
    case add(initialGroupID: UUID?)
    case edit(RoutineFormSnapshot)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let snapshot):
            snapshot.routineID.uuidString
        }
    }

    var title: String {
        switch self {
        case .add:
            "Add Routine"
        case .edit:
            "Edit Routine"
        }
    }

    var saveTitle: String {
        switch self {
        case .add:
            "Add"
        case .edit:
            "Save"
        }
    }

    var editingRoutineID: UUID? {
        switch self {
        case .add:
            nil
        case .edit(let snapshot):
            snapshot.routineID
        }
    }
}

@Observable
final class RoutineFormState {
    var name: String {
        didSet { clearValidationError() }
    }

    var targetCount: Int {
        didSet { clearValidationError() }
    }

    var period: RoutinePeriod {
        didSet {
            targetCount = clampedTargetCount(targetCount, for: period)
            clearValidationError()
        }
    }

    var groupID: UUID? {
        didSet { clearValidationError() }
    }

    private(set) var validationError: RoutineFormError?

    init(presentation: RoutineFormPresentation) {
        switch presentation {
        case .add(let initialGroupID):
            name = ""
            targetCount = 1
            period = .weekly
            groupID = initialGroupID
        case .edit(let snapshot):
            name = snapshot.name
            targetCount = snapshot.targetCount
            period = snapshot.period
            groupID = snapshot.groupID
        }

        targetCount = clampedTargetCount(targetCount, for: period)
    }

    var validationMessage: String? {
        validationError?.errorDescription
    }

    func makeDraft() throws -> RoutineDraft {
        do {
            let trimmedName = try trimmedRoutineName(name)
            try validateTargetCount(targetCount, for: period)

            guard let groupID else {
                let error = RoutineFormError.missingGroup
                validationError = error
                throw error
            }

            validationError = nil
            return RoutineDraft(
                name: trimmedName,
                targetCount: targetCount,
                period: period,
                groupID: groupID
            )
        } catch let error as RoutineValidationError {
            let formError = RoutineFormError.validation(error)
            validationError = formError
            throw formError
        } catch let error as RoutineFormError {
            validationError = error
            throw error
        } catch {
            validationError = nil
            throw error
        }
    }

    func clearValidationError() {
        validationError = nil
    }

    var targetRange: ClosedRange<Int> {
        switch period {
        case .weekly:
            1...7
        case .monthly:
            1...31
        }
    }

    private func clampedTargetCount(_ value: Int, for period: RoutinePeriod) -> Int {
        let range: ClosedRange<Int>
        switch period {
        case .weekly:
            range = 1...7
        case .monthly:
            range = 1...31
        }

        return min(max(value, range.lowerBound), range.upperBound)
    }
}
