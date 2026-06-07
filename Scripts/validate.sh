#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

./Scripts/generate-project.sh
./Scripts/check-format.sh
./Scripts/lint.sh
./Scripts/test-core.sh
./Scripts/build-ios.sh
./Scripts/test-ios.sh
