import Foundation

extension String {
    var routineAccessibilityIdentifierComponent: String {
        let normalized = lowercased().map { character in
            if character.isLetter || character.isNumber {
                return character
            }

            return "-"
        }

        let collapsed = String(normalized).split(separator: "-").joined(separator: "-")
        return collapsed.isEmpty ? "item" : collapsed
    }
}
