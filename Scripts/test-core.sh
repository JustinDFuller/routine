#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

arguments=(--package-path RoutineCore)

if ! [[ "${ROUTINE_VALIDATE_VERBOSE:-0}" == "1" || "${ROUTINE_SCRIPT_VERBOSE:-0}" == "1" ]]; then
    arguments=(--quiet "${arguments[@]}")
fi

swift test "${arguments[@]}"
