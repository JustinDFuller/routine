#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

./Scripts/generate-project.sh

destinations="$(xcodebuild -project Routine.xcodeproj -scheme RoutineApp -showdestinations 2>&1)"

if ! print -r -- "$destinations" | rg -q "Available destinations for the scheme"; then
    echo "Skipping generic iOS build: no eligible generic iOS destination is installed."
    exit 0
fi

xcodebuild -project Routine.xcodeproj -scheme RoutineApp -destination "generic/platform=iOS" build
