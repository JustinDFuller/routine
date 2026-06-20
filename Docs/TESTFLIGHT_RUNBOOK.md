# TestFlight Runbook

Use this runbook for the first internal beta. The widget ships in the same build as the app.

## Apple-Side Setup

Complete these once before the first archive:

- Confirm the Apple Developer team membership that will sign and upload the build.
- Register `com.justinfuller.routine` with App Groups enabled.
- Register `com.justinfuller.routine.widget` with App Groups enabled.
- Create `group.com.justinfuller.routine` and attach it to both bundle IDs.
- Create the App Store Connect app record for `com.justinfuller.routine`.

## Preflight

Before every upload:

- Pick the next unique `CURRENT_PROJECT_VERSION`.
- Run `CURRENT_PROJECT_VERSION=<n> make release-preflight`.
- Confirm `build/Routine.xcarchive` exists.
- Confirm `build/export/Routine.ipa` exists.
- Note any skipped lines emitted by `./Scripts/validate.sh` inside release preflight.

## Upload

Use Xcode Organizer as the canonical upload path for the first internal beta:

1. Open `Routine.xcodeproj` in Xcode with the correct signing account.
2. Choose the archived `RoutineApp` build in Organizer.
3. Distribute App.
4. Select App Store Connect.
5. Upload the build without changing the bundle IDs or App Group configuration.

## Internal Testing Setup

After upload:

- Wait for App Store Connect processing to finish.
- Add internal testers.
- Fill in the TestFlight "What to Test" field with the current focus areas: notification onboarding and scheduling, widget add/remove and completion, persistence across relaunch, and Home Screen/App Library icon verification.
- Share the build number and any known limitations with testers.

## Device QA

Run the full [DOGFOODING_CHECKLIST.md](DOGFOODING_CHECKLIST.md):

- On the primary personal iPhone.
- On at least one secondary internal TestFlight device.

Record:

- iOS version
- Device model
- Build number
- Any skipped steps
- Widget-specific failures
- Notification permission behavior

## Feedback Collection

Collect:

- App Store Connect TestFlight feedback
- Direct notes about notification timing/content
- Widget rendering or completion issues
- Any persistence or upgrade regressions after installing over an older build
