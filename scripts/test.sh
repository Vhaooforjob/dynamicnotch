#!/usr/bin/env bash
set -euo pipefail
pnpm test
if [ -d apps/macos/DynamicNotch.xcodeproj ]; then
  xcodebuild test -project apps/macos/DynamicNotch.xcodeproj -scheme DynamicNotch -destination 'platform=macOS'
fi
