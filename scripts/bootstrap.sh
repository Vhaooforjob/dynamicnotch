#!/usr/bin/env bash
set -euo pipefail

command -v node >/dev/null || { echo "Node.js is required"; exit 1; }
command -v pnpm >/dev/null || { echo "pnpm is required"; exit 1; }
command -v xcodebuild >/dev/null || { echo "Xcode is required"; exit 1; }

if [ ! -f .env ]; then
  cp .env.example .env
  echo "Created .env from .env.example"
fi

pnpm install

if command -v xcodegen >/dev/null; then
  (cd apps/macos && xcodegen generate)
else
  echo "Install XcodeGen to generate apps/macos/DynamicNotch.xcodeproj"
fi

echo "Next: make dev-api and make macos"
