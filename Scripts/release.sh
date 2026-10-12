#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/app-store-connect-credentials.sh

if [[ -z "${CURRENT_PROJECT_VERSION:-}" ]]; then
    echo "error: CURRENT_PROJECT_VERSION is required for a release." >&2
    echo "Set it in your shell, e.g. CURRENT_PROJECT_VERSION=2 ./Scripts/release.sh" >&2
    exit 1
fi

routine_load_app_store_connect_credentials || exit 1
trap routine_cleanup_app_store_connect_credentials EXIT
trap 'exit 130' INT TERM HUP

if [[ "$ROUTINE_CREDENTIALS_SOURCE" == "keychain" ]]; then
    env \
        -u APP_STORE_CONNECT_AUTH_KEY_PATH \
        -u APP_STORE_CONNECT_AUTH_KEY_ID \
        -u APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID \
        ./Scripts/release-preflight.sh
else
    ./Scripts/release-preflight.sh
fi

./Scripts/upload-ios.sh

delivery_id_path="build/export/delivery-id.txt"

if [[ ! -s "$delivery_id_path" ]]; then
    echo "error: no delivery ID found at $delivery_id_path after the upload." >&2
    exit 1
fi

./Scripts/build-status.sh "$(<"$delivery_id_path")"
