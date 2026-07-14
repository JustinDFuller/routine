#!/bin/zsh

routine_verbose_enabled() {
    [[ "${ROUTINE_VALIDATE_VERBOSE:-0}" == "1" || "${ROUTINE_SCRIPT_VERBOSE:-0}" == "1" ]]
}

routine_xcodebuild() {
    "${XCODEBUILD_BIN:-xcodebuild}" "$@"
}

routine_xcodebuild_with_optional_quiet() {
    local -a args
    args=("$@")

    if ! routine_verbose_enabled; then
        args=(-quiet "${args[@]}")
    fi

    routine_xcodebuild "${args[@]}"
}

routine_show_destinations() {
    routine_xcodebuild -project Routine.xcodeproj -scheme RoutineApp -showdestinations 2>&1
}

routine_extract_concrete_simulator_names() {
    local destinations="$1"

    print -r -- "$destinations" | awk '
        /platform:iOS Simulator/ && /name:/ && $0 !~ /name:Any iOS Simulator Device/ {
            line = $0
            if (match(line, /name:[^,}]+/)) {
                name = substr(line, RSTART + 5, RLENGTH - 5)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", name)
                print name
            }
        }
    '
}

routine_validate_app_store_connect_auth_key_trio() {
    local auth_key_path="$1"
    local auth_key_id="$2"
    local auth_key_issuer_id="$3"

    if [[ -n "$auth_key_path$auth_key_id$auth_key_issuer_id" ]]; then
        if [[ -z "$auth_key_path" || -z "$auth_key_id" || -z "$auth_key_issuer_id" ]]; then
            echo "error: APP_STORE_CONNECT_AUTH_KEY_PATH, APP_STORE_CONNECT_AUTH_KEY_ID, and APP_STORE_CONNECT_AUTH_KEY_ISSUER_ID must be set together." >&2
            return 1
        fi
    fi

    return 0
}

routine_resolve_ios_test_destination() {
    local destinations="$1"
    local device_name=""
    local ipad_name=""

    while IFS= read -r candidate_name; do
        [[ -z "$candidate_name" ]] && continue

        if [[ -z "$device_name" && "$candidate_name" == iPhone* ]]; then
            device_name="$candidate_name"
            break
        fi

        if [[ -z "$ipad_name" && "$candidate_name" == iPad* ]]; then
            ipad_name="$candidate_name"
        fi
    done < <(routine_extract_concrete_simulator_names "$destinations")

    device_name="${device_name:-$ipad_name}"
    [[ -n "$device_name" ]] || return 1

    print -r -- "platform=iOS Simulator,name=$device_name"
}
