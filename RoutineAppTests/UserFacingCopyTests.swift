import XCTest

final class UserFacingCopyTests: XCTestCase {
    func testEditedUserFacingSwiftFilesDoNotUseThreePeriodEllipsesInStringLiterals() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let relativePaths = [
            "RoutineApp/BreakView.swift",
            "RoutineApp/TodayDashboardView+Content.swift",
            "RoutineApp/Components/CollapsedRoutineRowView.swift",
            "RoutineApp/Components/RoutineCardView.swift",
            "RoutineApp/AddEditRoutineView.swift"
        ]

        for relativePath in relativePaths {
            let fileURL = repositoryRoot.appendingPathComponent(relativePath)
            let contents = try String(contentsOf: fileURL, encoding: .utf8)
            XCTAssertFalse(
                containsThreePeriodEllipsisInStringLiteral(contents),
                "\(relativePath) contains a literal three-period ellipsis in a string literal."
            )
        }
    }

    private func containsThreePeriodEllipsisInStringLiteral(_ contents: String) -> Bool {
        let prohibited = String(repeating: ".", count: 3)
        var isInString = false
        var isEscaped = false
        var buffer = ""

        for character in contents {
            if isInString {
                if isEscaped {
                    isEscaped = false
                    continue
                }

                if character == "\\" {
                    isEscaped = true
                    continue
                }

                if character == "\"" {
                    if buffer.contains(prohibited) {
                        return true
                    }
                    buffer = ""
                    isInString = false
                    continue
                }

                buffer.append(character)
            } else if character == "\"" {
                isInString = true
            }
        }

        return false
    }
}
