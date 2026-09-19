#!/usr/bin/env bash
set -euo pipefail
pnpm test
if [ -d apps/macos/NotchFlow.xcodeproj ]; then
  xcodebuild test -project apps/macos/NotchFlow.xcodeproj -scheme NotchFlow -destination 'platform=macOS'
fi
