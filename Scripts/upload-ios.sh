#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

# altool refuses to upload archives built with a beta Xcode/SDK, and resolves via
# whichever Xcode DEVELOPER_DIR points at. Default to the release Xcode here
# regardless of the system-wide `xcode-select` toolchain, which stays on the beta
# for everyday development. Override with DEVELOPER_DIR if needed.
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

source ./Scripts/xcode-destination-helpers.sh
source ./Scripts/app-store-connect-credentials.sh

upload_log=""

routine_load_app_store_connect_credentials || exit 1
trap 'rm -f "$upload_log"; routine_cleanup_app_store_connect_credentials' EXIT
trap 'exit 130' INT TERM HUP

xcrun_bin="${XCRUN_BIN:-xcrun}"
auth_key_path="${APP_STORE_CONNECT_AUTH_KEY_PATH:-}"
auth_key_id="${APP_STORE_CONNECT_AUTH_KEY_ID:-}"
auth_key_issuer_id="${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}"
ipa_path="${ROUTINE_UPLOAD_IPA_PATH:-build/export/Routine.ipa}"

routine_validate_app_store_connect_auth_key_trio "$auth_key_path" "$auth_key_id" "$auth_key_issuer_id" || exit 1

if [[ -z "$auth_key_path" || -z "$auth_key_id" || -z "$auth_key_issuer_id" ]]; then
    echo "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID are required to upload to App Store Connect." >&2
    echo "Store them once with ./Scripts/store-app-store-connect-credentials.sh, or set them in your shell, e.g. APP_STORE_CONNECT_AUTH_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXX.p8 APP_STORE_CONNECT_AUTH_KEY_ID=XXXXXXXXXX APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx ./Scripts/upload-ios.sh" >&2
    exit 1
fi

if [[ ! -f "$ipa_path" ]]; then
    echo "error: no exported .ipa found at $ipa_path. Run ./Scripts/export-ios.sh first." >&2
    exit 1
fi

delivery_id_path="${ipa_path:h}/delivery-id.txt"
rm -f "$delivery_id_path"

upload_log="$(mktemp)"

"$xcrun_bin" altool --upload-package "$ipa_path" \
    --api-key "$auth_key_id" \
    --api-issuer "$auth_key_issuer_id" \
    --p8-file-path "$auth_key_path" 2>&1 | tee "$upload_log"

delivery_id="$(sed -n 's/.*Delivery UUID: *\([0-9A-Fa-f-]\{36\}\).*/\1/p' "$upload_log" | head -n 1)"

if [[ -z "$delivery_id" ]]; then
    echo "error: the upload was accepted but altool returned no Delivery UUID, so processing cannot be checked." >&2
    exit 1
fi

print -r -- "$delivery_id" >"$delivery_id_path"

echo "Uploaded $ipa_path to App Store Connect."
echo "Delivery ID: $delivery_id (saved to $delivery_id_path)"
