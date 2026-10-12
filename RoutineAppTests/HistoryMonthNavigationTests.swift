import RoutineCore
import XCTest

@testable import Routine

final class HistoryMonthNavigationTests: XCTestCase {
    private let routineCalendar = RoutineCalendar(calendar: Calendar(identifier: .gregorian))

    private func navigation() throws -> HistoryMonthNavigation {
        let today = try XCTUnwrap(RoutineDay(year: 2026, month: 10, day: 12))
        return HistoryMonthNavigation(routineCalendar: routineCalendar, today: today)
    }

    private func month(_ year: Int, _ month: Int, _ day: Int = 1) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    func testOffsetBackwardFromCurrentMonthReturnsPreviousMonth() throws {
        let result = try navigation().selection(from: month(2026, 10, 12), offset: -1)

        XCTAssertEqual(result, try month(2026, 9))
    }

    func testOffsetBackwardCrossesYearBoundary() throws {
        let result = try navigation().selection(from: month(2026, 1), offset: -1)

        XCTAssertEqual(result, try month(2025, 12))
    }

    func testOffsetBackwardHasNoLimit() throws {
        let result = try navigation().selection(from: month(2026, 10), offset: -130)

        XCTAssertEqual(result, try month(2015, 12))
    }

    func testOffsetForwardFromPastMonthReturnsFollowingMonth() throws {
        let result = try navigation().selection(from: month(2026, 5), offset: 1)

        XCTAssertEqual(result, try month(2026, 6))
    }

    func testOffsetForwardReachingCurrentMonthReturnsNilForCurrent() throws {
        let result = try navigation().selection(from: month(2026, 9), offset: 1)

        XCTAssertNil(result)
    }

    func testOffsetForwardFromCurrentMonthStaysOnCurrentMonth() throws {
        let result = try navigation().selection(from: month(2026, 10, 12), offset: 1)

        XCTAssertNil(result)
    }

    func testOffsetForwardFarPastTodayClampsToCurrentMonth() throws {
        let result = try navigation().selection(from: month(2024, 3), offset: 100)

        XCTAssertNil(result)
    }

    func testSelectionOfLaterMonthInCurrentYearClampsToCurrentMonth() throws {
        let result = try navigation().selection(year: 2026, month: 12)

        XCTAssertNil(result)
    }

    func testSelectionOfCurrentMonthReturnsNil() throws {
        let result = try navigation().selection(year: 2026, month: 10)

        XCTAssertNil(result)
    }

    func testSelectionOfFutureYearClampsToCurrentMonth() throws {
        let result = try navigation().selection(year: 2030, month: 1)

        XCTAssertNil(result)
    }

    func testSwitchingFromLateMonthOfPriorYearToCurrentYearLandsOnCurrentMonth() throws {
        let result = try navigation().selection(year: 2026, month: 12)

        XCTAssertNil(result)
        XCTAssertEqual(try navigation().selection(year: 2025, month: 12), try month(2025, 12))
    }

    func testSelectionOfPastMonthReturnsFirstDayOfThatMonth() throws {
        let result = try navigation().selection(year: 2025, month: 10)

        XCTAssertEqual(result, try month(2025, 10))
    }

    func testAvailableMonthsAreLimitedInCurrentYearOnly() throws {
        let navigation = try navigation()

        XCTAssertEqual(navigation.availableMonths(inYear: 2026), 1...10)
        XCTAssertEqual(navigation.availableMonths(inYear: 2025), 1...12)
    }

    func testIsSameMonthComparesYearAndMonth() throws {
        let navigation = try navigation()

        XCTAssertTrue(navigation.isSameMonth(try month(2026, 10, 1), try month(2026, 10, 31)))
        XCTAssertFalse(navigation.isSameMonth(try month(2026, 10, 1), try month(2025, 10, 1)))
        XCTAssertFalse(navigation.isSameMonth(try month(2026, 10, 1), try month(2026, 9, 30)))
    }

    func testHistoryMonthTitleShowsMonthAndYear() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let routineCalendar = RoutineCalendar(calendar: calendar)

        XCTAssertEqual(routineCalendar.historyMonthTitle(for: try month(2026, 6, 15)), "June 2026")
        XCTAssertEqual(routineCalendar.historyMonthTitle(for: try month(2025, 12)), "December 2025")
    }
}
