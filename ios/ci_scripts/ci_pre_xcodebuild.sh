#!/bin/sh
set -e

FLUTTER_HOME="$HOME/flutter"

echo "=== Installing Flutter via git clone ==="
if [ ! -d "$FLUTTER_HOME" ]; then
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$FLUTTER_HOME"
fi

export PATH="$PATH:$FLUTTER_HOME/bin"
flutter --version

echo "=== Flutter pub get ==="
cd "$CI_PRIMARY_REPOSITORY_PATH"
flutter pub get

echo "=== Pod install ==="
cd "$CI_PRIMARY_REPOSITORY_PATH/ios"
pod install --repo-update

echo "=== Complete ==="
