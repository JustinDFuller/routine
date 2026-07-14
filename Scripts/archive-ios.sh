#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

development_team="${DEVELOPMENT_TEAM-CX2KMQZQ7X}"
auth_key_path="${APP_STORE_CONNECT_AUTH_KEY_PATH:-}"
auth_key_id="${APP_STORE_CONNECT_AUTH_KEY_ID:-}"
auth_key_issuer_id="${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}"

if [[ -z "$development_team" ]]; then
    echo "error: DEVELOPMENT_TEAM is required to archive for distribution." >&2
    echo "Set it in your shell, e.g. DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/archive-ios.sh" >&2
    exit 1
fi

if [[ -z "${CURRENT_PROJECT_VERSION:-}" ]]; then
    echo "error: CURRENT_PROJECT_VERSION is required to archive for distribution." >&2
    echo "Set it in your shell, e.g. CURRENT_PROJECT_VERSION=2 ./Scripts/archive-ios.sh" >&2
    exit 1
fi

routine_validate_app_store_connect_auth_key_trio "$auth_key_path" "$auth_key_id" "$auth_key_issuer_id" || exit 1

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

archive_path="build/Routine.xcarchive"
rm -rf "$archive_path"

xcodebuild_args=(
    -project Routine.xcodeproj
    -scheme RoutineApp
    -configuration Release
    -destination "generic/platform=iOS"
    -archivePath "$archive_path"
    "DEVELOPMENT_TEAM=${development_team}"
    "CURRENT_PROJECT_VERSION=${CURRENT_PROJECT_VERSION}"
)

if [[ -n "$auth_key_path" ]]; then
    xcodebuild_args+=(
        -authenticationKeyPath "$auth_key_path"
        -authenticationKeyID "$auth_key_id"
        -authenticationKeyIssuerID "$auth_key_issuer_id"
    )
fi

routine_xcodebuild_with_optional_quiet "${xcodebuild_args[@]}" -allowProvisioningUpdates archive

echo "Archived to $archive_path"
