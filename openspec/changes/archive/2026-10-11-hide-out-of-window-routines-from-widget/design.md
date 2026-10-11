# Design

## Context

The app already has everything except the widget rule and the form wording (see proposal.md). Observed in the code:

- Each routine stores an optional window (start/end minute of day) and a block mode of soft (default) or hard.
- `RoutineTrackingService.complete` checks the window only when the day being completed is today, and only for hard routines, after the "already completed" idempotence check. Past days skip the check, so "past days always completable" is already true.
- `DashboardProjectionBuilder` computes availability from the window and collapses out-of-window incomplete rows when the unavailable-collapse setting is on.
- `NextRoutineSelector` (widget) treats a routine as available only when it has no window, is soft, or is inside its window. This is the line that keeps soft routines on the widget. `nextRefreshBoundary` likewise only schedules window edges for hard routines.

## Goals / Non-Goals

**Goals:**
- Make the widget ignore any out-of-window routine, and refresh at every window edge.
- Present the stored block mode as an off-by-default "Strict window" toggle.

**Non-Goals:**
- No change to the stored data, to completion rules, or to Today's collapse behavior.
- No new setting for the widget. It always hides out-of-window routines.
- No rename of the stored soft/hard values or the internal type; only user-facing wording changes.

## Decisions

**Widget hides every out-of-window routine.** Remove the hard-only condition in the widget's availability check, so any routine with a window is offered only inside it. Alternative considered: follow the Today collapse setting. Rejected because the widget is a "what can I do right now" surface with one slot, and tying it to a Today display preference makes the same routine appear or vanish for a reason unrelated to the widget.

**Refresh at all window edges.** Remove the hard-only condition in the refresh-boundary calculation as well. Without it, a non-strict routine that is hidden before its window would not reappear until midnight or another refresh. The cost is at most two extra refresh times per windowed routine per day, and the existing logic already picks only the nearest future edge.

**Toggle instead of picker, same storage.** `RoutineFormState` gets a boolean `isStrictWindow` that reads and writes the existing block mode (`hard` is strict). This keeps the persisted values, the snapshot round-trip, and existing data untouched, so there is no migration. Alternative considered: a new stored boolean. Rejected because it duplicates state and needs migration for no behavioral gain.

**Hard routines stay visible but disabled on Today.** Existing behavior (muted card with a disabled control) is kept. Alternative considered: hide strict routines entirely. Rejected because it was not requested, and a collapsed row that can be expanded to see why it is disabled is clearer.

**Milestone bookkeeping.** `PROJECT_DESIGN.md` is at "Roadmap complete", so this follow-up is recorded as a new milestone at the end of the roadmap, marked CURRENT while implementing, then DONE.

## Risks / Trade-offs

- [Widget goes empty more often because non-strict out-of-window routines are now hidden] → That is the requested behavior, and the existing caught-up state covers it.
- [Existing tests assert that the widget offers a soft routine outside its window] → Update that test to the new expectation and add a refresh-boundary test for a soft window.
- [User-facing words change from soft/hard to default/strict while code keeps soft/hard] → Limit the rename to user-facing text and docs, and note the mapping in DATA_DESIGN.md.
