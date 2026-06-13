#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

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
    env "$@" "$validate_repo/Scripts/validate.sh" >"$output_file" 2>&1
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

echo "Scripts/build-ios.sh, Scripts/test-ios.sh, Scripts/validate.sh, and Scripts/run-ios.sh script tests passed."
