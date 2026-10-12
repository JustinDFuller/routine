# Signing and Deploy Setup

One-time, human-only setup for building, running, and shipping Routine entirely from the command line, with no Xcode GUI required. Complete this once per machine (local steps) and once per repository (GitHub secrets).

## First Launch

- Accept the Xcode license: `sudo xcodebuild -license accept`
- Run first-launch package installation: `sudo xcodebuild -runFirstLaunch`

## App Store Connect API Key

1. Sign in to [App Store Connect](https://appstoreconnect.apple.com) → Users and Access → Integrations → App Store Connect API.
2. Create a new key with the **Admin** role. Apple's cloud-managed signing (`-allowProvisioningUpdates` creating a new Distribution certificate) requires an Admin-role key; a lesser role such as App Manager fails with `Cloud signing permission error` / `403 FORBIDDEN_ERROR` on the first archive that needs a new certificate. A key's role can't be changed after creation — if you have a non-Admin key already, create a new one.
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

This release changes the App Group identifier from `group.com.justinfuller.routine` to `group.com.justinfuller.routines`. Before the first archive, verify that the signing team owns the new App Group and can still access the old one if existing development data must be preserved. If the old group belongs only to the Personal Team, treat the paid-team build as a fresh data store and record that limitation in the release notes.

## Beta Xcode

If a beta Xcode is installed and set as the active `xcode-select` toolchain (common if you're running beta seeds day-to-day), builds made with it are rejected by App Store Connect: `altool` fails with `Unsupported SDK or Xcode version` (error 90534), even after a successful archive/export. `archive-ios.sh`, `export-ios.sh`, and `upload-ios.sh` default `DEVELOPER_DIR` to `/Applications/Xcode.app/Contents/Developer` (the release Xcode) regardless of the system default, so this is handled automatically — no need to switch `xcode-select` or set `DEVELOPER_DIR` yourself unless the release Xcode lives somewhere else on this machine.

## Local Credentials in the Keychain

The release scripts that talk to App Store Connect (`release.sh`, `upload-ios.sh`, and `build-status.sh`) read the App Store Connect credentials from one macOS Keychain item, so nothing secret sits in your shell profile or in a loose file that any process running as you can read.

Store them once, after you have the `.p8`, Key ID, and Issuer ID from the section above:

```sh
./Scripts/store-app-store-connect-credentials.sh XXXXXXXXXX xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ~/.appstoreconnect/private_keys/AuthKey_XXXX.p8
```

The item is created in your login Keychain as service `routine.app-store-connect`, account `release`, with no trusted applications. macOS therefore shows a prompt every time the item is read, which is once per `make release`, `make build-status`, or `make upload-ios` run. Running the setup command again replaces the item, so any earlier "Always Allow" is cleared. The key is written to a private temporary file (mode `0600`) for the length of the command and removed when the command ends, whether it succeeds or fails.

Click **Allow** on the prompt. Never click **Always Allow**: that would trust `security` to read the item silently, for every caller including agents.

After storing the item:

1. Keep a backup of the `.p8` in your password manager. Apple only lets you download it once, and the Keychain item is not a backup.
2. Delete the loose `.p8` from `~/.appstoreconnect/private_keys` yourself once the backup is safe. The scripts never delete it for you.

If `APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, and `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID` are already set in the environment, the scripts use them and never touch the Keychain. This is how CI works, with the values coming from repository secrets. Set only some of them and the scripts fail with a "must be set together" error. If you set up credentials with the older `export APP_STORE_CONNECT_AUTH_KEY_*` lines in your shell profile, remove them: they take precedence over the Keychain, so the loose `.p8` would keep being used without a prompt.

`DEVELOPMENT_TEAM` already defaults to `CX2KMQZQ7X` inside `archive-ios.sh`, `export-ios.sh`, and `deploy-device.sh`; only export it if you need to override the default. The App Store Connect credentials are required together for `upload-ios.sh` and `build-status.sh`, and optional (but recommended for headless use) for `archive-ios.sh`/`export-ios.sh`. When all three are supplied, the scripts fail before invoking Xcode if the key path is unreadable.

### Agents and credentials

Agents run as your macOS user, so a `.p8` on disk is readable by them. The Keychain item prompts you on every read, which means an agent cannot use the key unless you approve it, and you can deny it. Agents hold no App Store Connect credentials. To confirm a release, they read the final line of the "iOS Release" run log, the run summary, or the `delivery-id.txt` file in the `build/export` artifact (see [BUILD_AND_DEPLOY.md](BUILD_AND_DEPLOY.md#confirming-a-release)). If an agent runs a local status check, you will see the Keychain prompt and can click Deny.

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
