#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT_DIR/StudyVaultApp"
PROJECT_FILE="$APP_DIR/StudyVault.xcodeproj/project.pbxproj"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

[ -d "$APP_DIR" ] || fail "StudyVaultApp directory is missing"
[ -d "$APP_DIR/StudyVault.xcodeproj" ] || fail "StudyVault.xcodeproj is missing"
[ -f "$APP_DIR/StudyVault/Info.plist" ] || fail "Info.plist is missing"
[ -f "$PROJECT_FILE" ] || fail "project.pbxproj is missing"

if find "$APP_DIR" \
  -path "$APP_DIR/build" -prune -o \
  -path "$APP_DIR/StudyVault/Resources/StudyFiles" -prune -o \
  \( -name '*.dart' -o -name 'pubspec.yaml' -o -path '*Flutter*' \) -print | grep -q .; then
  find "$APP_DIR" \
    -path "$APP_DIR/build" -prune -o \
    -path "$APP_DIR/StudyVault/Resources/StudyFiles" -prune -o \
    \( -name '*.dart' -o -name 'pubspec.yaml' -o -path '*Flutter*' \) -print >&2
  fail "Flutter/Dart runtime artifacts exist inside the وش الرأي app scope"
fi
pass "No Flutter/Dart runtime artifacts in active وش الرأي scope"

if grep -q "BatalAlDroob" "$PROJECT_FILE"; then
  fail "StudyVault project references BatalAlDroob"
fi
pass "StudyVault project is separated from BatalAlDroob"

DISPLAY_NAME="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleDisplayName' "$APP_DIR/StudyVault/Info.plist")"
[ "$DISPLAY_NAME" = "وش الرأي" ] || fail "Unexpected CFBundleDisplayName: $DISPLAY_NAME"
pass "Display name is وش الرأي"

if ! grep -q "PRODUCT_BUNDLE_IDENTIFIER = com.shary17454.esal;" "$PROJECT_FILE"; then
  fail "Bundle identifier is not com.shary17454.esal"
fi
pass "Bundle identifier matches وش الرأي"

if ! grep -q "SWIFT_VERSION = 6.0;" "$PROJECT_FILE"; then
  fail "Swift version is not 6.0"
fi
pass "Swift 6 is configured"

python3 "$APP_DIR/scripts/validate_wesh_alray_data.py"

printf 'Wesh Alray scope validation complete.\n'
