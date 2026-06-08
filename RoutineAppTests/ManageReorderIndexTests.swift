import Foundation
import XCTest

@testable import Routine

final class ManageReorderIndexTests: XCTestCase {
    func testServiceIndexTranslatesDownwardMoveWithinList() {
        XCTAssertEqual(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 0), destination: 2, itemCount: 3),
            1
        )
        XCTAssertEqual(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 0), destination: 3, itemCount: 3),
            2
        )
        XCTAssertEqual(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 2), destination: 0, itemCount: 3),
            0
        )
        XCTAssertEqual(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 0), destination: 1, itemCount: 3),
            0
        )
        XCTAssertEqual(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 2), destination: 3, itemCount: 3),
            2
        )
    }

    func testServiceIndexReturnsNilForUnsupportedOrInvalidSources() {
        XCTAssertNil(ManageReorderIndex.serviceIndex(from: [], destination: 0, itemCount: 3))
        XCTAssertNil(
            ManageReorderIndex.serviceIndex(from: IndexSet([0, 1]), destination: 2, itemCount: 3)
        )
        XCTAssertNil(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 0), destination: 0, itemCount: 0)
        )
        XCTAssertNil(
            ManageReorderIndex.serviceIndex(from: IndexSet(integer: 3), destination: 0, itemCount: 3)
        )
    }
}
