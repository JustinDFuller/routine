#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

if [[ -z "${IOS_TEST_DESTINATION:-}" ]]; then
    echo "Skipping iOS tests: set IOS_TEST_DESTINATION to a valid xcodebuild destination."
    exit 0
fi

./Scripts/generate-project.sh

xcodebuild \
    -project Routine.xcodeproj \
    -scheme RoutineApp \
    -destination "${IOS_TEST_DESTINATION}" \
    test
