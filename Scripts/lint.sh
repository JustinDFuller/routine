#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

swiftlint lint --strict --config .swiftlint.yml
