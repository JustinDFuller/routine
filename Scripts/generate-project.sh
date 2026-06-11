#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

if command -v xcodegen >/dev/null 2>&1; then
    xcodegen_cmd="$(command -v xcodegen)"
elif [[ -x /opt/homebrew/bin/xcodegen ]]; then
    xcodegen_cmd="/opt/homebrew/bin/xcodegen"
elif [[ -x /usr/local/bin/xcodegen ]]; then
    xcodegen_cmd="/usr/local/bin/xcodegen"
else
    echo "error: xcodegen is required to generate Routine.xcodeproj." >&2
    echo "Install it with Homebrew or add it to PATH, then rerun ./Scripts/generate-project.sh." >&2
    exit 127
fi

"$xcodegen_cmd" --spec project.yml
