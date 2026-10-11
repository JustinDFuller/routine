# routine-availability Specification

## Purpose

Lets a routine optionally be tied to a local time-of-day window. Outside the window the routine stays out of the way (collapsed on Today, absent from the widget) but remains completable unless the user opts into a strict window, and past days can always be completed.

## Requirements

### Requirement: Routines are available all day unless a window is set
A routine SHALL be available all day unless it has a configured time-of-day window. A window SHALL have a start time and an end time that differ, and MAY span midnight. Windows SHALL be evaluated in the user's current local time at the moment of display or completion.

#### Scenario: Routine without a window
- **WHEN** a routine has no configured window
- **THEN** it is treated as inside its window at every time of day

#### Scenario: Window that spans midnight
- **WHEN** a routine has a window from 11:00 PM to 3:00 AM
- **THEN** 11:30 PM and 1:00 AM are inside the window and 3:00 AM and 12:00 PM are outside it

#### Scenario: Equal start and end are rejected
- **WHEN** the user saves a routine whose start and end times are the same
- **THEN** the routine is not saved and the form explains that the times must differ

### Requirement: Out-of-window routines collapse on Today
When the "Collapse unavailable routines" setting is on (the default), Today SHALL show an incomplete routine that is outside its window as a compact row in its normal section. The user SHALL be able to expand the row to the full card, which shows the routine's window.

#### Scenario: Collapsed by default
- **WHEN** a routine with a window is incomplete and the current time is outside the window and the collapse setting is on
- **THEN** Today shows it as a compact row beneath the full cards in its section

#### Scenario: Expand a collapsed routine
- **WHEN** the user taps a compact out-of-window row
- **THEN** it expands to the full card and shows its window

#### Scenario: Collapse setting off
- **WHEN** the collapse setting is off and a routine is outside its window
- **THEN** Today shows it as a full card in its normal position

### Requirement: Out-of-window routines can be completed today by default
Unless the routine has a strict window, the user SHALL be able to complete it for today outside its window, including from the expanded card on Today.

#### Scenario: Complete an expanded out-of-window routine
- **WHEN** a routine without a strict window is outside its window, the user expands it, and taps complete
- **THEN** today is recorded as completed and the usual undo affordance is shown

### Requirement: Strict window blocks same-day completion outside the window
A routine MAY have a strict window, which SHALL be off by default and for every existing routine. For a routine with a strict window, a new completion for today SHALL be rejected outside the window with a clear message that states the window, and the card's complete control SHALL be disabled. A routine already completed today SHALL stay completed, and repeating the completion SHALL change nothing.

#### Scenario: Strict routine outside its window
- **WHEN** a routine with a strict window is outside its window and not yet completed today
- **THEN** its complete control is disabled and no completion for today can be recorded

#### Scenario: Strict routine inside its window
- **WHEN** a routine with a strict window is inside its window
- **THEN** it can be completed normally

#### Scenario: Already completed routine
- **WHEN** a strict routine was completed during its window and the current time is now outside it
- **THEN** it remains completed today and no duplicate completion is created

### Requirement: Past days can always be completed
The user SHALL be able to complete any past day for a routine from its History, regardless of the routine's window, whether its window is strict, and the current time.

#### Scenario: Strict routine on a past day
- **WHEN** the user completes a past day for a routine with a strict window while the current time is outside the window
- **THEN** the completion is recorded for that past day

#### Scenario: Future days remain unavailable
- **WHEN** the user tries to complete a day after today
- **THEN** the completion is rejected

### Requirement: The widget never offers out-of-window routines
The Home Screen widget SHALL only offer a routine as the next ready routine when the current time is inside the routine's window or the routine has no window. This SHALL apply whether or not the window is strict, and regardless of the "Collapse unavailable routines" setting on Today. When no other routine is ready, the widget SHALL show its caught-up state.

#### Scenario: Default routine outside its window
- **WHEN** an incomplete routine without a strict window is outside its window
- **THEN** the widget skips it and offers the next ready routine

#### Scenario: Strict routine outside its window
- **WHEN** an incomplete routine with a strict window is outside its window
- **THEN** the widget skips it and offers the next ready routine

#### Scenario: Collapse setting does not affect the widget
- **WHEN** the "Collapse unavailable routines" setting is off and a routine is outside its window
- **THEN** the widget still skips it

#### Scenario: Only out-of-window routines remain
- **WHEN** every remaining incomplete routine is outside its window
- **THEN** the widget shows its caught-up state

### Requirement: The widget refreshes when a window opens or closes
The widget SHALL refresh at the next start or end time of any routine's window, in addition to midnight, so a routine appears on the widget when its window opens and disappears when it closes.

#### Scenario: Window opens
- **WHEN** a routine without a strict window has a window that starts at 7:00 AM and the current time is 6:00 AM
- **THEN** the widget refreshes at 7:00 AM and offers the routine if it is next in order

#### Scenario: Window closes
- **WHEN** a routine's window ends at 5:00 PM and the current time is 4:00 PM
- **THEN** the widget refreshes at 5:00 PM and stops offering the routine

### Requirement: The form offers an optional strict window
The Add and Edit Routine form SHALL show a "Strict window" toggle only when the routine is not available all day. The toggle SHALL be off for new routines, and the form SHALL explain that outside the window the routine collapses and is hidden from the widget, that strict also prevents completing it then, and that past days can always be completed.

#### Scenario: Toggle hidden for all-day routines
- **WHEN** "Available all day" is on
- **THEN** the form does not show the "Strict window" toggle

#### Scenario: Toggle off by default
- **WHEN** the user turns "Available all day" off while adding a routine
- **THEN** the "Strict window" toggle is shown and off

#### Scenario: Existing strict routine
- **WHEN** the user edits a routine that already blocks completion outside its window
- **THEN** the "Strict window" toggle is on

#### Scenario: Strict setting is saved
- **WHEN** the user turns the toggle on and saves
- **THEN** reopening the routine shows the toggle on and the routine behaves as strict
