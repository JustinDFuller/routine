## Context

See proposal.md for why this change exists, and `specs/routine-history/spec.md` for the required behavior.

- `RoutineHistoryView` owns `@State selectedMonth: RoutineDay?`. `nil` means the current month. The displayed month is `selectedMonth ?? today`, and a `showPreviousMonth()` method moves it back one month using `RoutineCalendar.previousPeriodRange(for: .monthly, before:)`.
- The view rebuilds the history projection from the displayed month on every render. `HistoryProjectionBuilder.build(... displayedMonth:)` already builds the weeks, completed days, today marker, future-day flag, and goal-met highlighting for any month it is given, so browsing to an old month needs no change to that logic.
- `HistoryMonthGridView` is a plain view that receives the weeks and callbacks. It derives the title ("MMMM yyyy") from the first day of the first week and draws the back arrow button.
- `RoutineCalendar` has `previousPeriodRange` but no next-period helper.
- The deployment target is iOS 17, so `.transition(.push(from:))` and `scrollTargetBehavior` are available. The page is a vertical `ScrollView`, and each day is a button that opens a popover.
- `RoutineHistoryView` already has an `animationsAreDisabled` flag (Reduce Motion or the app's debug setting) that the undo banner uses; the same flag should drive the month transition.
- `RoutineHistoryViewData` carries no information about the routine's age. The routine's `createdAt` and its completions are available to the view (it queries them), and to the builder.

## Goals / Non-Goals

**Goals:**

- Navigation rules (clamping, the wheel's year range, what counts as "current month") are plain functions that can be unit-tested without a view.
- The grid keeps working exactly as it does today for any month, including day taps and popovers.
- A swipe never fights vertical scrolling.

**Non-Goals:**

- Using `UICalendarView` or `DatePicker(.graphical)`. Neither can draw the goal-met week highlight, the completion fills, or the per-day confirmation popover.
- A paged `TabView` of pre-built months. Only the displayed month is ever built.
- Persisting the displayed month.

## Decisions

### Navigation state stays as one optional month in the view

`selectedMonth: RoutineDay?` stays the single source of truth, with `nil` meaning the current month. Navigation methods become `showMonth(offset:)`, `showMonth(year:month:)`, and `showToday()`. A new `@State isPickerOpen` tracks the wheel.

Alternative: store a month index offset from today. Rejected, since the wheel sets an absolute year and month, and `RoutineDay` is already what the projection takes.

Alternative: keep `selectedMonth` but make it non-optional. Rejected, since `nil` is what makes History follow "today" if the app stays open across midnight or a month change. A stored month would go stale.

Every setter clamps to the current month, so no code path can show a future month. Setting a month equal to the current month stores `nil`, which keeps "is current month" a single `selectedMonth == nil` check.

### A next-month helper in `RoutineCore`

Add `nextPeriodRange(for:after:)` next to `previousPeriodRange`, with the same shape: it adds one day to the range's upper bound and returns the period containing it. Covered by `RoutineCalendarTests` for December to January and for February in a leap year.

Alternative: compute next month in the view with `Calendar` directly. Rejected, since the project keeps date math in `RoutineCalendar`, where it is tested, and the view should not touch `Calendar`.

### Navigation facts come from the projection, not the view

`RoutineHistoryViewData` gains `isDisplayingCurrentMonth: Bool` and `pickerYears: ClosedRange<Int>`. The builder already receives `today`, `displayedMonth`, the routine, and its completions, so it can compute both:

- `isDisplayingCurrentMonth`: the displayed month and today share a year and month.
- `pickerYears`: `min(routine.createdAt year, earliest completion year, today.year - 5)` through `today.year`. The completion list is already sorted by day key, so the earliest completion is the last element.

Alternative: compute these in the view. Rejected, since the repo tests these decisions through the builder (`HistoryProjectionBuilderTests`) and the view has no tests of its own.

The month wheel's available months for the selected year are derived in the view from `pickerYears.upperBound` and today's month, because that is a presentation rule over data the view already has. If the user picks a year where the previously chosen month is no longer valid (December 2025 to 2026 while today is October), the month is clamped to today's month, as the spec requires.

### Swipe is a simultaneous drag gesture on the grid, committed on end

`HistoryMonthGridView` attaches `.simultaneousGesture(DragGesture(minimumDistance: 20))`. It commits on `onEnded` only when `abs(translation.width) > 50` and `abs(translation.width) > 2 * abs(translation.height)`. It never acts during the drag, so a mostly vertical scroll can never change the month, and the drag does not need to track the finger.

Alternative: `TabView` with `.page` style for finger-following paging. Rejected: it would keep a view per month, fights the outer vertical `ScrollView`, and cannot cap at the current month cleanly.

Alternative: swipe handling with `highPriorityGesture`. Rejected, since it would block taps on days.

Day buttons keep their taps. A simultaneous gesture with a 20pt minimum distance does not cancel taps.

### Slide transition keyed to the month

The grid body is wrapped in a container with `.id(displayedMonthKey)` and `.transition(.push(from: edge))`, where the edge is `.leading` when moving back and `.trailing` when moving forward. State changes happen inside `withAnimation(animation)`, with `animation` nil and the transition `.opacity` when `animationsAreDisabled` is true. The direction is stored in a small `@State` set at the moment of the change, before the month changes.

Moving back slides the previous month in from the leading edge (pushing the current month out to the right), like Apple Calendar.

Alternative: no animation at all. Rejected, since an unanimated content swap hides which direction the user moved, and that is the main feedback for a swipe.

### The wheel replaces the grid in place, built from two `Picker`s

When `isPickerOpen` is true, the grid body is replaced by an `HStack` of two `Picker(.wheel)` views: months (localized month symbols from the calendar) and years (`pickerYears`). Both bind to the displayed year and month through `showMonth(year:month:)`. Because the displayed month updates live, the title and the summary above stay consistent while spinning.

The title is a `Button` with a trailing chevron that rotates from right to down when open. The Today button sits beside it, visible only when `isDisplayingCurrentMonth` is false.

Alternative: a sheet with `DatePicker(.graphical)`. Rejected during exploration: picking a specific day is redundant since the grid shows every day, and a sheet is heavier than an inline switch.

Alternative: `DatePicker` in `.compact` style. Rejected, since it selects a day and shows day-level chrome.

### Accessibility

- The title button's label is `"<Month Year>, choose month"` with a hint that it shows month and year wheels.
- The grid container gets `.accessibilityAdjustableAction`: `.increment` shows the next month, `.decrement` shows the previous month. Both go through the same clamping setters. After a change, a `AccessibilityNotification.Announcement` posts the new month and year, because the title text alone would not be spoken.
- The Today button is a normal labeled button ("Show current month").
- The wheels get labels "Month" and "Year".
- New identifiers: `routine-history-today-button`, `routine-history-month-wheel`, `routine-history-year-wheel`. `routine-history-month-title` stays. `routine-history-previous-month-button` is removed.

### Documentation

`VISUAL_DESIGN.md` ("Calendar-like month view") says the grid is for the current month. It changes to describe browsing by swipe and the picker. `DATA_DESIGN.md` mentions current-month completions for the month grid and the history view data; it is updated to say the displayed month and to list the two new view data fields.

## Risks / Trade-offs

[A horizontal swipe is not discoverable] → The title shows a chevron that signals it is tappable, and the same month change is reachable with the wheel. The user chose swipe only knowingly. If the screenshots or real use show people missing it, add arrow buttons later; that would not change the spec's navigation limits.

[A drag gesture on a view inside a `ScrollView` can steal or block scrolling] → The gesture only acts when the drag ends, and only when it is clearly horizontal. UI tests cover scrolling and day taps after a swipe. The check on a real device or simulator is part of the proof for the PR.

[The wheel's selection can land on an invalid month] → All setters clamp to the current month, and a unit test covers choosing a later month, then switching to the current year.

[Reading an arbitrarily old month builds a full month of days] → The projection builds one month only, and the cost does not grow with the distance from today.

[The routine's history can start before `createdAt` (backfilled completions)] → The year range includes the earliest completion's year, not just the creation year.

[Midnight or month rollover while History is open] → While on the current month (`selectedMonth == nil`) the grid follows today. A stored past month stays where the user put it.
