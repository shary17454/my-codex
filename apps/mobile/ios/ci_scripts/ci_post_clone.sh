#!/bin/sh
set -euo pipefail

cd "$CI_PRIMARY_REPOSITORY_PATH/apps/mobile"

if ! command -v flutter >/dev/null 2>&1; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter --version
if command -v xattr >/dev/null 2>&1; then
  xattr -cr . || true
fi
flutter pub get
flutter test
