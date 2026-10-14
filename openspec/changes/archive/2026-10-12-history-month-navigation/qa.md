# Manual verification: history-month-navigation

Video and screenshots were captured on commit c9b5d30. Later commits only extracted the swipe and transition-deferral rules into unit-tested helpers, made a day tap flush a pending month move, and cancelled it on disappear, with no change to the flows recorded. Captured in the iOS 26.5 simulator ("Routine iPhone 17"), using the real app with animations enabled, the baseline screenshot fixture, the in-memory store, and the fixed date 2026-06-10. A temporary XCUITest drove the gestures while `simctl io recordVideo` recorded the screen. The temporary test is not part of the change.

## Screen recording

[flow.mp4](qa/flow.mp4) (50 seconds, includes the app launch). In order:

1. Open History for "Morning yoga" (June 2026).
2. Swipe right six times: May, April, March, February, January 2026, then December 2025. The slide direction follows the swipe, and the Today button appears from the first swipe.
3. Swipe left seven times back to June 2026. The Today button disappears on arrival.
4. Swipe left again on the current month. Nothing happens.
5. Tap the title to open the month and year wheels, then jump the year wheel to 2024.
6. Tap Today. The wheels close and June 2026 returns.
7. Swipe right to May 2026, tap May 20, and the confirmation popover appears. Confirming records the completion.

## Screenshots

| | Month grid (May 2026) | Wheels |
| --- | --- | --- |
| Light | [light-grid.png](qa/light-grid.png) | [light-wheels.png](qa/light-wheels.png) |
| Dark | [dark-grid.png](qa/dark-grid.png) | [dark-wheels.png](qa/dark-wheels.png) |
| Accessibility XXXL Dynamic Type | [xxxl-grid.png](qa/xxxl-grid.png) | [xxxl-wheels.png](qa/xxxl-wheels.png) |

## Observations

- The wheels, title, and Today button lay out correctly at Accessibility XXXL. The Today button moves below the title, and the fixed 180pt wheel height still shows the selected row with its neighbors.
- At Accessibility XXXL the day grid itself truncates day numbers and wraps weekday letters. The weekday header and day cell layout are unchanged from before this change, so this is existing behavior and out of scope here.

## Reduce Motion, verified with the system setting

With the simulator's system Reduce Motion turned on (`com.apple.Accessibility ReduceMotionEnabled`) and no animation-disabling launch argument, a month swipe was recorded and the frames inspected. The old and new month grids fade in place over each other, with ghosted day numbers overlapping and no horizontal slide, so the cross-fade path runs from the real system setting. The setting was turned back off afterwards. Frames are in `qa/reduce-motion-crossfade.png`.

![Reduce Motion cross-fade frames](qa/reduce-motion-crossfade.png)

## VoiceOver adjustable action, exercised through the accessibility tree

VoiceOver itself cannot run in the simulator, and XCUITest cannot invoke an adjustable action. SwiftUI does build its accessibility tree once the simulator has application accessibility enabled (`com.apple.Accessibility AccessibilityEnabled` and `ApplicationAccessibilityEnabled`), so `HistoryMonthGridAccessibilityTests` hosts the month grid, finds the single adjustable accessibility element, and checks it:

- It is an accessibility element with the weekday letters as its label and the displayed month ("May 2026") as its value.
- `accessibilityIncrement()` reports a +1 month adjustment and `accessibilityDecrement()` reports -1, the same calls VoiceOver makes on a swipe up or down.

The test passed with the setting enabled. With it disabled, as on a stock simulator and in CI, the test reports itself skipped instead of failing. The setting was turned back off afterwards.

## Won't do

- A real VoiceOver session on a device (task 4.2). The owner decided on 2026-10-13 not to run it and to finalize without it. The adjustable action, its label, its value and its focusability are checked as above, but spoken output and the swipe gesture itself were not, and will not be verified as part of this change.
