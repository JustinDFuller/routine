## ADDED Requirements

### Requirement: Sideways swipes on the calendar never leave History
A sideways swipe that starts anywhere inside the calendar card (the title row, the day grid, and the month and year wheels when they are open) SHALL NOT take the user back to the previous screen, however many times the user swipes and whether or not the displayed month can change.

#### Scenario: Swipe right many times on the grid
- **WHEN** the user swipes right on the day grid eight times in a row
- **THEN** each swipe shows the previous month, the History screen stays open, and the title reads eight months earlier than where it started

#### Scenario: Swipe left on the current month
- **WHEN** the grid shows the current month and the user swipes left on it
- **THEN** the displayed month does not change and the History screen stays open

#### Scenario: Swipe right on the title row
- **WHEN** the user swipes right starting on the month title row
- **THEN** the displayed month does not change and the History screen stays open

#### Scenario: Swipe right on the open wheels
- **WHEN** the month and year wheels are open and the user swipes right starting on the card outside the wheels' scrolling area
- **THEN** the displayed month does not change and the History screen stays open

### Requirement: Swiping outside the calendar keeps its normal behavior
A swipe that starts outside the calendar card, including on the summary above it, the recent completions below it, or the left screen edge, SHALL behave as it does on any other screen: a swipe right goes back to the previous screen. Vertical scrolling and tapping SHALL keep working everywhere, including over the calendar card.

#### Scenario: Swipe right below the calendar
- **WHEN** the user swipes right starting on the recent completions section
- **THEN** the app goes back to the previous screen

#### Scenario: Swipe right from the left edge
- **WHEN** the user swipes right starting at the left screen edge, beside the calendar card
- **THEN** the app goes back to the previous screen

#### Scenario: Scroll over the calendar
- **WHEN** the user drags up or down starting on the day grid
- **THEN** the screen scrolls, the displayed month does not change, and the History screen stays open
