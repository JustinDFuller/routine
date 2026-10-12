# Proposal

## Why

Releasing build 4 showed that "the release succeeded" is not provable from the release run. The "iOS Release" workflow reports success as soon as App Store Connect accepts the upload, but the build is only usable in TestFlight after Apple finishes processing it. Checking that took a manual `altool --build-status` call with the App Store Connect API key, which the agent on this machine did not have.

Local credentials are also stored in a way that does not separate them from agents. The API key is a loose `.p8` file under `~/.appstoreconnect/private_keys`, and agents run as the same macOS user, so any agent can read it. Plain file permissions cannot change that.

## What Changes

- `make release` and the "iOS Release" workflow wait for App Store Connect to finish processing the uploaded build. They fail if processing ends in a failed or invalid state or does not finish within a time limit, and they end with a clear line stating the build number, the delivery ID, and the processing state.
- The upload step records the delivery ID that Apple returns, and the release fails if an upload that reports success returns none. The release artifact includes the delivery ID, so anyone can re-check the build later.
- A standalone build-status command checks the processing state of any delivery ID.
- The CI run writes the same result to the GitHub run summary, so a release can be confirmed from the run alone, without App Store Connect credentials. Agents confirm releases this way and do not hold credentials.
- Local App Store Connect credentials (Key ID, Issuer ID, and the `.p8` key) are stored in the macOS login Keychain in an item that no application is trusted to read silently, so every use triggers a macOS approval prompt. The release scripts read them from the Keychain when the usual environment variables are not already set. CI keeps supplying them through repository secrets, unchanged.
- A one-time setup script stores the credentials in the Keychain. A local release asks for approval once.
- The setup and release documentation describe the Keychain setup, the new wait-for-processing behavior, how to confirm a CI release from its log, and how agents are expected to handle credentials.
- No change to the app, to signing, to the archive/export steps, or to the existing environment-variable interface (`APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID`), which still takes precedence when set.

## Capabilities

### New Capabilities

- `release-pipeline`: How a Routine release is built and uploaded, how the pipeline confirms App Store Connect processed the build, and how App Store Connect credentials are stored and supplied to the release scripts.

### Modified Capabilities

None. `openspec/specs/` has only `routine-availability`, which is unrelated.

## Impact

- Scripts: `Scripts/upload-ios.sh` (capture the delivery ID), `Makefile` (`release` target and a new `build-status` target), plus new scripts for the release sequence, the build-status check, and Keychain credential loading and storing. Script tests in `Scripts/test-ios-script-tests.sh`.
- CI: `.github/workflows/ios-release.yml` picks up the new wait automatically because it already runs `make release`. The uploaded artifact now includes the delivery ID, and the job writes a run summary. No new secrets.
- Docs: `Docs/SIGNING_AND_DEPLOY_SETUP.md`, `Docs/BUILD_AND_DEPLOY.md`, and `PROJECT_DESIGN.md` (new milestone entry).
- Operator action outside the repo: after setup, move the existing `.p8` into the Keychain and keep a backup in a password manager; the change does not delete the loose file.
- Not affected: the app and widget code, signing and provisioning, `release-preflight.sh` stages, App Store submission (still manual in App Store Connect).
