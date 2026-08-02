#!/bin/sh
set -euo pipefail

expected_bundle_id="com.shary17454.esal"
expected_marketing_version="${EXPECTED_MARKETING_VERSION:-2.3}"
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

if ! echo "${build_number}" | grep -Eq '^[0-9]+$'; then
  echo "ERROR: Archived build number is not numeric: ${build_number}"
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

signed_app_path="${CI_APP_STORE_SIGNED_APP_PATH:-}"
if [ -z "${signed_app_path}" ] || [ ! -d "${signed_app_path}" ]; then
  echo "ERROR: App Store signed export directory is unavailable: ${signed_app_path:-unset}"
  exit 39
fi

ipa_path="$(find "${signed_app_path}" -maxdepth 1 -type f -name '*.ipa' -print | head -n 1)"
if [ -z "${ipa_path}" ] || [ ! -f "${ipa_path}" ]; then
  echo "ERROR: App Store signed IPA was not found in ${signed_app_path}."
  exit 40
fi

ipa_info_entry="$(unzip -Z1 "${ipa_path}" | grep -E '^Payload/[^/]+\.app/Info\.plist$' | head -n 1)"
if [ -z "${ipa_info_entry}" ]; then
  echo "ERROR: Main app Info.plist was not found inside the signed IPA."
  exit 41
fi

temporary_directory="$(mktemp -d)"
trap 'rm -rf "${temporary_directory}"' EXIT
signed_info_plist="${temporary_directory}/Info.plist"
unzip -p "${ipa_path}" "${ipa_info_entry}" > "${signed_info_plist}"

signed_bundle_id="$(plist_value CFBundleIdentifier "${signed_info_plist}")"
signed_marketing_version="$(plist_value CFBundleShortVersionString "${signed_info_plist}")"
signed_build_number="$(plist_value CFBundleVersion "${signed_info_plist}")"
signed_xcode_build="$(plist_value DTXcodeBuild "${signed_info_plist}")"
signed_sdk_name="$(plist_value DTSDKName "${signed_info_plist}")"

echo "Signed IPA bundle: ${signed_bundle_id}"
echo "Signed IPA version: ${signed_marketing_version} (${signed_build_number})"
echo "Signed IPA Xcode build: ${signed_xcode_build}"
echo "Signed IPA SDK: ${signed_sdk_name}"

[ "${signed_bundle_id}" = "${expected_bundle_id}" ] || exit 42
[ "${signed_marketing_version}" = "${expected_marketing_version}" ] || exit 43
[ "${signed_xcode_build}" = "${required_xcode_build}" ] || exit 44
case "${signed_sdk_name}" in
  "${required_sdk_prefix}"*) ;;
  *) exit 45 ;;
esac

echo "Xcode Cloud archive verification passed."
