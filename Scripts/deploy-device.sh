#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
configuration="${ROUTINE_BUILD_CONFIGURATION:-Debug}"
development_team="${DEVELOPMENT_TEAM-CX2KMQZQ7X}"
derived_data_path="${ROUTINE_DEPLOY_DEVICE_DERIVED_DATA_PATH:-DerivedData/DeployDevice}"
default_device_id="${ROUTINE_DEFAULT_IOS_DEVICE_ID:-00008140-001661682EB8401C}"

if [[ -z "$development_team" ]]; then
    echo "error: DEVELOPMENT_TEAM is required to deploy to a physical device." >&2
    echo "Set it in your shell, e.g. DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/deploy-device.sh" >&2
    exit 1
fi

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

device_id="${IOS_DEVICE_ID:-$default_device_id}"

if ! "$xcrun_bin" devicectl device info details --device "$device_id" >/dev/null; then
    echo "error: iPhone (${device_id}) is not connected. Plug in and unlock, then retry." >&2
    exit 1
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

echo "Deployed to ${device_id}."
