#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

development_team="${DEVELOPMENT_TEAM-CX2KMQZQ7X}"
auth_key_path="${APP_STORE_CONNECT_AUTH_KEY_PATH:-}"
auth_key_id="${APP_STORE_CONNECT_AUTH_KEY_ID:-}"
auth_key_issuer_id="${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}"

if [[ -z "$development_team" ]]; then
    echo "error: DEVELOPMENT_TEAM is required to export an archive for distribution." >&2
    echo "Set it in your shell, e.g. DEVELOPMENT_TEAM=YOURTEAMID ./Scripts/export-ios.sh" >&2
    exit 1
fi

if [[ -n "$auth_key_path$auth_key_id$auth_key_issuer_id" ]]; then
    if [[ -z "$auth_key_path" || -z "$auth_key_id" || -z "$auth_key_issuer_id" ]]; then
        echo "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID must be set together." >&2
        exit 1
    fi
fi

archive_path="build/Routine.xcarchive"

if [[ ! -d "$archive_path" ]]; then
    echo "error: no archive found at $archive_path. Run ./Scripts/archive-ios.sh first." >&2
    exit 1
fi

export_options_dir="$(mktemp -d)"
trap 'rm -rf "$export_options_dir"' EXIT

export_options_path="$export_options_dir/ExportOptions.plist"
sed "s/DEVELOPMENT_TEAM_PLACEHOLDER/${development_team}/" \
    "${EXPORT_OPTIONS_TEMPLATE:-Scripts/ExportOptions.plist}" >"$export_options_path"

export_path="build/export"
rm -rf "$export_path"

xcodebuild_args=(
    -exportArchive
    -archivePath "$archive_path"
    -exportOptionsPlist "$export_options_path"
    -exportPath "$export_path"
    -allowProvisioningUpdates
)

if [[ -n "$auth_key_path" ]]; then
    xcodebuild_args+=(
        -authenticationKeyPath "$auth_key_path"
        -authenticationKeyID "$auth_key_id"
        -authenticationKeyIssuerID "$auth_key_issuer_id"
    )
fi

routine_xcodebuild_with_optional_quiet "${xcodebuild_args[@]}"

echo "Exported to $export_path"
