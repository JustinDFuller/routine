# Visual Design Specification: Routine

## Purpose

This document defines the visual and interactive design of Routine for the planning phase of the product.

It is the design counterpart to [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md), which remains the source of truth for scope, behavior, and MVP boundaries.

This document is intentionally focused on:

- Design language
- User flows
- Interaction behavior
- Native iPhone design patterns and tools

This document does not define:

- System design
- Data structures
- Persistence or sync behavior
- Technical architecture
- Mockups, wireframes, or polished visual comps

## Product Framing

Routine is not a planner, scheduler, or coach. It is a personal visual tracker for recurring routines that happen on a flexible weekly or monthly cadence.

The app should feel like a calm personal control surface:

- Fast to read
- Fast to use throughout the day
- Clear about current status
- Forgiving when the user makes a mistake
- Native to iPhone, not like a custom productivity dashboard transplanted from the web

The design should reinforce the product principles from the brief:

- Flexible over rigid
- Visual over verbose
- Fast over feature-rich
- Forgiving over punitive
- Configurable over hard-coded

## Native iOS Design Foundation

The MVP should rely on native iOS patterns wherever possible so the product feels familiar, maintainable, and appropriately lightweight.

Preferred platform tools and conventions:

- `SwiftUI` for modern native interface construction
- `NavigationStack` for app hierarchy
- Native toolbar items for global actions
- Native sheets for focused add/edit tasks
- Native forms for routine editing
- Native lists, sections, swipe actions, and reorder behavior where they support the design cleanly
- `SF Symbols` for interface icons
- Semantic system colors and asset-catalog color roles for dark/light/high-contrast support
- Dynamic Type, VoiceOver, and reduced-motion-friendly behaviors by default

Custom visual treatment should be limited to the product's defining visual elements:

- Segmented progress rings
- Compact completion markings in history/calendar surfaces
- Card styling and transitions tuned to the product's calm visual language

Avoid for MVP:

- Third-party UI libraries
- A custom tab/navigation system
- Decorative motion systems
- Custom icon packs
- Gamified celebration patterns

## Design Principles

### 1. Visual first

The user should understand what is done, what is left, and how each routine is progressing before reading full text. Shape, fill, contrast, and position should carry as much meaning as possible.

### 2. One-tap common path

The most common action is marking a routine complete for today. That action must be available from the main dashboard with one tap on a comfortable target.

### 3. Forgiving by design

Accidental input is expected. Undo should be immediate after completion, and historical corrections should remain easy later.

### 4. Calm, not motivational

The app should feel useful and satisfying, but never judgmental, celebratory, streak-driven, or score-oriented.

### 5. Native where native works

Routine should borrow heavily from standard iPhone behaviors. Custom design should exist only where it materially improves the visual-first nature of the product.

### 6. Always visible

The dashboard should not hide completed items, infer scheduled obligations, or collapse monthly items by default. The app is a tracker, not a task sorter.

## Design Language

### Overall mood

The visual language should feel:

- Dark
- Grounded
- Warm
- Tactile
- Personal
- Quietly precise

It should not feel:

- Bright and gamified
- Corporate
- Clinical
- Dense and data-heavy
- Minimal to the point of ambiguity

### Color system

Use a role-based color system, not page-specific hardcoded colors. The implementation should prefer semantic system colors and asset colors with dark/light/increased-contrast variants.

Core color roles:

- `Canvas`
  - The full-screen background
  - Near-black or charcoal
  - Should feel like a calm base plane, not a pure black void
- `Surface`
  - The default routine card and grouped content surface
  - Slightly elevated from the canvas
- `Surface Elevated`
  - Used for sheets, overlays, and active/emphasized surfaces
  - Should read as layered above the base interface
- `Label Primary`
  - Routine names and high-importance text
- `Label Secondary`
  - Counts, last-done cues, and helper metadata
- `Accent Complete`
  - The primary completion/progress accent
  - Recommended direction: warm green or muted amber-green
  - Should feel mature and calm, not neon
- `Accent Active`
  - Used sparingly for selected controls, active focus, or navigation emphasis
  - May be a cooler neutral accent if needed, but should not compete with completion color
- `Accent Destructive`
  - Native iOS destructive red for delete/remove actions
- `Divider`
  - Subtle separators where needed, never high-contrast rules

Color usage rules:

- Completion state must never rely on color alone.
- Dark mode is the primary presentation target.
- The UI should still work cleanly in light mode, but the design language should be authored from dark mode first.
- Use contrast through value shifts, fill state, and surface layering more than through bright saturated color.
- Keep the number of decorative colors low. The interface should feel edited, not rainbow-coded.

### Surface language

Routine should use a layered dark surface model:

- Screen background uses the dimmest base color
- Routine cards sit above it as soft elevated surfaces
- Sheets and modal elements use a brighter elevated dark surface

This follows Apple's dark mode guidance around base and elevated backgrounds and helps the interface feel native in layered contexts.

### Typography

Use San Francisco and Dynamic Type, not a custom type system.

Recommended text roles:

- Screen title: `Large Title`
- Section headers: `Footnote` or `Subheadline`, semibold
- Routine name: `Body` or `Headline`, semibold
- Progress count: `Footnote`, medium or semibold
- Last-done metadata: `Caption` or `Footnote`, regular
- Form labels: native form defaults

Typography rules:

- Prefer sentence case.
- Avoid all-caps section labels unless the implementation can keep them subtle.
- Keep text short and functional.
- Do not use typographic tricks like heavy tracking, oversized numerals everywhere, or decorative display type.

### Shape and spacing

The shape system should be soft and consistent:

- Routine cards: rounded rectangles
- Progress indicators: circles/rings
- Metadata pills: softly rounded capsules
- Sheets and dialogs: native corner behavior

Recommended layout defaults:

- Horizontal page padding: `16pt`
- Vertical space between sections: `24pt`
- Routine card internal padding: `14-16pt`
- Routine card corner radius: approximately `16pt`
- Metadata pill corner radius: approximately `10pt`
- Minimum interactive control target: at least `44x44pt`

The result should feel comfortable for thumb use, not compressed to maximize density.

### Iconography

Use `SF Symbols` for all interface icons.

Recommended symbol directions:

- Completion check state: `checkmark`
- View history: `calendar`, `clock.arrow.circlepath`, or similar native symbol
- More actions: `ellipsis.circle`
- Add routine: `plus`
- Edit: `pencil`
- Delete: `trash`
- Reorder: native reorder handle

Symbol rules:

- Prefer monochrome or hierarchical rendering over multicolor symbols
- Use fill variants only when they reinforce state clearly
- Keep symbol weight aligned with adjacent text weight
- Do not mix unrelated visual styles across icons

Launcher icon guidance:

- The app launcher icon is separate from interface iconography and should be designed as its own artifact.
- It should be a polished MVP launcher icon for personal dogfooding readiness, not the start of a full brand system.
- It should follow the product's visual mood: dark, grounded, warm, tactile, calm, and not gamified.
- Avoid custom icon packs, mascots, gamified badges, streak or flame imagery, and dense UI screenshot-style compositions.

### Motion

Motion should confirm state changes, not entertain.

Recommended motion behavior:

- Completion: short fill/check transition, roughly `120-180ms`
- Undo banner: gentle slide/fade, roughly `180-220ms`
- Sheet presentation: standard iOS sheet behavior

Avoid:

- Bounce-heavy animations
- Confetti or reward bursts
- Progress pulses that imply urgency
- Constant animated surfaces

### Haptics

Use haptics lightly:

- Light impact or selection feedback on completion
- Light feedback on undo
- No heavy celebratory haptics for routine use

## Information Architecture

The MVP should use a dashboard-first hierarchy.

Primary surfaces:

1. Today Dashboard
2. Routine History
3. Manage Routines
4. Add/Edit Routine

Navigation model:

- Launch into the Today Dashboard
- Use a `NavigationStack` as the base app hierarchy
- Open Manage Routines from a dashboard toolbar action
- Present Add/Edit Routine as a focused modal sheet from Manage
- Open Routine History from an individual routine's secondary action path

Navigation should feel shallow and clear. The app does not need a persistent tab bar for MVP.

Reasoning:

- The dashboard is the product
- History is routine-specific, not a primary destination
- Management is necessary but secondary
- A tab bar would add visual weight without improving the main flow

## Screen Specifications

### Today Dashboard

The Today Dashboard is the default landing screen and primary daily-use surface.

#### Purpose

- Show the full routine in user-defined order
- Keep all routines visible
- Separate today's state visually
- Make completion a one-tap action
- Provide lightweight access to history and management

#### Top bar

Use native navigation chrome.

Recommended structure:

- Title: `Today`
- Optional subtitle/date context near the top of the content area, such as `Saturday, June 6`
- Trailing toolbar button: `Manage`

For MVP, prefer the text label `Manage` over an icon-only control. The action is important but secondary, and a labeled control improves clarity without adding much visual weight.

#### Content structure

The main content is a vertically scrolling grouped dashboard.

Structure:

- Sectioned by user-defined groups
- Each group rendered as a visible section with a text label
- Routine cards stacked within each section
- No default collapse behavior
- No hiding of completed routines

Section header behavior:

- Short text label only
- Semibold, subtle, secondary-toned
- Should separate content without becoming a dominant heading

Optional section summary:

- Allowed only if it stays visually quiet
- Example: `2 remaining`
- Omit if it creates clutter

#### Routine card anatomy

Each routine card should contain five pieces of information:

1. Progress ring
2. Routine name
3. Current count versus target
4. Frequency period context
5. Last-done cue

Recommended visual layout:

- Leading: segmented progress ring
- Center: routine name and metadata line
- Trailing: secondary action affordance

Recommended card behavior:

- The card itself is the primary completion target when the routine is incomplete today
- A dedicated secondary action button remains visible for history and additional actions

Recommended default sizes:

- Dashboard ring diameter: approximately `34pt`
- Card minimum visual height: approximately `72-88pt`, depending on text size
- Secondary action hit target: at least `44x44pt`

#### Metadata format

The metadata line should stay compact and scannable.

Recommended content pattern:

- Count pill, such as `3/5`
- Period label, such as `week` or `month`
- Last-done text, such as `Today`, `Yesterday`, `3d ago`, `Jun 2`, or `Never`

Recommended visual treatment:

- Count and period can be shown as separate quiet pills, or as a single compact pill
- Last-done text should remain plain secondary text, not another dominant chip

#### Card states

The dashboard must clearly distinguish at least these states:

##### Incomplete today

- Ring is partially filled or unfilled based on current period progress
- No completion checkmark in the center
- Card has the strongest available contrast
- Routine name is fully prominent
- Tap affordance should feel active

##### Completed today

- Ring reflects updated period progress
- Center checkmark appears in the ring
- Last-done text reads `Today`
- Card contrast softens slightly to indicate completion without disappearing
- Routine name remains readable and present
- Do not gray the row into irrelevance
- Do not use strikethrough

##### Period target met

- Ring reads visually complete
- Count remains visible
- If the routine is not done today, it should still appear actionable if incomplete for the day

##### Period target exceeded

- Ring remains visually full
- Count text shows actual overage, such as `6/5`
- Do not introduce badges, trophies, or reward styling

### Segmented Progress Ring

The segmented progress ring is the primary visual motif of the app.

#### Purpose

- Communicate weekly or monthly progress at a glance
- Anchor each card visually
- Reinforce completion without relying on text

#### Behavior

- Segment count should equal the target count when the target remains legible in ring form
- Filled segments should equal current period completions
- The ring should update immediately after a completion or undo
- A center checkmark should appear only when the routine is completed today

#### Legibility rule

Segmented rings work best for modest target counts, which matches the initial product examples.

Design decision for larger targets:

- For targets from `1` to `8`, use one visible segment per target
- For targets above `8`, switch to a continuous ring or lightly ticked ring while keeping the exact count in text

This keeps the visual language stable without forcing unreadable micro-segments in the dashboard.

#### Color and non-color communication

The ring must remain understandable without color alone.

Use:

- Filled versus unfilled segments
- Different opacity levels
- A center checkmark for done-today state
- Adjacent count text

Do not rely on:

- Accent color alone
- Tiny segment details that disappear at small sizes

### Secondary Actions on a Routine

Every routine needs a visible path to history and secondary actions without interfering with one-tap completion.

Recommended pattern:

- Provide a trailing `ellipsis.circle` button on every routine card
- Tapping that button opens a lightweight action sheet or confirmation dialog

Recommended actions:

- `View History`
- `Edit Routine`
- `Undo Today's Completion` when applicable
- `Cancel`

Do not place delete on the dashboard action sheet. Deletion belongs in routine management, not daily use.

### Completion Interaction

The completion interaction is the most important micro-flow in the app.

#### Incomplete routine

When the user taps an incomplete routine card:

- Mark the routine complete for today immediately
- Update the ring, count, and last-done cue immediately
- Add the center checkmark to the ring
- Apply subtle state-transition animation
- Trigger light haptic feedback
- Show a temporary undo affordance

The interaction should feel instant. There should be no intermediate confirmation step.

#### Undo affordance

After a completion, show a temporary undo surface near the bottom of the screen using a native-feeling transient overlay.

Recommended content:

- Message: `Completed Morning Yoga`
- Action: `Undo`

Behavior:

- Appears immediately after completion
- Stays visible long enough to be usable without rushing
- Dismisses automatically if ignored
- Does not block continued scrolling or completing other routines

#### Completed routine

When the user taps a routine already completed today:

- Do not create a second completion
- Open the same secondary action surface used by the trailing action button

This prevents accidental duplicate intent while still making the row useful after completion.

#### Undoing today's completion

The user must be able to undo today's completion from two places:

- The transient undo affordance immediately after completion
- The routine's secondary action sheet later

Undo behavior:

- Restore the incomplete-today visual state immediately
- Remove the center checkmark
- Update count and last-done cue
- Trigger light feedback

### Routine History

Routine History is the main answer to the question: "When did I last do this?"

#### Navigation

Access history from a routine's secondary actions.

History should open as a dedicated routine-specific screen in the navigation hierarchy, not as a tiny popover or a cramped inline expansion.

#### Purpose

- Show the last completion clearly
- Show recent completion patterns
- Allow correction of mistaken completions

#### Screen structure

Recommended layout:

1. Summary header
2. Calendar-like month view
3. Recent completions list

#### Summary header

The top of the history screen should include:

- Routine name
- Frequency summary, such as `5 per week`
- Larger progress ring or progress summary
- Last completed date in explicit language
- Current period count versus target

Recommended last-done phrasing:

- `Done today`
- `Last done yesterday`
- `Last done Jun 2`
- `No completions yet`

#### Calendar-like month view

Use a compact month grid for the current month as the primary visual history surface.

Behavior:

- Completed dates are visibly marked
- Today's date is visibly distinguishable whether completed or not
- The current month context is obvious
- The calendar should stay calm and readable, not become a dense analytics heatmap

Recommended marking style:

- Completed day: filled dot, fill ring, or highlighted cell
- Today: subtle outline or native emphasis
- Completed today: both completion mark and today emphasis

The calendar should communicate presence of activity, not score it.

#### Recent completions list

Below the month view, show an explicit descending list of recent completion dates.

Purpose:

- Make exact dates easy to scan
- Provide a straightforward correction path

Each row should show:

- Explicit date
- Relative cue if useful, such as `Yesterday`
- Remove action path

#### Removing a mistaken completion

From the recent completions list, the user should be able to remove an incorrect historical completion.

Behavior:

- The remove action is destructive
- The app confirms before deletion
- The history surface updates immediately after confirmation
- Dashboard state and period progress should reflect the change when the user returns

### Manage Routines

Manage Routines is the utilitarian configuration surface for the product.

It should feel simple, direct, and native, not like a setup wizard.

#### Navigation

Open Manage Routines from the dashboard toolbar.

Recommended presentation:

- Push onto the navigation stack from the dashboard

Reasoning:

- It preserves the dashboard as the app's home surface
- It avoids stacking too many modal layers
- It fits a settings-like maintenance task

#### Manage screen structure

The main management view should include:

- Sectioned list of routines by group
- Routine summary rows
- Add routine affordance
- Native edit mode for reorder behavior

Each row should show:

- Routine name
- Short summary, such as `5 per week`
- Optional group context if needed for clarity

#### Actions

Manage screen supports:

- Add routine
- Open routine for editing
- Reorder routines
- Delete routine

Delete should not be the dominant action visually.

### Add/Edit Routine

Adding and editing a routine should use a focused native form.

Recommended presentation:

- Modal sheet over Manage Routines

Reasoning:

- This is a contained task
- Native form sheets support clear cancel/save behavior
- It keeps management flow lightweight

#### Form fields

MVP fields:

- Routine name
- Target count
- Frequency period: `Weekly` or `Monthly`
- Group assignment

Preferred control patterns:

- Name: text field
- Target count: stepper or compact numeric picker
- Frequency period: segmented picker or inline picker with only two options
- Group assignment: picker or editable grouped choice based on existing groups

#### Form actions

- Primary save action: `Save` or `Done`
- Secondary dismiss action: `Cancel`

Form behavior:

- Keep labels direct and utilitarian
- Avoid helper text unless needed for clarity
- Reflect the same dark surface language as the rest of the app

#### Delete from edit

Deletion may also be exposed within edit, but it must:

- Use destructive red styling
- Be visually separated from save actions
- Require confirmation

## User Flows

### 1. Daily completion flow

1. User opens the app into the Today Dashboard.
2. User scans grouped routines.
3. User taps an incomplete routine card.
4. The card updates immediately to completed-today state.
5. Undo appears temporarily.
6. User either leaves the completion in place or taps `Undo`.

Success criteria:

- One tap completes
- No confusion about whether the action worked
- No route change required

### 2. Check last-done flow

1. User opens a routine's secondary actions.
2. User chooses `View History`.
3. History opens with last-done information visible near the top.
4. User inspects calendar markings or recent completions.
5. User returns to the dashboard.

Success criteria:

- Last completion can be found in seconds
- The user does not need to parse a dense timeline

### 3. Correct mistaken completion flow

1. User opens history for the routine.
2. User finds the incorrect date in recent completions.
3. User chooses remove/delete completion.
4. The app confirms the destructive action.
5. On confirmation, the date is removed and progress updates.

Success criteria:

- Correction is explicit and safe
- The user can trust the data after fixing it

### 4. Already completed routine flow

1. User taps a routine already completed today.
2. The app opens secondary actions instead of creating another completion.
3. User may undo today's completion or view history.

Success criteria:

- Duplicate daily completions are never created through repeated taps
- A completed row still feels useful

### 5. Routine setup and maintenance flow

1. User taps `Manage`.
2. User adds, edits, reorders, or deletes routines.
3. User dismisses the add/edit form.
4. User returns to the dashboard and sees the updated routine structure immediately.

Success criteria:

- Setup is straightforward
- Editing does not feel like leaving the app's main model

### 6. Empty state flow

If the user has no routines configured:

- The dashboard should show a practical empty state
- The empty state should explain the absence simply
- The empty state should provide a clear path to add routines

Recommended empty-state tone:

- `No routines yet`
- `Add your first routine to start tracking`

Avoid:

- Cheerful onboarding illustration systems
- Long explanatory copy
- Motivational language

## Interaction Rules

### Primary interactions

- Tap incomplete routine card to complete
- Tap completed routine card to open secondary actions
- Tap trailing more button for history/edit/undo actions
- Tap `Manage` for maintenance tasks

### Secondary interactions

- Swipe actions may be used inside management lists as shortcuts
- Long press may expose a context menu if it adds convenience

Neither swipe nor long press may be the only way to reach a core action.

### Gesture philosophy

Keep gestures simple, visible, and optional.

Avoid:

- Hidden multi-step gestures
- Drag interactions on the dashboard outside standard scroll
- Gesture-only affordances for correction or history

### State updates

Whenever the user completes or undoes a routine:

- The visible state should change immediately
- Counts should update immediately
- Last-done text should update immediately
- Progress indicators should update immediately

The interface should always feel current.

## Accessibility and Platform Expectations

Accessibility should be treated as part of the base design, not a post-design checklist.

Requirements:

- Support Dynamic Type
- Support VoiceOver with meaningful combined labels
- Maintain sufficient contrast in dark and light appearances
- Provide accessible labels for progress rings and secondary action buttons
- Do not rely on color alone for completion or period status
- Keep core controls at or above comfortable iPhone tap-target sizes
- Respect reduced motion where appropriate

Recommended VoiceOver phrasing example:

- `Morning Yoga, completed today, 3 of 5 this week`

The dashboard should remain understandable when:

- Colors are muted
- Text sizes are increased
- Motion is reduced
- The user navigates by assistive technology instead of direct touch

## Copy Guidelines

Copy should be short, direct, and nonjudgmental.

Prefer:

- `Today`
- `Done today`
- `Undo`
- `View history`
- `5 per week`
- `Last done yesterday`
- `No completions yet`

Avoid:

- `Streak`
- `Score`
- `Fail`
- `Perfect`
- `Crush your goals`
- `Stay on track`

The product should sound practical, not motivational.

## Explicit Non-Goals for MVP Design

The visual design should not imply or prepare for features that the MVP does not include.

Do not design around:

- Notifications
- Streaks
- Achievements
- Smart scheduling
- Recommended-today logic
- Widgets
- Collaboration
- Sharing
- Analytics dashboards

The design should stay focused on the four questions defined in the product brief.

## Acceptance Criteria

`VISUAL_DESIGN.md` is complete when it enables an engineer or designer to implement the MVP experience without inventing major product behavior or UI conventions.

Specifically, the document should make clear:

- What the app should feel like visually
- Which iOS-native tools and patterns should be preferred
- How the dashboard is organized
- What each routine card contains
- How completion and undo behave
- How history is presented
- How routine management works
- How accessibility and dark mode affect the design

## Apple References

The following Apple guidance should inform implementation:

- Human Interface Guidelines
  - https://developer.apple.com/design/human-interface-guidelines/
- Dark Mode
  - https://developer.apple.com/design/human-interface-guidelines/ios/visual-design/dark-mode
- Color
  - https://developer.apple.com/design/human-interface-guidelines/color
- Accessibility
  - https://developer.apple.com/design/human-interface-guidelines/accessibility
- Buttons
  - https://developer.apple.com/design/human-interface-guidelines/buttons
- Lists and tables
  - https://developer.apple.com/design/human-interface-guidelines/lists-and-tables
- Sheets
  - https://developer.apple.com/design/human-interface-guidelines/sheets
- SF Symbols
  - https://developer.apple.com/design/human-interface-guidelines/sf-symbols
- SwiftUI
  - https://developer.apple.com/documentation/swiftui/
- NavigationStack
  - https://developer.apple.com/documentation/swiftui/navigationstack
