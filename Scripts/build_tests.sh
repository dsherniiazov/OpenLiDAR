#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

xcodebuild \
  -project "$ROOT_DIR/OpenLidar/OpenLidar.xcodeproj" \
  -scheme OpenLidar \
  -destination 'generic/platform=iOS' \
  -derivedDataPath "$ROOT_DIR/.derived/tests" \
  build-for-testing \
  CODE_SIGNING_ALLOWED=NO

