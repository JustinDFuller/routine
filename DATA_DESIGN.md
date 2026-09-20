# Data Design Specification: Routine

## Purpose

This document defines the data design for the Routine MVP. It is grounded in [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md) for product scope and behavior, and [VISUAL_DESIGN.md](VISUAL_DESIGN.md) for interface, interaction, and native iPhone design direction.

The app is a personal, local-first iPhone routine tracker. The system should be high quality, robust, and extensible, while remaining small enough for an MVP dogfooding build.

This document covers:

- Data structures
- Domain methods and business rules
- Local data storage and access
- View implementation structure
- Routing and navigation state

This document does not cover:

- Third-party libraries
- Build settings
- Automated testing strategy
- Deployment, release, or App Store operations

## Data Design Goals

The technical design should preserve the product principles:

- Flexible over rigid: the model tracks recurring targets without fixed weekday schedules.
- Visual over verbose: the app derives compact progress state for visual presentation.
- Fast over feature-rich: the common completion path is one tap with immediate UI updates.
- Forgiving over punitive: accidental completions are reversible immediately and from history.
- Configurable over hard-coded: routines, groups, target counts, and order belong to the user.

The system should optimize for:

- Correct daily uniqueness: a routine can be completed at most once per local calendar day.
- Correct period progress: weekly routines count Monday-start calendar weeks; monthly routines count calendar months.
- Safe persistence: user data survives app restarts and common app lifecycle interruptions.
- Simple local architecture: no sync, accounts, analytics, or remote services; notifications and widget handoff stay local to the device.
- Extensibility: future features can add richer scheduling, deeper widget surfaces, or sync without rewriting the core domain model.

## Platform And Architecture Decisions

### Platform Baseline

- Target iPhone first.
- Use SwiftUI for interface construction.
- Use SwiftData for local persistence.
- Use iOS 17 or newer as the minimum OS baseline.
- Use `NavigationStack` for the app hierarchy.
- Use native sheets, forms, lists, sections, toolbar items, swipe actions, and edit mode where they fit the visual design.

SwiftData is the right default for this MVP because it is native, Swift-first, integrates with SwiftUI observation, persists model data across launches, supports schema evolution, and avoids the boilerplate of Core Data for a small local app.

### Architectural Shape

Use a layered architecture:

1. `Persistence Models`
   SwiftData `@Model` classes that store canonical data.

2. `Domain Values`
   Small Swift value types and enums that express period, local day identity, progress, and routes.

3. `Domain Services`
   `@MainActor` objects or structs that enforce business rules and perform writes through `ModelContext`.

4. `Query / Projection Layer`
   Fetches persisted objects and converts them into view data that is safe for SwiftUI views to render.

5. `SwiftUI Views`
   Views render state, handle user gestures, and delegate domain mutations to services.

The key rule: views may initiate user actions, but they must not own persistence rules. Duplicate prevention, date windows, reorder normalization, cascade behavior, and validation belong in domain services.

### Concurrency Model

Keep persistence access `@MainActor` for MVP.

Reasoning:

- The expected dataset is tiny: dozens of routines and hundreds or low thousands of completions.
- All mutations are foreground user interactions.
- SwiftData exposes a main context intended for UI-driven work.
- A main-actor model avoids premature concurrency complexity and reduces accidental UI consistency bugs.

If future data volume grows, background contexts can be introduced for import, export, or analytics-style queries without changing the domain model.

## Core Domain Concepts

### Routine

A routine is a user-defined recurring activity with:

- A name
- A target count
- A frequency period: weekly or monthly
- A display group
- A user-defined order inside that group
- Completion history

A routine is not a scheduled task. It does not define required weekdays, due dates, reminders, scores, or recommended days. A routine's completion history may yield a derived streak count, but the streak is not a persisted attribute of the routine.

### Routine Group

A routine group is a display-only section. It controls organization and visual grouping on the dashboard and dashboard-owned management modes.

Groups do not have completion logic. They do not aggregate progress for MVP.

Groups are first-class user-editable objects:

- Add group
- Rename group
- Reorder groups
- Delete an empty group

Deleting a non-empty group is blocked. The user must move or delete its routines first.

### Routine Completion

A routine completion records that one routine was completed on one local calendar day.

The completion model stores:

- The owning routine
- A local day key, such as `2026-06-06`
- The timestamp when the user recorded the completion

The local day key is the source of truth for daily uniqueness and period progress. The timestamp is supporting context for ordering and future debugging.

### Routine Day

`RoutineDay` is a domain value object representing a local calendar date independent of time of day.

It prevents timezone and daylight-saving-time issues caused by using raw `Date` values as day identity.

Recommended shape:

```swift
struct RoutineDay: Codable, Hashable, Comparable, Sendable {
    let year: Int
    let month: Int
    let day: Int

    var key: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    static func < (lhs: RoutineDay, rhs: RoutineDay) -> Bool {
        lhs.key < rhs.key
    }
}
```

The app derives `RoutineDay` from `Date.now` using a configured local calendar. The persisted completion stores the string key.

## Data Model

### Enums

```swift
enum RoutinePeriod: String, Codable, CaseIterable, Identifiable, Sendable {
    case weekly
    case monthly

    var id: String { rawValue }
}
```

Presentation labels are derived outside persistence:

- `weekly` renders as `week`, `Weekly`, or `per week` depending on context.
- `monthly` renders as `month`, `Monthly`, or `per month` depending on context.

### SwiftData Models

The SwiftData schema stores only canonical data. Derived dashboard state is never persisted.

#### RoutineGroup

```swift
@Model
final class RoutineGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify, inverse: \Routine.group)
    var routines: [Routine]

    init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        routines: [Routine] = []
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.routines = routines
    }
}
```

Design notes:

- `id` is an app-level stable identifier for routing and relationships.
- `sortOrder` defines dashboard and manage-screen section order.
- Group deletion is guarded in `RoutineManagementService`, not by relationship cascade.
- The group relationship can be nullified at the database level, but the service must prevent routine-orphaning in normal UI flows.

#### Routine

```swift
@Model
final class Routine {
    @Attribute(.unique) var id: UUID
    var name: String
    var targetCount: Int
    var periodRawValue: String
    var groupID: UUID
    var sortOrder: Int
    var availabilityStartMinute: Int?
    var availabilityEndMinute: Int?
    var availabilityBlockModeRawValue: String
    var createdAt: Date
    var updatedAt: Date

    var group: RoutineGroup?

    @Relationship(deleteRule: .cascade, inverse: \RoutineCompletion.routine)
    var completions: [RoutineCompletion]

    var period: RoutinePeriod {
        get { RoutinePeriod(rawValue: periodRawValue) ?? .weekly }
        set { periodRawValue = newValue.rawValue }
    }

    var availabilityWindow: RoutineAvailabilityWindow? { ... }

    var availabilityBlockMode: RoutineAvailabilityBlockMode { ... }

    init(
        id: UUID = UUID(),
        name: String,
        targetCount: Int,
        period: RoutinePeriod,
        sortOrder: Int,
        group: RoutineGroup,
        availabilityStartMinute: Int? = nil,
        availabilityEndMinute: Int? = nil,
        availabilityBlockMode: RoutineAvailabilityBlockMode = .soft,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        completions: [RoutineCompletion] = []
    ) {
        self.id = id
        self.name = name
        self.targetCount = targetCount
        self.periodRawValue = period.rawValue
        self.groupID = group.id
        self.sortOrder = sortOrder
        self.group = group
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.completions = completions
    }
}
```

Design notes:

- `periodRawValue` stores the enum as a stable string.
- `groupID` is duplicated from the relationship intentionally so fetching, routing, and reorder operations can use stable values.
- `availabilityStartMinute` and `availabilityEndMinute` persist an optional local wall-clock completion window in minutes after midnight.
- `nil` and `nil` is the only canonical all-day state.
- Partial persisted availability should be treated defensively as all-day in projections and tracking, but normal service and form saves must reject it.
- `availabilityWindow` should return `nil` unless both persisted minutes form a valid configured window.
- `availabilityBlockModeRawValue` persists the stable `soft` or `hard` enum raw value; absent or malformed values resolve to `soft`.
- `group` is optional at the SwiftData relationship level to support migration and framework behavior, but the app domain treats it as required.
- Deleting a routine cascades to its completions. This matches the MVP decision that deleted routine history is intentionally removed after confirmation.

#### RoutineCompletion

```swift
@Model
final class RoutineCompletion {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var routineDayKey: String
    var routineID: UUID
    var dayKey: String
    var completedAt: Date

    var routine: Routine?

    init(
        id: UUID = UUID(),
        routine: Routine,
        day: RoutineDay,
        completedAt: Date = .now
    ) {
        self.id = id
        self.routineID = routine.id
        self.dayKey = day.key
        self.routineDayKey = "\(routine.id.uuidString)|\(day.key)"
        self.completedAt = completedAt
        self.routine = routine
    }
}
```

Design notes:

- `routineDayKey` enforces one completion per routine per local day.
- `routineID` is duplicated from the relationship intentionally so predicates, uniqueness, and routing do not depend on relationship traversal.
- `dayKey` is the canonical calendar-day identity for progress.
- `completedAt` is not used for period membership; it exists for audit context and stable descending sort when needed.

### Routine Availability

Time-based availability is modeled as local wall-clock values, not absolute timestamps or stored timezone-specific schedules.

```swift
struct RoutineTimeOfDay: Equatable, Sendable {
    let hour: Int
    let minute: Int

    var minuteOfDay: Int { ... }

    init?(hour: Int, minute: Int)
    init?(minuteOfDay: Int)
}

struct RoutineAvailabilityWindow: Equatable, Sendable {
    let start: RoutineTimeOfDay
    let end: RoutineTimeOfDay

    var spansMidnight: Bool { ... }

    func contains(minuteOfDay: Int) -> Bool
}
```

```swift
enum RoutineAvailabilityBlockMode: String, CaseIterable, Codable, Sendable {
    case soft
    case hard
}
```

Rules:

- Valid hours are `0...23`.
- Valid minutes are `0...59`.
- Valid minute-of-day values are `0..<1440`.
- Configured windows must use distinct start and end minutes because all-day availability is represented by `nil`.
- Membership is start-inclusive and end-exclusive.
- Same-day windows contain minutes between `start.minuteOfDay` and `end.minuteOfDay`.
- Cross-midnight windows contain minutes greater than or equal to the start minute or strictly less than the end minute.
- Completion day keys always use the actual local calendar day of the tap, even when the window crosses midnight.
- A soft window is a preferred-time presentation signal: it compacts an out-of-window incomplete card but keeps completion actionable.
- A hard window also rejects a new same-day completion outside the configured window.
- Historical calendar completion remains available outside both window modes.

#### AppMetadata

```swift
@Model
final class AppMetadata {
    @Attribute(.unique) var key: String
    var value: String
    var updatedAt: Date

    init(key: String, value: String, updatedAt: Date = .now) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}
```

Use this for lightweight app-level facts, starting with:

- `starterDataSeedVersion = "1"`

The starter dataset is inserted only once. If the user deletes or edits starter routines, the app must not recreate them on the next launch.

## Data Invariants

The domain layer must preserve these invariants:

- Every routine has a non-empty trimmed name.
- Every routine belongs to exactly one group in normal app state.
- Every routine has a target count valid for its period.
- Weekly target count is `1...7`.
- Monthly target count is `1...31`.
- A routine's `groupID` matches its related group's `id` in normal app state.
- A completion belongs to one routine.
- A completion's `dayKey` is a valid `RoutineDay.key`.
- A completion's `routineDayKey` is unique.
- A routine can have at most one completion per local calendar day.
- If a routine persists an availability window, both availability minute fields are present and distinct.
- A group can be deleted only when it has no routines.
- Routine and group order is represented by contiguous integer `sortOrder` values after reorder operations.
- Period progress is derived from completion day keys, not stored.
- Last-done state is derived from completion day keys, not stored.

The UI should prevent invalid input, and services should also validate before writing. Do not rely on UI controls alone for correctness.

## Calendar And Date Handling

### RoutineCalendar

Create a small domain service for all date logic:

```swift
struct RoutineCalendar: Sendable {
    var calendar: Calendar

    static var current: RoutineCalendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = .current
        calendar.timeZone = .current
        calendar.firstWeekday = 2
        return RoutineCalendar(calendar: calendar)
    }

    func day(containing date: Date) -> RoutineDay
    func minuteOfDay(containing date: Date) -> Int
    func today(now: Date) -> RoutineDay
    func currentPeriodRange(for period: RoutinePeriod, containing day: RoutineDay) -> ClosedRange<RoutineDay>
    func currentWeekRange(containing day: RoutineDay) -> ClosedRange<RoutineDay>
    func currentMonthRange(containing day: RoutineDay) -> ClosedRange<RoutineDay>
    func daysInCurrentMonth(containing day: RoutineDay) -> [RoutineDay]
    func relativeLabel(for day: RoutineDay, today: RoutineDay) -> String
    func explicitDateLabel(for day: RoutineDay) -> String
}
```

Rules:

- `today` uses the user's current local calendar and timezone.
- `minuteOfDay(containing:)` uses the same configured Gregorian calendar, locale, and timezone as `today`.
- Calendar weeks start on Monday.
- Weekly progress includes Monday 00:00 through the start of the following Monday.
- Weekly range calculation should find the Monday containing the current day directly, not depend on locale-specific week-of-year numbering.
- Monthly progress includes the first local day of the month through the last local day of the month.
- Comparisons use `RoutineDay` and `dayKey`, not raw `Date` timestamps.
- Changing timezone later does not rewrite historical completion day keys.

Recommended labels:

- Today: `Today`
- Yesterday: `Yesterday`
- Recent within 7 days: `3d ago`
- Older in current year: `Jun 2`
- Older in prior year: `Jun 2, 2025`
- Never completed: `Never` or `No completions yet` depending on surface.

## Progress Model

Progress is a derived value used by dashboard cards, history summaries, and progress rings.

```swift
struct RoutineProgress: Equatable, Sendable {
    let period: RoutinePeriod
    let targetCount: Int
    let completedCount: Int
    let isCompletedToday: Bool
    let lastCompletedDay: RoutineDay?

    var remainingCount: Int {
        max(targetCount - completedCount, 0)
    }

    var isTargetMet: Bool {
        completedCount >= targetCount
    }

    var isOverTarget: Bool {
        completedCount > targetCount
    }

    var fillRatio: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(completedCount) / Double(targetCount), 1)
    }
}
```

### ProgressCalculator

```swift
struct ProgressCalculator {
    let routineCalendar: RoutineCalendar

    func progress(
        for routine: Routine,
        completions: [RoutineCompletion],
        today: RoutineDay
    ) -> RoutineProgress

    func completionsInCurrentPeriod(
        period: RoutinePeriod,
        completions: [RoutineCompletion],
        today: RoutineDay
    ) -> [RoutineCompletion]

    func lastCompletedDay(from completions: [RoutineCompletion]) -> RoutineDay?
}
```

Rules:

- Filled ring progress equals current-period completion count, capped visually at target count.
- Count text shows actual count over target, such as `6/5`.
- The center checkmark appears only when the routine is completed today.
- A target-met routine remains actionable if it has not been completed today.
- Overage is not gamified and does not create badges or celebration styling.

### RoutineStreak

`RoutineStreak` is a derived value owned by the RoutineCore module. It is never persisted.

```swift
struct RoutineStreak: Equatable, Sendable {
    let count: Int
    let period: RoutinePeriod
}
```

A `StreakCalculator` (or an extension on `ProgressCalculator`) computes this value from a routine's completion history and its `RoutineCalendar`:

```swift
struct StreakCalculator {
    let routineCalendar: RoutineCalendar

    func streak(
        for routine: Routine,
        completions: [RoutineCompletion],
        today: RoutineDay
    ) -> RoutineStreak
}
```

Rules:

- The streak is the count of consecutive finalized periods (weeks or months, matching the routine's `period`) in which the unique completion day count met or exceeded the routine's `targetCount`.
- "Finalized" means the period has fully closed before the current in-progress period. The period that contains `today` is excluded from the count until it closes.
- A missed finalized period resets the streak count to zero.
- Periods in which the unique completion count exceeds the target count once; there is no bonus for overachievement.
- Duplicate completions on the same `dayKey` are deduped using the same `Set`/`uniqueSortedDays` idiom already used by `ProgressCalculator`.
- Period ranges are derived from `RoutineCalendar.currentPeriodRange` and the configured `firstWeekday` (week start), so the streak respects the user's configured week-start day.
- `StreakCalculator` is pure: it has no SwiftUI, SwiftData, or UIKit dependencies and can run in `RoutineCoreTests` on Ubuntu.

## Domain Services And Methods

Domain services should be small, explicit, and organized around user intent.

### RoutineTrackingService

Responsibilities:

- Complete a routine for today.
- Undo today's completion.
- Remove a historical completion.
- Prevent duplicate completions.
- Enforce hard configured availability windows for new same-day completions.
- Save after successful mutations.

Recommended interface:

```swift
@MainActor
final class RoutineTrackingService {
    private let context: ModelContext
    private let routineCalendar: RoutineCalendar

    init(context: ModelContext, routineCalendar: RoutineCalendar = .current)

    func completeToday(routineID: UUID, now: Date = .now) throws -> CompletionResult
    func undoToday(routineID: UUID, now: Date = .now) throws -> UndoResult
    func removeCompletion(completionID: UUID) throws
}
```

Supporting results:

```swift
struct CompletionResult: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
    let day: RoutineDay
    let didInsert: Bool
}

struct UndoResult: Equatable, Sendable {
    let routineID: UUID
    let day: RoutineDay
    let didRemove: Bool
}

enum RoutineTrackingError: LocalizedError, Equatable {
    case unavailable(routineName: String, windowText: String)
}
```

Behavior:

- `completeToday` fetches the routine by ID.
- It computes today's `RoutineDay`.
- It checks for an existing completion with `routineDayKey`.
- If one exists, it returns `didInsert = false` and does not write.
- If no completion exists for today, it evaluates a hard availability window against the current local minute-of-day.
- If a hard routine is outside its configured window, it throws a user-safe unavailable error and does not insert a completion.
- Soft routines, all-day routines, and historical days insert normally.
- `undoToday` removes only the completion matching today's day key.
- `removeCompletion` removes a specific historical completion after the view has already confirmed the destructive action.
- All mutations save explicitly.
- Errors should be surfaced to the view as user-safe messages if save or fetch fails.

### RoutineManagementService

Responsibilities:

- Create routines.
- Edit routines.
- Delete routines.
- Reorder routines within and across groups.
- Create, rename, reorder, and delete empty groups.
- Normalize sort orders after changes.

Recommended interface:

```swift
@MainActor
final class RoutineManagementService {
    private let context: ModelContext

    init(context: ModelContext)

    func createRoutine(_ draft: RoutineDraft) throws -> UUID
    func updateRoutine(id: UUID, with draft: RoutineDraft) throws
    func deleteRoutine(id: UUID) throws
    func moveRoutine(id: UUID, toGroupID: UUID, at index: Int) throws

    func createGroup(name: String) throws -> UUID
    func renameGroup(id: UUID, name: String) throws
    func deleteGroup(id: UUID) throws
    func moveGroup(id: UUID, to index: Int) throws
}
```

Draft object:

```swift
struct RoutineDraft: Equatable, Sendable {
    var name: String
    var targetCount: Int
    var period: RoutinePeriod
    var groupID: UUID
    var availabilityStartMinute: Int?
    var availabilityEndMinute: Int?
    var availabilityBlockMode: RoutineAvailabilityBlockMode
}
```

Validation:

```swift
enum RoutineValidationError: LocalizedError, Equatable {
    case emptyName
    case invalidTargetCount(period: RoutinePeriod)
    case invalidAvailabilityWindow
    case missingGroup
    case emptyGroupName
    case nonEmptyGroup
}
```

Behavior:

- Names are trimmed before validation and persistence.
- Routine names do not need to be globally unique in MVP.
- Equal start/end availability minutes are invalid because all-day availability is represented by `nil`.
- Service validation should reject partial availability values if the API surface can express them.
- Group names should be unique after trimming and case-insensitive comparison to avoid accidental duplicate sections.
- New routines are appended to the end of the selected group.
- Moving routines updates group assignment and order.
- Reordering routines renormalizes all affected routines to `0...n-1`.
- Reordering groups renormalizes all groups to `0...n-1`.
- Deleting a routine requires confirmation in the view, then cascades completions.
- Deleting a non-empty group fails with `nonEmptyGroup`.

### StarterDataService

Responsibilities:

- Seed initial editable groups and routines for dogfooding.
- Ensure starter data is inserted once.

Recommended interface:

```swift
@MainActor
final class StarterDataService {
    private let context: ModelContext

    init(context: ModelContext)

    func seedIfNeeded() throws
}
```

Starter groups:

- Morning
- Movement
- Family / Home
- Learning / Creative
- Evening
- Monthly Maintenance

Starter routines should be based on the examples in the product brief. They are editable defaults, not fixed categories or protected system data.

Behavior:

- On first launch, check `AppMetadata` for `starterDataSeedVersion`.
- If missing, insert groups and routines, then set `starterDataSeedVersion = "1"`.
- If present, do nothing, even if no routines remain.

## Storage Design

### ModelContainer

The app should define one SwiftData `ModelContainer` containing:

- `RoutineGroup`
- `Routine`
- `RoutineCompletion`
- `AppMetadata`

Recommended setup:

```swift
@main
struct RoutineApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            RoutineGroup.self,
            Routine.self,
            RoutineCompletion.self,
            AppMetadata.self
        ])
    }
}
```

If the actual SwiftData API shape requires a schema object in the implementation, use an equivalent explicit schema. The important design point is a single local container shared through the SwiftUI environment.

### Storage Location

Use SwiftData's default local app-container storage for MVP.

Do not use:

- CloudKit
- App Groups
- External files
- UserDefaults for canonical routine data
- Keychain for routine data

Reasoning:

- The app is single-user and local-only.
- Routine history is structured relational data, not preferences.
- There are no credentials or small secrets requiring Keychain.
- SwiftData handles persistence, model storage configuration, and schema evolution.

### Data Protection

Rely on iOS sandboxing and platform file protection for the local store.

Routine data is personal but not credential-like. The MVP should not add custom encryption, biometric gates, or Keychain-backed storage. Those would add friction and operational complexity without matching the product scope.

If a later version introduces highly sensitive notes, account credentials, or sync tokens, that data should be stored separately using the appropriate Security framework or Keychain APIs.

### Save Strategy

Use explicit saves after user mutations:

- Completion inserted
- Today's completion undone
- Historical completion removed
- Routine created, edited, deleted, or moved
- Group created, renamed, deleted, or moved
- Starter data inserted

This keeps user actions durable quickly and makes failure handling clear.

### Migration Strategy

For MVP v1, no custom migration plan is required.

Design for future migrations by:

- Keeping persisted enum values as stable strings.
- Keeping app-level IDs stable.
- Avoiding derived persisted values that would need backfills.
- Using `AppMetadata` for seed and one-time app data flags.
- Adding a `SchemaMigrationPlan` later only when automatic migration is insufficient.

## Data Access Patterns

### Fetch By Stable ID

Views and routes pass `UUID` values, not SwiftData model instances.

Use helper fetches:

```swift
func routine(id: UUID) throws -> Routine
func group(id: UUID) throws -> RoutineGroup
func completion(id: UUID) throws -> RoutineCompletion
```

This avoids stale object references in navigation state and follows SwiftUI navigation guidance to keep paths value-based.

### Dashboard Query

Dashboard needs:

- Ordered groups
- Ordered routines per group
- Current-period completions for weekly and monthly routines
- Last completion per routine
- Today's completion state per routine

Recommended approach for MVP:

1. Fetch all groups sorted by `sortOrder`.
2. Fetch all routines, group them in memory by `groupID`, and sort each group by `sortOrder`.
3. Fetch all completions sorted by `routineID`, then `dayKey` descending.
4. Build `TodayDashboardViewData` in memory.

Because the data set is small, fetching all completions is the clearest MVP-safe strategy. It guarantees accurate last-done labels without a denormalized cache or per-routine fetch loop. If history grows large, replace this with targeted current-period fetches plus one latest-completion fetch per routine, or maintain a denormalized last-completion cache in a future version.

### History Query

History needs:

- The routine by ID
- Current-period completions for the summary
- Current-month completions for the month grid
- Recent completions in descending date order

Recommended projection:

```swift
struct RoutineHistoryViewData: Equatable, Sendable {
    let routineID: UUID
    let routineName: String
    let frequencySummary: String
    let progress: RoutineProgress
    let streakSummaryText: String?
    let streakAccessibilityText: String?
    let monthDays: [HistoryCalendarDay]
    let recentCompletions: [CompletionListItem]
}
```

Rules:

- `streakSummaryText` is `nil` when the streak count is zero; otherwise it is a plain human-readable phrase such as `3 weeks in a row` or `2 months in a row`.
- `streakAccessibilityText` mirrors `streakSummaryText` and is included in the history summary's combined VoiceOver label when non-nil.
- `HistoryProjectionBuilder` computes both fields from `StreakCalculator` on every projection build, after any completion, undo, or historical correction.

The recent completions list should sort by `dayKey` descending, then `completedAt` descending.

### Dashboard Management Query

Dashboard-owned management flows need:

- Ordered groups
- Ordered routines per group
- Routine summary strings

No progress history is required in the management projection. Keep this surface configuration-focused.

## View Data Structures

SwiftUI views should render immutable, lightweight view data where practical.

### Dashboard View Data

```swift
struct TodayDashboardViewData: Equatable, Sendable {
    let title: String
    let dateLabel: String
    let sections: [RoutineSectionViewData]
    let isEmpty: Bool
}

struct RoutineSectionViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let remainingCount: Int
    let routines: [RoutineCardViewData]
}

struct RoutineCardViewData: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let period: RoutinePeriod
    let countText: String
    let periodText: String
    let lastDoneText: String
    let streakText: String?
    let availabilityText: String?
    let accessibilityLabel: String
    let unavailableAccessibilityPhrase: String?
    let progressRing: ProgressRingViewData
    let isCompletedToday: Bool
    let isAvailableNow: Bool
    let isTargetMet: Bool
    let isOverTarget: Bool
}

struct ProgressRingViewData: Equatable, Sendable {
    let targetCount: Int
    let completedCount: Int
    let fillRatio: Double
    let showsTodayCheckmark: Bool
}
```

Rules:

- Use one continuous ring for every target count.
- All-day routines omit availability text to avoid clutter.
- Configured routines on Today omit visible availability text while currently available, and show an explicit range such as `Available 12:00 AM-6:45 AM` only while currently unavailable.
- Routines that are completed today may collapse into compact completed rows when the completed-collapse setting is enabled.
- Routines whose period goal is met but which are not completed today may collapse into compact goal-met rows when the goal-met-collapse setting is enabled.
- Incomplete unavailable routines remain visible in their normal group and order, present disabled completion state when expanded, and may collapse into compact clock rows on Today when the unavailable-collapse setting is enabled.
- Unavailable compaction takes precedence over goal-met compaction for routines that are both unavailable and already at goal.
- Section `remainingCount` includes incomplete routines that are currently available, not disabled unavailable routines.
- `streakText` is `nil` when the streak count is zero; otherwise it is a plain phrase such as `3 weeks in a row`. It is rendered on the full expanded card only and omitted from compact collapsed rows.
- `DashboardProjectionBuilder` computes `streakText` from `StreakCalculator` on every projection build.
- Accessibility label includes routine name, availability state when relevant, completed-today state, count, period, and streak text when non-nil.

### History View Data

```swift
struct HistoryCalendarDay: Identifiable, Equatable, Sendable {
    let id: String
    let day: RoutineDay
    let label: String
    let isInDisplayedMonth: Bool
    let isToday: Bool
    let isCompleted: Bool
}

struct CompletionListItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let day: RoutineDay
    let dateText: String
    let relativeText: String?
}
```

Rules:

- Calendar marks communicate completion through shape and fill, not color alone.
- Today's date is visually distinct even when incomplete.
- Completed today shows both completion mark and today emphasis.

### Form Draft State

Add/Edit Routine should edit draft state, not live model objects directly.

```swift
@Observable
final class RoutineFormState {
    var name: String
    var targetCount: Int
    var period: RoutinePeriod
    var groupID: UUID?
    var isAvailableAllDay: Bool
    var availabilityStartMinute: Int?
    var availabilityEndMinute: Int?

    var isValid: Bool { ... }
    func makeDraft() throws -> RoutineDraft
}
```

Benefits:

- Cancel can dismiss without mutating persisted data.
- Validation can be shown before save.
- Edit forms can initialize from persisted state and commit only on Save.
- All-day mode can preserve temporary picker values in state while still emitting `nil` availability in the saved draft.

## Views

### RootView

Responsibilities:

- Own the `NavigationStack`.
- Install navigation destinations.
- Trigger starter data seeding once when the model context is available.
- Provide shared services to child views through environment or explicit initialization.

Recommended structure:

```swift
struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            TodayDashboardView(path: $path)
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
    }
}
```

### TodayDashboardView

Purpose:

- Default landing screen.
- Shows all routines in user-defined group/order.
- Supports one-tap completion.
- Provides access to routine history, edit, undo, and manage.

Responsibilities:

- Query dashboard data.
- Render grouped sections.
- Render empty state when no routines exist.
- Handle routine card taps.
- Show transient undo banner.
- Navigate to History.

Behavior:

- Toolbar title: `Today`.
- Optional date label in content: formatted current date.
- Toolbar trailing action: `Manage`.
- Incomplete card tap calls `completeToday`.
- Completed card tap opens routine history without creating a duplicate completion.
- Trailing history button opens routine history without completing.
- Completion updates UI immediately via SwiftData observation and local undo-banner state.
- Undo banner remains usable but does not block scrolling or additional completions.

Dashboard controls:

- Trailing history button opens routine history.
- Inline routine edit control appears only in dashboard Edit mode.
- Same-day undo comes from the transient undo banner.

### RoutineCardView

Purpose:

- Display one routine's current state.
- Serve as the primary completion target when incomplete.

Anatomy:

- Leading continuous progress ring.
- Center name and metadata line.
- Trailing ellipsis action button.

States:

- Incomplete today: strong card contrast, no checkmark, active tap affordance.
- Completed today: center checkmark, last-done text `Today`, subtly softened card styling, no strikethrough.
- Target met: visually full ring, count still visible.
- Over target: full ring, count text shows actual overage.

Accessibility:

- Treat the card as one combined accessibility element for the primary action.
- Provide a separate accessible label for the trailing actions button.
- Do not rely on color alone; use checkmark, fill, opacity, and text.

### ProgressRingView

Purpose:

- Primary visual progress motif.
- Communicates current period progress and today's completion state.

Inputs:

- `ProgressRingViewData`
- Visual size
- Color role

Behavior:

- Render a base track plus one continuous trimmed progress stroke.
- Filled count is capped at target for drawing.
- Text count outside the ring shows actual overage.
- Center checkmark appears only when completed today.
- Completion animation is short, approximately `120-180ms`.
- Respect reduced motion by avoiding animated transitions when requested.

### RoutineHistoryView

Purpose:

- Answer "When did I last do this?"
- Show current period progress.
- Show current month completion marks.
- Allow removal of incorrect completions.

Structure:

1. Summary header
2. Current-month calendar grid
3. Recent completions list

Summary header:

- Routine name
- Frequency summary, such as `5 per week`
- Larger progress ring or progress summary
- Last completed phrase
- Current period count versus target

Recent completions:

- Descending dates
- Relative cue when useful
- Destructive remove action
- Confirmation before deletion

Behavior:

- Removing a completion updates the history view immediately after save.
- Dashboard reflects changed progress when returning because both screens read from the same SwiftData store.

### Dashboard Management Modes

Purpose:

- Keep routine tracking and management attached to Today.
- Configure routines and groups without pushing a separate screen.
- Preserve a shallow navigation model where history is the only pushed route.

Structure:

- A trailing `gearshape` menu in the dashboard top bar.
- A direct history affordance on each routine card.
- Optional inline management controls on group headers and routine cards.
- Separate dashboard-owned rearrange modes with native reorder lists and visible drag handles.

Actions:

- Add routine from the gear menu.
- Add group from the gear menu.
- Enter or exit inline dashboard Edit mode from the gear menu.
- Edit routine from the inline routine control in Edit mode.
- Edit group from inline dashboard group controls.
- Delete routine from the routine edit sheet only.
- Delete empty group from the group edit sheet only.
- Reorder routines within a group in dashboard Rearrange Routines mode.
- Reorder groups in dashboard Rearrange Groups mode.

Use native menu, sheet, and list-reorder behavior where it supports the design cleanly. Avoid a separate management route for MVP.

### AddEditRoutineView

Purpose:

- Focused native form for creating or editing a routine.

Presentation:

- Modal sheet over Today Dashboard.

Fields:

- Routine name: text field.
- Target count: stepper or compact numeric picker.
- Frequency period: segmented picker with Weekly and Monthly.
- Group assignment: picker of existing groups.

Toolbar:

- Leading: `Cancel`.
- Trailing: `Save` or `Done`.

Behavior:

- Editing happens in `RoutineFormState`.
- Save validates and calls `RoutineManagementService`.
- Cancel dismisses without saving.
- Delete may appear in edit mode only, visually separated, destructive, and confirmed.

### Group Editing Views

Group management can be simple:

- Add group sheet with name field.
- Edit group sheet with name field.
- Delete empty group from the edit group sheet after confirmation.
- Reorder groups through dashboard Rearrange Groups mode.

No onboarding wizard or category template system is needed.

## Routing

Use value-based app routes:

```swift
enum AppRoute: Hashable, Sendable {
    case routineHistory(routineID: UUID)
}
```

Rules:

- `TodayDashboardView` is the root and default launch screen.
- Routine History is pushed from a routine's secondary action path.
- Add/Edit Routine is a sheet from Today Dashboard.
- Group add/edit is a sheet from Today Dashboard.
- Do not use a tab bar for MVP.
- Do not store SwiftData model objects in navigation path values.

This keeps navigation shallow, native, and stable across model refreshes.

## User Interaction Flows

### Complete Routine Today

1. User taps an incomplete routine card.
2. Dashboard calls `RoutineTrackingService.completeToday`.
3. Service computes today's `RoutineDay`.
4. Service inserts a completion if no completion exists for the routine/day.
5. Service saves.
6. Dashboard updates ring, count, checkmark, and last-done cue.
7. Dashboard shows undo banner with `Completed <Routine Name>` and `Undo`.
8. Light haptic feedback fires after successful insertion.

If the completion already exists, no duplicate is inserted. The UI should open history if the card was already completed.

### Undo Today's Completion

1. User taps `Undo` in the transient banner.
2. Dashboard calls `RoutineTrackingService.undoToday`.
3. Service removes today's completion for that routine if present.
4. Service saves.
5. Dashboard updates immediately to incomplete-today state.
6. Light feedback fires after successful removal.

### Open History

1. User taps the routine history button, or taps a card that is already completed today.
3. Dashboard appends `.routineHistory(routineID)` to the navigation path.
4. History fetches routine and completion projections by ID.
5. User sees last-done summary, current-month marks, and recent completions.

### Remove Historical Completion

1. User swipes or taps remove on a recent completion row.
2. History view asks for destructive confirmation.
3. On confirmation, view calls `RoutineTrackingService.removeCompletion`.
4. Service deletes completion and saves.
5. History summary, month grid, and recent list update.

### Add Or Edit Routine

1. User opens the dashboard gear menu or enters dashboard Edit mode.
2. User chooses Add Routine or taps an inline routine edit control.
3. Add/Edit sheet opens with draft state.
4. User edits fields.
5. Save validates and calls management service.
6. Service saves.
7. Sheet dismisses and Today Dashboard updates.

### Delete Routine

1. User opens Edit Routine from the dashboard.
2. View asks for destructive confirmation.
3. On confirmation, management service deletes the routine.
4. SwiftData cascades completion deletion.
5. Dashboard no longer shows the routine.

### Manage Groups

1. User opens the dashboard gear menu, inline group controls, or a rearrange mode.
2. User adds, renames, reorders, or deletes an empty group.
3. Service validates group state and saves.
4. Dashboard section order and names update.

## Error Handling

The app should keep error handling simple but explicit.

Expected domain errors:

- Routine not found.
- Group not found.
- Completion not found.
- Invalid routine name.
- Invalid target count.
- Missing group.
- Duplicate group name.
- Attempt to delete non-empty group.
- Persistence save failure.

Recommended user-facing behavior:

- Validation errors appear inline in forms when possible.
- Save failures show a concise alert, such as `Could not save changes. Try again.`
- Not-found errors dismiss the stale screen or show `This routine no longer exists.`
- Duplicate completion attempts are not user-facing errors; they are treated as idempotent no-ops.

Do not introduce logging, telemetry, crash reporting, or analytics for MVP.

## Extensibility

The model intentionally leaves room for future improvements without implementing them now.

Future scheduling:

- Add schedule rules to `Routine` or a child model without changing completion history.
- Existing period progress remains valid.

Multiple completions per day:

- Replace `routineDayKey` uniqueness with a more flexible completion limit model.
- Keep `RoutineDay` as the day grouping primitive.

Notifications:

- Implemented as a global, non-per-routine behind-schedule alert. One enabled flag and one local minute-of-day preference are global `@AppStorage`/`UserDefaults` values, not a new SwiftData model, and do not overload `RoutinePeriod` with notification behavior.
- At rescheduling time, the alert selects the first routine in dashboard order with the greatest deficit between deduplicated period completions and target-proportional expected completions. It uses a two-day local rolling horizon and cancels/rebuilds after app foregrounding; completion or history correction; routine creation, edit, or deletion; notification setting changes; and data reset.
- Per-routine reminder notifications remain a future extension if ever added; they would need their own settings model separate from completion history.

Widgets:

- Add shared read projections later if an app group is introduced.
- Keep canonical data in SwiftData and expose widget-specific snapshots only when needed.

Sync:

- SwiftData can be configured for CloudKit in a later version, but MVP data assumptions must remain local-only.
- Before sync, review unique constraints, optional relationships, conflict behavior, and deletion semantics.

Richer analytics:

- Add derived query services over `RoutineCompletion`.
- Derived (non-persisted) streak counts are explicitly sanctioned: `StreakCalculator` in the RoutineCore module computes streak counts from completion history without any persistent model fields.
- Do not persist streak counts or scores unless a later measured performance problem requires a cache.

## Acceptance Criteria

The data design is satisfied when an implementation can meet these scenarios:

- The app launches to Today Dashboard.
- Starter groups and routines seed once and remain user-editable.
- All routines remain visible, including completed and monthly routines.
- Routines appear grouped and ordered by user configuration.
- One tap completes an incomplete routine for today.
- Repeated taps never create duplicate completions for the same routine/day.
- Undo removes today's completion and restores incomplete-today state.
- Current week progress counts Monday-start calendar weeks.
- Current month progress counts calendar months.
- Last-done labels derive from completion history.
- History shows routine summary, current-month completion marks, and recent completions.
- Historical completion removal requires confirmation and updates progress.
- The Today Dashboard owns add, edit, delete, and reorder routine flows through menus, sheets, and rearrange modes.
- Group management supports add, rename, reorder, and delete empty groups from dashboard-owned flows.
- Deleting a routine removes its completion history by cascade.
- Navigation uses `NavigationStack` with value-based routes.
- Add/Edit Routine appears as a sheet from Today Dashboard.
- The interface supports Dynamic Type, VoiceOver labels, sufficient contrast, and non-color state indicators.

## Apple References

These Apple resources should inform implementation:

- [SwiftData](https://developer.apple.com/documentation/swiftdata)
- [Preserving your app's model data across launches](https://developer.apple.com/documentation/swiftdata/preserving-your-apps-model-data-across-launches)
- [ModelContainer](https://developer.apple.com/documentation/swiftdata/modelcontainer)
- [SwiftUI Navigation](https://developer.apple.com/documentation/swiftui/navigation)
- [NavigationStack](https://developer.apple.com/documentation/swiftui/navigationstack)
- [Understanding the navigation stack](https://developer.apple.com/documentation/swiftui/understanding-the-navigation-stack)
- [Human Interface Guidelines: Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Human Interface Guidelines: Color](https://developer.apple.com/design/human-interface-guidelines/color)
- [Human Interface Guidelines: VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover)
- [Security framework](https://developer.apple.com/documentation/security/)
- [FileProtectionType](https://developer.apple.com/documentation/foundation/fileprotectiontype)
- [Keychain services](https://developer.apple.com/documentation/security/keychain-services)
