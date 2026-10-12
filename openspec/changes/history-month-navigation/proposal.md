# Proposal

## Why

Routine History shows one month at a time, but the only way to move is a back arrow. After going back there is no way to come forward again, no quick way back to the current month, and reaching a month a year ago takes a dozen taps. History can complete or remove any past day, so being able to reach an old month matters, not just a recent one.

The iOS calendar already has the interaction people expect: swipe sideways to change month, and tap the month name to jump straight to a month and year. History should work the same way.

## What Changes

- Swiping sideways on the month grid changes the displayed month. Swiping right shows the previous month. Swiping left shows the next month.
- Going forward stops at the current month. Future months cannot be shown.
- Going back has no limit.
- The back arrow button is removed. No forward arrow is added. Swiping is the only visual way to change month.
- The month title (for example `October 2026`) becomes a button. Tapping it replaces the grid with a month and year wheel. Spinning the wheel changes the displayed month. Tapping the title again closes the wheel and shows the grid.
- The wheel's years run from the earliest of the year the routine was created, the year of its earliest completion, and five years before the current year, through the current year. Months later than the current month are not selectable in the current year.
- A **Today** button appears next to the title whenever the displayed month is not the current month. Tapping it shows the current month and closes the wheel.
- Month changes slide in the direction of the swipe. With Reduce Motion on, or when the app disables animations for testing, they cross-fade instead.
- VoiceOver users change month with the adjustable action on the grid (swipe up for next, swipe down for previous). The title is announced as a button that chooses the month.
- The summary at the top of History (progress ring, count, streak) keeps describing the current week or month, whichever month the grid shows.
- History still opens on the current month every time. The chosen month is not remembered.
- `VISUAL_DESIGN.md` and `DATA_DESIGN.md` are updated, because they currently describe the grid as the current month only.
- Out of scope: remembering the chosen month between visits, a week view, a combined view across routines, and a Today jump anywhere other than History.

## Capabilities

### New Capabilities

- `routine-history`: How the Routine History screen lets the user browse months of completions: swipe navigation, the month and year picker, the Today shortcut, the limits on how far forward and back they can go, and the accessibility behavior of that navigation.

### Modified Capabilities

None. `openspec/specs/` has `release-pipeline` and `routine-availability`, neither of which covers the History screen.

## Impact

- UI: `RoutineApp/RoutineHistoryView.swift` (month state and navigation), `RoutineApp/Components/HistoryMonthGridView.swift` (swipe, title button, wheel, Today button, accessibility).
- Projection: `RoutineApp/Projections/HistoryProjectionBuilder.swift` and `RoutineApp/Projections/ViewData.swift` expose whether the displayed month is the current month and the year range for the wheel.
- Core: `RoutineCore/Sources/RoutineCore/RoutineCalendar.swift` may gain a helper for the next month, with tests in `RoutineCore/Tests/RoutineCoreTests/RoutineCalendarTests.swift`.
- Tests: `RoutineAppTests/HistoryProjectionBuilderTests.swift` and `RoutineAppUITests/RoutineAppUITests.swift`. The UI test `testHistoryPreviousMonthNavigationShowsPriorMonth` uses the removed back button and is replaced.
- Docs: `VISUAL_DESIGN.md` (Calendar-like month view) and `DATA_DESIGN.md` (history view data and the month grid lines).
- No data model, storage, notification, or widget changes. Completing or removing a day from an earlier month uses the same flow as today.
