# routine

Routine is a personal iPhone app for tracking recurring habits and routines in a simple, visual way. The MVP is local-only: it uses on-device SwiftData storage and does not include networking, analytics, tracking, CloudKit, or remote logging. It does include local, non-spammy daily check-in notifications (morning/afternoon/evening) backed by `UNUserNotificationCenter` — no per-routine reminders.

The product and system have been scoped in the planning documents below. Implementation should now follow [PROJECT_DESIGN.md](PROJECT_DESIGN.md), which breaks the MVP into dependency-ordered milestones and marks the current step.

## References

- [PROJECT_DESIGN.md](PROJECT_DESIGN.md)
- [PRODUCT_BRIEF.md](PRODUCT_BRIEF.md)
- [VISUAL_DESIGN.md](VISUAL_DESIGN.md)
- [DATA_DESIGN.md](DATA_DESIGN.md)
- [SYSTEM_DESIGN.md](SYSTEM_DESIGN.md)

## Prerequisites

- Xcode 26.5 or a compatible Xcode with iOS 17+ SDK support
- `xcodegen`
- `swift-format`
- `swiftlint`
- A booted iOS simulator runtime or connected iPhone if you want to run iOS tests instead of using the built-in skip path

## Project Setup

Generate the Xcode project before opening the app in Xcode:

- `./Scripts/generate-project.sh`
- `make generate`

Open `Routine.xcodeproj` in Xcode, select the `RoutineApp` scheme, and choose either an iPhone simulator or your connected iPhone.

## Local Commands

Use the scripts directly or the matching `make` targets:

- Format Swift sources: `./Scripts/format.sh` or `make format`
- Check formatting: `./Scripts/check-format.sh` or `make check-format`
- Regenerate launcher icons: `swift Scripts/generate-app-icons.swift` or `make app-icons`
- Run SwiftLint: `./Scripts/lint.sh` or `make lint`
- Run portable package tests: `./Scripts/test-core.sh` or `make test-core`
- Run script-level destination-resolution tests: `./Scripts/test-ios-script-tests.sh` or `make test-scripts`
- Build the app for a generic iOS destination when available: `./Scripts/build-ios.sh` or `make build-ios`
- Build the Release configuration: `ROUTINE_BUILD_CONFIGURATION=Release ./Scripts/build-ios.sh`
- Override local development signing when building for a personal device: `DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/build-ios.sh`
- Archive a Release build for distribution: `CURRENT_PROJECT_VERSION=2 ./Scripts/archive-ios.sh` or `CURRENT_PROJECT_VERSION=2 make archive-ios`
- Export an `.ipa` from the most recent archive: `./Scripts/export-ios.sh` or `make export-ios`
- Run the full release preflight before an internal beta upload: `CURRENT_PROJECT_VERSION=2 ./Scripts/release-preflight.sh` or `CURRENT_PROJECT_VERSION=2 make release-preflight`
- Deploy to a connected physical iPhone: `./Scripts/deploy-device.sh` or `make deploy-device`
- Upload an exported `.ipa` to App Store Connect: `./Scripts/upload-ios.sh` or `make upload-ios`
- Preflight and upload in one step: `CURRENT_PROJECT_VERSION=2 make release`
- Run iOS tests with an explicit destination: `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17' ./Scripts/test-ios.sh` or `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17' make test-ios`
- Run the full local validation chain: `./Scripts/validate.sh` or `make validate`

`Scripts/lint.sh` runs SwiftLint in strict mode against the committed `.swiftlint.yml`. The repo intentionally disables `file_length`, `function_body_length`, and `type_body_length` there; do not recreate task-local exceptions or alternate lint configs to work around other violations.

`Scripts/build-ios.sh` defaults to `Debug`. Set `ROUTINE_BUILD_CONFIGURATION=Release` to validate the Release path. Set `DEVELOPMENT_TEAM` only in your local shell when Xcode needs a team for device signing; do not commit signing credentials.

`Scripts/test-ios.sh` accepts `IOS_TEST_DESTINATION`. If that variable is unset, the script tries to choose a concrete simulator automatically and exits with a documented skip message when no eligible simulator destination exists.

`Scripts/build-ios.sh` and `Scripts/test-ios.sh` intentionally preserve skip behavior when the local machine has no eligible simulator or device destination available.

`Scripts/archive-ios.sh`, `make archive-ios`, and release preflight require an explicit `CURRENT_PROJECT_VERSION`; `Scripts/export-ios.sh` and `make export-ios` only require an existing archive. `Scripts/archive-ios.sh` and `Scripts/export-ios.sh` default `DEVELOPMENT_TEAM` to the current Routine team for local convenience, but still allow per-shell overrides. Both scripts pass `-allowProvisioningUpdates` so automatic signing can create or refresh distribution assets when Xcode is signed into the correct Apple Developer account. For headless use, set `APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, and `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID` together to let `xcodebuild` authenticate with an App Store Connect API key during archive/export.

## Dogfooding Checklist

Use [Docs/DOGFOODING_CHECKLIST.md](Docs/DOGFOODING_CHECKLIST.md) for the manual MVP acceptance pass before relying on the app locally.

## Release Docs

- Command index for building, running, and shipping without Xcode: [Docs/BUILD_AND_DEPLOY.md](Docs/BUILD_AND_DEPLOY.md)
- One-time signing and deploy setup: [Docs/SIGNING_AND_DEPLOY_SETUP.md](Docs/SIGNING_AND_DEPLOY_SETUP.md)
- Internal beta workflow: [Docs/TESTFLIGHT_RUNBOOK.md](Docs/TESTFLIGHT_RUNBOOK.md)
- Public App Store follow-up: [Docs/APP_STORE_SUBMISSION_CHECKLIST.md](Docs/APP_STORE_SUBMISSION_CHECKLIST.md)

## Local iPhone Deployment

Complete the one-time setup in [Docs/SIGNING_AND_DEPLOY_SETUP.md](Docs/SIGNING_AND_DEPLOY_SETUP.md), then:

1. Connect your iPhone via USB (or Wi-Fi debugging) and trust the Mac if prompted.
2. Run `make deploy-device`. This generates the project, builds for the connected device, installs it via `xcrun devicectl`, and launches it — no Xcode GUI required.
3. Confirm the launcher icon appears on the Home Screen and in the App Library.
4. Walk through the dogfooding checklist on the device. If no personal iPhone is available, run the same checks in Simulator and record the skipped physical-device items.

## TestFlight Distribution

Before the first archive, complete the Apple-side setup:

1. Enroll the Apple Developer membership for the team you plan to use.
2. Register the app bundle ID `com.justinfuller.routine` with App Groups enabled.
3. Register the widget bundle ID `com.justinfuller.routine.widget` with App Groups enabled.
4. Create the App Group `group.com.justinfuller.routine` and attach it to both bundle IDs.
5. Create the App Store Connect app record for the iOS app bundle ID.
6. Create an App Store Connect API key and export the auth-key environment variables, per [Docs/SIGNING_AND_DEPLOY_SETUP.md](Docs/SIGNING_AND_DEPLOY_SETUP.md).

Then build and upload with the next build number:

1. Pick the next unique `CURRENT_PROJECT_VERSION`.
2. Run `CURRENT_PROJECT_VERSION=2 make release`. This runs preflight (validate → build Release → archive → export) and then uploads `build/export/Routine.ipa` to App Store Connect headlessly via `xcrun altool`.

The full operator checklist lives in [Docs/TESTFLIGHT_RUNBOOK.md](Docs/TESTFLIGHT_RUNBOOK.md).

Notes:

- `MARKETING_VERSION` is set to `1.0.0` for the first real release train.
- Every TestFlight upload must use a unique, increasing `CURRENT_PROJECT_VERSION`.
- `RoutineApp/Info.plist` sets `ITSAppUsesNonExemptEncryption` to `false`, which matches the app’s local-only feature set and avoids the per-build export-compliance prompt for non-exempt encryption.
- The widget is part of the same first-ship internal beta and must stay provisioned with the same App Group as the app target.

## Privacy Posture

Routine is local-only for the MVP. The app and widget privacy manifests declare no tracking, no collected data, and only the required-reason API usage needed for local `UserDefaults` storage.

## Implementation Workflow

Each implementation session should:

1. Read [AGENTS.md](AGENTS.md), [PROJECT_DESIGN.md](PROJECT_DESIGN.md), and the four source specs.
2. Work only on the milestone marked `CURRENT` in [PROJECT_DESIGN.md](PROJECT_DESIGN.md).
3. Update [PROJECT_DESIGN.md](PROJECT_DESIGN.md) when the milestone is complete.
4. Commit, push, open a pull request, and stop.
