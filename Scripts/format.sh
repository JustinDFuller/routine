#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

swift-format format --in-place --recursive --parallel RoutineApp RoutineAppTests RoutineAppUITests RoutineCore
