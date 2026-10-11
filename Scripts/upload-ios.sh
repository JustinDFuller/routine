#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

# altool refuses to upload archives built with a beta Xcode/SDK, and resolves via
# whichever Xcode DEVELOPER_DIR points at. Default to the release Xcode here
# regardless of the system-wide `xcode-select` toolchain, which stays on the beta
# for everyday development. Override with DEVELOPER_DIR if needed.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

source ./Scripts/xcode-destination-helpers.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
auth_key_path="${APP_STORE_CONNECT_AUTH_KEY_PATH:-}"
auth_key_id="${APP_STORE_CONNECT_AUTH_KEY_ID:-}"
auth_key_issuer_id="${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}"
ipa_path="${ROUTINE_UPLOAD_IPA_PATH:-build/export/Routine.ipa}"

routine_validate_app_store_connect_auth_key_trio "$auth_key_path" "$auth_key_id" "$auth_key_issuer_id" || exit 1

if [[ -z "$auth_key_path" || -z "$auth_key_id" || -z "$auth_key_issuer_id" ]]; then
    echo "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID are required to upload to App Store Connect." >&2
    echo "Set them in your shell, e.g. APP_STORE_CONNECT_AUTH_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8 APP_STORE_CONNECT_AUTH_KEY_ID=XXXXXXXXXX APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ./Scripts/upload-ios.sh" >&2
    exit 1
fi

if [[ ! -f "$ipa_path" ]]; then
    echo "error: no exported .ipa found at $ipa_path. Run ./Scripts/export-ios.sh first." >&2
    exit 1
fi

"$xcrun_bin" altool --upload-package "$ipa_path" \
    --api-key "$auth_key_id" \
    --api-issuer "$auth_key_issuer_id" \
    --p8-file-path "$auth_key_path"

echo "Uploaded $ipa_path to App Store Connect."
