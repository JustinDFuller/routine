# Manual verification: history-month-navigation

Run on commit c9b5d30 (video and screenshots re-captured after the final code changes) in the iOS 26.5 simulator ("Routine iPhone 17"), using the real app with animations enabled, the baseline screenshot fixture, the in-memory store, and the fixed date 2026-06-10. A temporary XCUITest drove the gestures while `simctl io recordVideo` recorded the screen. The temporary test is not part of the change.

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

## Not verified manually

- VoiceOver itself (task 4.2). The adjustable action sits on the weekday header, a single focusable element whose value is the displayed month, so VoiceOver can reach it. XCUITest cannot invoke an adjustable action, and VoiceOver was not run, so a swipe up or down on that element has not been exercised. The navigation rules it uses are covered by unit tests, and a UI test checks the header value follows the displayed month.
- The Reduce Motion cross-fade. It is driven by the same flag the app's animation-disabling launch argument uses, which the UI tests exercise, but the system Reduce Motion setting was not toggled.
