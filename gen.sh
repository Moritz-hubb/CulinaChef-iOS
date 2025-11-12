#!/usr/bin/env bash
set -euo pipefail

# Install XcodeGen if not installed
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Installing XcodeGen via Homebrew..."
  brew install xcodegen
fi

cd "$(dirname "$0")"

# Generate Xcode project
xcodegen generate

echo "\nProject generated: CulinaChef.xcodeproj"
