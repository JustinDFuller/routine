import XCTest

@testable import RoutineCore

final class RoutineValidationTests: XCTestCase {
    func testRoutineNameIsTrimmed() throws {
        XCTAssertEqual(try trimmedRoutineName("  Read  "), "Read")
    }

    func testGroupNameIsTrimmed() throws {
        XCTAssertEqual(try trimmedGroupName("\n Home \t"), "Home")
    }

    func testWhitespaceOnlyNamesFail() {
        XCTAssertThrowsError(try trimmedRoutineName("   ")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
        }

        XCTAssertThrowsError(try trimmedGroupName("\n\t")) { error in
            XCTAssertEqual(error as? RoutineValidationError, .emptyName)
        }
    }

    func testWeeklyTargetRangeIsOneThroughSeven() {
        XCTAssertNoThrow(try validateTargetCount(1, for: .weekly))
        XCTAssertNoThrow(try validateTargetCount(7, for: .weekly))

        XCTAssertThrowsError(try validateTargetCount(0, for: .weekly)) { error in
            XCTAssertEqual(
                error as? RoutineValidationError,
                .invalidTargetCount(period: .weekly, min: 1, max: 7)
            )
        }
    }

    func testMonthlyTargetRangeIsOneThroughThirtyOne() {
        XCTAssertNoThrow(try validateTargetCount(1, for: .monthly))
        XCTAssertNoThrow(try validateTargetCount(31, for: .monthly))

        XCTAssertThrowsError(try validateTargetCount(32, for: .monthly)) { error in
            XCTAssertEqual(
                error as? RoutineValidationError,
                .invalidTargetCount(period: .monthly, min: 1, max: 31)
            )
        }
    }

    func testGroupNameUniquenessIsTrimmedAndCaseInsensitive() {
        XCTAssertThrowsError(
            try validateUniqueGroupName(" home ", existingNames: ["Home", "Work"])
        ) { error in
            XCTAssertEqual(error as? RoutineValidationError, .duplicateGroupName)
        }
    }

    func testExcludedCurrentGroupValueDoesNotFailUniquenessCheck() {
        XCTAssertNoThrow(
            try validateUniqueGroupName(
                " home ",
                existingNames: ["Home", "Work"],
                excluding: "Home"
            )
        )
    }
}
