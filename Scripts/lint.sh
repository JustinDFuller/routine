#!/bin/zsh

set -euo pipefail

cd "$(dirname "$0")/.."

swiftlint lint --config .swiftlint.yml
