#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
configuration="${ROUTINE_BUILD_CONFIGURATION:-Debug}"
development_team="${DEVELOPMENT_TEAM-CX2KMQZQ7X}"
derived_data_path="${ROUTINE_DEPLOY_DEVICE_DERIVED_DATA_PATH:-DerivedData/DeployDevice}"

if [[ -z "$development_team" ]]; then
    echo "error: DEVELOPMENT_TEAM is required to deploy to a physical device." >&2
    echo "Set it in your shell, e.g. DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/deploy-device.sh" >&2
    exit 1
fi

resolve_device() {
    local devices_json

    devices_json="$("$xcrun_bin" devicectl list devices --quiet --json-output -)"

    DEVICECTL_DEVICES_JSON="$devices_json" python3 - <<'PY'
import json
import os
import sys

payload = json.loads(os.environ["DEVICECTL_DEVICES_JSON"])
devices = payload.get("result", {}).get("devices", [])

for device in devices:
    hardware = device.get("hardwareProperties", {})
    connection = device.get("connectionProperties", {})

    if hardware.get("reality") != "physical":
        continue
    if hardware.get("platform") != "iOS":
        continue
    if connection.get("tunnelState") != "connected":
        continue

    identifier = device.get("identifier", "")
    name = device.get("deviceProperties", {}).get("name", "")
    if not identifier:
        continue

    sys.stdout.write(f"{identifier}\t{name}")
    raise SystemExit(0)

raise SystemExit(1)
PY
}

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

device_id="${IOS_DEVICE_ID:-}"
device_name=""

if [[ -n "$device_id" ]]; then
    :
else
    resolved_device="$(resolve_device)" || {
        echo "Skipping device deploy: no connected iPhone was found."
        exit 0
    }
    IFS=$'\t' read -r device_id device_name <<<"$resolved_device"
fi

routine_xcodebuild_with_optional_quiet \
    -project Routine.xcodeproj \
    -scheme RoutineApp \
    -configuration "$configuration" \
    -destination "id=$device_id" \
    -derivedDataPath "$derived_data_path" \
    "DEVELOPMENT_TEAM=${development_team}" \
    -allowProvisioningUpdates \
    build

app_path="$derived_data_path/Build/Products/${configuration}-iphoneos/Routine.app"

if [[ ! -d "$app_path" ]]; then
    echo "error: built app not found at ${app_path}." >&2
    exit 1
fi

"$xcrun_bin" devicectl device install app --device "$device_id" "$app_path"

if [[ "${ROUTINE_DEPLOY_DEVICE_LAUNCH:-1}" == "1" ]]; then
    "$xcrun_bin" devicectl device process launch --device "$device_id" com.justinfuller.routine
fi

echo "Deployed to ${device_name:-$device_id}."
