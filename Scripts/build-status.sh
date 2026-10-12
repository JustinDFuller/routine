#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

source ./Scripts/xcode-destination-helpers.sh
source ./Scripts/app-store-connect-credentials.sh

xcrun_bin="${XCRUN_BIN:-xcrun}"
interval="${ROUTINE_BUILD_STATUS_INTERVAL:-30}"
timeout="${ROUTINE_BUILD_STATUS_TIMEOUT:-1800}"
delivery_id="${1:-}"

if [[ -z "$delivery_id" ]]; then
    echo "error: a delivery ID is required." >&2
    echo "Usage: ./Scripts/build-status.sh <delivery-id> (the ID is in build/export/delivery-id.txt after a release)" >&2
    exit 1
fi

for setting in "$interval" "$timeout"; do
    if [[ ! "$setting" =~ '^[0-9]+([.][0-9]+)?$' ]]; then
        echo "error: ROUTINE_BUILD_STATUS_INTERVAL and ROUTINE_BUILD_STATUS_TIMEOUT must be non-negative numbers of seconds." >&2
        exit 1
    fi
done

routine_load_app_store_connect_credentials || exit 1
trap routine_cleanup_app_store_connect_credentials EXIT
trap 'exit 130' INT TERM HUP
routine_validate_app_store_connect_auth_key_trio \
    "${APP_STORE_CONNECT_AUTH_KEY_PATH:-}" \
    "${APP_STORE_CONNECT_AUTH_KEY_ID:-}" \
    "${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}" || exit 1

if [[ -z "${APP_STORE_CONNECT_AUTH_KEY_PATH:-}" ]]; then
    echo "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID are required to check App Store Connect processing." >&2
    echo "Store them once with ./Scripts/store-app-store-connect-credentials.sh, or set them in your shell." >&2
    exit 1
fi

state="UNKNOWN"
build_label="${CURRENT_PROJECT_VERSION:-unknown}"
elapsed_start=$SECONDS

report_outcome() {
    echo "Build $build_label (delivery $delivery_id) processing state: $state"

    if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        {
            echo "### App Store Connect processing"
            echo ""
            echo "| Build | Delivery ID | Processing state |"
            echo "| --- | --- | --- |"
            echo "| $build_label | \`$delivery_id\` | $state |"
        } >>"$GITHUB_STEP_SUMMARY"
    fi
}

while true; do
    response=""
    if response="$("$xcrun_bin" altool --build-status \
        --delivery-id "$delivery_id" \
        --api-key "$APP_STORE_CONNECT_AUTH_KEY_ID" \
        --api-issuer "$APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID" \
        --p8-file-path "$APP_STORE_CONNECT_AUTH_KEY_PATH" \
        --output-format json 2>&1)"; then
        queried_state="$(print -r -- "$response" | plutil -extract app-store-attributes.processingState raw -o - - 2>/dev/null || true)"
        queried_version="$(print -r -- "$response" | plutil -extract app-store-attributes.version raw -o - - 2>/dev/null || true)"

        if [[ -n "$queried_state" ]]; then
            state="$queried_state"
        fi

        if [[ -n "$queried_version" ]]; then
            build_label="$queried_version"
        fi
    else
        echo "Status query failed, will retry: $response" >&2
    fi

    case "$state" in
        VALID)
            report_outcome
            exit 0
            ;;
        FAILED|INVALID)
            echo "error: App Store Connect reported processing state $state for delivery $delivery_id." >&2
            report_outcome
            exit 1
            ;;
    esac

    if (( SECONDS - elapsed_start >= timeout )); then
        echo "error: App Store Connect did not finish processing delivery $delivery_id within ${timeout}s." >&2
        echo "Check again later with: make build-status DELIVERY_ID=$delivery_id" >&2
        report_outcome
        exit 1
    fi

    echo "Processing state is $state; checking again in ${interval}s."
    sleep "$interval"
done
