# Design

## Context

History is pushed onto the root `NavigationStack` (`RoutineApp/RootView.swift`). The month grid changes month with a SwiftUI `DragGesture` attached through `.simultaneousGesture` (`HistoryMonthGridView.swipeGesture`), so it never stops other gestures from starting. The app is built with the iOS 26 SDK and targets iOS 17 and later. See proposal.md for the symptom and the suspected cause.

On iOS 26, a pushed screen can be dismissed by a right swipe from anywhere on its content, through the navigation controller's `interactiveContentPopGestureRecognizer`, in addition to the left-edge `interactivePopGestureRecognizer`. Both are UIKit recognizers that SwiftUI does not let a `DragGesture` take priority over.

The cause is a hypothesis. The existing UI tests swipe right repeatedly and pass, but XCUITest swipes are fast and perfectly straight, unlike a finger.

## Goals / Non-Goals

**Goals:**
- A sideways swipe inside the calendar card is never interpreted as "go back".
- Everything outside the card, and vertical scrolling and taps everywhere, behave as they do today.
- The month-changing swipe keeps its current thresholds, animation and accessibility behavior.

**Non-Goals:**
- Changing which swipes change month, or adding a limit on going back.
- Disabling swipe-to-go-back on the whole screen.
- Applying the same treatment to other pushed screens.

## Decisions

### Reproduce before changing anything

The first task records the failure in the simulator on iOS 26.5 with slow, finger-like drags, using a routine with completions over several months and an empty routine, because the reporter wondered whether it depended on the oldest completion. If it does not reproduce, or it depends on data, the change stops and is reopened rather than shipping a fix for a guess.

### Make the navigation controller's back swipes wait for a calendar-owned pan recognizer

A small `UIViewRepresentable` is placed behind the calendar card and registers the card with a guard owned by the enclosing `UINavigationController`. The guard is one `UIPanGestureRecognizer` per navigation controller, added to the navigation controller's view and kept alive with it (it is not removed when the card leaves the window; only the card registration is). It calls `require(toFail:)` once on the navigation controller's iOS 26 content-pop recognizer so it waits for that pan to fail, and refuses to recognize simultaneously with either pop recognizer. The edge-pop recognizer is left alone because the pan never claims touches in the 24pt strip at the back edge of the screen. The pan begins for any touch that started inside the visible part of a registered card, below the navigation bar and outside that edge strip (mirrored for right-to-left layouts); it does not look at the direction, so a jittery start cannot hand the touch to the back swipe. A pan that begins is therefore never also seen as a back swipe. When no registered card contains the touch, the pan fails immediately and the back swipe proceeds as usual.

A consequence of `require(toFail:)` is that the content-pop swipe waits for the pan to decide before it can start. The pan decides at touch down and fails immediately outside the card, so no delay was observed on the History screen, but it was not measured on other pushed screens, and the dependency cannot be removed once added. That is why the pan is permanent per navigation controller and decides per touch instead of being added and removed with the card.

Why this over the alternatives:
- **Hide the back swipe on the whole screen** (`navigationBarBackButtonHidden` plus disabling the pop recognizers): loses the swipe back everywhere on the screen, which the user wants kept outside the card.
- **Replace `.simultaneousGesture` with `.highPriorityGesture`**: only affects SwiftUI's own gesture arbitration; the UIKit pop recognizer is still free to begin.
- **Use iOS 18's `UIGestureRecognizerRepresentable`**: cleaner, but the deployment target is iOS 17.
- **Make the calendar a horizontal paging `TabView` or `ScrollView`**: a real scroll view would claim horizontal pans, but it replaces the slide transition, the Reduce Motion cross-fade and the one-month-at-a-time clamping that already work and are tested.

The pan recognizer exists only to claim the gesture. The month still changes through the existing `swipeGesture` and `onShowMonth` path, which keeps the animations, the picker behavior and VoiceOver untouched. The pan does not cancel touches and recognizes alongside the card's own recognizers, so vertical scrolling, taps and the wheels keep working; the month-change thresholds stay in `HistoryMonthNavigation.swipeOffset(forTranslation:)`.

The `#available` guard covers the iOS 26-only content-pop recognizer; on earlier systems only the left-edge recognizer exists, and the pan never claims touches there, so it has no effect on back navigation.

### Cover the whole card, not only the grid

The title row and the wheels are part of the card, so a right swipe there is absorbed and changes nothing, which keeps the rule simple: inside the card stays, outside the card goes back.

## Risks / Trade-offs

- [The cause is not what we think] → The reproduction task is the first gate; the proposal is reopened if it fails.
- [Relying on UIKit internals of how SwiftUI hosts the stack] → Look up the navigation controller from the view's responder chain at window time, retry on later layout passes, and do nothing while it is not found; a UI test covers the behavior so an OS change that breaks it is caught.
- [The pan recognizer steals touches from taps or scrolling] → It only begins for touches that started inside the card, does not cancel touches in view, recognizes simultaneously with the card's own recognizers, and is covered by existing day-tap and vertical-scroll UI tests.
- [The edge swipe from the screen's left edge conflicts with the card] → The card begins 16pt in from the screen edge, which is inside the system's edge-swipe zone, so the pan ignores touches in the left 24pt of the screen, which includes the card's outer 8pt; a UI test covers a drag from the screen edge.
