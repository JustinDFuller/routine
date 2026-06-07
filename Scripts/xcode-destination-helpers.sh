#!/bin/zsh

routine_xcodebuild() {
    "${XCODEBUILD_BIN:-xcodebuild}" "$@"
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
