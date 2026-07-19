#!/bin/sh
set -euo pipefail

expected_bundle_id="com.shary17454.esal"
expected_marketing_version="${EXPECTED_MARKETING_VERSION:-1.10.0}"
required_xcode_build="17F113"
required_sdk_prefix="iphoneos26.5"

echo "== Xcode Cloud post-build verification =="
echo "Action: ${CI_XCODEBUILD_ACTION:-unknown}"
echo "Exit code: ${CI_XCODEBUILD_EXIT_CODE:-unknown}"
echo "Build: ${CI_BUILD_NUMBER:-unknown}"
echo "Commit: ${CI_COMMIT:-unknown}"

if [ "${CI_XCODEBUILD_EXIT_CODE:-1}" != "0" ]; then
  echo "ERROR: xcodebuild failed; archive verification cannot continue."
  exit "${CI_XCODEBUILD_EXIT_CODE:-1}"
fi

if [ "${CI_XCODEBUILD_ACTION:-}" != "archive" ]; then
  echo "No archive action; post-build verification skipped."
  exit 0
fi

archive_path="${CI_ARCHIVE_PATH:-}"
if [ -z "${archive_path}" ] || [ ! -d "${archive_path}" ]; then
  echo "ERROR: CI_ARCHIVE_PATH is unavailable or invalid: ${archive_path:-unset}"
  exit 30
fi

app_plist="$(find "${archive_path}/Products/Applications" -maxdepth 2 -type f -name Info.plist -print | head -n 1)"
if [ -z "${app_plist}" ] || [ ! -f "${app_plist}" ]; then
  echo "ERROR: The archived app Info.plist was not found."
  exit 31
fi

plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$2"
}

bundle_id="$(plist_value CFBundleIdentifier "${app_plist}")"
marketing_version="$(plist_value CFBundleShortVersionString "${app_plist}")"
build_number="$(plist_value CFBundleVersion "${app_plist}")"
xcode_build="$(plist_value DTXcodeBuild "${app_plist}")"
sdk_name="$(plist_value DTSDKName "${app_plist}")"
minimum_os="$(plist_value MinimumOSVersion "${app_plist}")"

echo "Archived bundle: ${bundle_id}"
echo "Archived version: ${marketing_version} (${build_number})"
echo "Archived Xcode build: ${xcode_build}"
echo "Archived SDK: ${sdk_name}"
echo "Archived minimum OS: ${minimum_os}"

[ "${bundle_id}" = "${expected_bundle_id}" ] || {
  echo "ERROR: Unexpected archived bundle identifier."
  exit 32
}

[ "${marketing_version}" = "${expected_marketing_version}" ] || {
  echo "ERROR: Unexpected archived marketing version."
  exit 33
}

[ "${xcode_build}" = "${required_xcode_build}" ] || {
  echo "ERROR: Archive was not produced by the approved production Xcode build ${required_xcode_build}."
  exit 34
}

case "${sdk_name}" in
  "${required_sdk_prefix}"*) ;;
  *)
    echo "ERROR: Archive SDK ${sdk_name} does not match ${required_sdk_prefix} or newer compatible suffix."
    exit 35
    ;;
esac

if [ -n "${CI_BUILD_NUMBER:-}" ] && [ "${build_number}" != "${CI_BUILD_NUMBER}" ]; then
  echo "ERROR: Archived build ${build_number} differs from Xcode Cloud build ${CI_BUILD_NUMBER}."
  exit 36
fi

extensions_directory="$(dirname "${app_plist}")/PlugIns"
if [ -d "${extensions_directory}" ]; then
  find "${extensions_directory}" -type f -path '*.appex/Info.plist' -print | while IFS= read -r extension_plist; do
    extension_version="$(plist_value CFBundleShortVersionString "${extension_plist}")"
    extension_build="$(plist_value CFBundleVersion "${extension_plist}")"
    extension_id="$(plist_value CFBundleIdentifier "${extension_plist}")"

    echo "Extension ${extension_id}: ${extension_version} (${extension_build})"
    [ "${extension_version}" = "${marketing_version}" ] || exit 37
    [ "${extension_build}" = "${build_number}" ] || exit 38
  done
fi

echo "Xcode Cloud archive verification passed."
