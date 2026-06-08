import Foundation
import Observation
import RoutineCore

enum GroupFormError: LocalizedError, Equatable, Sendable {
    case validation(RoutineValidationError)

    var errorDescription: String? {
        switch self {
        case .validation(let error):
            error.errorDescription
        }
    }
}

@Observable
final class GroupFormState {
    var name: String {
        didSet { clearValidationError() }
    }

    private(set) var validationError: GroupFormError?

    init(name: String = "") {
        self.name = name
    }

    var validationMessage: String? {
        validationError?.errorDescription
    }

    func makeName(
        existingNames: [String],
        excluding excludedName: String? = nil
    ) throws -> String {
        do {
            let trimmedName = try trimmedGroupName(name)
            let comparisonNames =
                if let excludedName {
                    existingNames.filter {
                        $0.caseInsensitiveCompare(excludedName) != .orderedSame
                    }
                } else {
                    existingNames
                }

            try validateUniqueGroupName(trimmedName, existingNames: comparisonNames)
            validationError = nil
            return trimmedName
        } catch let error as RoutineValidationError {
            let formError = GroupFormError.validation(error)
            validationError = formError
            throw formError
        } catch let error as GroupFormError {
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
}
