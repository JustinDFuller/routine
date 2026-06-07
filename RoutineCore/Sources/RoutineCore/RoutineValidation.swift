import Foundation

public enum RoutineValidationError: LocalizedError, Equatable, Sendable {
    case emptyName
    case invalidTargetCount(period: RoutinePeriod, min: Int, max: Int)
    case duplicateGroupName

    public var errorDescription: String? {
        switch self {
        case .emptyName:
            "Name can't be empty."
        case .invalidTargetCount(let period, let min, let max):
            switch period {
            case .weekly:
                "Weekly routines must be between \(min) and \(max)."
            case .monthly:
                "Monthly routines must be between \(min) and \(max)."
            }
        case .duplicateGroupName:
            "A group with that name already exists."
        }
    }
}

public func trimmedRoutineName(_ name: String) throws -> String {
    try trimmedName(name)
}

public func trimmedGroupName(_ name: String) throws -> String {
    try trimmedName(name)
}

public func validateTargetCount(_ count: Int, for period: RoutinePeriod) throws {
    let limits: ClosedRange<Int>
    switch period {
    case .weekly:
        limits = 1...7
    case .monthly:
        limits = 1...31
    }

    guard limits.contains(count) else {
        throw RoutineValidationError.invalidTargetCount(period: period, min: limits.lowerBound, max: limits.upperBound)
    }
}

public func validateUniqueGroupName(
    _ name: String,
    existingNames: [String],
    excluding excludedName: String? = nil
) throws {
    let normalizedCandidate = try normalizedName(name)
    let normalizedExcluded = excludedName.flatMap { try? normalizedName($0) }

    for existingName in existingNames {
        let normalizedExisting = try normalizedName(existingName)

        if normalizedExisting == normalizedExcluded {
            continue
        }

        if normalizedExisting == normalizedCandidate {
            throw RoutineValidationError.duplicateGroupName
        }
    }
}

private func trimmedName(_ name: String) throws -> String {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.isEmpty == false else {
        throw RoutineValidationError.emptyName
    }

    return trimmed
}

private func normalizedName(_ name: String) throws -> String {
    try trimmedName(name).lowercased()
}
