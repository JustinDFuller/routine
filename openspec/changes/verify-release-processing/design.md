## Context

See proposal.md for why this change exists.

- `make release` runs `Scripts/release-preflight.sh` (validate, build Release, archive, export) and then `Scripts/upload-ios.sh`, which calls `xcrun altool --upload-package` and exits as soon as App Store Connect accepts the upload.
- `altool` prints `Delivery UUID: <id>` on a successful upload and can report processing with `altool --build-status --delivery-id <id> --output-format json`. The JSON carries `app-store-attributes.processingState` (for example `VALID`) and `app-store-attributes.version`.
- Credentials reach the scripts through three variables: `APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, and `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID`. `routine_validate_app_store_connect_auth_key_trio` in `Scripts/xcode-destination-helpers.sh` requires all three together and a readable key path. The "iOS Release" workflow fills them from repository secrets.
- Script behavior is tested in `Scripts/test-ios-script-tests.sh` with fake binaries injected through variables such as `XCRUN_BIN`, and that suite runs as a stage of `./Scripts/validate.sh`.
- Agents run as the same macOS user as the maintainer, so any file the maintainer can read, an agent can read.
- The repository is public, so credentials must never be committed. `*.p8` and `/build/` are already git-ignored.

## Goals / Non-Goals

**Goals:**

- A finished release run is, by itself, proof of whether the build was processed.
- A local release asks the maintainer for approval once, and no agent can use the key without that approval.
- The CI path does not change except for the added wait, the delivery ID in the artifact, and the run summary.

**Non-Goals:**

- Submitting a build to TestFlight groups or App Review.
- Removing the loose `.p8` from disk. The maintainer does that after setup.
- Defending against malware that runs with the maintainer's own approval clicks.
- Any change to signing, provisioning, or the app.

## Decisions

### One Keychain item holds all three credentials

A generic-password item with service `routine.app-store-connect` and account `release` stores a single value: three lines holding the Key ID, the Issuer ID, and the base64-encoded `.p8`. The setup script writes it with `security add-generic-password -U -T ""`, which trusts no application, so every read prompts.

Why one item: a Keychain prompt is per item read. Splitting the credentials into three items would mean three prompts per release.

Alternatives:

- Three separate items. Rejected: three prompts.
- Only the `.p8` in the Keychain, with the Key ID and Issuer ID in a file. Rejected: it splits setup into two places for no security gain, since those two values are identifiers, not secrets.
- A plain file with restricted permissions. Rejected: agents share the macOS user, so permissions do not separate them.

### The loader only reads the Keychain when the variables are unset

`Scripts/app-store-connect-credentials.sh` is sourced by the scripts that need credentials. If all three variables are set, it does nothing, which is the CI path and keeps today's behavior. If none is set, it reads the Keychain item, writes the key to a `mktemp` file with mode `0600`, exports the three variables, and registers an `EXIT` trap that deletes the file. If only some are set, it leaves them alone so the existing validation reports that they must be set together.

The Keychain read uses `security find-generic-password -w`, and `SECURITY_BIN` can be overridden so tests use a fake. The loader then calls the existing `routine_validate_app_store_connect_auth_key_trio`.

Alternatives:

- Always prefer the Keychain. Rejected: it would break CI, which has no Keychain item.
- Have `altool` find the key under `~/.appstoreconnect/private_keys`. Rejected: that is the loose-file setup this change moves away from.

### A new release script loads credentials once

`Scripts/release.sh` loads credentials, then runs `release-preflight.sh`, `upload-ios.sh`, and `build-status.sh` in order, and the `Makefile` `release` target calls it. Because the exported variables are inherited by the child scripts, which then skip the Keychain, a local release prompts once. Each script still sources the loader so that running it on its own works.

The preflight stages do not need credentials, but loading first means a denied prompt fails the release before the slow archive, not after it.

Alternative: keep the two-line `make` recipe and let each script load credentials. Rejected: two prompts, and the denial would surface only after the archive.

### The delivery ID is saved by the upload step

`Scripts/upload-ios.sh` keeps its `altool` output, extracts `Delivery UUID: <id>`, and writes the ID to `build/export/delivery-id.txt`. If `altool` exits successfully but no ID is found, the script fails. `build/export` is already uploaded as the workflow artifact, so the ID ships with it without a workflow change.

Alternative: parse the delivery ID in the status script from the log. Rejected: a file is stable, and a person re-checking later needs it without the log.

### Status checks use JSON output and a bounded poll

`Scripts/build-status.sh <delivery-id>` calls `altool --build-status --output-format json` in a loop and reads `app-store-attributes.processingState` with `plutil`, which is on every macOS runner. The state `VALID` ends the loop with success. `FAILED` and `INVALID` end it with failure. Any other state, or a transient query error, waits and retries.

The interval and limit come from `ROUTINE_BUILD_STATUS_INTERVAL` (default 30 seconds) and `ROUTINE_BUILD_STATUS_TIMEOUT` (default 1800 seconds). On timeout the script fails and prints the exact `make build-status DELIVERY_ID=<id>` command to run later.

The script always ends with `Build <version> (delivery <id>) processing state: <state>`. When `GITHUB_STEP_SUMMARY` is set, it appends the same facts as a short table. The release script prints the final line last so it is the last line of the run log.

Alternatives:

- Query the App Store Connect REST API directly with a JWT. Rejected: it needs token signing code, while `altool` already authenticates with the same key.
- Fail on the first non-`VALID` state. Rejected: processing is normally a few minutes of `PROCESSING`.

### Agents confirm from CI output, not credentials

No new capability is given to agents. `gh run view <id> --log` shows the final line, and the artifact shows the delivery ID. The documentation tells agents to stop and ask when a Keychain prompt appears, because the maintainer is the only one who should click Allow.

### Testing uses the existing fake-binary harness

`Scripts/test-ios-script-tests.sh` gains a fake `xcrun` that replays scripted `altool` outputs and a fake `security` that returns a canned item. Cases cover: already `VALID`, `PROCESSING` then `VALID`, `FAILED`, `INVALID`, timeout with a short limit, UUID extraction, a missing UUID, a loader that skips the Keychain when variables are set, a loader that writes a `0600` key and removes it on both success and failure, a denied Keychain read, and the setup script refusing an unreadable key. Real Keychain behavior (the macOS prompt) cannot run in CI, so it is proved by hand and recorded in the PR.

## Risks / Trade-offs

- [Choosing "Always Allow" in the Keychain prompt would trust `security` for every caller, agents included] → The documentation says to click Allow only, and the setup script prints the same warning.
- [The temporary key file sits on disk for the length of a release] → It is `0600`, deleted by an `EXIT` trap on success and failure, and created under the scripts' temp directory. The window is minutes, and the loose `.p8` it replaces is permanent.
- [`altool` output formats can change, which would break UUID extraction or JSON parsing] → Both fail loudly with the raw output printed, and the tests pin the expected shapes.
- [A 30-minute wait adds CI minutes on the macOS runner] → Processing normally takes a few minutes, and the limit is configurable.
- [A denied or unanswered prompt blocks a local release] → The failure message says credentials were not provided, and CI remains available.
- [The maintainer must move the `.p8` by hand] → Documented as an explicit step. The change deliberately does not delete the loose file.

## Migration Plan

1. Merge the change. CI releases keep working unchanged and gain the wait and the summary.
2. The maintainer runs the setup script once, answers the prompt, and confirms a status check works.
3. The maintainer stores a backup of the `.p8` in a password manager, then deletes the loose file.

Rollback: revert the change. The Keychain item is harmless on its own and can be removed with `security delete-generic-password -s routine.app-store-connect`.

## Open Questions

None that change the specs or the task breakdown.
