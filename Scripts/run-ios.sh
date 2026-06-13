#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
open_bin="${OPEN_BIN:-open}"
configuration="${ROUTINE_BUILD_CONFIGURATION:-Debug}"
derived_data_path="${ROUTINE_RUN_DERIVED_DATA_PATH:-DerivedData/RunIOS}"

resolve_simulator() {
    local mode="$1"
    local argument="${2:-}"
    local simulator_json

    simulator_json="$("$xcrun_bin" simctl list devices available -j)"

    SIMULATOR_JSON="$simulator_json" python3 - "$mode" "$argument" <<'PY'
import json
import os
import sys

mode = sys.argv[1]
argument = sys.argv[2]
payload = json.loads(os.environ["SIMULATOR_JSON"])

devices = []
for runtime_devices in payload.get("devices", {}).values():
    for device in runtime_devices:
        if not device.get("isAvailable", True):
            continue
        devices.append(device)


def is_iphone(device):
    return str(device.get("name", "")).startswith("iPhone")


def emit(device):
    sys.stdout.write(f"{device['udid']}\t{device['name']}\t{device.get('state', '')}")
    return 0


if mode == "name":
    matches = [device for device in devices if device.get("name") == argument]
    iphone_matches = [device for device in matches if is_iphone(device)]
    if iphone_matches:
        raise SystemExit(emit(iphone_matches[0]))
    if matches:
        raise SystemExit(emit(matches[0]))
    raise SystemExit(1)

booted_iphones = [
    device for device in devices
    if is_iphone(device) and device.get("state") == "Booted"
]
if booted_iphones:
    raise SystemExit(emit(booted_iphones[0]))

available_iphones = [device for device in devices if is_iphone(device)]
if available_iphones:
    raise SystemExit(emit(available_iphones[0]))

raise SystemExit(1)
PY
}

boot_simulator_if_needed() {
    local device_id="$1"

    if ! "$xcrun_bin" simctl bootstatus "$device_id" -b >/dev/null 2>&1; then
        "$xcrun_bin" simctl boot "$device_id"
        "$xcrun_bin" simctl bootstatus "$device_id" -b
    fi
}

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

device_id="${IOS_RUN_DEVICE_ID:-}"
device_name=""

if [[ -n "$device_id" ]]; then
    :
elif [[ -n "${IOS_RUN_DEVICE_NAME:-}" ]]; then
    resolved_simulator="$(resolve_simulator name "${IOS_RUN_DEVICE_NAME}")" || {
        echo "error: unable to find an available simulator named '${IOS_RUN_DEVICE_NAME}'." >&2
        exit 1
    }
    IFS=$'\t' read -r device_id device_name _ <<<"$resolved_simulator"
else
    resolved_simulator="$(resolve_simulator auto)" || {
        echo "error: unable to find an available iPhone simulator." >&2
        exit 1
    }
    IFS=$'\t' read -r device_id device_name _ <<<"$resolved_simulator"
fi

boot_simulator_if_needed "$device_id"

routine_xcodebuild_with_optional_quiet \
    -project Routine.xcodeproj \
    -scheme RoutineApp \
    -configuration "$configuration" \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_data_path" \
    build

app_path="$derived_data_path/Build/Products/${configuration}-iphonesimulator/Routine.app"

if [[ ! -d "$app_path" ]]; then
    echo "error: built app not found at ${app_path}." >&2
    exit 1
fi

"$xcrun_bin" simctl install "$device_id" "$app_path"
"$open_bin" -a Simulator
"$xcrun_bin" simctl launch --terminate-running-process "$device_id" com.justinfuller.routine
