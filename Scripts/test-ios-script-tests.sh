#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir" build/Routine.xcarchive build/export' EXIT

assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected to find '$needle' in:"
        echo "$haystack"
        exit 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" == *"$needle"* ]]; then
        echo "Did not expect to find '$needle' in:"
        echo "$haystack"
        exit 1
    fi
}

assert_equals() {
    local actual="$1"
    local expected="$2"

    if [[ "$actual" != "$expected" ]]; then
        echo "Expected '$expected' but found '$actual'."
        exit 1
    fi
}

assert_line_before() {
    local haystack="$1"
    local first="$2"
    local second="$3"
    local first_line
    local second_line

    first_line="$(print -r -- "$haystack" | grep -nF "$first" | head -n 1 | cut -d: -f1)"
    second_line="$(print -r -- "$haystack" | grep -nF "$second" | head -n 1 | cut -d: -f1)"

    if [[ -z "$first_line" || -z "$second_line" || "$first_line" -ge "$second_line" ]]; then
        echo "Expected '$first' to appear before '$second' in:"
        echo "$haystack"
        exit 1
    fi
}

run_command_and_capture() {
    local output_file="$1"
    local had_errexit=0
    shift

    if [[ -o errexit ]]; then
        had_errexit=1
    fi

    set +e
    "$@" >"$output_file" 2>&1
    local exit_code=$?
    if (( had_errexit )); then
        set -e
    else
        set +e
    fi
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

create_fake_screenshot_export() {
    local export_root="$1"
    local mode="${2:-valid}"

    python3 - "$export_root" "$mode" <<'PY'
import json
import pathlib
import sys
import uuid

export_root = pathlib.Path(sys.argv[1])
mode = sys.argv[2]
export_root.mkdir(parents=True, exist_ok=True)

slugs = [
    "dashboard-overview",
    "dashboard-lower-progress",
    "completion-undo-banner",
    "history-rich",
    "history-remove-confirmation",
    "history-after-removal",
    "management-menu",
    "add-routine-form-default",
    "add-routine-form-configured",
    "dashboard-after-add-routine",
    "dashboard-edit-mode",
    "add-group-form",
    "dashboard-after-add-group",
    "edit-group-form",
    "delete-group-confirmation",
    "rearrange-groups",
    "rearrange-routines",
    "settings-week-start",
]

attachments = []
counter = 0
for index, slug in enumerate(slugs, start=1):
    for appearance in ["light", "dark"]:
        counter += 1
        exported_file_name = f"export-{counter:02d}.png"
        suggested_name = f"{index:02d}-{slug}-{appearance}_0_{str(uuid.uuid4()).upper()}.png"
        attachments.append(
            {
                "configurationName": "Test Scheme Action",
                "deviceId": "SIM-ULATOR-ID",
                "deviceName": "iPhone 17",
                "exportedFileName": exported_file_name,
                "isAssociatedWithFailure": False,
                "suggestedHumanReadableName": suggested_name,
                "timestamp": counter,
            }
        )

        if mode != "missing-file" or counter != 36:
            payload = f"png-{index:02d}-{slug}-{appearance}".encode("utf-8")
            if mode == "identical-appearance-content" and slug == "dashboard-overview":
                payload = b"png-01-dashboard-overview-shared"
            (export_root / exported_file_name).write_bytes(payload)

attachments.reverse()

if mode == "duplicate":
    attachments[-1]["suggestedHumanReadableName"] = attachments[-2]["suggestedHumanReadableName"]
elif mode == "malformed-name":
    attachments[-1]["suggestedHumanReadableName"] = "bad-name.png"
elif mode == "missing-appearance":
    for attachment in attachments:
        suggested_name = attachment["suggestedHumanReadableName"]
        if suggested_name.startswith("17-rearrange-routines-light_0_"):
            attachment["suggestedHumanReadableName"] = (
                f"17-rearrange-routines-alt-dark_0_{str(uuid.uuid4()).upper()}.png"
            )
            break

manifest = [
    {
        "attachments": attachments,
        "testIdentifier": "RoutineAppScreenshotTests/testCaptureFullAppScreenshotsAcrossForcedAppearances()",
    }
]
(export_root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY
}

script_test_dir="$workdir/build-test-ios"
mkdir -p "$script_test_dir"

log_file="$script_test_dir/xcodebuild.log"
generate_log="$script_test_dir/generate.log"
fake_xcodebuild="$script_test_dir/xcodebuild"
fake_generate="$script_test_dir/generate-project.sh"

cat >"$fake_xcodebuild" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_XCODEBUILD_LOG}"

if [[ "$*" == *"-showdestinations"* ]]; then
    print -r -- "${FAKE_SHOWDESTINATIONS_OUTPUT:-}"
    exit 0
fi

if [[ "$*" == *"-exportOptionsPlist"* && -n "${FAKE_XCODEBUILD_EXPORT_OPTIONS_LOG:-}" ]]; then
    args=("$@")
    for i in {1..$#}; do
        if [[ "${args[$i]}" == "-exportOptionsPlist" ]]; then
            cat "${args[$((i + 1))]}" >>"${FAKE_XCODEBUILD_EXPORT_OPTIONS_LOG}"
        fi
    done
fi

exit "${FAKE_XCODEBUILD_EXIT_CODE:-0}"
EOF

cat >"$fake_generate" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "generate" >>"${FAKE_GENERATE_LOG}"
EOF

chmod +x "$fake_xcodebuild" "$fake_generate"

run_build_ios_and_capture() {
    local output_file="$script_test_dir/output.txt"
    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        -u DEVELOPMENT_TEAM \
        -u APP_STORE_CONNECT_AUTH_KEY_PATH \
        -u APP_STORE_CONNECT_AUTH_KEY_ID \
        -u APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID \
        FAKE_XCODEBUILD_LOG="$log_file" \
        FAKE_GENERATE_LOG="$generate_log" \
        XCODEBUILD_BIN="$fake_xcodebuild" \
        GENERATE_PROJECT_SCRIPT="$fake_generate" \
        "$@" \
        ./Scripts/build-ios.sh >"$output_file" 2>&1
    local exit_code=$?
    set -e
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

run_test_ios_and_capture() {
    local output_file="$script_test_dir/output.txt"
    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        -u DEVELOPMENT_TEAM \
        -u APP_STORE_CONNECT_AUTH_KEY_PATH \
        -u APP_STORE_CONNECT_AUTH_KEY_ID \
        -u APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID \
        FAKE_XCODEBUILD_LOG="$log_file" \
        FAKE_GENERATE_LOG="$generate_log" \
        XCODEBUILD_BIN="$fake_xcodebuild" \
        GENERATE_PROJECT_SCRIPT="$fake_generate" \
        "$@" \
        ./Scripts/test-ios.sh >"$output_file" 2>&1
    local exit_code=$?
    set -e
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

: >"$log_file"
: >"$generate_log"
generic_destinations=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }\n'
run_build_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$generic_destinations"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
default_build_log="$(<"$log_file")"
assert_contains "$default_build_log" "-showdestinations"
assert_contains "$default_build_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -configuration Debug -destination generic/platform=iOS Simulator build"

: >"$log_file"
: >"$generate_log"
device_destinations=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS, arch:arm64, id:AAAA, name:Justin\'s iPhone }\n'
run_build_ios_and_capture \
    FAKE_SHOWDESTINATIONS_OUTPUT="$device_destinations" \
    ROUTINE_BUILD_CONFIGURATION=Release \
    DEVELOPMENT_TEAM=TEAM123ABC
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
release_build_log="$(<"$log_file")"
assert_contains "$release_build_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -configuration Release DEVELOPMENT_TEAM=TEAM123ABC -destination generic/platform=iOS build"

: >"$log_file"
: >"$generate_log"
missing_destinations_output='xcodebuild: error: Unable to find a destination matching the provided destination specifier.'
run_build_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$missing_destinations_output"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
assert_contains "$REPLY" "Skipping iOS build: no eligible generic simulator or device destination is installed."
missing_build_log="$(<"$log_file")"
assert_contains "$missing_build_log" "-showdestinations"
if [[ "$missing_build_log" == *" build"* ]]; then
    echo "Expected build skip path to avoid invoking xcodebuild build."
    exit 1
fi

: >"$log_file"
: >"$generate_log"
run_test_ios_and_capture IOS_TEST_DESTINATION="platform=iOS Simulator,name=Custom Device,OS=99.0"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
override_log="$(<"$log_file")"
assert_contains "$override_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -destination platform=iOS Simulator,name=Custom Device,OS=99.0 test"
assert_not_contains "$override_log" "-showdestinations"

: >"$log_file"
: >"$generate_log"
showdestinations_output=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }\n    { platform:iOS Simulator, arch:arm64, id:AAAA, OS:26.0, name:iPad Pro (13-inch) }\n    { platform:iOS Simulator, arch:arm64, id:BBBB, OS:26.0, name:iPhone 17 }\n    { platform:iOS Simulator, arch:arm64, id:CCCC, OS:26.0, name:iPhone Air }\n'
run_test_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$showdestinations_output"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
auto_log="$(<"$log_file")"
assert_contains "$auto_log" "-showdestinations"
assert_contains "$auto_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -destination platform=iOS Simulator,name=iPhone 17 test"

: >"$log_file"
: >"$generate_log"
iPad_only_output=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:AAAA, OS:26.0, name:iPad mini (A17 Pro) }\n    { platform:iOS Simulator, arch:arm64, id:BBBB, OS:26.0, name:iPad Pro (13-inch) }\n'
run_test_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$iPad_only_output"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
ipad_log="$(<"$log_file")"
assert_contains "$ipad_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -destination platform=iOS Simulator,name=iPad mini (A17 Pro) test"

: >"$log_file"
: >"$generate_log"
placeholder_only_output=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }\n'
run_test_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$placeholder_only_output"
assert_equals "$?" "0"
assert_contains "$REPLY" "Skipping iOS tests: no concrete iOS Simulator destination is available."
assert_equals "$(<"$generate_log")" ""
skip_log="$(<"$log_file")"
assert_contains "$skip_log" "-showdestinations"
if [[ "$skip_log" == *" test"* ]]; then
    echo "Expected skip path to avoid invoking xcodebuild test."
    exit 1
fi

run_archive_ios_and_capture() {
    local output_file="$script_test_dir/output.txt"
    local had_errexit=0
    if [[ -o errexit ]]; then
        had_errexit=1
    fi

    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        -u DEVELOPMENT_TEAM \
        -u APP_STORE_CONNECT_AUTH_KEY_PATH \
        -u APP_STORE_CONNECT_AUTH_KEY_ID \
        -u APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID \
        FAKE_XCODEBUILD_LOG="$log_file" \
        FAKE_GENERATE_LOG="$generate_log" \
        XCODEBUILD_BIN="$fake_xcodebuild" \
        GENERATE_PROJECT_SCRIPT="$fake_generate" \
        "$@" \
        ./Scripts/archive-ios.sh >"$output_file" 2>&1
    local exit_code=$?
    if (( had_errexit )); then
        set -e
    fi
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

: >"$log_file"
: >"$generate_log"
set +e
run_archive_ios_and_capture
missing_build_number_exit_code=$?
set -e
assert_equals "$missing_build_number_exit_code" "1"
assert_contains "$REPLY" "error: CURRENT_PROJECT_VERSION is required to archive for distribution."
assert_equals "$(<"$generate_log")" ""

: >"$log_file"
: >"$generate_log"
run_archive_ios_and_capture DEVELOPMENT_TEAM=TEAM456DEF CURRENT_PROJECT_VERSION=42
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
override_archive_log="$(<"$log_file")"
assert_contains "$override_archive_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -configuration Release -destination generic/platform=iOS -archivePath build/Routine.xcarchive DEVELOPMENT_TEAM=TEAM456DEF CURRENT_PROJECT_VERSION=42 -allowProvisioningUpdates archive"

: >"$log_file"
: >"$generate_log"
set +e
run_archive_ios_and_capture DEVELOPMENT_TEAM=
missing_team_exit_code=$?
set -e
assert_equals "$missing_team_exit_code" "1"
assert_contains "$REPLY" "error: DEVELOPMENT_TEAM is required to archive for distribution."
assert_equals "$(<"$generate_log")" ""

: >"$log_file"
: >"$generate_log"
run_archive_ios_and_capture \
    APP_STORE_CONNECT_AUTH_KEY_PATH=/tmp/AuthKey_TEST.p8 \
    APP_STORE_CONNECT_AUTH_KEY_ID=ABC1234567 \
    APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=11111111-2222-3333-4444-555555555555 \
    CURRENT_PROJECT_VERSION=42
assert_equals "$?" "0"
auth_archive_log="$(<"$log_file")"
assert_contains "$auth_archive_log" "-authenticationKeyPath /tmp/AuthKey_TEST.p8 -authenticationKeyID ABC1234567 -authenticationKeyIssuerID 11111111-2222-3333-4444-555555555555 -allowProvisioningUpdates archive"

: >"$log_file"
: >"$generate_log"
set +e
run_archive_ios_and_capture APP_STORE_CONNECT_AUTH_KEY_PATH=/tmp/AuthKey_TEST.p8 CURRENT_PROJECT_VERSION=42
partial_auth_archive_exit_code=$?
set -e
assert_equals "$partial_auth_archive_exit_code" "1"
assert_contains "$REPLY" "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID must be set together."
assert_equals "$(<"$generate_log")" ""

archive_make_repo="$workdir/archive-make-repo"
mkdir -p "$archive_make_repo/Scripts"
cp ./Makefile "$archive_make_repo/Makefile"

cat >"$archive_make_repo/Scripts/archive-ios.sh" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "${CURRENT_PROJECT_VERSION:-}" >>"${FAKE_MAKE_ARCHIVE_LOG}"
EOF

chmod +x "$archive_make_repo/Scripts/archive-ios.sh"

run_make_archive_and_capture() {
    local output_file="$script_test_dir/output.txt"
    local had_errexit=0
    if [[ -o errexit ]]; then
        had_errexit=1
    fi

    set +e
    (
        cd "$archive_make_repo"
        env \
            -u ROUTINE_VALIDATE_VERBOSE \
            -u ROUTINE_SCRIPT_VERBOSE \
            -u CURRENT_PROJECT_VERSION \
            "$@" make archive-ios
    ) >"$output_file" 2>&1
    local exit_code=$?
    if (( had_errexit )); then
        set -e
    fi
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

make_archive_log="$workdir/make-archive.log"

: >"$make_archive_log"
set +e
run_make_archive_and_capture FAKE_MAKE_ARCHIVE_LOG="$make_archive_log"
missing_make_archive_exit_code=$?
set -e
if [[ "$missing_make_archive_exit_code" == "0" ]]; then
    echo "Expected make archive-ios to fail without CURRENT_PROJECT_VERSION."
    exit 1
fi
assert_contains "$REPLY" "CURRENT_PROJECT_VERSION"
assert_equals "$(<"$make_archive_log")" ""

: >"$make_archive_log"
run_make_archive_and_capture CURRENT_PROJECT_VERSION=42 FAKE_MAKE_ARCHIVE_LOG="$make_archive_log"
assert_equals "$?" "0"
assert_equals "$(<"$make_archive_log")" "42"

export_options_template="$script_test_dir/ExportOptions.plist"
cat >"$export_options_template" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>teamID</key>
	<string>DEVELOPMENT_TEAM_PLACEHOLDER</string>
</dict>
</plist>
EOF

export_options_log="$script_test_dir/export-options-applied.plist"

run_export_ios_and_capture() {
    local output_file="$script_test_dir/output.txt"
    local had_errexit=0
    if [[ -o errexit ]]; then
        had_errexit=1
    fi

    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        -u DEVELOPMENT_TEAM \
        -u APP_STORE_CONNECT_AUTH_KEY_PATH \
        -u APP_STORE_CONNECT_AUTH_KEY_ID \
        -u APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID \
        FAKE_XCODEBUILD_LOG="$log_file" \
        FAKE_XCODEBUILD_EXPORT_OPTIONS_LOG="$export_options_log" \
        XCODEBUILD_BIN="$fake_xcodebuild" \
        EXPORT_OPTIONS_TEMPLATE="$export_options_template" \
        "$@" \
        ./Scripts/export-ios.sh >"$output_file" 2>&1
    local exit_code=$?
    if (( had_errexit )); then
        set -e
    fi
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

: >"$log_file"
: >"$export_options_log"
set +e
run_export_ios_and_capture
no_archive_exit_code=$?
set -e
assert_equals "$no_archive_exit_code" "1"
assert_contains "$REPLY" "error: no archive found at build/Routine.xcarchive. Run ./Scripts/archive-ios.sh first."

mkdir -p build/Routine.xcarchive

: >"$log_file"
: >"$export_options_log"
set +e
run_export_ios_and_capture DEVELOPMENT_TEAM=
missing_team_export_exit_code=$?
set -e
assert_equals "$missing_team_export_exit_code" "1"
assert_contains "$REPLY" "error: DEVELOPMENT_TEAM is required to export an archive for distribution."

: >"$log_file"
: >"$export_options_log"
run_export_ios_and_capture
assert_equals "$?" "0"
export_log="$(<"$log_file")"
assert_contains "$export_log" "-quiet -exportArchive -archivePath build/Routine.xcarchive -exportOptionsPlist"
assert_contains "$export_log" "-exportPath build/export"
assert_contains "$export_log" "-allowProvisioningUpdates"
assert_contains "$(<"$export_options_log")" "<string>CX2KMQZQ7X</string>"

: >"$log_file"
: >"$export_options_log"
run_export_ios_and_capture DEVELOPMENT_TEAM=TEAM789XYZ
assert_equals "$?" "0"
assert_contains "$(<"$export_options_log")" "<string>TEAM789XYZ</string>"

: >"$log_file"
: >"$export_options_log"
run_export_ios_and_capture \
    APP_STORE_CONNECT_AUTH_KEY_PATH=/tmp/AuthKey_TEST.p8 \
    APP_STORE_CONNECT_AUTH_KEY_ID=ABC1234567 \
    APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=11111111-2222-3333-4444-555555555555
assert_equals "$?" "0"
auth_export_log="$(<"$log_file")"
assert_contains "$auth_export_log" "-authenticationKeyPath /tmp/AuthKey_TEST.p8 -authenticationKeyID ABC1234567 -authenticationKeyIssuerID 11111111-2222-3333-4444-555555555555"

: >"$log_file"
: >"$export_options_log"
set +e
run_export_ios_and_capture APP_STORE_CONNECT_AUTH_KEY_ID=ABC1234567
partial_auth_export_exit_code=$?
set -e
assert_equals "$partial_auth_export_exit_code" "1"
assert_contains "$REPLY" "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID must be set together."

rm -rf build/Routine.xcarchive build/export

validate_repo="$workdir/validate-repo"
mkdir -p "$validate_repo/Scripts"
cp ./Scripts/validate.sh "$validate_repo/Scripts/validate.sh"
chmod +x "$validate_repo/Scripts/validate.sh"

for stage_name in \
    generate-project \
    test-ios-script-tests \
    test-core \
    test-ios \
    check-format \
    lint \
    build-ios
do
    cat >"$validate_repo/Scripts/${stage_name}.sh" <<'EOF'
#!/bin/zsh
set -euo pipefail

stage_name="${0:t:r}"
stage_key="$(print -r -- "$stage_name" | tr '[:lower:]-' '[:upper:]_')"
output_var="FAKE_${stage_key}_OUTPUT"
exit_var="FAKE_${stage_key}_EXIT"

if [[ -n "${(P)output_var:-}" ]]; then
    print -r -- "${(P)output_var}"
fi

exit "${${(P)exit_var}:-0}"
EOF
    chmod +x "$validate_repo/Scripts/${stage_name}.sh"
done

run_validate_and_capture() {
    local output_file="$workdir/validate-output.txt"
    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        "$@" "$validate_repo/Scripts/validate.sh" >"$output_file" 2>&1
    CAPTURED_EXIT_CODE=$?
    set -e
    REPLY="$(<"$output_file")"
    return 0
}

run_validate_and_capture \
    FAKE_GENERATE_PROJECT_OUTPUT="hidden generate chatter" \
    FAKE_TEST_IOS_SCRIPT_TESTS_OUTPUT="hidden scripts chatter" \
    FAKE_TEST_CORE_OUTPUT="hidden core chatter" \
    FAKE_TEST_IOS_OUTPUT="hidden ios chatter" \
    FAKE_CHECK_FORMAT_OUTPUT="hidden format chatter" \
    FAKE_LINT_OUTPUT="hidden lint chatter" \
    FAKE_BUILD_IOS_OUTPUT="hidden build chatter"
assert_equals "$?" "0"
validate_output="$REPLY"
assert_contains "$validate_output" "PASS generate-project"
assert_contains "$validate_output" "PASS test-ios-script-tests"
assert_contains "$validate_output" "PASS test-core"
assert_contains "$validate_output" "PASS test-ios"
assert_contains "$validate_output" "PASS check-format"
assert_contains "$validate_output" "PASS lint"
assert_contains "$validate_output" "PASS build-ios"
assert_not_contains "$validate_output" "hidden generate chatter"
assert_not_contains "$validate_output" "hidden build chatter"

set +e
run_validate_and_capture \
    FAKE_TEST_CORE_OUTPUT=$'core failure line 1\ncore failure line 2' \
    FAKE_TEST_CORE_EXIT=42
set -e
validate_failure_exit="$CAPTURED_EXIT_CODE"
assert_equals "$validate_failure_exit" "42"
validate_failure_output="$REPLY"
assert_contains "$validate_failure_output" "PASS generate-project"
assert_contains "$validate_failure_output" "PASS test-ios-script-tests"
assert_contains "$validate_failure_output" "FAIL test-core"
assert_contains "$validate_failure_output" "Command: ./Scripts/test-core.sh"
assert_contains "$validate_failure_output" "Exit code: 42"
assert_contains "$validate_failure_output" "core failure line 1"
assert_contains "$validate_failure_output" "core failure line 2"

run_validate_and_capture \
    FAKE_BUILD_IOS_OUTPUT="Skipping iOS build: no eligible generic simulator or device destination is installed."
assert_equals "$?" "0"
validate_skip_output="$REPLY"
assert_contains "$validate_skip_output" "PASS build-ios"
assert_contains "$validate_skip_output" "Skipping iOS build: no eligible generic simulator or device destination is installed."

run_validate_and_capture \
    ROUTINE_VALIDATE_VERBOSE=1 \
    FAKE_GENERATE_PROJECT_OUTPUT="stream me directly"
assert_equals "$?" "0"
validate_verbose_output="$REPLY"
assert_contains "$validate_verbose_output" "stream me directly"
assert_contains "$validate_verbose_output" "PASS generate-project"

release_preflight_repo="$workdir/release-preflight-repo"
mkdir -p "$release_preflight_repo/Scripts"
cp ./Scripts/release-preflight.sh "$release_preflight_repo/Scripts/release-preflight.sh"
chmod +x "$release_preflight_repo/Scripts/release-preflight.sh"

for stage_name in validate build-ios archive-ios export-ios
do
    cat >"$release_preflight_repo/Scripts/${stage_name}.sh" <<'EOF'
#!/bin/zsh
set -euo pipefail

stage_name="${0:t:r}"
stage_key="$(print -r -- "$stage_name" | tr '[:lower:]-' '[:upper:]_')"
output_var="FAKE_${stage_key}_OUTPUT"
exit_var="FAKE_${stage_key}_EXIT"

print -r -- "$stage_name" >>"${FAKE_RELEASE_PREFLIGHT_ORDER_LOG}"

if [[ -n "${ROUTINE_BUILD_CONFIGURATION:-}" ]]; then
    print -r -- "${stage_name}:ROUTINE_BUILD_CONFIGURATION=${ROUTINE_BUILD_CONFIGURATION}" >>"${FAKE_RELEASE_PREFLIGHT_ENV_LOG}"
fi

if [[ -n "${CURRENT_PROJECT_VERSION:-}" ]]; then
    print -r -- "${stage_name}:CURRENT_PROJECT_VERSION=${CURRENT_PROJECT_VERSION}" >>"${FAKE_RELEASE_PREFLIGHT_ENV_LOG}"
fi

if [[ -n "${(P)output_var:-}" ]]; then
    print -r -- "${(P)output_var}"
fi

exit "${${(P)exit_var}:-0}"
EOF
    chmod +x "$release_preflight_repo/Scripts/${stage_name}.sh"
done

run_release_preflight_and_capture() {
    local output_file="$workdir/release-preflight-output.txt"
    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        "$@" "$release_preflight_repo/Scripts/release-preflight.sh" >"$output_file" 2>&1
    CAPTURED_EXIT_CODE=$?
    set -e
    REPLY="$(<"$output_file")"
    return 0
}

release_preflight_order_log="$workdir/release-preflight-order.log"
release_preflight_env_log="$workdir/release-preflight-env.log"

: >"$release_preflight_order_log"
: >"$release_preflight_env_log"
set +e
run_release_preflight_and_capture \
    FAKE_RELEASE_PREFLIGHT_ORDER_LOG="$release_preflight_order_log" \
    FAKE_RELEASE_PREFLIGHT_ENV_LOG="$release_preflight_env_log"
set -e
assert_equals "$CAPTURED_EXIT_CODE" "1"
assert_contains "$REPLY" "error: CURRENT_PROJECT_VERSION is required for release preflight."
assert_equals "$(wc -l <"$release_preflight_order_log" | tr -d ' ')" "0"

: >"$release_preflight_order_log"
: >"$release_preflight_env_log"
run_release_preflight_and_capture \
    CURRENT_PROJECT_VERSION=42 \
    FAKE_RELEASE_PREFLIGHT_ORDER_LOG="$release_preflight_order_log" \
    FAKE_RELEASE_PREFLIGHT_ENV_LOG="$release_preflight_env_log" \
    FAKE_VALIDATE_OUTPUT="Skipping iOS tests: no concrete iOS Simulator destination is available."
assert_equals "$?" "0"
release_preflight_output="$REPLY"
assert_contains "$release_preflight_output" "PASS validate"
assert_contains "$release_preflight_output" "PASS build-release"
assert_contains "$release_preflight_output" "PASS archive"
assert_contains "$release_preflight_output" "PASS export"
assert_contains "$release_preflight_output" "Skipping iOS tests: no concrete iOS Simulator destination is available."
assert_contains "$release_preflight_output" "Release preflight finished for CURRENT_PROJECT_VERSION=42."
release_preflight_order="$(<"$release_preflight_order_log")"
assert_equals "$release_preflight_order" $'validate\nbuild-ios\narchive-ios\nexport-ios'
release_preflight_env="$(<"$release_preflight_env_log")"
assert_contains "$release_preflight_env" "build-ios:ROUTINE_BUILD_CONFIGURATION=Release"
assert_contains "$release_preflight_env" "archive-ios:CURRENT_PROJECT_VERSION=42"

run_ios_dir="$workdir/run-ios"
mkdir -p "$run_ios_dir"

run_ios_xcodebuild_log="$run_ios_dir/xcodebuild.log"
run_ios_xcrun_log="$run_ios_dir/xcrun.log"
run_ios_open_log="$run_ios_dir/open.log"
run_ios_generate_log="$run_ios_dir/generate.log"
run_ios_device_state="$run_ios_dir/device-state.txt"
fake_run_ios_xcodebuild="$run_ios_dir/xcodebuild"
fake_run_ios_xcrun="$run_ios_dir/xcrun"
fake_run_ios_open="$run_ios_dir/open"
fake_run_ios_generate="$run_ios_dir/generate-project.sh"

cat >"$fake_run_ios_xcodebuild" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_RUN_IOS_XCODEBUILD_LOG}"

configuration="Debug"
derived_data_path=""

while (( $# > 0 )); do
    case "$1" in
        -configuration)
            configuration="$2"
            shift 2
            ;;
        -derivedDataPath)
            derived_data_path="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

mkdir -p "${derived_data_path}/Build/Products/${configuration}-iphonesimulator/Routine.app"
EOF

cat >"$fake_run_ios_xcrun" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_RUN_IOS_XCRUN_LOG}"

if [[ "$1" == "simctl" && "$2" == "list" && "$3" == "devices" && "$4" == "available" && "$5" == "-j" ]]; then
    print -r -- "${FAKE_RUN_IOS_SIMCTL_LIST_JSON}"
    exit 0
fi

if [[ "$1" == "simctl" && "$2" == "bootstatus" ]]; then
    device_id="$3"
    if grep -Fqx "${device_id}:Booted" "${FAKE_RUN_IOS_DEVICE_STATE_FILE}"; then
        exit 0
    fi
    exit 1
fi

if [[ "$1" == "simctl" && "$2" == "boot" ]]; then
    device_id="$3"
    python3 - "$device_id" "${FAKE_RUN_IOS_DEVICE_STATE_FILE}" <<'PY'
import pathlib
import sys

device_id = sys.argv[1]
state_path = pathlib.Path(sys.argv[2])
lines = []
updated = False
if state_path.exists():
    for raw_line in state_path.read_text().splitlines():
        current_id, _, _ = raw_line.partition(":")
        if current_id == device_id:
            lines.append(f"{device_id}:Booted")
            updated = True
        else:
            lines.append(raw_line)
if not updated:
    lines.append(f"{device_id}:Booted")
state_path.write_text("\n".join(lines) + ("\n" if lines else ""))
PY
    exit 0
fi

exit 0
EOF

cat >"$fake_run_ios_open" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_RUN_IOS_OPEN_LOG}"
EOF

cat >"$fake_run_ios_generate" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "generate" >>"${FAKE_RUN_IOS_GENERATE_LOG}"
EOF

chmod +x \
    "$fake_run_ios_xcodebuild" \
    "$fake_run_ios_xcrun" \
    "$fake_run_ios_open" \
    "$fake_run_ios_generate"

run_run_ios_and_capture() {
    local output_file="$run_ios_dir/output.txt"
    set +e
    env \
        -u ROUTINE_VALIDATE_VERBOSE \
        -u ROUTINE_SCRIPT_VERBOSE \
        -u CURRENT_PROJECT_VERSION \
        FAKE_RUN_IOS_XCODEBUILD_LOG="$run_ios_xcodebuild_log" \
        FAKE_RUN_IOS_XCRUN_LOG="$run_ios_xcrun_log" \
        FAKE_RUN_IOS_OPEN_LOG="$run_ios_open_log" \
        FAKE_RUN_IOS_GENERATE_LOG="$run_ios_generate_log" \
        FAKE_RUN_IOS_DEVICE_STATE_FILE="$run_ios_device_state" \
        XCODEBUILD_BIN="$fake_run_ios_xcodebuild" \
        XCRUN_BIN="$fake_run_ios_xcrun" \
        OPEN_BIN="$fake_run_ios_open" \
        GENERATE_PROJECT_SCRIPT="$fake_run_ios_generate" \
        "$@" \
        ./Scripts/run-ios.sh >"$output_file" 2>&1
    local exit_code=$?
    set -e
    REPLY="$(<"$output_file")"
    return "$exit_code"
}

: >"$run_ios_xcodebuild_log"
: >"$run_ios_xcrun_log"
: >"$run_ios_open_log"
: >"$run_ios_generate_log"
print -r -- "DEVICE-ID:Shutdown" >"$run_ios_device_state"
run_run_ios_and_capture \
    IOS_RUN_DEVICE_ID="DEVICE-ID" \
    FAKE_RUN_IOS_SIMCTL_LIST_JSON='{"devices":{}}'
assert_equals "$?" "0"
assert_equals "$(<"$run_ios_generate_log")" "generate"
explicit_id_xcrun_log="$(<"$run_ios_xcrun_log")"
explicit_id_xcodebuild_log="$(<"$run_ios_xcodebuild_log")"
assert_not_contains "$explicit_id_xcrun_log" "simctl list devices available -j"
assert_contains "$explicit_id_xcrun_log" "simctl bootstatus DEVICE-ID -b"
assert_contains "$explicit_id_xcrun_log" "simctl boot DEVICE-ID"
assert_contains "$explicit_id_xcrun_log" "simctl install DEVICE-ID DerivedData/RunIOS/Build/Products/Debug-iphonesimulator/Routine.app"
assert_contains "$explicit_id_xcrun_log" "simctl launch --terminate-running-process DEVICE-ID com.justinfuller.routine"
assert_contains "$explicit_id_xcodebuild_log" "-quiet -project Routine.xcodeproj -scheme RoutineApp -configuration Debug -destination id=DEVICE-ID -derivedDataPath DerivedData/RunIOS build"
assert_not_contains "$explicit_id_xcodebuild_log" "generic/platform=iOS Simulator"

: >"$run_ios_xcodebuild_log"
: >"$run_ios_xcrun_log"
: >"$run_ios_open_log"
: >"$run_ios_generate_log"
cat >"$run_ios_device_state" <<'EOF'
NAME-MATCH:Shutdown
OTHER-ID:Shutdown
EOF
name_match_json='{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{"udid":"OTHER-ID","name":"iPhone 17","state":"Shutdown","isAvailable":true},{"udid":"NAME-MATCH","name":"iPhone 17 Pro","state":"Shutdown","isAvailable":true}]}}'
run_run_ios_and_capture \
    IOS_RUN_DEVICE_NAME="iPhone 17 Pro" \
    FAKE_RUN_IOS_SIMCTL_LIST_JSON="$name_match_json"
assert_equals "$?" "0"
name_match_xcodebuild_log="$(<"$run_ios_xcodebuild_log")"
assert_contains "$name_match_xcodebuild_log" "-destination id=NAME-MATCH"

: >"$run_ios_xcodebuild_log"
: >"$run_ios_xcrun_log"
: >"$run_ios_open_log"
: >"$run_ios_generate_log"
cat >"$run_ios_device_state" <<'EOF'
SHUTDOWN-ID:Shutdown
BOOTED-ID:Booted
EOF
booted_preferred_json='{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{"udid":"SHUTDOWN-ID","name":"iPhone 16","state":"Shutdown","isAvailable":true},{"udid":"BOOTED-ID","name":"iPhone 17","state":"Booted","isAvailable":true}]}}'
run_run_ios_and_capture FAKE_RUN_IOS_SIMCTL_LIST_JSON="$booted_preferred_json"
assert_equals "$?" "0"
booted_preferred_xcodebuild_log="$(<"$run_ios_xcodebuild_log")"
booted_preferred_xcrun_log="$(<"$run_ios_xcrun_log")"
assert_contains "$booted_preferred_xcodebuild_log" "-destination id=BOOTED-ID"
assert_not_contains "$booted_preferred_xcrun_log" "simctl boot BOOTED-ID"

: >"$run_ios_xcodebuild_log"
: >"$run_ios_xcrun_log"
: >"$run_ios_open_log"
: >"$run_ios_generate_log"
print -r -- "SHUTDOWN-NAMED:Shutdown" >"$run_ios_device_state"
shutdown_selected_json='{"devices":{"com.apple.CoreSimulator.SimRuntime.iOS-26-0":[{"udid":"SHUTDOWN-NAMED","name":"iPhone 17 Pro","state":"Shutdown","isAvailable":true}]}}'
run_run_ios_and_capture \
    IOS_RUN_DEVICE_NAME="iPhone 17 Pro" \
    FAKE_RUN_IOS_SIMCTL_LIST_JSON="$shutdown_selected_json"
assert_equals "$?" "0"
shutdown_selected_xcrun_log="$(<"$run_ios_xcrun_log")"
shutdown_selected_open_log="$(<"$run_ios_open_log")"
assert_line_before "$shutdown_selected_xcrun_log" "simctl boot SHUTDOWN-NAMED" "simctl install SHUTDOWN-NAMED DerivedData/RunIOS/Build/Products/Debug-iphonesimulator/Routine.app"
assert_line_before "$shutdown_selected_xcrun_log" "simctl install SHUTDOWN-NAMED DerivedData/RunIOS/Build/Products/Debug-iphonesimulator/Routine.app" "simctl launch --terminate-running-process SHUTDOWN-NAMED com.justinfuller.routine"
assert_contains "$shutdown_selected_open_log" "-a Simulator"

screenshot_assets_dir="$workdir/screenshot-assets"
mkdir -p "$screenshot_assets_dir"

run_screenshot_assets_and_capture() {
    local output_file="$screenshot_assets_dir/output.txt"
    run_command_and_capture "$output_file" python3 ./Scripts/screenshot-assets.py "$@"
}

valid_export_root="$screenshot_assets_dir/valid-export"
valid_canonical_root="$screenshot_assets_dir/canonical"
create_fake_screenshot_export "$valid_export_root" valid
mkdir -p "$valid_canonical_root"
print -r -- "stale" >"$valid_canonical_root/stale.png"
run_screenshot_assets_and_capture promote --export-root "$valid_export_root" --canonical-root "$valid_canonical_root" --expected-count 36
assert_equals "$?" "0"
assert_equals "$(find "$valid_canonical_root" -maxdepth 1 -type f -name '*.png' | wc -l | tr -d ' ')" "36"
assert_equals "$(find "$valid_canonical_root" -maxdepth 1 -type f -name 'stale.png' | wc -l | tr -d ' ')" "0"
canonical_manifest="$(<"$valid_canonical_root/manifest.json")"
assert_line_before "$canonical_manifest" "\"file\": \"01-dashboard-overview-dark.png\"" "\"file\": \"01-dashboard-overview-light.png\""
assert_line_before "$canonical_manifest" "\"file\": \"01-dashboard-overview-light.png\"" "\"file\": \"17-rearrange-routines-light.png\""

duplicate_export_root="$screenshot_assets_dir/duplicate-export"
duplicate_canonical_root="$screenshot_assets_dir/duplicate-canonical"
create_fake_screenshot_export "$duplicate_export_root" duplicate
set +e
run_screenshot_assets_and_capture promote --export-root "$duplicate_export_root" --canonical-root "$duplicate_canonical_root" --expected-count 36
duplicate_exit_code=$?
set -e
assert_equals "$duplicate_exit_code" "1"
assert_contains "$REPLY" "duplicate canonical screenshot name"

missing_file_export_root="$screenshot_assets_dir/missing-file-export"
missing_file_canonical_root="$screenshot_assets_dir/missing-file-canonical"
create_fake_screenshot_export "$missing_file_export_root" missing-file
set +e
run_screenshot_assets_and_capture promote --export-root "$missing_file_export_root" --canonical-root "$missing_file_canonical_root" --expected-count 36
missing_file_exit_code=$?
set -e
assert_equals "$missing_file_exit_code" "1"
assert_contains "$REPLY" "missing exported screenshot file"

malformed_export_root="$screenshot_assets_dir/malformed-export"
malformed_canonical_root="$screenshot_assets_dir/malformed-canonical"
create_fake_screenshot_export "$malformed_export_root" malformed-name
set +e
run_screenshot_assets_and_capture promote --export-root "$malformed_export_root" --canonical-root "$malformed_canonical_root" --expected-count 36
malformed_exit_code=$?
set -e
assert_equals "$malformed_exit_code" "1"
assert_contains "$REPLY" "malformed suggestedHumanReadableName"

missing_appearance_export_root="$screenshot_assets_dir/missing-appearance-export"
missing_appearance_canonical_root="$screenshot_assets_dir/missing-appearance-canonical"
create_fake_screenshot_export "$missing_appearance_export_root" missing-appearance
set +e
run_screenshot_assets_and_capture promote --export-root "$missing_appearance_export_root" --canonical-root "$missing_appearance_canonical_root" --expected-count 36
missing_appearance_exit_code=$?
set -e
assert_equals "$missing_appearance_exit_code" "1"
assert_contains "$REPLY" "screenshot index 17 must include exactly one dark and one light capture"

identical_appearance_export_root="$screenshot_assets_dir/identical-appearance-export"
identical_appearance_canonical_root="$screenshot_assets_dir/identical-appearance-canonical"
create_fake_screenshot_export "$identical_appearance_export_root" identical-appearance-content
set +e
run_screenshot_assets_and_capture promote --export-root "$identical_appearance_export_root" --canonical-root "$identical_appearance_canonical_root" --expected-count 36
identical_appearance_exit_code=$?
set -e
assert_equals "$identical_appearance_exit_code" "1"
assert_contains "$REPLY" "screenshot index 01 has byte-identical dark and light captures"

run_screenshot_assets_and_capture \
    render-pr-section \
    --manifest "$valid_canonical_root/manifest.json" \
    --canonical-root Docs/Screenshots \
    --repo-owner JustinDFuller \
    --repo-name routine \
    --ref 0123456789abcdef0123456789abcdef01234567
assert_equals "$?" "0"
rendered_pr_section="$REPLY"
assert_contains "$rendered_pr_section" "## Screenshots"
assert_contains "$rendered_pr_section" "Canonical assets: Docs/Screenshots"
assert_contains "$rendered_pr_section" "https://github.com/JustinDFuller/routine/blob/0123456789abcdef0123456789abcdef01234567/Docs/Screenshots/01-dashboard-overview-dark.png?raw=true"
assert_not_contains "$rendered_pr_section" "raw.githubusercontent.com"
assert_line_before "$rendered_pr_section" "| 01 Dashboard Overview |" "| 17 Rearrange Routines |"

run_screenshot_assets_and_capture \
    render-pr-section \
    --manifest "$valid_canonical_root/manifest.json" \
    --canonical-root Docs/Screenshots \
    --repo-owner JustinDFuller \
    --repo-name routine \
    --branch screenshots
assert_equals "$?" "0"
assert_contains "$REPLY" "https://github.com/JustinDFuller/routine/blob/screenshots/Docs/Screenshots/01-dashboard-overview-dark.png?raw=true"

replace_input_file="$screenshot_assets_dir/pr-body-with-markers.md"
replace_output_file="$screenshot_assets_dir/pr-body-with-markers-updated.md"
cat >"$replace_input_file" <<'EOF'
## Summary
- summary line

## Validation
- ./Scripts/validate.sh

<!-- BEGIN GENERATED SCREENSHOTS -->
old screenshot block
<!-- END GENERATED SCREENSHOTS -->

## Notes
- keep this
EOF

run_screenshot_assets_and_capture \
    replace-pr-body \
    --manifest "$valid_canonical_root/manifest.json" \
    --canonical-root Docs/Screenshots \
    --repo-owner JustinDFuller \
    --repo-name routine \
    --ref 89abcdef0123456789abcdef0123456789abcdef \
    --input "$replace_input_file" \
    --output "$replace_output_file"
assert_equals "$?" "0"
replaced_pr_body="$(<"$replace_output_file")"
assert_contains "$replaced_pr_body" "## Summary"
assert_contains "$replaced_pr_body" "## Validation"
assert_contains "$replaced_pr_body" "## Notes"
assert_not_contains "$replaced_pr_body" "old screenshot block"
assert_contains "$replaced_pr_body" "<!-- BEGIN GENERATED SCREENSHOTS -->"
assert_contains "$replaced_pr_body" "https://github.com/JustinDFuller/routine/blob/89abcdef0123456789abcdef0123456789abcdef/Docs/Screenshots/17-rearrange-routines-light.png?raw=true"
assert_not_contains "$replaced_pr_body" "raw.githubusercontent.com"
assert_line_before "$replaced_pr_body" "## Validation" "<!-- BEGIN GENERATED SCREENSHOTS -->"
assert_line_before "$replaced_pr_body" "<!-- END GENERATED SCREENSHOTS -->" "## Notes"

append_input_file="$screenshot_assets_dir/pr-body-without-markers.md"
append_output_file="$screenshot_assets_dir/pr-body-without-markers-updated.md"
cat >"$append_input_file" <<'EOF'
## Summary
- summary line

## Validation
- ./Scripts/capture-screenshots.sh
- ./Scripts/validate.sh

## Notes
- keep this
EOF

run_screenshot_assets_and_capture \
    replace-pr-body \
    --manifest "$valid_canonical_root/manifest.json" \
    --canonical-root Docs/Screenshots \
    --repo-owner JustinDFuller \
    --repo-name routine \
    --ref screenshots \
    --input "$append_input_file" \
    --output "$append_output_file"
assert_equals "$?" "0"
appended_pr_body="$(<"$append_output_file")"
assert_line_before "$appended_pr_body" "## Validation" "<!-- BEGIN GENERATED SCREENSHOTS -->"
assert_line_before "$appended_pr_body" "<!-- END GENERATED SCREENSHOTS -->" "## Notes"
assert_not_contains "$appended_pr_body" "raw.githubusercontent.com"

capture_screenshots_dir="$workdir/capture-screenshots"
mkdir -p "$capture_screenshots_dir"

capture_xcodebuild_log="$capture_screenshots_dir/xcodebuild.log"
capture_xcrun_log="$capture_screenshots_dir/xcrun.log"
capture_generate_log="$capture_screenshots_dir/generate.log"
capture_promote_log="$capture_screenshots_dir/promote.log"
fake_capture_xcodebuild="$capture_screenshots_dir/xcodebuild"
fake_capture_xcrun="$capture_screenshots_dir/xcrun"
fake_capture_generate="$capture_screenshots_dir/generate-project.sh"
fake_capture_promoter="$capture_screenshots_dir/fake-promoter.py"

cat >"$fake_capture_xcodebuild" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_CAPTURE_XCODEBUILD_LOG}"

if [[ "$*" == *"-showdestinations"* ]]; then
    cat <<'OUT'
Available destinations for the "RoutineScreenshots" scheme:
    { platform:iOS Simulator, arch:arm64, id:SIM-ULATOR-ID, OS:26.0, name:iPhone 17 }
OUT
    exit 0
fi

result_bundle_path=""
while (( $# > 0 )); do
    case "$1" in
        -resultBundlePath)
            result_bundle_path="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [[ -n "$result_bundle_path" ]]; then
    mkdir -p "$result_bundle_path"
fi
EOF

cat >"$fake_capture_xcrun" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "$*" >>"${FAKE_CAPTURE_XCRUN_LOG}"

if [[ "$1" == "xcresulttool" && "$2" == "export" && "$3" == "attachments" ]]; then
    output_root=""
    while (( $# > 0 )); do
        case "$1" in
            --output-path)
                output_root="$2"
                shift 2
                ;;
            *)
                shift
                ;;
        esac
    done

    python3 - "$output_root" <<'PY'
import json
import pathlib
import sys
import uuid

output_root = pathlib.Path(sys.argv[1])
output_root.mkdir(parents=True, exist_ok=True)

attachments = []
slugs = [
    "dashboard-overview",
    "dashboard-lower-progress",
    "completion-undo-banner",
    "history-rich",
    "history-remove-confirmation",
    "history-after-removal",
    "management-menu",
    "add-routine-form-default",
    "add-routine-form-configured",
    "dashboard-after-add-routine",
    "dashboard-edit-mode",
    "add-group-form",
    "dashboard-after-add-group",
    "edit-group-form",
    "delete-group-confirmation",
    "rearrange-groups",
    "rearrange-routines",
    "settings-week-start",
]

counter = 0
for index, slug in enumerate(slugs, start=1):
    for appearance in ["dark", "light"]:
        counter += 1
        exported_file_name = f"capture-{counter:02d}.png"
        suggested_name = f"{index:02d}-{slug}-{appearance}_0_{str(uuid.uuid4()).upper()}.png"
        (output_root / exported_file_name).write_bytes(b"png")
        attachments.append(
            {
                "configurationName": "Test Scheme Action",
                "deviceId": "SIM-ULATOR-ID",
                "deviceName": "iPhone 17",
                "exportedFileName": exported_file_name,
                "isAssociatedWithFailure": False,
                "suggestedHumanReadableName": suggested_name,
                "timestamp": counter,
            }
        )

manifest = [{"attachments": attachments}]
(output_root / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
PY
    exit 0
fi

exit 0
EOF

cat >"$fake_capture_generate" <<'EOF'
#!/bin/zsh
set -euo pipefail

print -r -- "generate" >>"${FAKE_CAPTURE_GENERATE_LOG}"
EOF

cat >"$fake_capture_promoter" <<'EOF'
#!/usr/bin/env python3
import os
import pathlib
import sys

log_path = pathlib.Path(os.environ["CAPTURE_PROMOTE_LOG"])
log_path.write_text(" ".join(sys.argv[1:]) + "\n")
EOF

chmod +x "$fake_capture_xcodebuild" "$fake_capture_xcrun" "$fake_capture_generate" "$fake_capture_promoter"

run_capture_screenshots_and_capture() {
    local output_file="$capture_screenshots_dir/output.txt"
    run_command_and_capture "$output_file" env \
        FAKE_CAPTURE_XCODEBUILD_LOG="$capture_xcodebuild_log" \
        FAKE_CAPTURE_XCRUN_LOG="$capture_xcrun_log" \
        FAKE_CAPTURE_GENERATE_LOG="$capture_generate_log" \
        XCODEBUILD_BIN="$fake_capture_xcodebuild" \
        XCRUN_BIN="$fake_capture_xcrun" \
        GENERATE_PROJECT_SCRIPT="$fake_capture_generate" \
        ROUTINE_SCREENSHOT_ASSET_SCRIPT="$fake_capture_promoter" \
        ROUTINE_SCREENSHOT_OUTPUT_ROOT="$capture_screenshots_dir/raw" \
        ROUTINE_SCREENSHOT_CANONICAL_ROOT="$capture_screenshots_dir/canonical" \
        CAPTURE_PROMOTE_LOG="$capture_promote_log" \
        ./Scripts/capture-screenshots.sh
}

run_capture_screenshots_and_capture
assert_equals "$?" "0"
capture_output="$REPLY"
assert_contains "$capture_output" "Captured 36 screenshots on iPhone 17."
assert_contains "$capture_output" "Canonical output: $capture_screenshots_dir/canonical"
assert_equals "$(<"$capture_generate_log")" "generate"
promote_invocation="$(<"$capture_promote_log")"
assert_contains "$promote_invocation" "promote --export-root $capture_screenshots_dir/raw/"
assert_contains "$promote_invocation" "--canonical-root $capture_screenshots_dir/canonical --expected-count 36"

echo "Scripts/build-ios.sh, Scripts/test-ios.sh, Scripts/validate.sh, Scripts/release-preflight.sh, Scripts/run-ios.sh, Scripts/archive-ios.sh, Scripts/export-ios.sh, Scripts/capture-screenshots.sh, and Scripts/screenshot-assets.py script tests passed."
