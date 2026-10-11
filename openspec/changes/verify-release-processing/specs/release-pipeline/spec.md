# Spec Delta

## Purpose

Defines how a Routine release is uploaded to App Store Connect, how the pipeline proves App Store Connect finished processing the build, and how the App Store Connect credentials the pipeline needs are stored and supplied, so a release can be confirmed without anyone holding those credentials by hand.

## ADDED Requirements

### Requirement: A release is not complete until App Store Connect has processed the build
After a build is uploaded, the release SHALL wait for App Store Connect to report a final processing state for that upload, and SHALL succeed only when that state is valid. The release SHALL fail when processing ends in a failed or invalid state, and SHALL fail when no final state is reported within the time limit. The wait interval and the time limit SHALL be configurable and SHALL default to checking every 30 seconds for up to 30 minutes.

#### Scenario: Processing finishes successfully
- **WHEN** an upload is accepted and App Store Connect reports the build as valid
- **THEN** the release succeeds

#### Scenario: Processing takes a while
- **WHEN** App Store Connect first reports the build as still processing and later reports it as valid within the time limit
- **THEN** the release keeps checking and then succeeds

#### Scenario: Processing fails
- **WHEN** App Store Connect reports the build as failed or invalid
- **THEN** the release fails and shows the reported state

#### Scenario: Processing does not finish in time
- **WHEN** no final processing state is reported within the time limit
- **THEN** the release fails and prints the command that re-checks the same upload later

### Requirement: The release reports its outcome in a final line
Every release that reaches the processing check SHALL end with one line stating the build number, the delivery ID of the upload, and the final processing state. When the release runs in GitHub Actions, the same information SHALL also be written to the run summary.

#### Scenario: Outcome in the log
- **WHEN** a release finishes, successfully or not, after the upload was accepted
- **THEN** the last release line names the build number, the delivery ID, and the processing state

#### Scenario: Outcome in the run summary
- **WHEN** the release runs in GitHub Actions
- **THEN** the run summary shows the build number, the delivery ID, and the processing state

### Requirement: The upload's delivery ID is recorded
The upload step SHALL record the delivery ID that App Store Connect returns, and the release SHALL fail if an upload reports success without returning one. The delivery ID SHALL be included in the files the release publishes as its artifact.

#### Scenario: Delivery ID captured
- **WHEN** the upload step finishes with an accepted upload
- **THEN** the delivery ID is saved next to the exported build

#### Scenario: Upload accepted without a delivery ID
- **WHEN** the upload step reports success but no delivery ID can be found in its output
- **THEN** the release fails and says why

### Requirement: Any upload's processing state can be checked on demand
A standalone check SHALL report the current processing state for a given delivery ID, SHALL exit successfully only when that state is valid, and SHALL use the same time limit and interval settings as the release.

#### Scenario: Check an earlier upload
- **WHEN** the check is run with the delivery ID of an upload that has finished processing
- **THEN** it prints the final processing state and exits successfully

#### Scenario: Missing delivery ID
- **WHEN** the check is run without a delivery ID
- **THEN** it fails and explains that a delivery ID is required

### Requirement: A release can be confirmed from CI output alone
The result of a release run in GitHub Actions SHALL be readable from the run's log and summary without App Store Connect credentials, so that a person or an agent without those credentials can tell whether the build was processed.

#### Scenario: Confirming without credentials
- **WHEN** someone with read access to the repository's Actions runs opens a finished release run
- **THEN** they can read the processing outcome and the delivery ID without needing any App Store Connect credentials

### Requirement: Local credentials are kept in the macOS Keychain and need approval on each use
The App Store Connect Key ID, Issuer ID, and API key SHALL be stored in the macOS login Keychain in a single item that no application is allowed to read without a macOS approval prompt. A one-time setup command SHALL create or update that item from the Key ID, the Issuer ID, and a key file. The release scripts SHALL read the credentials from that item and SHALL ask for approval once per release run, not once per step.

#### Scenario: One-time setup
- **WHEN** the setup command is run with a Key ID, an Issuer ID, and a readable key file
- **THEN** the Keychain item exists and contains all three

#### Scenario: Setup with an unreadable key file
- **WHEN** the setup command is run with a key file that cannot be read
- **THEN** it fails without creating or changing the Keychain item

#### Scenario: Local release asks once
- **WHEN** a local release runs with credentials in the Keychain and no credential environment variables set
- **THEN** macOS asks for approval once, and every step of that release uses the same credentials

#### Scenario: Approval denied
- **WHEN** the Keychain prompt is denied or cannot be answered
- **THEN** the step that needed the credentials fails with a message that says the credentials were not provided

### Requirement: Credentials are exposed only for the length of a command
When credentials come from the Keychain, the key SHALL be written only to a temporary file readable by the current user alone, and that file SHALL be removed when the command ends, whether it succeeded or failed.

#### Scenario: Temporary key removed after success
- **WHEN** a command that loaded credentials from the Keychain finishes successfully
- **THEN** the temporary key file no longer exists

#### Scenario: Temporary key removed after failure
- **WHEN** a command that loaded credentials from the Keychain fails partway through
- **THEN** the temporary key file no longer exists

#### Scenario: Temporary key permissions
- **WHEN** credentials are loaded from the Keychain
- **THEN** the temporary key file is readable and writable by the current user only

### Requirement: Credential environment variables keep precedence
When `APP_STORE_CONNECT_AUTH_KEY_PATH`, `APP_STORE_CONNECT_AUTH_KEY_ID`, and `APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID` are all set, the scripts SHALL use them and SHALL NOT read the Keychain. If only some of them are set, the scripts SHALL fail with the existing message that they must be set together.

#### Scenario: CI credentials
- **WHEN** the three variables are set, as in the GitHub Actions workflow
- **THEN** no Keychain access happens and the release behaves as it does today

#### Scenario: Partially set variables
- **WHEN** only some of the three variables are set
- **THEN** the script fails and says they must be set together
