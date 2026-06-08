import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class GroupFormStateTests: XCTestCase {
    func testMakeNameTrimsValidNames() throws {
        let state = GroupFormState(name: "  Health  ")

        let name = try state.makeName(existingNames: ["Work"])

        XCTAssertEqual(name, "Health")
        XCTAssertNil(state.validationMessage)
    }

    func testEmptyNameBlocksSaveAndExposesValidationMessage() throws {
        let state = GroupFormState(name: " \n ")

        XCTAssertThrowsError(try state.makeName(existingNames: [])) { error in
            XCTAssertEqual(error as? GroupFormError, .validation(.emptyName))
        }
        XCTAssertEqual(state.validationMessage, "Name can't be empty.")
    }

    func testDuplicateNameBlocksSave() throws {
        let state = GroupFormState(name: "Home")

        XCTAssertThrowsError(try state.makeName(existingNames: ["Home", "Work"])) { error in
            XCTAssertEqual(error as? GroupFormError, .validation(.duplicateGroupName))
        }
        XCTAssertEqual(state.validationMessage, "A group with that name already exists.")
    }

    func testCaseInsensitiveDuplicateNameBlocksSave() throws {
        let state = GroupFormState(name: " home ")

        XCTAssertThrowsError(try state.makeName(existingNames: ["Home", "Work"])) { error in
            XCTAssertEqual(error as? GroupFormError, .validation(.duplicateGroupName))
        }
        XCTAssertEqual(state.validationMessage, "A group with that name already exists.")
    }

    func testRenameToSameNameIsAllowedWhenExcludingCurrentName() throws {
        let state = GroupFormState(name: " home ")

        let name = try state.makeName(
            existingNames: ["Home", "Work"],
            excluding: "Home"
        )

        XCTAssertEqual(name, "home")
        XCTAssertNil(state.validationMessage)
    }
}
