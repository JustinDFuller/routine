# Tasks

## 1. Keychain credentials

- [ ] 1.1 Add `Scripts/app-store-connect-credentials.sh` with the loader (env vars win, then Keychain item `routine.app-store-connect`, `0600` temp key removed by an `EXIT` trap, `SECURITY_BIN` override, existing trio validation afterwards) and verify with new cases in `Scripts/test-ios-script-tests.sh` for: variables set means no Keychain call, Keychain loads all three, temp key is `0600`, temp key removed after success and after failure, denied read fails with a "credentials were not provided" message, partially set variables fail with the existing "set together" message.
- [ ] 1.2 Add `Scripts/store-app-store-connect-credentials.sh` (Key ID, Issuer ID, key path; creates or updates the item with `-T ""`; prints the "click Allow, never Always Allow" warning) and verify with test cases for a successful store, an unreadable key file leaving the item unchanged, and missing arguments.
- [ ] 1.3 Document the Keychain setup in `Docs/SIGNING_AND_DEPLOY_SETUP.md` (replace the "Local Environment for Release Scripts" export block, add the password-manager backup step, the manual step of removing the loose `.p8`, and an "Agents and credentials" note) and verify every command in it runs as written against the new scripts.

## 2. Delivery ID and processing check

- [ ] 2.1 Change `Scripts/upload-ios.sh` to load credentials through the loader, capture `Delivery UUID:` from the `altool` output, write it to `build/export/delivery-id.txt`, and fail when an accepted upload has no UUID; verify with test cases for UUID extraction, the written file, and the missing-UUID failure.
- [ ] 2.2 Add `Scripts/build-status.sh <delivery-id>` (JSON poll, `VALID` succeeds, `FAILED` and `INVALID` fail, `ROUTINE_BUILD_STATUS_INTERVAL` and `ROUTINE_BUILD_STATUS_TIMEOUT` with 30 s and 1800 s defaults, final `Build <version> (delivery <id>) processing state: <state>` line, re-check command on timeout, `GITHUB_STEP_SUMMARY` table when set, clear failure when the delivery ID is missing) and verify with test cases for already `VALID`, `PROCESSING` then `VALID`, `FAILED`, `INVALID`, timeout, missing delivery ID, and summary output.
- [ ] 2.3 Add `Scripts/release.sh` that loads credentials once, then runs `release-preflight.sh`, `upload-ios.sh`, and `build-status.sh`, and make the `Makefile` `release` target call it and add a `build-status` target taking `DELIVERY_ID`; verify with test cases that a release loads the Keychain once, a failing status check fails the release, and the final outcome line is the last release line, and that `make -n release` and `make -n build-status DELIVERY_ID=x` show the expected commands.

## 3. CI and docs

- [ ] 3.1 Confirm `.github/workflows/ios-release.yml` needs no new secrets, still uploads `build/export` (now containing `delivery-id.txt`), and still sets the three credential variables so the loader skips the Keychain; verify by reading the workflow and by a script test that runs `release.sh` with the three variables set and asserts no `security` call.
- [ ] 3.2 Update `Docs/BUILD_AND_DEPLOY.md` (`make release` waits for processing, `make build-status` in the command index, how to confirm a CI release from the final log line, the run summary, and `delivery-id.txt`) and verify each documented command and log line matches actual output.
- [ ] 3.3 Add milestone M24 for this work to `PROJECT_DESIGN.md` and update the roadmap table and current milestone line; verify the table and milestone text are consistent.

## 4. Validation and proof

- [ ] 4.1 Run `./Scripts/validate.sh` and verify every stage passes; report any skipped lines it emits.
- [ ] 4.2 With the maintainer present, run `make build-status DELIVERY_ID=2a0163e0-90f5-4a55-b0cd-44e1200b1b78` after storing the Keychain item, and verify a macOS prompt appears, Allow prints `processing state: VALID` for build 4, and Deny fails with the "credentials were not provided" message; record both in the PR.
- [ ] 4.3 After the change merges, run the "iOS Release" workflow for the next build number with the maintainer's go-ahead, and verify the run log's last release line and the run summary show the build number, delivery ID, and `VALID`; add them to the PR or a follow-up note.

## Workflow follow-up

- Archive the change (syncing the `release-pipeline` delta spec) after the project's review requirements are satisfied.
