ROUTINE_ASC_KEYCHAIN_ACCOUNT="release"
ROUTINE_ASC_KEYCHAIN_SERVICE="routine.app-store-connect"
ROUTINE_CREDENTIALS_SOURCE="none"
ROUTINE_LOADED_KEY_DIR=""

routine_cleanup_app_store_connect_credentials() {
    if [[ -n "$ROUTINE_LOADED_KEY_DIR" ]]; then
        rm -rf "$ROUTINE_LOADED_KEY_DIR"
        ROUTINE_LOADED_KEY_DIR=""
    fi
}

routine_load_app_store_connect_credentials() {
    local security_bin="${SECURITY_BIN:-security}"
    local item=""
    local item_status=0
    local key_id=""
    local issuer_id=""
    local encoded_key=""

    if [[ -n "${APP_STORE_CONNECT_AUTH_KEY_PATH:-}${APP_STORE_CONNECT_AUTH_KEY_ID:-}${APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID:-}" ]]; then
        ROUTINE_CREDENTIALS_SOURCE="environment"
        return 0
    fi

    item="$("$security_bin" find-generic-password \
        -s "$ROUTINE_ASC_KEYCHAIN_SERVICE" \
        -a "$ROUTINE_ASC_KEYCHAIN_ACCOUNT" \
        -w 2>/dev/null)" || item_status=$?

    if (( item_status == 44 )); then
        ROUTINE_CREDENTIALS_SOURCE="none"
        return 0
    fi

    if (( item_status != 0 )); then
        echo "error: App Store Connect credentials were not provided: the Keychain item '$ROUTINE_ASC_KEYCHAIN_SERVICE' could not be read (security exited $item_status). Approve the Keychain prompt with Allow, or set APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID." >&2
        return 1
    fi

    IFS=: read -r key_id issuer_id encoded_key <<<"$item"

    if [[ -z "$key_id" || -z "$issuer_id" || -z "$encoded_key" ]]; then
        echo "error: the Keychain item '$ROUTINE_ASC_KEYCHAIN_SERVICE' is malformed. Re-run ./Scripts/store-app-store-connect-credentials.sh." >&2
        return 1
    fi

    ROUTINE_LOADED_KEY_DIR="$(mktemp -d "${TMPDIR:-/tmp}/routine-asc.XXXXXX")"

    local key_path="$ROUTINE_LOADED_KEY_DIR/AuthKey_${key_id}.p8"
    if ! (umask 077 && print -rn -- "$encoded_key" | base64 --decode >"$key_path") || ! chmod 600 "$key_path"; then
        routine_cleanup_app_store_connect_credentials
        echo "error: the Keychain item '$ROUTINE_ASC_KEYCHAIN_SERVICE' could not be decoded. Re-run ./Scripts/store-app-store-connect-credentials.sh." >&2
        return 1
    fi

    export APP_STORE_CONNECT_AUTH_KEY_PATH="$key_path"
    export APP_STORE_CONNECT_AUTH_KEY_ID="$key_id"
    export APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID="$issuer_id"
    ROUTINE_CREDENTIALS_SOURCE="keychain"
}
