#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

resolved_destination="${IOS_TEST_DESTINATION:-}"

if [[ -z "$resolved_destination" ]]; then
    destinations="$(routine_show_destinations)"
    if ! resolved_destination="$(routine_resolve_ios_test_destination "$destinations")"; then
        echo "Skipping iOS tests: no concrete iOS Simulator destination is available."
        exit 0
    fi
fi

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

routine_xcodebuild_with_optional_quiet \
    -project Routine.xcodeproj \
    -scheme RoutineApp \
    -destination "${resolved_destination}" \
    test
