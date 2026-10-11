# Proposal

## Why

A routine can be tied to a time of day (for example, "Wake up early" from 12:00 AM to 6:45 AM). By default it must not get in the way outside that window, but a strict "you cannot complete this now" rule is annoying, so completion stays allowed unless the user opts into strictness. Today that works on the Today screen: out-of-window routines collapse into compact rows and can still be expanded and completed. The Home Screen widget does not follow it. It still offers a non-strict routine outside its window as the "next ready routine", so the widget nudges the user toward something that is not meant to be done right now.

The strictness control is also worded as an "Outside window: Soft block / Hard block" picker, which reads as a decision every windowed routine must make. It should read as one optional setting that is off by default.

## What Changes

- The widget never offers a routine outside its configured time window, whether or not that routine is strict, and regardless of the "Collapse unavailable routines" setting on Today.
- The widget refreshes when any windowed routine's window opens or closes, not only when a strict routine's window does, so a routine reappears on the widget when its window starts.
- The Add/Edit Routine form replaces the "Outside window" Soft/Hard picker with a "Strict window" toggle that is off by default and only appears when the routine is not available all day. The footer explains the behavior, including that past days can always be completed.
- The product documents describe the behavior as default versus strict instead of soft versus hard.
- No change to stored data. The existing stored block-mode value maps to the toggle (strict means the existing "hard" value), so no migration is needed.
- No change to Today collapse behavior, same-day completion rules, or History. They already match the intended behavior and are captured in the new spec so they stay that way.

## Capabilities

### New Capabilities

- `routine-availability`: Optional time-of-day windows on routines: how an out-of-window routine appears on Today and on the widget, when it can be completed, the optional strict window, and the guarantee that past days can always be completed.

### Modified Capabilities

None. `openspec/specs/` has no existing capabilities; this change creates the first one.

## Impact

- Widget: `RoutineWidget/NextRoutineSelector.swift` (which routine is shown, and when the widget next refreshes) and its tests in `RoutineAppTests/NextRoutineSelectorTests.swift`.
- Form: `RoutineApp/AddEditRoutineView.swift` and `RoutineApp/RoutineFormState.swift`, with tests in `RoutineAppTests/RoutineFormStateTests.swift` and any UI test that uses the picker.
- Docs: `PRODUCT_BRIEF.md`, `DATA_DESIGN.md`, `VISUAL_DESIGN.md`, `PROJECT_DESIGN.md` (new milestone entry).
- Not affected: persistence schema, `RoutineTrackingService` completion rules, Today dashboard projections, behind-schedule notifications.
