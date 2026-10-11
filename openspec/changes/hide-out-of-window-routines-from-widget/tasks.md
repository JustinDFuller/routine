# Tasks

## 1. Widget hides out-of-window routines

- [ ] 1.1 In `RoutineWidget/NextRoutineSelector.swift`, make the availability check and the refresh-boundary calculation apply to every routine with a window, not only strict ones. Verify with `NextRoutineSelectorTests` (below).
- [ ] 1.2 Update `RoutineAppTests/NextRoutineSelectorTests.swift`: change the soft-routine-outside-window test to expect the routine is skipped, add a test that a soft window's start and end are refresh boundaries, and add a test that a cross-midnight soft window is handled. Verify with `xcodebuild test -only-testing:RoutineAppTests/NextRoutineSelectorTests`.
- [ ] 1.3 Update `DATA_DESIGN.md` (window rules, near the soft/hard bullets) and `PRODUCT_BRIEF.md` (Availability-window rules) to state the widget rule and use default/strict wording. Verify by re-reading both sections for leftover soft/hard wording that contradicts the spec.

## 2. Strict window toggle in the form

- [ ] 2.1 Add `isStrictWindow` to `RoutineFormState` mapped to the existing block mode, and replace the "Outside window" picker in `RoutineApp/AddEditRoutineView.swift` with a "Strict window" toggle (identifier `routine-form-availability-strict-toggle`) plus the footer text from the spec. Verify the app builds with `./Scripts/build-ios.sh`.
- [ ] 2.2 Add `RoutineAppTests/RoutineFormStateTests.swift` coverage: off by default for a new routine, snapshot of a strict routine turns it on, saving output carries the block mode, and the toggle state is irrelevant when available all day. Verify with `xcodebuild test -only-testing:RoutineAppTests/RoutineFormStateTests`.
- [ ] 2.3 Update any UI test or accessibility identifier that references the old picker (search for `block-mode-picker`), and update the Availability form description in `VISUAL_DESIGN.md`. Verify `grep -rn "block-mode-picker\|Soft block\|Hard block"` returns nothing outside design history.

## 3. Milestone and final validation

- [ ] 3.1 Add the new milestone to `PROJECT_DESIGN.md` (roadmap table, milestone section, current milestone line) and mark it DONE with a completion note when finished. Verify the roadmap table and Current Milestone line agree.
- [ ] 3.2 Run `./Scripts/validate.sh` and report any skipped lines it emits. Verify it ends with all stages passing.
- [ ] 3.3 Capture proof in the running app on the simulator and attach it to the PR: the Strict window toggle (off by default) with its footer; a collapsed out-of-window routine that expands and completes; a strict routine with a disabled control; completing a past day from History; and the widget hiding an out-of-window routine and showing it again once the window includes the current time. Verify the screenshots or recording are in the PR description.

## Workflow follow-up

- Open the implementation PR for review before archiving.
- Archive the change after the PR is merged, which creates the first baseline spec in `openspec/specs/routine-availability/`.
