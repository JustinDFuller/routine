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
| CI release | GitHub → Actions → "iOS Release" → Run workflow |

## Environment

Set once per shell session (see [SIGNING_AND_DEPLOY_SETUP.md](SIGNING_AND_DEPLOY_SETUP.md) for how to obtain these):

```sh
export DEVELOPMENT_TEAM=CX2KMQZQ7X
export APP_STORE_CONNECT_AUTH_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8
export APP_STORE_CONNECT_AUTH_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

`DEVELOPMENT_TEAM` defaults to `CX2KMQZQ7X` already; the App Store Connect variables are required together for uploads.

## Command Details

- `make build-ios` — builds for whatever generic simulator or device destination is available. Skips cleanly with no error if none is installed.
- `make run-ios` — builds and runs on a booted (or auto-selected) simulator.
- `make deploy-device` — builds and installs on a specific physical iPhone (hard-coded default UDID; set `IOS_DEVICE_ID` to target a different device) via `xcrun devicectl`, then launches the app. Verifies the device is actually reachable before building and **errors out (exit 1)** if it is not connected. Set `ROUTINE_DEPLOY_DEVICE_LAUNCH=0` to install without launching.
- `make release` — runs `release-preflight` (validate → build Release → archive → export) and then `upload-ios` (uploads `build/export/Routine.ipa` to App Store Connect via `xcrun altool`). Requires `CURRENT_PROJECT_VERSION` and the App Store Connect environment variables.
- `make release-preflight` — the archive/export half of `release`, without uploading. Useful to confirm a build is producible before spending an upload.
- `make upload-ios` — uploads an already-exported `build/export/Routine.ipa` on its own.

The same uploaded build serves both TestFlight and the App Store: TestFlight testers can use it automatically once App Store Connect finishes processing, and the App Store release is the manual metadata-review-and-submit step in the checklist above.

## Local vs. CI

Local `make` targets are the primary path. The "iOS Release" GitHub Actions workflow (`.github/workflows/ios-release.yml`) is a manual (`workflow_dispatch`-only) backup that runs the same `make release` command on `macos-15`, exports the Xcode path selected by `setup-xcode`, and reads the App Store Connect key and team from repository secrets. Prove a release locally (fresh paid-team install, then a TestFlight upload) before trusting CI to do the same, since CI reuses the same cloud-signing path.

## Dev-Assist Tooling (Not Part of Deploy)

[Axiom](https://github.com/CharlesWiltgen/Axiom) is a Claude Code skills/agents collection plus CLIs (`xclog`, `xcsym`, `xcui`, `xcprof`) for logging, crash symbolication, simulator UI-driving, and profiling. It does not build or ship the app, and it is not part of the commands above. It's optional and only useful for the local debug/verify loop.
