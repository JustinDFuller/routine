#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

log_file="$workdir/xcodebuild.log"
generate_log="$workdir/generate.log"
fake_xcodebuild="$workdir/xcodebuild"
fake_generate="$workdir/generate-project.sh"

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

assert_contains() {
    local haystack="$1"
    local needle="$2"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "Expected to find '$needle' in:"
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

run_build_ios_and_capture() {
    local output_file="$workdir/output.txt"
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
    local output_file="$workdir/output.txt"
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
assert_contains "$default_build_log" "-configuration Debug -destination generic/platform=iOS Simulator build"

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
assert_contains "$release_build_log" "-configuration Release DEVELOPMENT_TEAM=TEAM123ABC -destination generic/platform=iOS build"

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
assert_contains "$override_log" "-destination platform=iOS Simulator,name=Custom Device,OS=99.0 test"
if [[ "$override_log" == *"-showdestinations"* ]]; then
    echo "Expected IOS_TEST_DESTINATION override to bypass destination discovery."
    exit 1
fi

: >"$log_file"
: >"$generate_log"
showdestinations_output=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:dvtdevice-DVTiOSDeviceSimulatorPlaceholder-iphonesimulator:placeholder, name:Any iOS Simulator Device }\n    { platform:iOS Simulator, arch:arm64, id:AAAA, OS:26.0, name:iPad Pro (13-inch) }\n    { platform:iOS Simulator, arch:arm64, id:BBBB, OS:26.0, name:iPhone 17 }\n    { platform:iOS Simulator, arch:arm64, id:CCCC, OS:26.0, name:iPhone Air }\n'
run_test_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$showdestinations_output"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
auto_log="$(<"$log_file")"
assert_contains "$auto_log" "-showdestinations"
assert_contains "$auto_log" "-destination platform=iOS Simulator,name=iPhone 17 test"

: >"$log_file"
: >"$generate_log"
iPad_only_output=$'Available destinations for the "RoutineApp" scheme:\n    { platform:iOS Simulator, arch:arm64, id:AAAA, OS:26.0, name:iPad mini (A17 Pro) }\n    { platform:iOS Simulator, arch:arm64, id:BBBB, OS:26.0, name:iPad Pro (13-inch) }\n'
run_test_ios_and_capture FAKE_SHOWDESTINATIONS_OUTPUT="$iPad_only_output"
assert_equals "$?" "0"
assert_equals "$(<"$generate_log")" "generate"
ipad_log="$(<"$log_file")"
assert_contains "$ipad_log" "-destination platform=iOS Simulator,name=iPad mini (A17 Pro) test"

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

echo "Scripts/build-ios.sh and Scripts/test-ios.sh script tests passed."
