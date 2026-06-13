#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

swift-format lint --strict --recursive --parallel Scripts RoutineApp RoutineAppTests RoutineAppUITests RoutineAppScreenshotTests RoutineCore
