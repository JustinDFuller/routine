#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

arguments=(lint --strict --config .swiftlint.yml)

if ! [[ "${ROUTINE_VALIDATE_VERBOSE:-0}" == "1" || "${ROUTINE_SCRIPT_VERBOSE:-0}" == "1" ]]; then
    arguments=(lint --quiet --strict --config .swiftlint.yml)
fi

swiftlint "${arguments[@]}"
