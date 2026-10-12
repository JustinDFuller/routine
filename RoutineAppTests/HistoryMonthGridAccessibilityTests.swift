import RoutineCore
import SwiftUI
import UIKit
import XCTest

@testable import Routine

@MainActor
final class HistoryMonthGridAccessibilityTests: XCTestCase {
    private let routineCalendar: RoutineCalendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return RoutineCalendar(calendar: calendar)
    }()

    private func hostedGrid(onAdjustMonth: @escaping (Int) -> Void) throws -> (UIWindow, UIView) {
        let month = try XCTUnwrap(RoutineDay(year: 2026, month: 5, day: 1))
        let day = HistoryCalendarDay(
            id: "2026-05-01", day: month, label: "1", isInDisplayedMonth: true,
            isToday: false, isCompleted: false, isFuture: false
        )
        let week = HistoryCalendarWeek(
            id: 0, days: [day], leadingPlaceholders: 5, trailingPlaceholders: 1, isGoalMet: false)
        let grid = HistoryMonthGridView(
            weeks: [week], displayedMonth: month, routineCalendar: routineCalendar,
            isDisplayingCurrentMonth: false, pickerYears: 2021...2026, monthsInYear: { _ in 1...12 },
            isPickerOpen: false, slideEdge: .trailing, usesCrossFade: false,
            onTogglePicker: {}, onShowMonth: { _ in }, onAdjustMonth: onAdjustMonth,
            onSelectMonth: { _, _ in }, onShowToday: {}, onTapDay: { _ in },
            popoverIsPresented: { _ in .constant(false) }, onConfirmDay: {}
        )
        let controller = UIHostingController(rootView: grid)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.5))
        return (window, controller.view)
    }

    private func findAdjustable(in object: Any, depth: Int = 0) -> NSObject? {
        guard let object = object as? NSObject, depth < 14 else { return nil }
        if object.isAccessibilityElement, object.accessibilityTraits.contains(.adjustable) { return object }
        var kids: [Any] = object.accessibilityElements ?? []
        if kids.isEmpty {
            let count = object.accessibilityElementCount()
            if count != NSNotFound { kids = (0..<count).compactMap { object.accessibilityElement(at: $0) } }
        }
        if let view = object as? UIView { kids += view.subviews }
        for kid in kids { if let hit = findAdjustable(in: kid, depth: depth + 1) { return hit } }
        return nil
    }

    func testWeekdayHeaderAdjustableActionMovesTheMonth() throws {
        var offsets: [Int] = []
        let (window, view) = try hostedGrid(onAdjustMonth: { offsets.append($0) })
        withExtendedLifetime(window) {}
        guard let header = findAdjustable(in: view) else {
            throw XCTSkip(
                "SwiftUI builds its accessibility tree only when the simulator has application accessibility enabled")
        }
        XCTAssertTrue(header.isAccessibilityElement)
        XCTAssertEqual(header.accessibilityLabel, "Sun Mon Tue Wed Thu Fri Sat")
        XCTAssertEqual(header.accessibilityValue, "May 2026")
        header.accessibilityIncrement()
        header.accessibilityDecrement()
        XCTAssertEqual(offsets, [1, -1])
    }
}
