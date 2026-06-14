#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
timestamp="$(date '+%Y%m%d-%H%M%S')"
output_root="${ROUTINE_SCREENSHOT_OUTPUT_ROOT:-Screenshots/local}/${timestamp}"
canonical_root="${ROUTINE_SCREENSHOT_CANONICAL_ROOT:-Docs/Screenshots}"
result_bundle_path="${output_root}/RoutineScreenshots.xcresult"
destination_override="${ROUTINE_SCREENSHOT_DESTINATION:-${IOS_TEST_DESTINATION:-}}"
screenshot_asset_script="${ROUTINE_SCREENSHOT_ASSET_SCRIPT:-./Scripts/screenshot-assets.py}"

mkdir -p "$output_root"

showdestinations_output() {
    routine_xcodebuild -project Routine.xcodeproj -scheme RoutineScreenshots -showdestinations 2>&1
}

resolve_simulator_record() {
    local destinations="$1"
    local requested_name="${2:-}"
    local requested_id="${3:-}"

    print -r -- "$destinations" | awk -v requested_name="$requested_name" -v requested_id="$requested_id" '
        /platform:iOS Simulator/ && /id:/ && /name:/ && $0 !~ /name:Any iOS Simulator Device/ {
            line = $0
            if (!match(line, /id:[^,}]+/)) {
                next
            }
            id = substr(line, RSTART + 3, RLENGTH - 3)
            if (!match(line, /name:[^,}]+/)) {
                next
            }
            name = substr(line, RSTART + 5, RLENGTH - 5)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
            gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
            if (name !~ /^iPhone/) {
                next
            }
            if (requested_id != "" && id != requested_id) {
                next
            }
            if (requested_name != "" && name != requested_name) {
                next
            }
            print id "|" name
            exit
        }
    '
}

parse_destination_override() {
    local destination="$1"
    local destination_id=""
    local destination_name=""

    if [[ "$destination" =~ 'id=([^,]+)' ]]; then
        destination_id="${match[1]}"
    fi

    if [[ "$destination" =~ 'name=([^,]+)' ]]; then
        destination_name="${match[1]}"
    fi

    print -r -- "${destination_id}|${destination_name}"
}

simulator_udid=""
cleanup() {
    if [[ -n "$simulator_udid" ]]; then
        "$xcrun_bin" simctl status_bar "$simulator_udid" clear >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

destinations="$(showdestinations_output)"

if [[ -n "$destination_override" ]]; then
    override_parts="$(parse_destination_override "$destination_override")"
    requested_id="${override_parts%%|*}"
    requested_name="${override_parts#*|}"
    simulator_record="$(resolve_simulator_record "$destinations" "$requested_name" "$requested_id")"
    resolved_destination="$destination_override"
else
    simulator_record="$(resolve_simulator_record "$destinations")"
    resolved_destination=""
fi

if [[ -z "$simulator_record" ]]; then
    echo "Skipping screenshot capture: no concrete iPhone simulator destination is available."
    exit 0
fi

simulator_udid="${simulator_record%%|*}"
simulator_name="${simulator_record#*|}"

if [[ -z "$resolved_destination" ]]; then
    resolved_destination="platform=iOS Simulator,id=${simulator_udid}"
fi

"$xcrun_bin" simctl boot "$simulator_udid" >/dev/null 2>&1 || true
"$xcrun_bin" simctl bootstatus "$simulator_udid" -b
"$xcrun_bin" simctl status_bar "$simulator_udid" override \
    --time 9:41 \
    --dataNetwork wifi \
    --wifiMode active \
    --wifiBars 3 \
    --cellularMode active \
    --cellularBars 4 \
    --operatorName '' \
    --batteryState charged \
    --batteryLevel 100

rm -rf "$result_bundle_path"

routine_xcodebuild_with_optional_quiet \
    -project Routine.xcodeproj \
    -scheme RoutineScreenshots \
    -destination "$resolved_destination" \
    -resultBundlePath "$result_bundle_path" \
    test

"$xcrun_bin" xcresulttool export attachments \
    --path "$result_bundle_path" \
    --output-path "$output_root" \
    --filter "*.png"

png_count="$(find "$output_root" -type f -name '*.png' | wc -l | tr -d ' ')"
expected_png_count=36

if [[ "$png_count" != "$expected_png_count" ]]; then
    echo "error: expected ${expected_png_count} screenshots, found ${png_count} in ${output_root}." >&2
    exit 1
fi

python3 "$screenshot_asset_script" promote \
    --export-root "$output_root" \
    --canonical-root "$canonical_root" \
    --expected-count "$expected_png_count"

echo "Captured ${png_count} screenshots on ${simulator_name}."
echo "Output: ${output_root}"
echo "Canonical output: ${canonical_root}"
