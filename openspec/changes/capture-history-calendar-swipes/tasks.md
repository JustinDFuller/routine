# Tasks

## 1. Reproduce

- [ ] 1.1 On the iOS 26.5 simulator, record slow, finger-like right drags on the day grid (`press(forDuration:thenDragTo:withVelocity:)` or computer use) until the screen leaves History, using a routine with completions over several months and an empty routine; verify with a recording that the failure reproduces and note whether it ever lines up with the oldest-completion month. If it does not reproduce or depends on the data, stop and reopen the proposal.

## 2. Gesture bridge

- [ ] 2.1 Add a `UIViewRepresentable` in `RoutineApp/Components/` that, while in the window, adds a horizontal-only `UIPanGestureRecognizer` over the calendar card and makes the enclosing navigation controller's content-pop and edge-pop recognizers require it to fail (content-pop behind `#available(iOS 26, *)`), removing both when it leaves the window; verify the app target builds (`./Scripts/build-ios.sh`).
- [ ] 2.2 Attach the bridge to the whole calendar card in `HistoryMonthGridView`; verify the existing `RoutineAppUITests+HistoryMonthNavigation` tests still pass.

## 3. Tests

- [ ] 3.1 Add a UI test that makes eight slow right drags on the day grid and asserts `routine-history-root` still exists and the title reads eight months earlier.
- [ ] 3.2 Add UI tests that a right drag on the title row, and on the card with the wheels open, leaves History open and the month unchanged, and that a left drag on the current month does the same.
- [ ] 3.3 Add UI tests that a right drag on the recent completions section, and one from the left screen edge, go back to the home screen, and that a vertical drag over the grid still scrolls without changing the month.

## 4. Docs

- [ ] 4.1 Add a line to the calendar month view section of `VISUAL_DESIGN.md` saying sideways swipes inside the card are owned by the calendar; verify by reading the section against the spec.

## 5. Validation and proof

- [ ] 5.1 Run `./Scripts/validate.sh` and verify every stage passes; report any skipped lines it emits.
- [ ] 5.2 Record the running app showing eight or more swipes back staying in History, a left swipe on the current month doing nothing, a right swipe below the calendar going home, vertical scrolling over the calendar, and tapping a day; attach it to the PR description.

## Workflow follow-up

- Archive the change (syncing the new requirements into the `routine-history` spec) after the project's review requirements are satisfied.
