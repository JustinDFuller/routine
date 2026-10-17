# Proposal

## Why

On the History screen, swiping right on the calendar goes back a month. After a few swipes, the next swipe leaves History and returns to the home screen instead of showing the previous month. The calendar has no lower limit on how far back it goes, so running out of months is not the cause.

The likely cause is that History is a pushed screen. On iOS 26 and later, swiping right from anywhere on a pushed screen can take it back, and that system swipe competes with the calendar's own swipe. The calendar's gesture is attached so that it does not stop the system swipe from also starting, so on some swipes the system one wins. This has not been reproduced yet, and the first implementation task is to reproduce it and confirm the cause.

The calendar should behave as a swipe-owning surface: a sideways swipe on it only ever means "change month", never "leave this screen".

## What Changes

- A sideways swipe anywhere inside the calendar card (the title row, the day grid, and the month and year wheels when they are open) never takes the user back to the home screen.
- On the day grid, swiping right keeps showing the previous month with no limit, as today. Swiping left on the current month still does nothing, and now also does not leave History.
- On the title row and on the open wheels, a sideways swipe is absorbed and changes nothing.
- Swiping anywhere outside the calendar card, including the summary above it and the recent completions below it, keeps working as it does today, including swiping right to go back to the home screen and the left-edge swipe.
- Vertical scrolling and tapping a day keep working everywhere, including over the calendar.
- Out of scope: any change to how months are shown, the picker, Today, animations, or VoiceOver navigation; changes to other screens that are pushed onto the navigation stack.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `routine-history`: adds a requirement that sideways swipes on the calendar card never leave History, and a scenario on swiping outside the card that preserves the current back behavior. Existing requirements are not changed.

## Impact

- UI: `RoutineApp/Components/HistoryMonthGridView.swift` (claim sideways swipes over the calendar card) and a new small UIKit bridge file in `RoutineApp/Components/` that makes the navigation controller's swipe-to-go-back wait for the calendar's swipe.
- Reuses the swipe thresholds in `RoutineApp/HistoryMonthNavigation.swift` so the claimed swipe and the month-changing swipe agree.
- Tests: `RoutineAppUITests/RoutineAppUITests+HistoryMonthNavigation.swift` gains slower, finger-like drags, plus tests for the title row, the wheels, and a swipe outside the card.
- Docs: `VISUAL_DESIGN.md` (calendar month view) gains a line on swipe ownership.
- No data model, storage, notification, or widget changes.
