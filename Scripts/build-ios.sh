#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

./Scripts/generate-project.sh

destinations="$(xcodebuild -project Routine.xcodeproj -scheme RoutineApp -showdestinations 2>&1)"

if print -r -- "$destinations" | grep -Fq "Unable to find a destination matching"; then
    echo "Skipping generic iOS build: no eligible generic iOS destination is installed."
    exit 0
fi

if print -r -- "$destinations" | grep -Fq "Ineligible destinations for the \"RoutineApp\" scheme:"; then
    echo "Skipping generic iOS build: no eligible generic iOS destination is installed."
    exit 0
fi

xcodebuild -project Routine.xcodeproj -scheme RoutineApp -destination "generic/platform=iOS" build
