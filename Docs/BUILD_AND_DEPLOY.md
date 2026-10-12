# Build and Deploy

Routine is built, run, and shipped entirely from the command line — no Xcode GUI required. Complete [SIGNING_AND_DEPLOY_SETUP.md](SIGNING_AND_DEPLOY_SETUP.md) once before your first device build or release upload.

## Command Index

| Goal | Command |
|---|---|
| Build locally | `make build-ios` |
| Run in the simulator | `make run-ios` |
| Deploy to my phone | `make deploy-device` |
| Deploy to TestFlight | `CURRENT_PROJECT_VERSION=<n> make release` |
| Deploy for real (App Store) | `make release`, then finish in App Store Connect ([checklist](APP_STORE_SUBMISSION_CHECKLIST.md)) |
| Check processing of an uploaded build | `make build-status DELIVERY_ID=<id>` |
| CI release | GitHub → Actions → "iOS Release" → Run workflow |

## Credentials

Local releases read the App Store Connect credentials from the macOS Keychain, with a prompt each time (see [SIGNING_AND_DEPLOY_SETUP.md](SIGNING_AND_DEPLOY_SETUP.md#local-credentials-in-the-keychain) for the one-time setup). Setting `APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, and `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID` together in the environment overrides the Keychain, which is how CI supplies them.

`DEVELOPMENT_TEAM` defaults to `CX2KMQZQ7X` already.

## Command Details

- `make build-ios` — builds for whatever generic simulator or device destination is available. Skips cleanly with no error if none is installed.
- `make run-ios` — builds and runs on a booted (or auto-selected) simulator.
- `make deploy-device` — builds and installs on a specific physical iPhone (hard-coded default UDID; set `IOS_DEVICE_ID` to target a different device) via `xcrun devicectl`, then launches the app. Verifies the device is actually reachable before building and **errors out (exit 1)** if it is not connected. Set `ROUTINE_DEPLOY_DEVICE_LAUNCH=0` to install without launching.
- `make release` — runs `release-preflight` (validate → build Release → archive → export), then `upload-ios` (uploads `build/export/Routine.ipa` to App Store Connect via `xcrun altool` and saves the delivery ID to `build/export/delivery-id.txt`), then waits for App Store Connect to finish processing the build. Requires `CURRENT_PROJECT_VERSION` and the App Store Connect credentials. It polls every 30 seconds for up to 30 minutes (`ROUTINE_BUILD_STATUS_INTERVAL` and `ROUTINE_BUILD_STATUS_TIMEOUT` override these) and exits non-zero if processing fails or times out. The last line it prints is `Build <version> (delivery <id>) processing state: <state>`.
- `make build-status DELIVERY_ID=<id>` — checks processing for an already uploaded build, using the ID from `build/export/delivery-id.txt` or the upload output. It prints the same final line. After a timeout, run it again later to keep waiting.
- `make release-preflight` — the archive/export half of `release`, without uploading. Useful to confirm a build is producible before spending an upload.
- `make upload-ios` — uploads an already-exported `build/export/Routine.ipa` on its own and saves the delivery ID to `build/export/delivery-id.txt`. It does not wait for processing; use `make build-status` for that.

The same uploaded build serves both TestFlight and the App Store: TestFlight testers can use it automatically once App Store Connect finishes processing, and the App Store release is the manual metadata-review-and-submit step in the checklist above.

## Local vs. CI

Local `make` targets are the primary path. The "iOS Release" GitHub Actions workflow (`.github/workflows/ios-release.yml`) is a manual (`workflow_dispatch`-only) backup that runs the same `make release` command on the `xcode-27` runner image, exports the Xcode path selected by `setup-xcode`, skips the simulator UI tests with `ROUTINE_SKIP_UI_TESTS=1` (GitHub's hosted simulators were unreliable for them; local `make release` runs the full suite), and reads the App Store Connect key and team from repository secrets, so it never touches the Keychain. Prove a release locally (fresh paid-team install, then a TestFlight upload) before trusting CI to do the same, since CI reuses the same cloud-signing path.

## Confirming a Release

A green "iOS Release" run means Apple finished processing the build, not only that the upload was accepted, because `make release` waits for the result. To confirm one without any credentials:

- Open the run log and read the last line of the "Release" step: `Build <version> (delivery <id>) processing state: VALID`. From a terminal, `gh run view <run-id> --log` shows the same line.
- Open the run summary, which has an "App Store Connect processing" table with the build number, delivery ID, and processing state.
- Download the `build/export` artifact, whose `delivery-id.txt` holds the delivery ID.

A state of `FAILED` or `INVALID`, or a timeout, fails the run. After a timeout, `make build-status DELIVERY_ID=<id>` keeps waiting.

## Dev-Assist Tooling (Not Part of Deploy)

[Axiom](https://github.com/CharlesWiltgen/Axiom) is a Claude Code skills/agents collection plus CLIs (`xclog`, `xcsym`, `xcui`, `xcprof`) for logging, crash symbolication, simulator UI-driving, and profiling. It does not build or ship the app, and it is not part of the commands above. It's optional and only useful for the local debug/verify loop.
