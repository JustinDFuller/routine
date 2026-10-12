#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh
source ./Scripts/app-store-connect-credentials.sh

if [[ -z "${CURRENT_PROJECT_VERSION:-}" ]]; then
    echo "error: CURRENT_PROJECT_VERSION is required for a release." >&2
    echo "Set it in your shell, e.g. CURRENT_PROJECT_VERSION=2 ./Scripts/release.sh" >&2
    exit 1
fi

routine_load_app_store_connect_credentials || exit 1
trap routine_cleanup_app_store_connect_credentials EXIT
trap 'exit 130' INT TERM HUP

routine_validate_app_store_connect_auth_key_trio \
    "${APP_STORE_CONNECT_AUTH_KEY_PATH:-}" \
    "${APP_STORE_CONNECT_AUTH_KEY_ID:-}" \
    "${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}" || exit 1

if [[ -z "${APP_STORE_CONNECT_AUTH_KEY_PATH:-}" ]]; then
    echo "error: App Store Connect credentials are required for a release." >&2
    echo "Store them once with ./Scripts/store-app-store-connect-credentials.sh, or set APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID in your shell." >&2
    exit 1
fi

./Scripts/release-preflight.sh

./Scripts/upload-ios.sh

ipa_path="${ROUTINE_UPLOAD_IPA_PATH:-build/export/Routine.ipa}"
delivery_id_path="${ipa_path:h}/delivery-id.txt"

if [[ ! -s "$delivery_id_path" ]]; then
    echo "error: no delivery ID found at $delivery_id_path after the upload." >&2
    exit 1
fi

./Scripts/build-status.sh "$(<"$delivery_id_path")"
