# routine

Routine is a personal iPhone app for tracking recurring habits and routines in a simple, visual way. The MVP is local-only: it uses on-device SwiftData storage and does not include networking, analytics, tracking, notifications, widgets, CloudKit, or remote logging.

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
- Run SwiftLint: `./Scripts/lint.sh` or `make lint`
- Run portable package tests: `./Scripts/test-core.sh` or `make test-core`
- Run script-level destination-resolution tests: `./Scripts/test-ios-script-tests.sh` or `make test-scripts`
- Build the app for a generic iOS destination when available: `./Scripts/build-ios.sh` or `make build-ios`
- Build the Release configuration: `ROUTINE_BUILD_CONFIGURATION=Release ./Scripts/build-ios.sh`
- Override local development signing when building for a personal device: `DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/build-ios.sh`
- Run iOS tests with an explicit destination: `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17' ./Scripts/test-ios.sh` or `IOS_TEST_DESTINATION='platform=iOS Simulator,name=iPhone 17' make test-ios`
- Run the full local validation chain: `./Scripts/validate.sh` or `make validate`

`Scripts/build-ios.sh` defaults to `Debug`. Set `ROUTINE_BUILD_CONFIGURATION=Release` to validate the Release path. Set `DEVELOPMENT_TEAM` only in your local shell when Xcode needs a team for device signing; do not commit signing credentials.

`Scripts/test-ios.sh` accepts `IOS_TEST_DESTINATION`. If that variable is unset, the script tries to choose a concrete simulator automatically and exits with a documented skip message when no eligible simulator destination exists.

`Scripts/build-ios.sh` and `Scripts/test-ios.sh` intentionally preserve skip behavior when the local machine has no eligible simulator or device destination available.

## Dogfooding Checklist

Use [Docs/DOGFOODING_CHECKLIST.md](Docs/DOGFOODING_CHECKLIST.md) for the manual MVP acceptance pass before relying on the app locally.

## Local iPhone Deployment

1. Generate the project with `./Scripts/generate-project.sh`.
2. Open `Routine.xcodeproj` in Xcode.
3. Select the `RoutineApp` scheme and your connected iPhone.
4. If Xcode requires a team, set your signing team locally in Xcode or validate the CLI build with `DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/build-ios.sh`.
5. Build and run from Xcode.
6. Confirm the launcher icon appears on the Home Screen and in the App Library.
7. Walk through the dogfooding checklist on the device. If no personal iPhone is available, run the same checks in Simulator and record the skipped physical-device items.

## Privacy Posture

Routine is local-only for the MVP. `RoutineApp/PrivacyInfo.xcprivacy` declares no tracking and no collected data, which matches the current app architecture.

## Implementation Workflow

Each implementation session should:

1. Read [AGENTS.md](AGENTS.md), [PROJECT_DESIGN.md](PROJECT_DESIGN.md), and the four source specs.
2. Work only on the milestone marked `CURRENT` in [PROJECT_DESIGN.md](PROJECT_DESIGN.md).
3. Update [PROJECT_DESIGN.md](PROJECT_DESIGN.md) when the milestone is complete.
4. Commit, push, open a pull request, and stop.
