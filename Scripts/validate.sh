#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

log_dir="$(mktemp -d)"
trap 'rm -rf "$log_dir"' EXIT

run_stage() {
    local stage_name="$1"
    shift

    local -a command
    command=("$@")

    local log_file="$log_dir/${stage_name}.log"
    local exit_code=0
    local command_display="${(j: :)command}"

    if [[ "${ROUTINE_VALIDATE_VERBOSE:-0}" == "1" ]]; then
        set +e
        "${command[@]}" 2>&1 | tee "$log_file"
        exit_code=${pipestatus[1]}
        set -e
    else
        set +e
        "${command[@]}" >"$log_file" 2>&1
        exit_code=$?
        set -e
    fi

    if (( exit_code != 0 )); then
        echo "FAIL ${stage_name}"
        echo "Command: ${command_display}"
        echo "Exit code: ${exit_code}"
        if [[ -s "$log_file" ]]; then
            echo "Output:"
            cat "$log_file"
        fi
        exit "$exit_code"
    fi

    echo "PASS ${stage_name}"

    while IFS= read -r skip_line; do
        [[ -z "$skip_line" ]] && continue
        echo "$skip_line"
    done < <(grep '^Skipping' "$log_file" || true)
}

run_stage "generate-project" ./Scripts/generate-project.sh
run_stage "test-ios-script-tests" ./Scripts/test-ios-script-tests.sh
run_stage "test-core" ./Scripts/test-core.sh
run_stage "test-ios" ./Scripts/test-ios.sh
run_stage "check-format" ./Scripts/check-format.sh
run_stage "lint" ./Scripts/lint.sh
run_stage "build-ios" ./Scripts/build-ios.sh
