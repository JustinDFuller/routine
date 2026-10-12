# Tasks

## 1. Calendar and projection

- [x] 1.1 Add `nextPeriodRange(for:after:)` to `RoutineCalendar` and verify with new `RoutineCalendarTests` cases for a mid-year month, December to January, and February in a leap year and a non-leap year (`./Scripts/test-core.sh` passes).
- [x] 1.2 Add `isDisplayingCurrentMonth` and `pickerYears` to `RoutineHistoryViewData` and compute them in `HistoryProjectionBuilder` (earliest of the routine's `createdAt` year, the earliest completion's year, and today's year minus five, through today's year); verify with new `HistoryProjectionBuilderTests` cases for a new routine (2021 through 2026), a routine with a 2017 completion (2017 through 2026), a displayed month in a prior year, and the current month flag being true only for the current month.
- [x] 1.3 Verify with a `HistoryProjectionBuilderTests` case that a past displayed month marks exactly its recorded completions, marks no day as today, computes weekly and monthly goal-met highlighting for that month, and leaves the summary progress and recent completions unchanged.

## 2. Navigation state in the History screen

- [x] 2.1 In `RoutineHistoryView`, replace `showPreviousMonth()` with clamped `showMonth(offset:)`, `showMonth(year:month:)`, and `showToday()`, storing `nil` for the current month, and add the picker-open state and swipe-direction state; verify with an `RoutineAppTests` case on the navigation rules (offset clamping at the current month, later month in the current year clamps to today's month, switching from December of a prior year to the current year lands on today's month).
- [x] 2.2 Pass the new inputs to `HistoryMonthGridView` and remove the `onShowPreviousMonth` wiring; verify the app target builds (`./Scripts/build-ios.sh`).

## 3. Month grid UI

- [x] 3.1 In `HistoryMonthGridView`, remove the back arrow button, make the title a button with a chevron that rotates when the wheels are open, and show the Today button only when `isDisplayingCurrentMonth` is false; verify with a UI test that the title is a button, Today is absent on the current month, and Today appears after changing month.
- [x] 3.2 Add the swipe gesture (drag of at least 20pt, committed on end when the horizontal travel is over 50pt and over twice the vertical travel, right goes back, left goes forward, ignored on the current month) and the slide transition keyed to the displayed month with a cross-fade when `animationsAreDisabled`; verify with UI tests that swiping right shows May 2026 from June 2026, swiping left returns to June 2026, swiping left on June 2026 changes nothing, and the page still scrolls vertically.
- [x] 3.3 Add the month and year wheels that replace the grid in place, with the year list from `pickerYears` and the month list limited to the current month in the current year; verify with UI tests that opening the wheels shows June and 2026, setting the year to 2025 makes the title read "June 2025", Today closes the wheels and returns to "June 2026", and tapping the title again returns to the grid.
- [x] 3.4 Verify with a UI test that tapping a day in an earlier month after swiping still opens the confirmation popover and confirming records or removes that day's completion.

## 4. Accessibility

- [x] 4.1 Give the title the label `"<Month Year>, choose month"` and a hint, label the Today button and the two wheels, and add the identifiers `routine-history-today-button`, `routine-history-month-wheel`, and `routine-history-year-wheel`; verify with UI tests that query these identifiers and read the title label.
- [x] 4.2 Add an accessibility adjustable action on the grid's weekday header (increment for the next month, decrement for the previous month, same clamping) and post an announcement of the new month and year; XCUITest cannot invoke an adjustable action, so a UI test verifies the header value follows the displayed month and unit tests cover the navigation rules (see qa.md).
- [x] 4.3 Verify the Reduce Motion path: with the app's animations disabled (launch configuration), swipe navigation still changes the month, and the code path uses the cross-fade (covered by the UI tests above running with animations disabled).

## 5. Docs and test cleanup

- [x] 5.1 Remove `testHistoryPreviousMonthNavigationShowsPriorMonth` and the `routine-history-previous-month-button` references, replaced by the tests above; verify `grep -rn "previous-month" RoutineApp RoutineAppUITests RoutineAppScreenshotTests RoutineAppTests` returns nothing.
- [x] 5.2 Update `VISUAL_DESIGN.md` (Calendar-like month view: browsable by swipe, the title opens a month and year picker, Today appears off the current month, forward stops at the current month) and `DATA_DESIGN.md` (history view data lists `isDisplayingCurrentMonth` and `pickerYears`; the grid shows the displayed month rather than the current month); verify by reading both sections against the spec.
- [x] 5.3 Add milestone M25 for this work to `PROJECT_DESIGN.md` and update the roadmap table and current milestone line following the existing M23 and M24 entries; verify the table and the milestone text are consistent.

## 6. Validation and proof

- [x] 6.1 Run `./Scripts/validate.sh` and verify every stage passes; report any skipped lines it emits.
- [x] 6.2 Run the app in the simulator and record a screen recording that shows swiping back across a year boundary, trying to swipe past the current month, opening the wheels, jumping to a prior year, tapping Today, and completing a day in an earlier month; add it to the PR description with light and dark mode screenshots and one at a large Dynamic Type size.

## Workflow follow-up

- Archive the change (syncing the new `routine-history` spec) after the project's review requirements are satisfied.
