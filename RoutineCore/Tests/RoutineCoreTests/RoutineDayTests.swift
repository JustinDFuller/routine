import XCTest

@testable import RoutineCore

final class RoutineDayTests: XCTestCase {
    func testKeyFormatsSingleDigitMonthAndDayWithZeroPadding() throws {
        let day = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))
        XCTAssertEqual(day.key, "2024-06-02")
    }

    func testKeyFormatsDoubleDigitMonthAndDayWithoutChangingValues() throws {
        let day = try XCTUnwrap(RoutineDay(year: 2024, month: 11, day: 12))
        XCTAssertEqual(day.key, "2024-11-12")
    }

    func testEqualityAndOrderingUseStableDayKeys() throws {
        let earlier = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 2))
        let sameDay = try XCTUnwrap(RoutineDay(key: "2024-06-02"))
        let later = try XCTUnwrap(RoutineDay(year: 2024, month: 6, day: 3))

        XCTAssertEqual(earlier, sameDay)
        XCTAssertLessThan(earlier, later)
        XCTAssertEqual([later, earlier].sorted(), [earlier, later])
    }

    func testParsesValidKey() throws {
        let day = try XCTUnwrap(RoutineDay(key: "2025-02-09"))
        XCTAssertEqual(day.year, 2025)
        XCTAssertEqual(day.month, 2)
        XCTAssertEqual(day.day, 9)
    }

    func testRejectsMalformedKeys() {
        XCTAssertNil(RoutineDay(key: "2025-2-09"))
        XCTAssertNil(RoutineDay(key: "2025-02-9"))
        XCTAssertNil(RoutineDay(key: "2025/02/09"))
        XCTAssertNil(RoutineDay(key: "abc"))
        XCTAssertNil(RoutineDay(key: "2025-02-09-extra"))
    }

    func testRejectsImpossibleDates() {
        XCTAssertNil(RoutineDay(key: "2025-13-01"))
        XCTAssertNil(RoutineDay(key: "2025-02-30"))
        XCTAssertNil(RoutineDay(year: 2025, month: 4, day: 31))
    }
}
