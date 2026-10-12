# Spec Delta

## Purpose

Lets the user browse a routine's completions month by month on the History screen, reach any past month quickly, and return to the current month, while still being able to complete or remove any past day.

## ADDED Requirements

### Requirement: History opens on the current month
The History screen SHALL show the month grid for the current month each time it opens. The month the user last viewed SHALL NOT be remembered between visits.

#### Scenario: Open History
- **WHEN** the user opens History for a routine and today is in October 2026
- **THEN** the grid shows October 2026 and the title reads "October 2026"

#### Scenario: Reopen after browsing
- **WHEN** the user browses to August 2024, leaves History, and opens History again
- **THEN** the grid shows the current month

### Requirement: Swiping changes the displayed month
The user SHALL be able to swipe sideways on the month grid to change the displayed month. Swiping right SHALL show the previous month and swiping left SHALL show the next month. The month title SHALL always show the month and the year.

#### Scenario: Swipe to the previous month
- **WHEN** the grid shows June 2026 and the user swipes right on it
- **THEN** the grid shows May 2026 and the title reads "May 2026"

#### Scenario: Swipe forward again
- **WHEN** the grid shows May 2026 and the user swipes left on it
- **THEN** the grid shows June 2026

#### Scenario: Swipe across a year boundary
- **WHEN** the grid shows January 2026 and the user swipes right on it
- **THEN** the grid shows December 2025 and the title reads "December 2025"

#### Scenario: No back arrow button
- **WHEN** the user views the month grid
- **THEN** no previous-month or next-month arrow button is shown

### Requirement: Future months cannot be shown
The user SHALL NOT be able to display a month later than the current month, by swiping or by the picker. Going back SHALL have no limit.

#### Scenario: Swipe forward on the current month
- **WHEN** the grid shows the current month and the user swipes left on it
- **THEN** the grid still shows the current month

#### Scenario: Browse far into the past
- **WHEN** the user swipes right repeatedly past a year boundary more than once
- **THEN** each swipe shows the previous month, including months before the routine was created

### Requirement: Swiping does not interfere with the rest of the screen
A swipe SHALL change the month only when the gesture is mostly horizontal and travels a clear distance. Scrolling the screen vertically and tapping a day SHALL keep working as they do today, in every displayed month.

#### Scenario: Scroll the screen
- **WHEN** the user drags up or down on the grid to scroll the History screen
- **THEN** the screen scrolls and the displayed month does not change

#### Scenario: Tap a day after changing month
- **WHEN** the user swipes to an earlier month and taps a past day
- **THEN** the same confirmation appears to mark that day complete or remove its completion, and confirming records the change for that day

### Requirement: Tapping the title opens a month and year wheel
The month title SHALL be a button. Tapping it SHALL replace the month grid with a month wheel and a year wheel, both set to the displayed month. Changing either wheel SHALL change the displayed month immediately. Tapping the title again SHALL close the wheels and show the grid for the displayed month.

#### Scenario: Open the wheels
- **WHEN** the grid shows October 2026 and the user taps the title
- **THEN** the grid is replaced by a month wheel set to October and a year wheel set to 2026

#### Scenario: Jump to a past year
- **WHEN** the wheels are open on October 2026 and the user sets the year wheel to 2025
- **THEN** the title reads "October 2025"

#### Scenario: Close the wheels
- **WHEN** the wheels are open on August 2024 and the user taps the title
- **THEN** the wheels close and the grid shows August 2024

### Requirement: The wheel offers months from the routine's history through today
The year wheel SHALL list every year from the earliest of the year the routine was created, the year of its earliest recorded completion, and five years before the current year, through the current year. In the current year the month wheel SHALL NOT offer months later than the current month.

#### Scenario: New routine
- **WHEN** a routine was created this year and today is in October 2026
- **THEN** the year wheel lists 2021 through 2026

#### Scenario: Routine with an older completion
- **WHEN** a routine has a completion recorded in 2017 and today is in October 2026
- **THEN** the year wheel lists 2017 through 2026

#### Scenario: Current year limits the months
- **WHEN** the year wheel is on 2026 and today is in October 2026
- **THEN** the month wheel offers January through October only

#### Scenario: Switching to the current year after choosing a later month
- **WHEN** the wheels show December 2025 and the user sets the year wheel to 2026 while today is in October 2026
- **THEN** the displayed month becomes October 2026

### Requirement: Today returns to the current month
A Today button SHALL be shown next to the title whenever the displayed month is not the current month, and SHALL NOT be shown when it is. Tapping it SHALL show the current month and close the wheels if they are open.

#### Scenario: Today appears after leaving the current month
- **WHEN** the user swipes from the current month to the previous month
- **THEN** the Today button is shown

#### Scenario: Today is hidden on the current month
- **WHEN** the grid shows the current month
- **THEN** the Today button is not shown

#### Scenario: Tap Today from the wheels
- **WHEN** the wheels are open on August 2024 and the user taps Today
- **THEN** the wheels close, the grid shows the current month, and the Today button is hidden

### Requirement: Month changes are animated with respect to motion settings
When the displayed month changes by swiping, the new month SHALL slide in from the side matching the swipe direction. When Reduce Motion is on, or the app has animations disabled, the change SHALL cross-fade instead of sliding. A change made by the wheels or by Today MAY use the same transition.

#### Scenario: Slide
- **WHEN** Reduce Motion is off and the user swipes right
- **THEN** the previous month slides in from the leading edge

#### Scenario: Reduce Motion
- **WHEN** Reduce Motion is on and the user swipes right
- **THEN** the previous month appears with a cross-fade and no sliding movement

### Requirement: Month navigation is accessible with VoiceOver
The title SHALL be announced as a button that chooses the month, including the displayed month and year. The month grid SHALL be adjustable so that VoiceOver users can move to the next month by swiping up and to the previous month by swiping down, with the same limits as swiping. The Today button SHALL have a clear label.

#### Scenario: Title label
- **WHEN** VoiceOver focuses the title while the grid shows June 2026
- **THEN** it announces "June 2026, choose month" as a button

#### Scenario: Adjust to the previous month
- **WHEN** VoiceOver is focused on the grid and the user swipes down
- **THEN** the grid shows the previous month and VoiceOver announces the new month and year

#### Scenario: Adjust forward on the current month
- **WHEN** VoiceOver is focused on the grid showing the current month and the user swipes up
- **THEN** the displayed month does not change

### Requirement: The summary describes the current period for every displayed month
The summary at the top of History (progress ring, count against target, last done, and streak) SHALL describe the routine as of today, whichever month the grid shows. The recent completions list SHALL also be unaffected by the displayed month.

#### Scenario: Browse an older month
- **WHEN** the routine has 3 of 5 completions this week and the user shows a month from last year
- **THEN** the summary still reads 3/5 this week and the recent completions list is unchanged

### Requirement: Any displayed month shows its own completions and markers
For any displayed month, days SHALL be marked completed according to the routine's recorded completions, today SHALL be marked only when it is in the displayed month, days after today SHALL be disabled, and weekly or monthly goal-met highlighting SHALL be computed for that month's weeks or month.

#### Scenario: Past month with completions
- **WHEN** the user shows a past month in which the routine has three recorded completions
- **THEN** exactly those three days are marked completed and no day is marked as today

#### Scenario: Weekly goal met in a past month
- **WHEN** the routine is weekly with a target of 2 and a week of the displayed past month holds 2 completions
- **THEN** that week is highlighted as goal met
