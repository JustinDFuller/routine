#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

source ./Scripts/xcode-destination-helpers.sh

configuration="${ROUTINE_BUILD_CONFIGURATION:-Debug}"

"${GENERATE_PROJECT_SCRIPT:-./Scripts/generate-project.sh}"

destinations="$(routine_show_destinations)"

xcodebuild_args=(
    -project Routine.xcodeproj
    -scheme RoutineApp
    -configuration "$configuration"
)

if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
    xcodebuild_args+=("DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM}")
fi

if print -r -- "$destinations" | grep -Fq "Unable to find a destination matching"; then
    echo "Skipping iOS build: no eligible generic simulator or device destination is installed."
    exit 0
fi

if print -r -- "$destinations" | grep -Fq "Ineligible destinations for the \"RoutineApp\" scheme:"; then
    echo "Skipping iOS build: no eligible generic simulator or device destination is installed."
    exit 0
fi

if print -r -- "$destinations" | grep -Fq "platform:iOS Simulator"; then
    routine_xcodebuild_with_optional_quiet "${xcodebuild_args[@]}" -destination "generic/platform=iOS Simulator" build
    exit 0
fi

if print -r -- "$destinations" | grep -Fq "platform:iOS"; then
    routine_xcodebuild_with_optional_quiet "${xcodebuild_args[@]}" -destination "generic/platform=iOS" build
    exit 0
fi

echo "Skipping iOS build: no eligible generic simulator or device destination is installed."
