import XCTest

@testable import RoutineCore

final class SortNormalizationTests: XCTestCase {
    func testEmptyInputReturnsEmptyDictionary() {
        XCTAssertEqual(normalizedSortOrders(for: [String]()), [:])
    }

    func testSingleItemStartsAtZero() {
        XCTAssertEqual(normalizedSortOrders(for: ["a"]), ["a": 0])
    }

    func testAlreadyContiguousInputPreservesOrder() {
        XCTAssertEqual(
            normalizedSortOrders(for: ["a", "b", "c"]),
            ["a": 0, "b": 1, "c": 2]
        )
    }

    func testReorderedInputUsesSuppliedOrder() {
        XCTAssertEqual(
            normalizedSortOrders(for: ["c", "a", "b"]),
            ["c": 0, "a": 1, "b": 2]
        )
    }

    func testDuplicateIdsUseFirstOccurrenceOnly() {
        XCTAssertEqual(
            normalizedSortOrders(for: ["a", "b", "a", "c", "b"]),
            ["a": 0, "b": 1, "c": 2]
        )
    }
}
