#!/bin/sh
set -e

echo "=== Xcode Cloud Flutter Pre-build Script ==="
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"

# Detect Homebrew prefix (Apple Silicon vs Intel)
if [ -d "/opt/homebrew" ]; then
  HOMEBREW_PREFIX="/opt/homebrew"
else
  HOMEBREW_PREFIX="/usr/local"
fi
export PATH="$HOMEBREW_PREFIX/bin:$PATH"

echo "=== Installing Flutter ==="
HOMEBREW_NO_AUTO_UPDATE=1 brew install flutter 2>&1 || HOMEBREW_NO_AUTO_UPDATE=1 brew upgrade flutter 2>&1 || true

FLUTTER_BIN=$(which flutter || echo "$HOMEBREW_PREFIX/bin/flutter")
echo "Flutter binary: $FLUTTER_BIN"
$FLUTTER_BIN --version

echo "=== Flutter pub get ==="
cd "$CI_PRIMARY_REPOSITORY_PATH"
$FLUTTER_BIN pub get

echo "=== Pod install ==="
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install

echo "=== Pre-build complete ==="
