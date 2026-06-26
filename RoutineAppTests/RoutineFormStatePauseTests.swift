import Foundation
import RoutineCore
import XCTest

@testable import Routine

@MainActor
final class RoutineFormStatePauseTests: XCTestCase {
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

    func testPauseProducesCorrectResumeDayKeyForWeeklyRoutine() throws {
        let calendar = makeCalendar()
        let monday = try makeDay(2026, 6, 22)

        let state = RoutineFormState(
            presentation: .add(initialGroupID: UUID()),
            routineCalendar: calendar,
            today: monday
        )
        state.name = "Walk"
        state.period = .weekly
        state.isPausedRoutine = true
        state.pauseSkipPeriods = 1

        let draft = try state.makeDraft()

        let expectedResumeDay = try makeDay(2026, 6, 29)
        XCTAssertEqual(draft.pauseResumeDayKey, expectedResumeDay.key)
    }

    func testPauseProducesCorrectResumeDayKeyForMonthlyRoutine() throws {
        let calendar = makeCalendar()
        let firstOfJune = try makeDay(2026, 6, 1)

        let state = RoutineFormState(
            presentation: .add(initialGroupID: UUID()),
            routineCalendar: calendar,
            today: firstOfJune
        )
        state.name = "Budget Review"
        state.period = .monthly
        state.isPausedRoutine = true
        state.pauseSkipPeriods = 2

        let draft = try state.makeDraft()

        let expectedResumeDay = try makeDay(2026, 8, 1)
        XCTAssertEqual(draft.pauseResumeDayKey, expectedResumeDay.key)
    }

    func testNoPausedProducesNilPauseResumeDayKey() throws {
        let calendar = makeCalendar()
        let monday = try makeDay(2026, 6, 22)

        let state = RoutineFormState(
            presentation: .add(initialGroupID: UUID()),
            routineCalendar: calendar,
            today: monday
        )
        state.name = "Walk"
        state.isPausedRoutine = false

        let draft = try state.makeDraft()
        XCTAssertNil(draft.pauseResumeDayKey)
    }

    func testEditingExistingPausedRoutineShowsCorrectSkipCount() throws {
        let calendar = makeCalendar()
        let today = try makeDay(2026, 6, 22)
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
                    pauseResumeDayKey: resumeDay.key
                )
            ),
            routineCalendar: calendar,
            today: today
        )

        XCTAssertTrue(state.isPausedRoutine)
        XCTAssertEqual(state.pauseSkipPeriods, 2)
    }

    func testResumingViaClearingPauseFlagProducesNilKey() throws {
        let calendar = makeCalendar()
        let today = try makeDay(2026, 6, 22)
        let resumeDay = try makeDay(2026, 6, 29)

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
                    pauseResumeDayKey: resumeDay.key
                )
            ),
            routineCalendar: calendar,
            today: today
        )

        XCTAssertTrue(state.isPausedRoutine)
        state.isPausedRoutine = false

        let draft = try state.makeDraft()
        XCTAssertNil(draft.pauseResumeDayKey)
    }

    func testChangingPeriodResetsPauseState() throws {
        let calendar = makeCalendar()
        let today = try makeDay(2026, 6, 22)

        let state = RoutineFormState(
            presentation: .add(initialGroupID: UUID()),
            routineCalendar: calendar,
            today: today
        )
        state.name = "Walk"
        state.period = .weekly
        state.isPausedRoutine = true
        state.pauseSkipPeriods = 3

        state.period = .monthly

        XCTAssertFalse(state.isPausedRoutine)
        XCTAssertEqual(state.pauseSkipPeriods, 1)
    }
}
