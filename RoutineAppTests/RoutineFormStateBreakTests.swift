import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineFormStateBreakTests: XCTestCase {
    private func makeCalendar() -> RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/New_York") ?? .gmt
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }

    private func makeDay(_ year: Int, _ month: Int, _ day: Int) throws -> RoutineDay {
        try XCTUnwrap(RoutineDay(year: year, month: month, day: day))
    }

    func testAddingRoutineDoesNotCreateBreakState() throws {
        let state = RoutineFormState(
            presentation: .add(initialGroupID: UUID()),
            routineCalendar: makeCalendar(),
            today: try makeDay(2026, 6, 22)
        )
        state.name = "Walk"

        let draft = try state.makeDraft()

        XCTAssertNil(draft.breakResumeDayKey)
    }

    func testEditingRoutinePreservesExistingBreakResumeDayKey() throws {
        let resumeDay = try makeDay(2026, 7, 6)
        let state = RoutineFormState(
            presentation: .edit(
                RoutineFormSnapshot(
                    routineID: UUID(),
                    name: "Walk",
                    targetCount: 3,
                    period: .weekly,
                    groupID: UUID(),
                    availabilityStartMinute: nil,
                    availabilityEndMinute: nil,
                    breakResumeDayKey: resumeDay.key
                )
            ),
            routineCalendar: makeCalendar(),
            today: try makeDay(2026, 6, 22)
        )

        let draft = try state.makeDraft()

        XCTAssertEqual(draft.breakResumeDayKey, resumeDay.key)
    }

    func testChangingRoutinePeriodKeepsBreakDateSeparateFromDefinition() throws {
        let resumeDay = try makeDay(2026, 7, 6)
        let state = RoutineFormState(
            presentation: .edit(
                RoutineFormSnapshot(
                    routineID: UUID(),
                    name: "Walk",
                    targetCount: 3,
                    period: .weekly,
                    groupID: UUID(),
                    availabilityStartMinute: nil,
                    availabilityEndMinute: nil,
                    breakResumeDayKey: resumeDay.key
                )
            ),
            routineCalendar: makeCalendar(),
            today: try makeDay(2026, 6, 22)
        )

        state.period = .monthly
        let draft = try state.makeDraft()

        XCTAssertEqual(draft.period, .monthly)
        XCTAssertEqual(draft.breakResumeDayKey, resumeDay.key)
    }
}
