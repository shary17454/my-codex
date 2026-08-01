#!/bin/bash
set -euo pipefail

BATAL_BUNDLE_ID="com.batalaldroob.parts"
EXPECTED_MARKETING_VERSION="${EXPECTED_MARKETING_VERSION:-2.5}"
EXPECTED_XCODE_CODE="${EXPECTED_XCODE_CODE:-2660}"
EXPECTED_XCODE_BUILD="${EXPECTED_XCODE_BUILD:-17F113}"
EXPECTED_SDK_NAME="${EXPECTED_SDK_NAME:-iphoneos26.5}"
EXPECTED_PLATFORM_NAME="${EXPECTED_PLATFORM_NAME:-iphoneos}"
EXPECTED_PLATFORM_VERSION="${EXPECTED_PLATFORM_VERSION:-26.5}"
EXPECTED_MINIMUM_OS="${EXPECTED_MINIMUM_OS:-17.0}"

IS_BATAL_BUILD="false"
if [ "${BATAL_ARCHIVE_GUARD:-0}" = "1" ] || [ "${CI_BUNDLE_ID:-}" = "${BATAL_BUNDLE_ID}" ] || [ "${CI_PRODUCT:-}" = "BatalAlDroob" ]; then
  IS_BATAL_BUILD="true"
elif [ -n "${CI_PROJECT_FILE_PATH:-}" ] && echo "${CI_PROJECT_FILE_PATH}" | grep -Eq '(^|/)BatalAlDroob\.xcodeproj$'; then
  IS_BATAL_BUILD="true"
elif [ -n "${CI_XCODE_PROJECT:-}" ] && echo "${CI_XCODE_PROJECT}" | grep -Eq '(^|/)BatalAlDroob(\.xcodeproj)?$'; then
  IS_BATAL_BUILD="true"
fi

if [ "${IS_BATAL_BUILD}" != "true" ]; then
  exit 0
fi

echo "== Batal Al-Droob archive metadata guard =="
echo "Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "xcodebuild exit code: ${CI_XCODEBUILD_EXIT_CODE:-unknown}"
echo "Commit: ${CI_COMMIT:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"

if [ "${CI_XCODEBUILD_ACTION:-archive}" != "archive" ]; then
  echo "Skipping archive metadata validation for a non-archive action."
  exit 0
fi

if [ "${CI_XCODEBUILD_EXIT_CODE:-0}" != "0" ]; then
  echo "Archive action already failed; metadata validation skipped."
  exit 0
fi

ARCHIVE_PATH="${ARCHIVE_PATH_OVERRIDE:-${CI_ARCHIVE_PATH:-}}"
if [ -z "${ARCHIVE_PATH}" ] || [ ! -d "${ARCHIVE_PATH}" ]; then
  echo "error: CI_ARCHIVE_PATH does not point to a readable xcarchive: ${ARCHIVE_PATH:-unset}" >&2
  exit 1
fi

APP_PATH="${ARCHIVE_PATH}/Products/Applications/BatalAlDroob.app"
APP_INFO="${APP_PATH}/Info.plist"
if [ ! -f "${APP_INFO}" ]; then
  echo "error: BatalAlDroob.app Info.plist is missing from archive ${ARCHIVE_PATH}." >&2
  exit 1
fi

EXPECTED_BUILD="${EXPECTED_ARCHIVE_BUILD:-${CI_BUILD_NUMBER:-}}"
if ! echo "${EXPECTED_BUILD}" | grep -Eq '^[0-9]+$'; then
  echo "error: Expected archive build is unavailable or nonnumeric. Set Xcode Cloud Next Build Number or EXPECTED_ARCHIVE_BUILD." >&2
  exit 1
fi

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null || true
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    echo "error: $3 mismatch. Expected '$2', found '$1'." >&2
    exit 1
  fi
}

print_bundle_metadata() {
  INFO_PATH="$1"
  BUNDLE_PATH="$2"
  echo "-- ${BUNDLE_PATH}"
  for KEY in CFBundleIdentifier CFBundleDisplayName CFBundleShortVersionString CFBundleVersion DTPlatformName DTPlatformVersion DTSDKName DTSDKBuild DTXcode DTXcodeBuild MinimumOSVersion; do
    echo "${KEY}: $(plist_value "${INFO_PATH}" "${KEY}")"
  done
}

MAIN_IDENTIFIER="$(plist_value "${APP_INFO}" CFBundleIdentifier)"
MAIN_VERSION="$(plist_value "${APP_INFO}" CFBundleShortVersionString)"
MAIN_BUILD="$(plist_value "${APP_INFO}" CFBundleVersion)"
MAIN_PLATFORM_NAME="$(plist_value "${APP_INFO}" DTPlatformName)"
MAIN_PLATFORM_VERSION="$(plist_value "${APP_INFO}" DTPlatformVersion)"
MAIN_XCODE_CODE="$(plist_value "${APP_INFO}" DTXcode)"
MAIN_XCODE_BUILD="$(plist_value "${APP_INFO}" DTXcodeBuild)"
MAIN_SDK_NAME="$(plist_value "${APP_INFO}" DTSDKName)"
MAIN_MINIMUM_OS="$(plist_value "${APP_INFO}" MinimumOSVersion)"

print_bundle_metadata "${APP_INFO}" "${APP_PATH}"
assert_equal "${MAIN_IDENTIFIER}" "${BATAL_BUNDLE_ID}" "CFBundleIdentifier"
assert_equal "${MAIN_VERSION}" "${EXPECTED_MARKETING_VERSION}" "CFBundleShortVersionString"
assert_equal "${MAIN_BUILD}" "${EXPECTED_BUILD}" "CFBundleVersion"
assert_equal "${MAIN_PLATFORM_NAME}" "${EXPECTED_PLATFORM_NAME}" "DTPlatformName"
assert_equal "${MAIN_PLATFORM_VERSION}" "${EXPECTED_PLATFORM_VERSION}" "DTPlatformVersion"
assert_equal "${MAIN_XCODE_CODE}" "${EXPECTED_XCODE_CODE}" "DTXcode"
assert_equal "${MAIN_XCODE_BUILD}" "${EXPECTED_XCODE_BUILD}" "DTXcodeBuild"
assert_equal "${MAIN_SDK_NAME}" "${EXPECTED_SDK_NAME}" "DTSDKName"
assert_equal "${MAIN_MINIMUM_OS}" "${EXPECTED_MINIMUM_OS}" "MinimumOSVersion"

while IFS= read -r EMBEDDED_BUNDLE; do
  EMBEDDED_INFO="${EMBEDDED_BUNDLE}/Info.plist"
  [ -f "${EMBEDDED_INFO}" ] || continue
  print_bundle_metadata "${EMBEDDED_INFO}" "${EMBEDDED_BUNDLE}"
  assert_equal "$(plist_value "${EMBEDDED_INFO}" CFBundleShortVersionString)" "${MAIN_VERSION}" "Embedded CFBundleShortVersionString"
  assert_equal "$(plist_value "${EMBEDDED_INFO}" CFBundleVersion)" "${MAIN_BUILD}" "Embedded CFBundleVersion"
done < <(find "${APP_PATH}" -type d \( -name '*.appex' -o -name '*.app' \) ! -path "${APP_PATH}" -print)

if [ -d "${APP_PATH}/Frameworks" ]; then
  while IFS= read -r FRAMEWORK_INFO; do
    print_bundle_metadata "${FRAMEWORK_INFO}" "$(dirname "${FRAMEWORK_INFO}")"
  done < <(find "${APP_PATH}/Frameworks" -name Info.plist -type f -print)
fi

echo "PASS: xcarchive metadata matches Batal Al-Droob release settings."
