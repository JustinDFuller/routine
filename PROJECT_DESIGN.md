# Project Design: Routine

## Purpose

This document turns the planning specs for Routine into concrete implementation milestones.

Routine is a personal iPhone app for tracking flexible weekly and monthly routines in a visual, low-friction way. Each milestone below is intended to be completed by one agent in one focused coding session and delivered as one pull request that can be reviewed and merged before the next milestone starts.

Do not treat milestone count as a schedule. Treat milestone boundaries as dependency and review boundaries.

## Source Of Truth

Before starting any milestone, read these files:

- [AGENTS.md](AGENTS.md)
- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- [DATA_DESIGN.md](DATA_DESIGN.md)
- [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)
- This file

Use the existing specs this way:

- Product scope and behavior: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- Visual and interaction language: [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- Data structures, domain methods, projections, views, and routing: [DATA_DESIGN.md](DATA_DESIGN.md)
- Architecture, build, deployment, testing, debugging, resilience, performance, security, accessibility, and tooling: [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)

If specs appear to conflict, preserve the product behavior first, then the data/domain invariants, then the implementation architecture, then visual details. Update the relevant source spec only when a real product or architecture decision changes.

## Current Milestone

**CURRENT: M11 - Group And Reorder UI**

The implementation agent should work only on the milestone marked `CURRENT`, unless the user explicitly changes this file or requests a different milestone.

## Status Legend

- `CURRENT`: The next milestone to implement.
- `NOT STARTED`: Future work.
- `DONE`: Merged or ready to be considered complete.
- `BLOCKED`: Cannot continue without an external decision or environment change.

## Agent Workflow

Each implementation session should follow this workflow:

1. Read the source-of-truth files listed above.
2. Confirm the milestone marked `CURRENT`.
3. Make only the changes needed for that milestone.
4. Add or update tests whenever the milestone touches core invariants.
5. Run the narrowest relevant validation first, then the broadest available validation for the milestone.
6. Update this file:
   - Change the completed milestone from `CURRENT` to `DONE`.
   - Change the next milestone from `NOT STARTED` to `CURRENT`.
   - Update the roadmap table to match the milestone status sections.
   - Update the `Current Milestone` line near the top.
   - Add a short completion note under the completed milestone if any validation was skipped.
7. Run `git status --short` and review the final diff.
8. Commit the milestone work.
9. Push the branch.
10. Open a PR with `gh pr create`.
11. Stop after opening the PR.

Do not combine multiple milestones in one PR unless the user explicitly asks for that. Do not leave a milestone half-complete and advance the current marker.

## Validation Rules

Validation expands as the project becomes real:

- Early milestones may only have package tests, formatting checks, or generic iOS builds.
- iOS simulator and UI tests are conditional until a simulator runtime or suitable connected device is available.
- If a validation command is unavailable because of the local environment, document the skipped check in the PR and in this file under the completed milestone.
- A milestone that adds or changes an invariant must include tests for that invariant in the same PR.

Core invariants that require automated coverage when touched:

- Daily completion uniqueness.
- Monday-start weekly date windows.
- Calendar-month date windows.
- Starter data seeds once.
- Routine and group validation.
- Sort-order normalization.
- Historical completion deletion.
- Dashboard and history projection correctness.
- Navigation by stable IDs.

## Roadmap

| Status | Milestone | Working State |
| --- | --- | --- |
| DONE | M01 - Project Scaffold And Local Tooling | Repo has a generated iOS project, portable package target, scripts, and a minimal app shell. |
| DONE | M02 - RoutineCore Domain Logic | Portable domain logic is implemented and tested locally and in Ubuntu CI. |
| DONE | M03 - SwiftData Persistence Foundation | App has canonical SwiftData models, container setup, fetch helpers, and in-memory test support. |
| DONE | M04 - Starter Data Seeding | First launch seeds editable dogfooding routines exactly once. |
| DONE | M05 - Tracking Service | Completing, duplicate prevention, undo, and historical removal work through tested services. |
| DONE | M06 - Management Service | Routine and group CRUD, validation, moves, and sort normalization work through tested services. |
| DONE | M07 - Projection Layer | Dashboard, history, and manage screens have immutable view data builders. |
| DONE | M08 - Visual Foundation Components | Color roles, progress ring, routine card, and undo banner components compile and render from view data. |
| DONE | M09 - Today Dashboard Flow | The main dashboard shows seeded routines and supports one-tap completion with undo. |
| DONE | M10 - Routine Management UI | The user can add, edit, delete, and assign routines from native management screens. |
| CURRENT | M11 - Group And Reorder UI | The user can manage groups and reorder routines/groups through native controls. |
| NOT STARTED | M12 - Routine History UI | The user can inspect and correct routine-specific completion history. |
| NOT STARTED | M13 - Accessibility, Polish, And UI Coverage | Primary flows satisfy accessibility, motion, visual, and UI-test expectations. |
| NOT STARTED | M14 - Dogfooding Readiness | Local validation, diagnostics, privacy, app icon, and device-readiness checks are complete. |

## Milestones

### M01 - Project Scaffold And Local Tooling

Status: `DONE`

Goal: create a buildable project foundation that later agents can extend without deciding project shape.

Dependencies: none.

Primary references: [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md), especially Project Structure, Targets And Modules, Build And Local Development, Formatting And Linting.

Deliverables:

- Add the repository structure described in the system design: `RoutineApp/`, `RoutineCore/`, `RoutineAppTests/`, `RoutineAppUITests/`, and `Scripts/`.
- Add `project.yml` as the canonical XcodeGen project definition.
- Add a minimal `RoutineApp` SwiftUI iPhone app target with a placeholder `RootView`.
- Add a minimal `RoutineCore` Swift package or package-backed target that can build and test without iOS-only frameworks.
- Add test targets for `RoutineCore`, `RoutineAppTests`, and `RoutineAppUITests`, even if app tests begin with smoke tests only.
- Add root development config: `.gitignore`, `.swift-format`, `.swiftlint.yml`, and any required generated-project ignore rules.
- Add local scripts for project generation, in-place formatting, formatting checks, SwiftLint, core tests, generic iOS build, and full validation.
- Add a basic privacy manifest file for the app target.
- Do not implement product behavior yet.

Validation:

- Generate the project with the new script.
- Run formatting check.
- Run SwiftLint if it can execute against the scaffold.
- Run `RoutineCore` tests.
- Build the iOS app for a generic iOS destination if available.
- Document any simulator/UI-test skips caused by missing simulator runtimes.

Completion update:

- Mark this milestone `DONE`.
- Mark M02 `CURRENT`.

Completion note:

- `Scripts/validate.sh` completed with explicit skips for the generic iOS build and iOS tests because this machine does not have an eligible generic iOS device destination or simulator runtime installed.

### M02 - RoutineCore Domain Logic

Status: `DONE`

Goal: implement portable domain values and pure business logic before SwiftData or SwiftUI depends on them.

Dependencies: M01.

Primary references: [DATA_DESIGN.md](DATA_DESIGN.md) sections Core Domain Concepts, Calendar And Date Handling, Progress Model; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) sections Calendar And Date Policy and Testing Strategy.

Deliverables:

- Implement `RoutinePeriod`, `RoutineDay`, `RoutineCalendar`, `RoutineProgress`, and `ProgressCalculator` in `RoutineCore`.
- Implement pure validation helpers for routine names, group names, target ranges, and case-insensitive group-name uniqueness.
- Implement pure sort-order normalization helpers if management services will use shared logic.
- Keep `RoutineCore` free of SwiftUI, SwiftData, UIKit, OSLog, and iOS-only APIs.
- Add an Ubuntu-compatible GitHub Actions workflow for `RoutineCore` build/tests and formatting check if the formatter is practical in CI.

Validation:

- Run `RoutineCore` tests locally.
- Run formatting check.
- Confirm the GitHub Actions workflow is syntactically valid.

Required tests:

- `RoutineDay` key formatting, ordering, equality, and parsing if parsing is implemented.
- Monday-start week ranges for every weekday.
- Week boundaries across month and year changes.
- Month ranges, including February and leap years.
- DST-adjacent local date behavior where Foundation can affect conversion.
- Weekly and monthly progress counting.
- Target-met and over-target behavior.
- Completed-today detection.
- Last-completed-day derivation.
- Relative and explicit date labels.
- Target count validation.
- Name trimming and empty-name validation.
- Group-name uniqueness comparison.
- Sort normalization helper behavior if implemented.

Completion update:

- Mark this milestone `DONE`.
- Mark M03 `CURRENT`.

Completion note:

- `Scripts/validate.sh` completed with explicit skips for the generic iOS build and iOS tests because this machine does not have an eligible generic iOS destination or configured `IOS_TEST_DESTINATION`. The Ubuntu workflow runs `swift build` and `swift test`, but leaves `swift-format` as a local validation because adding a compatible formatter setup to Ubuntu was not practical for this milestone.

### M03 - SwiftData Persistence Foundation

Status: `DONE`

Goal: add the canonical local data model and testable persistence setup without implementing user workflows yet.

Dependencies: M01, M02.

Primary references: [DATA_DESIGN.md](DATA_DESIGN.md) sections Data Model, Storage Design, Data Access Patterns; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) sections Domain Model And Persistence and Robustness And Resilience.

Deliverables:

- Add SwiftData models for `RoutineGroup`, `Routine`, `RoutineCompletion`, and `AppMetadata`.
- Preserve the data invariants from `DATA_DESIGN.md`, adapting only where SwiftData requires a practical implementation adjustment.
- Add a single app `ModelContainer` containing all canonical models.
- Add test helpers for in-memory SwiftData containers.
- Add stable-ID fetch helpers for routines, groups, and completions.
- Add typed or mappable persistence/domain errors for not-found and save failure cases.
- Keep derived progress, labels, and dashboard state out of persistence.

Validation:

- Build the iOS app.
- Run app unit tests against an in-memory container.
- Run `RoutineCore` tests.
- Run formatting and lint checks.

Required tests:

- Models can be inserted, fetched by stable ID, related, and deleted in an in-memory store.
- Routine deletion cascades completions.
- Completion day identity uses `dayKey`.
- Routine-day uniqueness is enforced or explicitly guarded in the service-facing helper layer if SwiftData uniqueness behavior requires that split.

Completion update:

- Mark this milestone `DONE`.
- Mark M04 `CURRENT`.

### M04 - Starter Data Seeding

Status: `DONE`

Goal: make the first dogfooding launch useful while ensuring seed data never reappears after user edits or deletion.

Dependencies: M03.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Initial Data Strategy; [DATA_DESIGN.md](DATA_DESIGN.md) StarterDataService; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Domain Services and Robustness And Resilience.

Deliverables:

- Implement `StarterDataService`.
- Seed the starter groups from the product brief: Morning, Movement, Family / Home, Learning / Creative, Evening, Monthly Maintenance.
- Seed starter routines based on the product brief examples with appropriate weekly or monthly periods and target counts.
- Store `starterDataSeedVersion = "1"` in `AppMetadata`.
- Trigger seeding once from the app shell when the model context is available.
- Ensure seeded groups and routines are normal editable data, not protected templates.
- If seeding fails, launch without crashing and surface/log a user-safe failure.

Validation:

- Run app unit tests with an in-memory container.
- Build the iOS app.
- Run `RoutineCore` tests.
- Run formatting and lint checks.

Required tests:

- Empty store seeds once.
- Existing seed metadata prevents reseeding, even when no routines remain.
- Starter groups and routines have expected names, periods, targets, groups, and contiguous sort orders.
- Seeded data can be edited or deleted by normal service paths once those paths exist; until then, assert it is not specially marked or protected.

Completion update:

- Mark this milestone `DONE`.
- Mark M05 `CURRENT`.

### M05 - Tracking Service

Status: `DONE`

Goal: implement the core daily-use mutation path behind the future dashboard.

Dependencies: M03, M04.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Completion rules; [DATA_DESIGN.md](DATA_DESIGN.md) RoutineTrackingService; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Domain Services, Error Handling, Robustness And Resilience.

Deliverables:

- Implement `RoutineTrackingService` as a main-actor SwiftData service.
- Implement `completeToday(routineID:now:)`, `undoToday(routineID:now:)`, and `removeCompletion(completionID:)`.
- Make same-routine same-day completion idempotent.
- Remove only today's completion from `undoToday`.
- Remove historical completions by completion ID.
- Save explicitly after successful mutations.
- Map low-level persistence failures to user-safe errors.
- Avoid user-facing errors for duplicate complete attempts.

Validation:

- Run app service tests with an in-memory container.
- Run `RoutineCore` tests.
- Build the iOS app.
- Run formatting and lint checks.

Required tests:

- Completing an incomplete routine inserts exactly one completion.
- Completing the same routine/day again returns `didInsert = false` and does not duplicate.
- Completing different routines on the same day works.
- Completing the same routine on different days works.
- Undo today removes only today's completion.
- Undo today when no completion exists is safe.
- Historical removal deletes only the selected completion.
- Missing routine and missing completion errors are user-safe.
- Progress derived after completion/removal matches expected day keys.

Completion update:

- Mark this milestone `DONE`.
- Mark M06 `CURRENT`.

### M06 - Management Service

Status: `DONE`

Goal: implement routine and group maintenance rules behind the future management UI.

Dependencies: M03, M04.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Manage Routines View; [DATA_DESIGN.md](DATA_DESIGN.md) RoutineManagementService; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Domain Services, Error Handling, Robustness And Resilience.

Deliverables:

- Implement `RoutineDraft`.
- Implement `RoutineManagementService`.
- Support create, update, delete, and move routine operations.
- Support create, rename, delete empty, and move group operations.
- Trim names before validation and persistence.
- Enforce target ranges: weekly `1...7`, monthly `1...31`.
- Allow duplicate routine names.
- Reject empty group names and duplicate group names after trimming with case-insensitive comparison.
- Block non-empty group deletion.
- Normalize sort orders after create, move, delete, and reorder operations.
- Save explicitly after successful mutations.

Validation:

- Run app service tests with an in-memory container.
- Run `RoutineCore` tests.
- Build the iOS app.
- Run formatting and lint checks.

Required tests:

- Creating and editing routines validates name, target, period, and group.
- New routines append to the selected group.
- Updating a routine can change group, period, target, and name.
- Deleting a routine cascades completion history.
- Moving routines within a group and across groups updates `groupID`, relationship, and contiguous sort order.
- Creating and renaming groups validates empty and duplicate names.
- Deleting an empty group succeeds.
- Deleting a non-empty group fails without orphaning routines.
- Moving groups normalizes group sort order.

Completion update:

- Mark this milestone `DONE`.
- Mark M07 `CURRENT`.

### M07 - Projection Layer

Status: `DONE`

Goal: create immutable view data builders so SwiftUI screens render derived state without owning business rules.

Dependencies: M02, M03, M05, M06.

Primary references: [DATA_DESIGN.md](DATA_DESIGN.md) sections Data Access Patterns, View Data Structures, Views; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Query / Projection Layer and Performance And Responsiveness.

Deliverables:

- Implement `DashboardProjectionBuilder`.
- Implement `HistoryProjectionBuilder`.
- Implement `ManageProjectionBuilder`.
- Add the view data structures defined in `DATA_DESIGN.md` or equivalent names with the same behavior.
- Fetch in bulk and build projections in memory for the dashboard.
- Include all routines on dashboard projections, including completed and monthly routines.
- Produce count text, period text, last-done labels, accessibility labels, section remaining counts, and progress ring data.
- Produce history summary, current-month calendar day data, and descending recent completions.
- Produce manage list sections and routine summary strings without progress concerns.
- Safely handle stale routine IDs by producing a not-found state or typed error for the view.

Validation:

- Run projection tests with in-memory fixture data.
- Run service tests.
- Run `RoutineCore` tests.
- Build the iOS app.
- Run formatting and lint checks.

Required tests:

- Dashboard includes every group and every routine in sort order.
- Dashboard includes monthly routines and completed routines.
- Current week/month counts use `RoutineCore` date windows.
- Last-done labels match today, yesterday, recent days, older current-year dates, prior-year dates, and never.
- Progress ring data switches from segmented to continuous/ticked above target count 8.
- History marks today, completed dates, completed today, and recent completions correctly.
- Recent completions sort by `dayKey` descending, then `completedAt` descending.
- Manage projections ignore dashboard progress and render expected summaries.
- Missing routed routine does not crash projection construction.

Completion update:

- Mark this milestone `DONE`.
- Mark M08 `CURRENT`.

### M08 - Visual Foundation Components

Status: `DONE`

Goal: establish the reusable visual language before wiring complete screens.

Dependencies: M07.

Primary references: [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Design Language, Segmented Progress Ring, Routine Card Anatomy, Undo affordance; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Visual Implementation Details and Accessibility.

Deliverables:

- Add asset-catalog or semantic color roles for canvas, surface, elevated surface, label roles, completion accent, active accent, destructive accent, and dividers.
- Implement `SegmentedProgressRingView`.
- Implement `RoutineCardView`.
- Implement `UndoBannerView`.
- Add small reusable metadata/count components only if they reduce duplication.
- Ensure components render entirely from immutable view data.
- Ensure the progress ring does not query persistence or calculate progress internally.
- Support segmented rings for targets `1...8` and continuous or lightly ticked rings above `8`.
- Include center checkmark only when completed today.
- Respect Reduce Motion for animations.
- Add accessibility labels or hide redundant child accessibility where the parent card already speaks equivalent state.
- Add SwiftUI previews or preview fixtures where useful, without depending on live persistence.

Validation:

- Build the iOS app.
- Run relevant app unit tests if any component logic is testable.
- Run `RoutineCore` tests.
- Run formatting and lint checks.

Manual checks:

- Components render legibly in dark mode.
- Components remain readable in light mode.
- Large Dynamic Type does not make routine card text overlap controls.
- Progress state is understandable without color alone.

Completion update:

- Mark this milestone `DONE`.
- Mark M09 `CURRENT`.

Completion note:

- Validation scripts completed successfully. Manual SwiftUI preview inspection in dark mode, light mode, large Dynamic Type, and Reduce Motion was not performed from this CLI session because Xcode preview rendering is not available here.

### M09 - Today Dashboard Flow

Status: `DONE`

Goal: make the primary app surface usable for daily tracking.

Dependencies: M04, M05, M07, M08.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Today Dashboard and Routine Item Interaction; [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Today Dashboard, Completion Interaction, Secondary Actions; [DATA_DESIGN.md](DATA_DESIGN.md) TodayDashboardView and Routing.

Deliverables:

- Implement `RootView` with `NavigationStack` and value-based `AppRoute`.
- Implement `TodayDashboardView` as the default launch screen.
- Query groups, routines, and completions and render `TodayDashboardViewData`.
- Show grouped routine cards in user-defined order.
- Show a practical empty state when there are no routines.
- Add the dashboard toolbar title `Today` and trailing `Manage` action.
- Add date context near the top of dashboard content.
- Tap an incomplete card to complete today's routine through `RoutineTrackingService`.
- Tap a completed card to open secondary actions instead of duplicating completion.
- Make the trailing ellipsis open secondary actions without completing.
- Include secondary actions: `View History`, `Edit Routine`, `Undo Today's Completion` when applicable, and `Cancel`.
- Do not include delete in the dashboard action sheet.
- Show a transient undo banner after successful completion.
- Undo updates the card state immediately through the service/store.
- Add temporary safe placeholder destinations for Manage and History only if those screens are not implemented yet.

Validation:

- Build the iOS app.
- Run dashboard/projection/service tests.
- Run `RoutineCore` tests.
- Run formatting and lint checks.
- If a simulator or device is available, launch the app and manually complete/undo a seeded routine.

Required tests:

- Dashboard projection and service tests from prior milestones remain green.
- If UI testing infrastructure is ready, add a smoke UI test for launch and seeded dashboard visibility.

Manual checks:

- Starter data appears grouped on first launch.
- One tap completes an incomplete routine.
- Repeated tap on a completed routine does not create another completion.
- Undo restores the incomplete-today state.
- Monthly routines remain visible.
- Completed routines remain visible and readable.

Completion update:

- Mark this milestone `DONE`.
- Mark M10 `CURRENT`.

Completion note:

- `./Scripts/test-ios.sh` and `./Scripts/validate.sh` reached the iOS UI-test phase but could not complete because `xcodebuild` repeatedly failed to launch the simulator app with `FBSOpenApplicationServiceErrorDomain` / `Application failed preflight checks` on available iPhone simulator destinations. A direct `simctl` launch of the built app succeeded, and a screenshot-based manual check confirmed the seeded grouped dashboard render, but interactive manual completion/undo verification was not possible from this CLI session.

### M10 - Routine Management UI

Status: `DONE`

Goal: let the user create and maintain routines without leaving the app.

Dependencies: M06, M07, M09.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Manage Routines View; [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Manage Routines and Add/Edit Routine; [DATA_DESIGN.md](DATA_DESIGN.md) ManageRoutinesView and AddEditRoutineView.

Deliverables:

- Replace any temporary Manage placeholder with `ManageRoutinesView`.
- Push Manage from the dashboard toolbar.
- Render routines in native grouped sections using manage projections.
- Implement `AddEditRoutineView` as a native sheet.
- Implement draft-state editing so cancel never mutates persisted data.
- Support adding a routine with name, target count, weekly/monthly period, and group assignment.
- Support editing name, target count, period, and group assignment.
- Support deleting a routine after confirmation.
- Show inline validation for invalid drafts where practical.
- Map service errors to concise user-safe messages.
- Return to dashboard with updated data visible after saves.
- If group-management UI is not done yet, use existing groups from starter data and clearly avoid dead-end controls.

Validation:

- Build the iOS app.
- Run management service and manage projection tests.
- Run `RoutineCore` tests.
- Run formatting and lint checks.
- If a simulator or device is available, manually add, edit, and delete one routine.

Required tests:

- Add/edit form draft validation blocks invalid saves.
- Cancel leaves persisted routine unchanged.
- Add routine appears on dashboard.
- Edit routine updates dashboard and manage rows.
- Delete routine removes it from dashboard after confirmation.

Completion update:

- Mark this milestone `DONE`.
- Mark M11 `CURRENT`.

Completion note:

- Passed `./Scripts/test-core.sh`, targeted iOS management/form/projection tests, `./Scripts/check-format.sh`, `./Scripts/lint.sh`, and `./Scripts/build-ios.sh`. A follow-up `./Scripts/test-ios.sh` run reached only the UI-test phase and failed because the simulator repeatedly returned `FBSOpenApplicationServiceErrorDomain` / `Application failed preflight checks` while launching the app, so full UI-test coverage and manual add/edit/delete simulator verification were skipped.

### M11 - Group And Reorder UI

Status: `CURRENT`

Goal: complete routine organization controls with native group and ordering behavior.

Dependencies: M06, M10.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Manage Routines View; [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Manage Routines; [DATA_DESIGN.md](DATA_DESIGN.md) RoutineManagementService and Group Editing Views.

Deliverables:

- Add group creation and rename sheets.
- Support deleting empty groups after confirmation.
- Block non-empty group deletion with a user-safe message.
- Support group reorder through native edit mode or an equally native-feeling management affordance.
- Support routine reorder within groups.
- Support moving routines across groups through edit form group assignment, and through direct move/reorder controls if native list behavior supports it cleanly.
- Normalize sort order after all reorder and move operations.
- Keep dashboard and manage screens in sync after reordering.
- Avoid custom drag systems unless native controls cannot satisfy the MVP behavior.

Validation:

- Build the iOS app.
- Run management service tests.
- Run manage projection tests.
- Run `RoutineCore` tests.
- Run formatting and lint checks.
- If a simulator or device is available, manually add/rename/delete an empty group and reorder routines/groups.

Required tests:

- Group add and rename update manage and dashboard sections.
- Empty group deletion succeeds.
- Non-empty group deletion is blocked without orphaning routines.
- Routine reorder persists and dashboard reflects the new order.
- Group reorder persists and dashboard reflects the new order.
- Moving a routine to another group updates group assignment and contiguous ordering.

Completion update:

- Mark this milestone `DONE`.
- Mark M12 `CURRENT`.

### M12 - Routine History UI

Status: `NOT STARTED`

Goal: let the user answer "when did I last do this?" and correct mistaken completions.

Dependencies: M05, M07, M09.

Primary references: [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) Routine History / Calendar View; [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Routine History and Correct mistaken completion flow; [DATA_DESIGN.md](DATA_DESIGN.md) RoutineHistoryView.

Deliverables:

- Replace any temporary History placeholder with `RoutineHistoryView`.
- Navigate to history from dashboard secondary actions by stable routine ID.
- Show a safe not-found state if the routed routine no longer exists.
- Add summary header with routine name, frequency summary, current period progress, and last completed phrase.
- Add current-month calendar-like grid with completed dates and today state.
- Add descending recent completions list.
- Support removing a completion after destructive confirmation.
- Refresh history immediately after removal.
- Ensure dashboard progress reflects history changes when returning.
- Keep the calendar visual calm, not heatmap-like or gamified.

Validation:

- Build the iOS app.
- Run history projection and tracking service tests.
- Run `RoutineCore` tests.
- Run formatting and lint checks.
- If a simulator or device is available, manually open history and remove a completion.

Required tests:

- History opens for the selected routine.
- Missing routine route shows not-found behavior instead of crashing.
- Summary labels match never, today, yesterday, recent, current-year, and prior-year dates.
- Month grid marks today, completed days, and completed today.
- Recent completions sort correctly.
- Removing a completion requires confirmation and updates projection state.

Completion update:

- Mark this milestone `DONE`.
- Mark M13 `CURRENT`.

### M13 - Accessibility, Polish, And UI Coverage

Status: `NOT STARTED`

Goal: make the implemented MVP flows reliable, native-feeling, and accessible enough for daily use.

Dependencies: M09, M10, M11, M12.

Primary references: [VISUAL_DESIGN.md](VISUAL_DESIGN.md) Accessibility and Platform Expectations; [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Accessibility, Visual Implementation Details, Testing Strategy.

Deliverables:

- Audit and improve VoiceOver labels for dashboard cards, progress rings, secondary action buttons, history cells, forms, and destructive confirmations.
- Ensure completed state never relies on color alone.
- Verify minimum `44x44pt` interaction targets for primary controls.
- Improve Dynamic Type behavior so text does not overlap or truncate critical state.
- Respect Reduce Motion in completion, undo, and navigation-adjacent custom animations.
- Add light haptics on successful completion and undo.
- Tune dark-mode-first colors while keeping light mode readable.
- Add or complete DEBUG launch arguments for deterministic UI test state, fixed current date, seeded in-memory store, empty in-memory store, reset mode, disabled animations, and seed-version testing.
- Add XCUITest coverage for the highest-value flows where local environment supports it.
- Document manual checks that remain brittle or environment-dependent.

Validation:

- Build the iOS app.
- Run unit, integration, and `RoutineCore` tests.
- Run UI tests if a simulator runtime or connected test device is available.
- Run formatting and lint checks.
- Manually inspect dark mode, light mode, large Dynamic Type, VoiceOver, and Reduce Motion on a simulator or device if available.

Required UI test scenarios where available:

- Launch shows Today Dashboard.
- Empty launch state shows empty state.
- Seeded dashboard shows grouped routines.
- Completion updates visible state and shows undo.
- Undo restores state.
- Completed routine tap opens actions rather than duplicating completion.
- View History opens the correct routine.
- Manage opens from toolbar.
- Add, edit, and delete routine flows work.
- Historical removal requires confirmation.

Completion update:

- Mark this milestone `DONE`.
- Mark M14 `CURRENT`.

### M14 - Dogfooding Readiness

Status: `NOT STARTED`

Goal: make the MVP ready to install and rely on locally for personal dogfooding.

Dependencies: all previous milestones.

Primary references: [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md) Deployment, GitHub Actions Strategy, Debugging And Observability, Security And Privacy, Acceptance Criteria.

Deliverables:

- Review all local scripts and make sure they are documented, executable, concise, and fail fast.
- Ensure Ubuntu GitHub Actions run the portable checks that make sense for the final project.
- Add or finalize OSLog diagnostics categories for app lifecycle, persistence, starter data, tracking, management, projection, routing, and UI.
- Ensure debug launch arguments are DEBUG-only and unavailable in Release behavior.
- Confirm `PrivacyInfo.xcprivacy` declares local-only behavior with no tracking and no data collection if the implementation still has no networking or SDKs.
- Add a real `RoutineApp/Assets.xcassets/AppIcon.appiconset` for the MVP launcher icon.
- Restore `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in `project.yml`.
- Make the launcher icon align with the visual direction: dark, grounded, warm, tactile, calm, and not gamified.
- Update README with local setup, project generation, validation, and local device deployment instructions.
- Add a manual dogfooding acceptance checklist, either in README or a small docs file.
- Verify generated project files and local Xcode user data are ignored or intentionally committed according to the project policy.
- Review for accidental secrets, signing credentials, provisioning profiles, device logs, screenshots, or personal data.
- Do not add TestFlight, cloud sync, analytics, notifications, widgets, or app-store workflow unless the product specs are explicitly changed first.

Validation:

- Run full local validation script.
- Run `RoutineCore` tests.
- Run iOS unit tests when a destination is available.
- Run UI tests when a simulator runtime or connected test device is available.
- Build the app for a generic iOS destination and verify asset catalog compilation with `--app-icon AppIcon`.
- Install and run on the personal iPhone if available.
- Confirm the intended launcher icon appears on the Home Screen and in the App Library.
- Manually verify starter data, persistence across relaunch, completion, undo, history correction, management, dark/light mode, Dynamic Type, VoiceOver, Reduce Motion, and one-handed use.

Completion update:

- Mark this milestone `DONE`.
- Replace the `Current Milestone` line with `MVP implementation roadmap complete`.
- Do not add a new milestone unless a new product or engineering scope decision has been made.

## MVP Completion Criteria

The roadmap is complete when the app demonstrates the MVP acceptance criteria from [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md):

- The project can be generated from XcodeGen.
- The app builds locally in Xcode.
- The app installs and runs on the personal iPhone.
- The app launches to Today Dashboard.
- Starter data seeds once and remains editable.
- All routines remain visible, including completed and monthly routines.
- One tap completes an incomplete routine for today.
- Duplicate same-day completions cannot be created.
- Undo removes today's completion.
- History shows last-done context, current-month marks, and recent completions.
- Historical completions can be removed after confirmation.
- Manage Routines supports add, edit, delete, and reorder.
- Groups support add, rename, reorder, and empty-group deletion.
- Current week progress uses Monday-start weeks.
- Current month progress uses calendar months.
- Data survives app relaunch.
- Formatting and lint commands are documented and runnable locally.
- Portable domain tests run in Ubuntu GitHub Actions.
- SwiftData service tests run locally.
- UI tests or documented manual checks cover the primary flows.
- OSLog diagnostics are available locally without analytics.
- The app respects Dynamic Type, VoiceOver, contrast, reduced motion, and non-color status indicators.
- No secrets, signing credentials, analytics SDKs, or network dependencies are introduced.
