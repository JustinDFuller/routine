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

A small `UIViewRepresentable` is placed behind the calendar card. When it joins the window it finds the enclosing `UINavigationController`, adds a `UIPanGestureRecognizer` to the card's host view that only begins for mostly horizontal movement, and calls `require(toFail:)` on the navigation controller's content-pop and edge-pop recognizers so they wait for that pan to fail. A pan that begins inside the card is therefore never also seen as a back swipe. When the view leaves the window it removes the recognizer and the dependencies.

Why this over the alternatives:
- **Hide the back swipe on the whole screen** (`navigationBarBackButtonHidden` plus disabling the pop recognizers): loses the swipe back everywhere on the screen, which the user wants kept outside the card.
- **Replace `.simultaneousGesture` with `.highPriorityGesture`**: only affects SwiftUI's own gesture arbitration; the UIKit pop recognizer is still free to begin.
- **Use iOS 18's `UIGestureRecognizerRepresentable`**: cleaner, but the deployment target is iOS 17.
- **Make the calendar a horizontal paging `TabView` or `ScrollView`**: a real scroll view would claim horizontal pans, but it replaces the slide transition, the Reduce Motion cross-fade and the one-month-at-a-time clamping that already work and are tested.

The pan recognizer exists only to claim the gesture. The month still changes through the existing `swipeGesture` and `onShowMonth` path, which keeps the animations, the picker behavior and VoiceOver untouched. The recognizer's begin check reuses the thresholds in `HistoryMonthNavigation.swipeOffset(forTranslation:)` semantics (mostly horizontal) so a mostly vertical drag still scrolls.

The `#available` guard covers the iOS 26-only content-pop recognizer; on earlier systems only the left-edge recognizer exists, and the card does not reach the screen edge, so nothing needs claiming there.

### Cover the whole card, not only the grid

The title row and the wheels are part of the card, so a right swipe there is absorbed and changes nothing, which keeps the rule simple: inside the card stays, outside the card goes back.

## Risks / Trade-offs

- [The cause is not what we think] → The reproduction task is the first gate; the proposal is reopened if it fails.
- [Relying on UIKit internals of how SwiftUI hosts the stack] → Look up the navigation controller from the view's responder chain at window time and do nothing if it is not found; a UI test covers the behavior so an OS change that breaks it is caught.
- [The pan recognizer steals touches from taps or scrolling] → It begins only for mostly horizontal movement, does not cancel touches in view, and is covered by existing day-tap and vertical-scroll UI tests.
- [The edge swipe from the screen's left edge conflicts with the card] → The card has 16pt horizontal screen padding plus its own padding, so the left screen edge is outside the card; a UI test covers it.
