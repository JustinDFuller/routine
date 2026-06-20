#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -z "${CURRENT_PROJECT_VERSION:-}" ]]; then
    echo "error: CURRENT_PROJECT_VERSION is required for release preflight." >&2
    echo "Set it in your shell, e.g. CURRENT_PROJECT_VERSION=2 ./Scripts/release-preflight.sh" >&2
    exit 1
fi

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

run_stage "validate" ./Scripts/validate.sh
run_stage "build-release" env ROUTINE_BUILD_CONFIGURATION=Release ./Scripts/build-ios.sh
run_stage "archive" env CURRENT_PROJECT_VERSION="${CURRENT_PROJECT_VERSION}" ./Scripts/archive-ios.sh
run_stage "export" ./Scripts/export-ios.sh

echo "Release preflight finished for CURRENT_PROJECT_VERSION=${CURRENT_PROJECT_VERSION}."
