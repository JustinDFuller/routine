# QA notes

## Reproduction (task 1.1)

Run on the "Routine iPhone 17" iOS 26.5 simulator, driven through Device Hub with real mouse input (a scripted left-button press, 30 incremental drag events over 0.4 seconds, release) from the left third to the right third of the day grid.

Fixture: `-routine-fixed-date 2026-06-10 -routine-use-in-memory-store -routine-screenshot-fixture full-app -routine-open-morning-yoga-history-with-completion`, with completions on Jun 8, 9 and 10.

- Run 1: drag 1 showed May 2026, drag 2 showed April 2026, drag 3 left History for the home screen.
- Run 2 (recorded): History left for the home screen on drag 2, while the grid was still on May 2026.

The failing drag is not tied to the data: the oldest completion is in June 2026, and the jump home happened on the second or third drag, in months with no completions. The XCUITest `press(forDuration:thenDragTo:)` drags, slow drags and edge-start drags did not reproduce it in eight attempts each, so only real pointer input exposes the competing system back swipe.

Conclusion: the suspected cause holds. A right swipe on the grid is sometimes taken by the system back swipe instead of the calendar, so the proposal proceeds unchanged.

Recording of the failure before the fix: [before-fix-jumps-home.mp4](qa/before-fix-jumps-home.mp4). Three real drags on the grid leave History for the home screen on the second one.

## After the fix (task 5.2)

Same simulator, same fixture, same real mouse input, with the fix installed.

- [after-fix-twelve-swipes.mp4](qa/after-fix-twelve-swipes.mp4): twelve right drags on the grid. History stays open every time and the title steps back one month per drag, from June 2026 to June 2025.
- [after-fix-scenarios.mp4](qa/after-fix-scenarios.mp4), in order:
  1. Three left drags on the current month: History stays open and the month stays June 2026.
  2. Two right drags on the title row: History stays open and the month stays June 2026.
  3. A vertical drag up over the grid: the page scrolls and shows the recent completions, and the month does not change. A drag back down returns it.
  4. A click on Jun 9: the confirmation popover opens ([day-tap-popover.png](qa/day-tap-popover.png)), and a click outside dismisses it.
  5. A right drag on the recent completions section: the app goes back to the home screen ([swipe-below-calendar-goes-home.png](qa/swipe-below-calendar-goes-home.png)).

The wheels-open and left-screen-edge cases are covered by the UI tests `testHistoryRightDragsWithWheelsOpenStayInHistoryWithoutChangingMonth` and `testHistoryRightDragFromLeftScreenEdgeGoesBackToHome`, which pass in the full UI suite (50 tests).

Two earlier versions of the claiming pan were checked the same way before the final one. Deciding from the pan's translation at begin time let the month change on only 6 to 9 of 12 drags. Deciding from velocity brought it back to one month per drag, but a review pointed out that any direction test can let a jittery start hand the touch back to the system back swipe. The final version therefore begins for every touch that starts inside the card, below the navigation bar and outside the 24pt back-edge strip, and the recordings above are from that version.

The scripted mouse is not perfectly repeatable. Some runs while another app held the display stepped back fewer than twelve months, but History never closed in any run with the fix.

The new UI tests do not fail without the fix, because XCUITest drags never reproduced the failure; they guard the specified behavior, and the recordings above are the proof the fix works.
