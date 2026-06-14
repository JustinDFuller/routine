# System Design: Routine

## Purpose

This document defines the implementation system design for Routine, a personal iPhone app for tracking flexible weekly and monthly routines in a visual, low-friction way.

It is the engineering counterpart to:

- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md), the source of truth for product scope and behavior.
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md), the source of truth for visual and interaction design.
- [DATA_DESIGN.md](DATA_DESIGN.md), the source of truth for data structures, storage, domain methods, views, and routing.

The goal of this document is to make implementation straightforward for a senior iOS engineer or an agent such as Codex. It should prevent re-research, reduce implementation drift, and make quality expectations explicit.

This is an MVP, but it should be built as a high-quality personal production app: simple in scope, robust in behavior, idiomatic in platform use, and easy to debug on the developer's Mac and personal iPhone.

## Scope And Constraints

Routine is a local-first, single-user iPhone app.

In scope for the MVP:

- A SwiftUI iPhone app with a dashboard-first flow.
- Local SwiftData persistence.
- User-editable routine groups, routines, ordering, and completion history.
- Weekly and monthly target progress.
- One-tap completion, immediate undo, and history correction.
- Local development, local device deployment, local full validation, and Linux-friendly GitHub Actions checks.

Out of scope for the MVP:

- Cloud sync, accounts, sharing, or collaboration.
- Notifications, widgets, watch app, or lock screen surfaces.
- Analytics, telemetry, remote logging, or crash-reporting SDKs.
- Smart scheduling, recommendations, streaks, scoring, or gamification.
- Public App Store launch workflow as a required path.

Operational constraints:

- The repository is private on GitHub.
- The app only needs to work on the developer's personal iPhone and development Mac for now.
- The app is personally funded, so recurring services and paid infrastructure should be avoided.
- Implementation will primarily be performed by Codex, so project structure and scripts must be explicit, repeatable, and friendly to small autonomous edits.

## Platform Baseline

Use the platform choices already established in [DATA_DESIGN.md](DATA_DESIGN.md):

- iOS 17 or newer.
- SwiftUI for UI.
- SwiftData for local persistence.
- Swift concurrency and Observation where they fit the platform model.
- `NavigationStack` with value-based routes.
- Native sheets, forms, lists, sections, toolbar items, swipe actions, and edit mode where appropriate.
- SF Symbols for icons.
- Semantic system colors and asset-catalog color roles.

Current local development environment observed during planning:

- Xcode 26.5.
- Apple Swift 6.3.2.
- iOS 26.5 SDK and iOS Simulator 26.5 SDK installed.
- No simulator runtimes currently listed by `simctl`.
- `xcodegen`, `swift-format`, and SwiftLint are installed locally.

The implementation should not require this exact Xcode version forever, but the initial project should be validated against this machine. If a later agent upgrades the toolchain, it must update this document or a dedicated development setup document with the new known-good versions.

## Architecture Overview

Routine should use a small layered architecture that is explicit enough to preserve domain rules without overengineering the MVP.

Layers:

1. App shell
   The iOS application entry point, SwiftData `ModelContainer`, root navigation, app-wide environment values, launch arguments, and debug configuration.

2. SwiftUI views
   Native UI surfaces for the Today Dashboard, Routine History, Add/Edit Routine, group editing, reusable cards, progress rings, banners, and empty states.

3. View state and projections
   Lightweight immutable view data plus small observable form or screen state objects. These convert persisted models and domain values into UI-ready strings, flags, accessibility labels, and drawing inputs.

4. Domain services
   Object-oriented services that enforce user-intent operations such as completing a routine, undoing today, removing a completion, creating routines, editing routines, deleting routines, moving routines, managing groups, seeding starter data, and producing user-safe error outcomes.

5. Domain values
   Small value types and enums for routine period, routine day, progress, calendar calculations, validation results, routes, and view data. Pure domain logic belongs here when it can be independent of SwiftUI and SwiftData.

6. Persistence models
   SwiftData `@Model` classes that store canonical data only: routine groups, routines, routine completions, and app metadata.

7. Diagnostics and test support
   OSLog categories, debug launch arguments, in-memory store setup, deterministic dates, seeded fixtures, UI test reset hooks, and local validation scripts.

Core rule:

Views may initiate user actions, but they must not own persistence rules. Duplicate prevention, date-window logic, validation, ordering, deletion semantics, and save behavior belong in domain services or domain values.

This keeps the app object-oriented around real user operations while allowing the date and progress logic to remain value-oriented and easy to test.

## Project Structure

Use XcodeGen as the source of truth for the Xcode project. Commit `project.yml`; do not rely on hand-editing a checked-in `.xcodeproj` as the canonical project definition.

Recommended repository layout:

- `RoutineApp/`
  iOS app target sources, including app entry point, SwiftUI screens, SwiftData models, assets, privacy manifest, debug helpers, and app-specific services.

- `RoutineCore/`
  A Swift package containing portable domain logic that can build and test on macOS and Linux. It should avoid SwiftUI, SwiftData, UIKit, OSLog, and iOS-only APIs unless guarded in a separate target.

- `RoutineAppTests/`
  iOS unit and integration tests for SwiftData-backed services, app projections, persistence behavior, and app-specific adapters.

- `RoutineAppUITests/`
  XCUITest flows for the running iOS app.

- `Scripts/`
  Local validation scripts for project generation, formatting, linting, package tests, Xcode builds, and Xcode tests.

- `.github/workflows/`
  Ubuntu-compatible GitHub Actions workflows for portable checks.

- `Docs/`
  Optional future implementation notes if a topic becomes too detailed for the main planning documents.

- Root config files
  `project.yml`, `Package.swift` for `RoutineCore` if the package lives at the repository root or a nested package manifest if `RoutineCore` is standalone, `.swift-format`, `.swiftlint.yml`, `.gitignore`, and any makefile or task runner used by scripts.

Keep source files grouped by feature and layer rather than by file type alone. For example, dashboard views and dashboard projections should live close enough that agents can find the whole feature without scanning the entire app.

## Targets And Modules

Use this target shape for the MVP:

- `RoutineApp`
  The iOS application target. Owns SwiftUI screens, SwiftData models, the app entry point, app assets, app-specific services, and local device deployment configuration.

- `RoutineCore`
  A Swift package or framework target for portable logic. Owns routine period values, routine day values, calendar calculations, progress calculations, validation policies, sorting helpers, formatting policy where Foundation supports it cross-platform, and pure test fixtures.

- `RoutineAppTests`
  XCTest target for iOS-only unit and integration tests. Owns in-memory SwiftData tests, app projection tests that depend on SwiftData models, and service tests that require `ModelContext`.

- `RoutineCoreTests`
  Swift package tests that can run on Ubuntu GitHub Actions and locally. Owns pure domain tests.

- `RoutineAppUITests`
  XCUITest target for end-to-end flows. These tests run locally against a simulator if a simulator runtime is installed, or against a connected test device when practical.

Do not split the MVP into many framework targets. The only intentional split is `RoutineCore` because it enables fast pure tests and meaningful Linux CI without paid macOS runners.

## Dependency Policy

Runtime dependencies should be Apple-native only for MVP:

- SwiftUI.
- SwiftData.
- Foundation.
- Observation.
- OSLog.
- UIKit only where SwiftUI does not expose a needed platform capability, such as haptics.
- XCTest and XCUITest for tests.
- SF Symbols and asset catalogs for visual assets.

Do not add third-party runtime libraries for UI, persistence, routing, date handling, analytics, networking, dependency injection, or logging in the MVP.

Development tools:

- XcodeGen for project generation.
- `swift-format` for formatting and formatting checks.
- SwiftLint for local linting focused on correctness and maintainability.
- GitHub Actions on Ubuntu for portable checks.

Library and tool documentation:

- Apple SwiftData: https://developer.apple.com/documentation/swiftdata
- Apple SwiftUI: https://developer.apple.com/documentation/swiftui
- Apple NavigationStack: https://developer.apple.com/documentation/swiftui/navigationstack
- Apple OSLog logging: https://developer.apple.com/documentation/os/logging
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/
- Apple Accessibility guidance: https://developer.apple.com/design/human-interface-guidelines/accessibility
- Apple Privacy Manifest files: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files
- XcodeGen: https://github.com/yonaskolb/XcodeGen
- swift-format: https://github.com/swiftlang/swift-format
- SwiftLint: https://github.com/realm/SwiftLint
- GitHub Actions: https://docs.github.com/actions

## Domain Model And Persistence

Use the model design in [DATA_DESIGN.md](DATA_DESIGN.md) as the canonical data contract.

Persisted entities:

- `RoutineGroup`
  A first-class display section with a stable ID, name, sort order, timestamps, and relationship to routines.

- `Routine`
  A user-defined activity with stable ID, name, target count, period raw value, group ID, sort order, timestamps, group relationship, and completions relationship.

- `RoutineCompletion`
  A completion record for one routine on one local calendar day, with a stable ID, routine ID, day key, unique routine-day key, timestamp, and routine relationship.

- `AppMetadata`
  Lightweight app facts such as starter data seed version.

Persistence rules:

- Store canonical data only.
- Do not persist dashboard progress, last-done labels, target-met state, remaining counts, or accessibility text.
- Use SwiftData's default local app-container storage for MVP.
- Use one shared `ModelContainer` for the app.
- Keep persistence access on the main actor for the MVP.
- Save explicitly after every user mutation.
- Use in-memory containers for service tests and UI test launch modes.

Domain invariants:

- Routine names and group names are trimmed before validation.
- Routine names can repeat.
- Group names should be unique after trimming with case-insensitive comparison.
- Weekly target counts are `1...7`.
- Monthly target counts are `1...31`.
- Every routine belongs to exactly one group in normal app state.
- A completion's day key is the source of truth for date identity.
- A routine can have at most one completion per local calendar day.
- A routine-day unique key enforces duplicate prevention at the data layer.
- Groups can be deleted only when empty.
- Deleting a routine deletes its completion history after confirmation.
- Reorder operations normalize affected sort orders to contiguous values.

If an implementation detail in SwiftData makes the exact model shape from [DATA_DESIGN.md](DATA_DESIGN.md) awkward, preserve the behavior and invariants first, then document the implementation adjustment near the model declaration.

## Calendar And Date Policy

Date handling is central to product correctness. Implement all date calculations through a single domain calendar abstraction.

Rules:

- Use a Gregorian calendar.
- Use the user's current locale and timezone for deriving today.
- Default week start to Sunday; honor `calendar.firstWeekday` so the user can configure any start day.
- Represent local dates as `RoutineDay` values, not raw `Date` values.
- Persist completion day identity as a stable `YYYY-MM-DD` day key.
- Use day keys, not timestamps, for daily uniqueness and progress membership.
- Use completion timestamps only for audit context and stable secondary sorting.
- Do not rewrite historical day keys if the user later changes timezone.
- Calculate the week containing a day using `calendar.firstWeekday` directly rather than depending on locale-specific week-of-year behavior.
- Monthly progress is the first through last local day of the month.

Testing date behavior is mandatory. Include fixed-date tests for:

- Configured week-start day and week-boundary calculations for both Sunday-start and Monday-start configurations.
- Month starts and ends.
- Leap years.
- Daylight saving time transitions where Foundation behavior can affect local dates.
- Relative labels for today, yesterday, recent dates, current-year older dates, prior-year dates, and never-completed state.

## Domain Services

Implement small object-oriented services around user intent.

Required services:

- `RoutineTrackingService`
  Completes a routine for today, undoes today's completion, removes a specific historical completion, prevents duplicates, and saves explicitly.

- `RoutineManagementService`
  Creates, updates, deletes, moves, and reorders routines; creates, renames, deletes, and reorders groups; validates drafts; normalizes sort orders.

- `StarterDataService`
  Seeds starter groups and routines once, using `AppMetadata` to prevent reseeding after user edits or deletion.

- `DashboardProjectionBuilder`
  Converts groups, routines, completions, progress, and date labels into immutable dashboard view data.

- `HistoryProjectionBuilder`
  Converts one routine and its completions into summary, month grid, and recent-completion view data.

- `ManageProjectionBuilder`
  Converts groups and routines into dashboard-owned management view data without dashboard progress concerns.

- `AppDiagnostics`
  Owns loggers, signpost helpers, and DEBUG-only diagnostic behavior.

Service design rules:

- Services are `@MainActor` when they touch SwiftData.
- Services accept stable IDs for mutations rather than relying on SwiftData model instances stored in view state.
- Services throw typed or mappable domain errors.
- Views map errors to concise user-safe messages.
- Duplicate completion attempts are idempotent no-ops, not scary user-facing errors.
- The service layer is the only place that should decide whether a save is needed after a mutation.

## SwiftUI Implementation

Use SwiftUI as the primary UI framework and lean on native components unless the visual specification explicitly calls for custom rendering.

Primary screens:

- `RootView`
  Owns `NavigationStack`, route destinations, starter data seeding trigger, and app-level service construction.

- `TodayDashboardView`
  Default launch screen. Shows all grouped routines, handles one-tap completion, keeps unavailable routines visible with muted disabled completion state, opens history directly from routine cards, shows undo banner, owns routine/group management sheets and rearrange modes, and navigates to history.

- `RoutineHistoryView`
  Routine-specific history screen with summary header, current-month calendar-like grid, recent completions, and destructive correction flow.

- `AddEditRoutineView`
  Native form sheet with draft state for routine name, target count, period, group assignment, and optional local-time availability window.

- Group add/edit sheets
  Small native forms for creating, renaming, and deleting groups.

Reusable UI components:

- `RoutineCardView`.
- `ProgressRingView`.
- `UndoBannerView`.
- `HistoryMonthGridView`.
- `CompletionListRow`.
- Form rows and validation message components where native forms need consistent behavior.

UI state rules:

- Keep persisted model objects out of navigation paths.
- Keep form edits in draft state until save.
- Keep transient undo banner state local to the dashboard.
- Let SwiftData observation refresh screens after saves, but keep projections explicit and testable.

Visual rules:

- Dark mode is the primary design target.
- Use asset-catalog color roles for `Canvas`, `Surface`, `Surface Elevated`, label roles, completion accent, active accent, destructive accent, and dividers.
- Use semantic colors and high-contrast variants where possible.
- Do not communicate completion by color alone.
- Progress ring drawing must include shape/fill/checkmark/text semantics.
- Completion animation should be short and disabled or simplified when reduced motion is enabled.
- Haptics should be light and only fire after successful completion or undo.

## Routing And Navigation

Use `NavigationStack` with value-based routes.

Routes:

- Today Dashboard is the root and default launch screen.
- Routine History is pushed from a routine's direct history path.
- Add/Edit Routine is presented as a sheet from Today Dashboard.
- Group add/edit is presented as a sheet from Today Dashboard.
- The dashboard top bar uses a trailing `gearshape` menu for `Add Routine`, `Add Group`, `Edit`/`Done Editing`, `Rearrange Groups`, and `Rearrange Routines`.
- Rearrange modes stay on Today Dashboard and exit with a top-bar `Done` action.

Navigation rules:

- Do not use a tab bar for MVP.
- Do not store SwiftData models in navigation path values.
- Route to routine history by stable routine ID.
- If a routed routine no longer exists, show a small not-found state with a clear way back or pop the route.
- Routine editing stays in dashboard Edit mode.
- Same-day undo stays in the transient dashboard banner and through history correction.

The navigation hierarchy must stay shallow. The dashboard is the product; management and history are supporting surfaces.

## Build And Local Development

Use XcodeGen to generate the Xcode project from `project.yml`.

Required local scripts or make tasks:

- Generate the Xcode project.
- Format Swift sources in place.
- Check Swift formatting without modifying files.
- Run SwiftLint locally.
- Run `RoutineCore` package tests.
- Build the iOS app for a connected device or generic iOS destination.
- Run iOS unit tests when an appropriate destination is available.
- Run UI tests when a simulator runtime or suitable device is available.
- Run a full local validation command that chains the applicable checks.

Command policy:

- Scripts should fail fast.
- Scripts should print concise, actionable errors.
- Scripts should not require global state beyond Xcode command line tools and documented Homebrew tools.
- Scripts should not mutate source files except for the explicit format command.
- Generated artifacts should either be ignored or intentionally committed; avoid ambiguous generated state.

Xcode project policy:

- `project.yml` is canonical.
- Generated `.xcodeproj` may be ignored to avoid merge noise unless a later decision explicitly commits it for convenience.
- Schemes should be shared and generated.
- Build settings should be centralized in XcodeGen setting groups where possible.
- Debug and Release configurations should be explicit.
- Swift language mode and deployment target should be explicit.
- Bundle identifier and signing team should be configurable without committing secrets.

Launcher icon staging:

- App launcher icon work is intentionally deferred until M14 so earlier build-unblock milestones can proceed without final icon assets.
- Until M14, local builds may omit or explicitly clear `ASSETCATALOG_COMPILER_APPICON_NAME` in `project.yml` if that is required to keep the app buildable without a real app icon asset catalog.
- M14 must restore `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` and validate that the intended icon appears after install on the personal iPhone.

Recommended initial build settings:

- iOS deployment target: iOS 17.0 or newer.
- Swift language mode: current toolchain Swift mode used by the project, with warnings reviewed during implementation.
- Enable strict concurrency checks at a level that is practical for SwiftUI and SwiftData. Escalate only when the app compiles cleanly without excessive annotation churn.
- Debug uses development signing and local diagnostics.
- Release strips debug-only launch arguments and diagnostic reset hooks.

## Deployment

Optimize first for local device dogfooding.

Local iPhone deployment flow:

- Generate the Xcode project.
- Open the project in Xcode.
- Select the `RoutineApp` scheme.
- Select the personal iPhone as the run destination.
- Use automatic signing with the developer's Apple ID or team.
- Build and run from Xcode.
- Confirm the app launches into Today Dashboard and starter data seeds only once.

Versioning:

- Use a human-readable marketing version such as `0.1.0` for the first dogfooding build.
- Use an incrementing build number for local archives.
- Update version/build numbers through XcodeGen settings or a documented config file, not by hand-editing generated project internals.

App identity:

- Display name: `Routine`.
- Bundle identifier should use a private reverse-DNS value controlled by the developer.
- Signing team should not be hardcoded in a way that breaks another clone unless the repo is intentionally personal-only.

TestFlight:

- Not required for MVP implementation.
- Add only when local device dogfooding is insufficient.
- If added later, document Apple Developer Program membership, App Store Connect app record, archive validation, TestFlight internal testing, privacy answers, and export compliance decisions.

## GitHub Actions Strategy

Use GitHub Actions without macOS jobs for MVP.

Ubuntu Actions should run:

- `RoutineCore` build.
- `RoutineCore` tests.
- Swift formatting check where the formatter is installable in the workflow.
- Markdown or documentation checks only if they are cheap and useful.

Ubuntu Actions should not attempt:

- Xcode project generation requiring Xcode-specific behavior.
- iOS app compilation.
- SwiftData integration tests.
- XCUITests.
- Code signing.
- TestFlight upload.

This split gives useful automated feedback without paid macOS runners or Apple signing complexity. Full iOS confidence remains a local responsibility.

## Formatting And Linting

Use `swift-format` as the formatter of record.

Formatting policy:

- Commit a `.swift-format` configuration.
- Use one command for in-place formatting.
- Use one command for lint-style formatting checks.
- Prefer the formatter over manual style debates.
- Do not use SwiftLint rules to duplicate formatting concerns already handled by `swift-format`.

Use SwiftLint for targeted maintainability rules.

SwiftLint policy:

- Commit `.swiftlint.yml`.
- Keep the rule set conservative during MVP implementation.
- Avoid high-churn style rules that fight SwiftUI's natural shape.
- Enable rules that catch likely defects or readability problems, such as force unwraps, force tries, empty collections, duplicate imports, unused closures, and accidental complexity.
- Keep line-length rules pragmatic for SwiftUI and tests.
- Do not require warnings-as-errors until the initial implementation is stable.
- SwiftLint should run locally with the same Xcode toolchain used to compile the app.

Agent rule:

- Any agent modifying Swift files should run formatting before final validation, then run formatting checks, lint, relevant tests, and build checks where available.

## Testing Strategy

Testing should scale with risk. Date logic, persistence invariants, duplicate prevention, and destructive corrections are high-risk and must have automated coverage.

### RoutineCore Tests

Run locally and in Ubuntu GitHub Actions.

Required coverage:

- `RoutineDay` construction, key formatting, ordering, equality, and invalid-input handling if parsing exists.
- `RoutineTimeOfDay` minute validation and invalid-input handling.
- `RoutineAvailabilityWindow` validation, same-day containment, cross-midnight containment, and inclusive/exclusive boundaries.
- Current-week ranges for each weekday for both Sunday-start (default) and Monday-start configurations.
- Week boundaries across month and year changes.
- Current-month ranges, including February and leap years.
- Progress counting for weekly and monthly periods.
- Target met and over-target behavior.
- Completed-today detection.
- Last-completed-day derivation.
- Relative and explicit date labels.
- Local minute-of-day extraction using the configured calendar timezone, including a non-UTC timezone and a DST-adjacent date.
- Target count validation for weekly and monthly routines.
- Name trimming and empty-name validation.
- Group-name uniqueness comparison.
- Reorder normalization helper behavior if implemented in portable logic.

### iOS Unit And Integration Tests

Run locally with Xcode when a valid destination is available.

Use in-memory SwiftData containers for service tests.

Required coverage:

- Starter data seeds once and never reseeds after metadata exists.
- Starter groups and routines are editable normal data.
- Completing an incomplete routine inserts exactly one completion.
- Repeating completion for the same routine/day is idempotent.
- Completion outside a configured availability window is blocked with a user-safe error.
- Duplicate completion remains idempotent even when the current time is outside the configured window.
- Cross-midnight availability completion stores the current local calendar day.
- Undo today removes only today's completion.
- Undo today with no completion is safe.
- Historical completion removal deletes the selected completion and updates projections.
- Deleting a routine cascades its completions.
- Deleting an empty group succeeds.
- Deleting a non-empty group is blocked by the service.
- Creating and editing routines enforce target ranges and group membership.
- Creating and editing routines persist all-day versus configured availability correctly and reject invalid equal start/end windows.
- Moving routines within and across groups updates group IDs and contiguous sort order.
- Reordering groups normalizes sort order.
- Dashboard projection includes all routines, including completed and monthly routines.
- Dashboard projection marks unavailable configured routines, preserves card order, and excludes unavailable incomplete routines from remaining counts.
- History projection marks today, completed dates, completed today, and recent completions correctly.
- Stale routine routes resolve to not-found behavior rather than crashes.
- Persistence save failures are mapped to user-safe errors where failures can be simulated.

### UI Tests

Run locally after a simulator runtime is installed or on a suitable connected device.

Use DEBUG-only launch arguments to create deterministic UI test state.

Required coverage:

- Launch shows Today Dashboard.
- Empty state appears when launched with empty test data.
- Seeded dashboard shows grouped routines in expected order.
- Tapping an incomplete card completes it, updates visible count/state, and shows undo.
- Tapping undo restores incomplete state.
- Tapping a completed routine opens history instead of duplicating completion.
- The direct history affordance opens the correct routine history screen.
- History shows last-done summary, month grid, and recent completions.
- Removing a historical completion requires confirmation.
- The dashboard gear menu is the only top-level management entry.
- Add routine sheet saves a valid routine and returns to Today.
- Edit routine sheet updates a routine and returns to Today.
- Delete routine requires confirmation and removes it from dashboard.
- Add group and edit group flows start from Today and return to Today.
- No Manage Routines screen is reachable from app navigation.
- Reorder mode is accessible enough for manual validation even if fully automated drag tests are brittle.

### Manual Device Acceptance

Run before relying on the app for real dogfooding.

Checklist:

- App installs and launches on the personal iPhone.
- Starter data seeds once.
- App relaunch preserves edits and completions.
- Completion feels instant.
- Undo is reachable and does not block scrolling.
- Haptics are light and not distracting.
- Dark mode matches the visual language.
- Light mode remains readable.
- Dynamic Type does not truncate critical labels or make controls unusable.
- VoiceOver reads routine card state, count, period, and actions clearly.
- Reduced Motion avoids unnecessary animation.
- Deleting and correcting history feel safe.
- One-handed use on the target iPhone is practical.

## Debugging And Observability

Do not add analytics or remote telemetry for MVP. Use local diagnostics only.

Use OSLog with clear categories:

- `app.lifecycle`
- `persistence`
- `starter-data`
- `tracking`
- `management`
- `projection`
- `routing`
- `ui`

Logging rules:

- Log user-intent events at a useful debug level during development.
- Log persistence failures and unexpected invariant failures.
- Do not log sensitive personal routine names at high severity unless needed locally for debugging.
- Prefer IDs, counts, and operation names in routine logs.
- Keep logs concise enough to read in Xcode Console or Console.app.

Use signposts sparingly:

- Dashboard projection build duration.
- History projection build duration.
- Starter data seed duration.
- SwiftData save duration for user mutations.

Debug launch arguments:

- Fixed current date for deterministic projections and UI tests.
- Empty in-memory store.
- Seeded in-memory store.
- UI test reset mode.
- Disable animations for UI tests.
- Force starter-data seed version for testing seed behavior.

Debug surfaces:

- No permanent in-app debug menu is required for MVP.
- If debugging real data becomes painful, add a DEBUG-only diagnostics view hidden behind an explicit launch argument. It may show store location, object counts, current day key, seed version, and app/build version. It must not ship in Release.

Crash handling:

- No third-party crash reporter for MVP.
- Rely on Xcode device logs and local crash reports.
- Avoid `fatalError` for recoverable domain or persistence cases.
- Use assertions for impossible programmer errors in DEBUG only, with safe user behavior in Release.

## Error Handling

Errors should be explicit, local, and user-safe.

Expected domain and persistence errors:

- Routine not found.
- Group not found.
- Completion not found.
- Empty routine name.
- Empty group name.
- Invalid target count.
- Missing group.
- Duplicate group name.
- Non-empty group deletion.
- Persistence save failure.
- Stale navigation route.

User-facing behavior:

- Form validation appears inline before save when possible.
- Save failures show a concise alert such as `Could not save changes. Try again.`
- Not-found routes show a simple missing-routine state or return to the prior screen.
- Duplicate completion attempts do not show an alert.
- Destructive actions always require confirmation.
- If starter data seeding fails, the app should still launch and show an empty state plus a user-safe alert or log. It should not crash.

Implementation rules:

- Typed domain errors should map to stable user messages.
- Low-level errors should be logged locally and wrapped before presentation.
- Service methods should leave data unchanged on validation failure.
- If a multi-object operation fails during save, the view should refresh from SwiftData rather than assuming local optimistic state remains correct.

## Robustness And Resilience

Robustness for this app means the user's routine history stays correct, recoverable, and understandable.

Required resilience behaviors:

- Completion is idempotent for a routine/day.
- Availability windows are evaluated in the user's current local calendar and timezone at the moment of projection or completion.
- Cross-midnight availability windows still store completions on the actual local calendar day of the tap.
- Undo today is safe if the completion has already been removed.
- Historical removal targets a specific completion ID.
- Dashboard state derives from the store after saves, not from untrusted cached counts.
- Progress derives from day keys, not timestamps.
- App launch tolerates missing or deleted routines referenced by stale navigation.
- Starter data never recreates itself after the user deletes or edits it.
- Sort order is normalized after create, move, delete, and reorder operations.
- Group deletion cannot orphan routines through normal UI flows.
- Form cancel never mutates persisted state.
- App relaunch preserves user changes.

Data corruption posture:

- Do not build a complex repair system for MVP.
- Where possible, projection builders should ignore impossible orphaned records rather than crash.
- Services should repair minor order gaps opportunistically during reorder operations.
- If a routine has a missing group due to migration or framework behavior, show it in a safe fallback group only if needed to let the user repair it. The normal service path should prevent this state.

Migration posture:

- No custom migration plan is required for v1.
- Persist enum raw values as stable strings.
- Keep IDs stable.
- Do not persist derived state that would require backfills.
- Add new optional routine availability minute fields through SwiftData lightweight migration first.
- Add a custom SwiftData schema migration only if validation shows the optional-field migration is insufficient.

Backup posture:

- No custom export/import for MVP.
- Since the app is personal and local-only, real data loss risk should be acknowledged during dogfooding.
- If the app becomes relied upon daily, add a simple local export feature before adding cloud sync.

## Performance And Responsiveness

The dataset is expected to be small: dozens of routines and hundreds or low thousands of completions. Optimize for clarity first, but keep the UI responsive.

Performance rules:

- Keep SwiftData access on the main actor for MVP.
- Fetch groups, routines, and completions in bulk for dashboard projection.
- Build immutable view data in memory.
- Avoid per-row database fetch loops.
- Avoid storing derived progress caches in v1.
- Keep progress ring drawing simple and deterministic.
- Use one continuous ring for every target count.
- Cap visual fill at target count while text shows actual overage.
- Keep completion animation short.
- Respect Reduce Motion.

Performance checks:

- Dashboard should feel instant after tapping complete or undo.
- Scrolling should remain smooth with the full starter routine list.
- History view should open quickly for a routine with many completions.
- Initial seed should not noticeably delay launch.
- Projection builders should be easy to profile with signposts if needed.

If performance becomes a problem:

- First measure with Instruments and signposts.
- Then reduce projection work or targeted fetch size.
- Only then consider denormalized last-completion caches or background contexts.

Do not prematurely introduce background persistence, caching layers, or complex state stores for the MVP.

## Security And Privacy

Routine stores personal behavior data, but no credentials or account secrets.

Security posture:

- Store canonical data only in SwiftData's local app container.
- Rely on iOS sandboxing and platform file protection.
- Do not store routine data in UserDefaults.
- Do not use Keychain for routine data.
- Do not add custom encryption or biometric gating for MVP.
- Do not add networking unless a future feature explicitly requires it.
- Do not include analytics, advertising, tracking, or remote diagnostics SDKs.

Privacy posture:

- The app should collect no data from the user for third parties.
- The app should make no network requests in MVP.
- Add `PrivacyInfo.xcprivacy` before app packaging.
- Declare no tracking and no data collection if the implementation remains local-only.
- If any future SDK or network feature is added, update privacy declarations before shipping that change.

Repository hygiene:

- Do not commit signing certificates, provisioning profiles, private keys, API keys, or personal Apple ID credentials.
- Do not commit local Xcode user data.
- Do not commit device logs containing personal routine history.
- Keep generated project files ignored unless intentionally committed.
- Review screenshots before sharing because they may contain real routine names and history.

Release build behavior:

- Disable DEBUG-only reset hooks and diagnostic launch shortcuts.
- Do not expose test data controls.
- Keep OSLog usage acceptable for local diagnostics, but avoid verbose personal-data logging.

## Accessibility

Accessibility is a first-class implementation requirement.

Required support:

- Dynamic Type.
- VoiceOver.
- Sufficient contrast in dark and light appearances.
- High-contrast variants where asset colors need them.
- Non-color completion indicators.
- Reduced Motion.
- Minimum 44 by 44 point interactive targets.
- Clear focus order.
- Accessible destructive confirmations.

Dashboard accessibility:

- Each routine card should be a combined accessibility element for the primary action.
- The card label should include routine name, completed-today state, count, period, and last-done cue.
- The card action should communicate that activating it completes the routine when incomplete.
- A completed card should not suggest that activation will complete again; it should open actions.
- The trailing secondary action button should be a separate accessible element with a direct label.

Progress ring accessibility:

- The ring should not be the only way to understand progress.
- It should expose an accessibility label or be hidden when the parent card already includes equivalent information.
- The checkmark and count text must carry completion state in addition to color/fill.

History accessibility:

- Calendar cells should identify date, today state, and completed state.
- Recent completion rows should expose remove actions clearly.
- Destructive removal should require an accessible confirmation.

Forms accessibility:

- Text fields, steppers, segmented controls, and pickers should use native labels.
- Validation messages should be reachable by assistive technology.
- Save should be disabled or blocked with an inline explanation when a draft is invalid.

Manual accessibility checks:

- VoiceOver through dashboard, history, manage, and add/edit form.
- Largest practical Dynamic Type sizes.
- Reduce Motion enabled.
- Dark mode and light mode.
- Increased Contrast if available on the target device.

## Visual Implementation Details

Follow [VISUAL_DESIGN.md](VISUAL_DESIGN.md) for visual language.

Implementation guidance:

- Use a layered dark surface model: canvas, surface, elevated surface.
- Use role-based colors rather than hardcoded per-view colors.
- Keep typography native with San Francisco and Dynamic Type.
- Use `Large Title` for screen title where native navigation supports it.
- Use compact semibold section headers.
- Use body/headline treatment for routine names.
- Use footnote/caption treatment for metadata.
- Keep routine cards comfortable for thumb use.
- Avoid strikethrough for completed routines.
- Avoid motivational language, celebration effects, streaks, badges, or gamified styling.
- Keep monthly routines visible by default.
- Keep completed routines visible and readable.

Progress ring:

- It is a custom SwiftUI drawing component because it is the app's defining visual motif.
- It should be deterministic, cheap to draw, and snapshot-testable where practical.
- It should accept view data, size, color role, and environment motion settings.
- It should not query persistence or calculate progress internally.

Undo banner:

- It should appear near the bottom of the dashboard.
- It should not block scrolling or additional completions.
- It should support replacing the current banner when another routine is completed.
- It should dismiss automatically after a reasonable interval.
- It should remain accessible to VoiceOver and not disappear too quickly for assistive use.

## Agent Implementation Workflow

Because Codex will do most implementation, keep every task reproducible.

Expected workflow for implementation agents:

1. Read `AGENTS.md`, `PRODUCT_BRIEF.md`, `VISUAL_DESIGN.md`, `DATA_DESIGN.md`, and this document.
2. Make one coherent change at a time.
3. Prefer existing project patterns once implementation begins.
4. Run the narrowest relevant tests first.
5. Run formatting before final validation.
6. Run local validation commands that are available in the current environment.
7. Report any skipped checks and why.
8. Do not edit generated project files directly when `project.yml` is the source of truth.
9. Do not add dependencies without updating this document and explaining the tradeoff.
10. Do not change product scope without updating the product, visual, or data spec as appropriate.

When a task touches a core invariant, the agent should add or update tests in the same change.

Core invariants that require tests when touched:

- Daily uniqueness.
- Week/month date windows.
- Starter data seed-once behavior.
- Routine/group validation.
- Sort-order normalization.
- Historical deletion.
- Dashboard and history projection correctness.
- Navigation by stable ID.

## Acceptance Criteria

The system design is satisfied when an implementation can demonstrate:

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
- The Today Dashboard owns routine management through home-based menus, sheets, and rearrange modes.
- Groups support add, rename, reorder, and empty-group deletion from dashboard-owned flows.
- Current week progress uses user-configured calendar weeks (Sunday-start by default).
- Current month progress uses calendar months.
- Data survives app relaunch.
- Formatting and lint commands are documented and runnable locally.
- Portable domain tests run in Ubuntu GitHub Actions.
- SwiftData service tests run locally.
- UI tests or documented manual checks cover the primary flows.
- OSLog diagnostics are available locally without analytics.
- The app respects Dynamic Type, VoiceOver, contrast, reduced motion, and non-color status indicators.
- No secrets, signing credentials, analytics SDKs, or network dependencies are introduced.

## Future Extension Points

These are intentionally not part of MVP implementation, but the architecture should leave room for them:

- Export/import for local backups.
- TestFlight distribution.
- macOS GitHub Actions or Xcode Cloud.
- Widgets through shared read projections.
- Notifications through separate reminder settings.
- Cloud sync after reviewing SwiftData/CloudKit constraints, conflict handling, uniqueness, and deletion semantics.
- Multiple completions per day by replacing the routine-day uniqueness policy with a more flexible completion limit.
- Richer analytics through derived query services, not persisted streaks or scores unless product scope changes.
