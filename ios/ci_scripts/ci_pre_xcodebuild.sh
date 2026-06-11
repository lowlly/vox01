#!/bin/sh
set -e

echo "=== Installing Flutter ==="
brew install flutter

echo "=== Flutter pub get ==="
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

echo "=== Pod install ==="
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install --repo-update

echo "=== Done ==="
