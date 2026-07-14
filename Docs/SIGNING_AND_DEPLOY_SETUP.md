# Signing and Deploy Setup

One-time, human-only setup for building, running, and shipping Routine entirely from the command line, with no Xcode GUI required. Complete this once per machine (local steps) and once per repository (GitHub secrets).

## First Launch

- Accept the Xcode license: `sudo xcodebuild -license accept`
- Run first-launch package installation: `sudo xcodebuild -runFirstLaunch`

## App Store Connect API Key

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API.
2. Create a new key with the **App Manager** role.
3. Download the `.p8` file. Apple only lets you download it once.
4. Record the **Key ID** and **Issuer ID** shown next to the key.
5. Store the `.p8` outside the repository, e.g. `~/.appstoreconnect/private_keys/AuthKey_XXXX.p8`. `*.p8` is already git-ignored, but keeping it outside the repo entirely avoids any risk of committing it.

## Apple Distribution Certificate

With `CODE_SIGN_STYLE=Automatic`, `-allowProvisioningUpdates`, and the App Store Connect API key, `xcodebuild archive` will create and download a cloud-managed Apple Distribution certificate automatically on the first archive that needs one. No manual certificate creation is required.

Fallback, if cloud creation is ever unavailable: create an *Apple Distribution* certificate manually on the [Apple Developer portal](https://developer.apple.com/account/resources/certificates/list) under Certificates, Identifiers & Profiles.

## App Records and IDs

This is one-time Apple Developer / App Store Connect website setup, already documented in [TESTFLIGHT_RUNBOOK.md](TESTFLIGHT_RUNBOOK.md#apple-side-setup):

- Register `com.justinfuller.routine` with App Groups enabled.
- Register `com.justinfuller.routine.widget` with App Groups enabled.
- Create `group.com.justinfuller.routines` and attach it to both bundle IDs.
- Create the App Store Connect app record for `com.justinfuller.routine`.

## Local Environment for Release Scripts

Export these in your shell before running `archive-ios.sh`, `export-ios.sh`, `upload-ios.sh`, `deploy-device.sh`, or `release-preflight.sh`/`release`:

```sh
export DEVELOPMENT_TEAM=CX2KMQZQ7X
export APP_STORE_CONNECT_AUTH_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8
export APP_STORE_CONNECT_AUTH_KEY_ID=XXXXXXXXXX
export APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

`DEVELOPMENT_TEAM` already defaults to `CX2KMQZQ7X` inside `archive-ios.sh`, `export-ios.sh`, and `deploy-device.sh`; only export it if you need to override the default. The App Store Connect variables are required together for `upload-ios.sh` and optional (but recommended for headless use) for `archive-ios.sh`/`export-ios.sh`.

## Device Registration for On-Phone Installs

1. Connect the iPhone via USB (or set up Wi-Fi debugging), and trust the Mac on the device when prompted.
2. `-allowProvisioningUpdates` automatically registers the device's UDID with the team on the first device build — no manual portal step needed.
3. Run `make deploy-device` to build, install, and launch on the connected phone.

## Required GitHub Secrets

Set these on the repository before running the "iOS Release" GitHub Actions workflow (Settings → Secrets and variables → Actions):

| Secret | Value |
|---|---|
| `APP_STORE_CONNECT_AUTH_KEY` | The `.p8` key contents (raw or base64-encoded) |
| `APP_STORE_CONNECT_AUTH_KEY_ID` | The Key ID from App Store Connect |
| `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID` | The Issuer ID from App Store Connect |
| `DEVELOPMENT_TEAM` | `CX2KMQZQ7X` |

See [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md) for the full command index once setup is complete.
