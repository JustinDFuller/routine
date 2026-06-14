import XCTest

@testable import RoutineCore

final class WeekdayTests: XCTestCase {
    func testRawValueMatchesCalendarFirstWeekdayNumbering() {
        XCTAssertEqual(Weekday.sunday.rawValue, 1)
        XCTAssertEqual(Weekday.monday.rawValue, 2)
        XCTAssertEqual(Weekday.tuesday.rawValue, 3)
        XCTAssertEqual(Weekday.wednesday.rawValue, 4)
        XCTAssertEqual(Weekday.thursday.rawValue, 5)
        XCTAssertEqual(Weekday.friday.rawValue, 6)
        XCTAssertEqual(Weekday.saturday.rawValue, 7)
    }

    func testDisplayNameIsFullDayName() {
        XCTAssertEqual(Weekday.sunday.displayName, "Sunday")
        XCTAssertEqual(Weekday.monday.displayName, "Monday")
        XCTAssertEqual(Weekday.tuesday.displayName, "Tuesday")
        XCTAssertEqual(Weekday.wednesday.displayName, "Wednesday")
        XCTAssertEqual(Weekday.thursday.displayName, "Thursday")
        XCTAssertEqual(Weekday.friday.displayName, "Friday")
        XCTAssertEqual(Weekday.saturday.displayName, "Saturday")
    }

    func testShortSymbolIsThreeLetterAbbreviation() {
        XCTAssertEqual(Weekday.sunday.shortSymbol, "Sun")
        XCTAssertEqual(Weekday.monday.shortSymbol, "Mon")
        XCTAssertEqual(Weekday.tuesday.shortSymbol, "Tue")
        XCTAssertEqual(Weekday.wednesday.shortSymbol, "Wed")
        XCTAssertEqual(Weekday.thursday.shortSymbol, "Thu")
        XCTAssertEqual(Weekday.friday.shortSymbol, "Fri")
        XCTAssertEqual(Weekday.saturday.shortSymbol, "Sat")
    }

    func testAllCasesAreOrderedSundayThroughSaturday() {
        XCTAssertEqual(
            Weekday.allCases,
            [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        )
    }

    func testInitFromStorageValueDecodesValidRawValues() {
        XCTAssertEqual(Weekday(storageValue: 1), .sunday)
        XCTAssertEqual(Weekday(storageValue: 2), .monday)
        XCTAssertEqual(Weekday(storageValue: 7), .saturday)
    }

    func testInitFromStorageValueFallsBackToSundayForOutOfRangeValues() {
        XCTAssertEqual(Weekday(storageValue: 0), .sunday)
        XCTAssertEqual(Weekday(storageValue: 8), .sunday)
        XCTAssertEqual(Weekday(storageValue: -1), .sunday)
    }
}
