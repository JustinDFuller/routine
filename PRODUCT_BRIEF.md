# Product Brief: Routine

## Summary

Routine is a personal iPhone app for tracking a flexible, recurring routine. It is designed first for a single user who wants to dogfood the app on their own phone, iterate quickly, and focus on usefulness over completeness.

The MVP should make it fast to answer five questions:

1. What have I already done today?
2. What have I not done today?
3. How am I progressing against this week or month?
4. When did I last do this?
5. Has this routine been met across consecutive weeks or months?

The product should feel visual first, not text heavy. Text is necessary for labels and dates, but status should be communicated primarily through visual controls and progress indicators.

## Context

The user has a routine made up of recurring activities that are consistent but not rigidly daily. Most activities are targets like "4 times per week" or "1 time per month," not fixed weekday obligations. The app must support user-defined routines rather than shipping with hard-coded habits.

Example routine items include:

### Weekly examples

- Wake up early, 4x per week
- Functional workout, 5x per week
- Morning yoga, 5x per week
- Mist plants, 6x per week
- Play with kids, 5x per week
- Learn math, 3x per week
- Duolingo, 6x per week
- Walk the dog, 5x per week
- Read a book, 4x per week
- Write something, 3x per week
- Practice piano, 3x per week
- Basketball, 3x per week
- Practice leetcode, 3x per week
- Evening yoga, 4x per week
- Do something nice for my wife, 1x per week
- Water plants, 1x per week
- Run razor cleaner, 1x per week

### Monthly examples

- Clean air purifiers, 1x per month
- Rotate plants, 1x per month
- Whiten teeth, 1x per month

## Product Goal

Help the user consistently keep up with their routine by making completion tracking simple, visual, and forgiving.

## MVP Goals

- Make routine completion fast enough to use casually throughout the day.
- Make daily status legible at a glance.
- Make weekly and monthly progress visible without requiring math or memory.
- Make it easy to recover from mistakes such as accidental completion.
- Make setup practical by allowing routines to be created and managed in-app.

## Out of Scope

- Smart scheduling or app-generated "recommended today" logic
- Per-routine reminders or notification quick actions
- Scores, achievements, public sharing, analytics, or gamified reward systems
- Watch app or lock screen surfaces
- Sharing, collaboration, or multi-user support
- Cloud sync
- Telemetry, analytics, or production-grade operational concerns
- Technical architecture, build strategy, code organization, or implementation details
- Final visual mockups or polished design comps

## Target User

Primary user: the builder of the app.

The MVP is optimized for one person who wants a practical personal tracker on an iPhone, uses dark mode, and is willing to iterate based on real daily use. Broader public usability matters, but it is secondary to immediate personal usefulness.

## Product Principles

- Flexible over rigid: the app tracks recurring targets without forcing fixed-day schedules.
- Visual over verbose: progress and state should scan quickly.
- Fast over feature-rich: common actions should take one tap whenever possible.
- Forgiving over punitive: mistakes should be reversible and incomplete items should not feel like failures.
- Configurable over hard-coded: routines, frequencies, groups, and order belong to the user.

## MVP Feature Set

- Create a routine with a name, target count, and frequency period.
- Support two frequency periods: weekly and monthly.
- Edit and delete routines.
- Group routines into display sections.
- Reorder routines within the app.
- Mark a routine complete for the current day.
- Store completion history.
- Show last completed date for each routine.
- Show current weekly or monthly progress visually.
- Let the user review past completions in a calendar/history view.
- Offer local morning, afternoon, and evening check-in notifications that stay quiet once goals are met.
- Show the next ready routine in a Home Screen widget, with tap-through to Today and one-tap completion.

## Core Product Behavior

### Completion rules

- A routine can be completed at most once per calendar day in the MVP.
- Tapping an incomplete routine marks it complete for today.
- Tapping an already completed routine should not create a second completion.
- After a completion, the app should present an immediate undo affordance.
- The user must also be able to remove a mistaken completion from the routine history.

### Progress rules

- Weekly routines count completions in the current calendar week.
- Monthly routines count completions in the current calendar month.
- "Remaining today" means not yet completed today.
- The app does not decide which routines are required on a specific day, but routines may optionally limit when they can be completed.

### Availability-window rules

- A routine can optionally define a preferred local-time window.
- Outside a soft window, the routine stays compact on Today but can still be completed.
- A routine can opt into a hard window, which also blocks a new same-day completion outside the window.
- Calendar history can complete any past day outside either window mode.

### Streak rules

- A streak is the count of consecutive finalized periods (weeks or months) in which the routine met its target count.
- A missed finalized period — one that closed without meeting the target — resets the streak count to zero.
- The current in-progress period is excluded from the streak count until it closes; its target-met state is shown separately.
- Periods in which the target was exceeded count once toward the streak, not more.
- Duplicate completions on the same day are deduped before evaluating period target counts.

### Visibility rules

- All routines remain visible on the main dashboard.
- Monthly routines are not hidden or collapsed by default.
- Groups are display-only sections in the MVP and do not carry their own completion logic.

## Interface Overview

The MVP should be centered on a dark-mode-first interface optimized for one-handed iPhone use. The visual system should emphasize completion state and progress over long explanatory copy.

### 1. Today Dashboard

This is the primary screen and the default landing view.

Purpose:

- Show the full routine in the user's chosen order
- Separate completed and incomplete items visually
- Make completion a one-tap action
- Provide fast access to last-done context

Structure:

- Grouped sections for related routines
- A routine card or row for each item
- Clear visual difference between done-today and not-done-today states
- Persistent visibility of both weekly and monthly items

What each routine item should show:

- Routine name
- Completion control
- Visual progress indicator for current week or month
- Current count versus target
- Last completed cue

### 2. Routine Item Interaction

Primary interaction:

- Tap to mark complete for today

Result of completion:

- The completion control changes state immediately
- The progress indicator updates immediately
- The item visually shifts to a completed state
- A temporary undo action appears

Secondary interaction on an already completed item:

- Open routine history directly

Secondary interaction from the routine row:

- A dedicated History affordance opens routine history without interfering with one-tap completion
- Routine editing remains available from dashboard Edit mode, not from a routine action sheet

### 3. Routine History / Calendar View

Purpose:

- Help the user answer "when did I last do this?"
- Let the user inspect recent completion patterns
- Allow correction of mistaken completions

Behavior:

- Show past completion dates in a calendar-like or recent-history format
- Make today's completion easy to identify
- Allow removal of an incorrect logged completion

This view is the main solution for uncertainty around last completion.

### 4. Manage Routines View

Purpose:

- Set up and maintain the routine without leaving the app

Capabilities:

- Add a new routine
- Edit name
- Set target count
- Choose weekly or monthly frequency
- Assign or change group
- Reorder routines
- Delete a routine

The setup flow should be simple and utilitarian rather than highly guided.

## Visual Language

The app should communicate status primarily through visual indicators.

Preferred direction for MVP:

- Continuous rings as the main progress indicator
- A complete/incomplete control with a strong state change
- Clear done-today styling differences
- Supportive use of text for counts and last-done dates

Rationale:

- Continuous rings make weekly and monthly target progress legible at a glance.
- A separate calendar/history view can carry the denser temporal context that a timeline strip would otherwise need to show inline.
- This keeps the dashboard visually clear while still letting the user inspect history when needed.

## Initial Data Strategy

The first dogfooding build should ship with the user's current routines preloaded so the app is immediately useful.

Suggested starter groups for the initial dataset:

- Morning
- Movement
- Family / Home
- Learning / Creative
- Evening
- Monthly Maintenance

These are editable defaults, not fixed product categories.

## MVP Success Criteria

The MVP is successful if the user can:

- Set up their real routine in the app without external tools
- Use the app throughout the day without friction
- See, at a glance, what is done and not done today
- Understand weekly or monthly progress without counting manually
- Recover confidently from accidental taps
- Check the last completion date of any routine in a few seconds

## Open Future Improvements

These are intentionally deferred, not part of the MVP:

- Smart daily suggestions based on target frequency and recent completion history
- Per-routine limits for more than one completion per day
- Multiple dashboard modes, such as a richer calendar-first view
- Lock screen surfaces or richer widget families
- Shared or public use cases

## Assumptions

- The app is iPhone-first.
- Dark mode is the primary presentation target.
- The local calendar day determines whether something counts as done today.
- The calendar week starts on Monday.
