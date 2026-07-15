#!/bin/sh
set -euo pipefail

required_xcode_version="26.6"
required_xcode_build="17F113"
required_min_iphoneos_sdk="26.5"

echo "== Xcode Cloud preflight =="
echo "Commit: $(git rev-parse HEAD 2>/dev/null || echo unknown)"
echo "Branch: ${CI_BRANCH:-unknown}"
echo "Workflow: ${CI_WORKFLOW:-unknown}"
echo "Product: ${CI_PRODUCT:-unknown}"
echo "CI build number: ${CI_BUILD_NUMBER:-unset}"
echo "Xcode project: ${CI_XCODE_PROJECT:-unset}"
echo "Xcode workspace: ${CI_XCODE_WORKSPACE:-unset}"
echo "Developer dir: $(xcode-select -p)"

xcodebuild -version
iphoneos_sdk_version="$(xcrun --sdk iphoneos --show-sdk-version)"
iphoneos_sdk_path="$(xcrun --sdk iphoneos --show-sdk-path)"
xcode_version="$(xcodebuild -version | awk 'NR == 1 { print $2 }')"
xcode_build="$(xcodebuild -version | awk 'NR == 2 { print $3 }')"

echo "iPhoneOS SDK version: ${iphoneos_sdk_version}"
echo "iPhoneOS SDK path: ${iphoneos_sdk_path}"

case "${xcode_version}" in
  *beta*|*Beta*|27*beta*|27*)
    echo "ERROR: Xcode Beta or Xcode 27 beta is not allowed for App Store production uploads."
    echo "Detected Xcode: ${xcode_version} (${xcode_build})"
    echo "Required workflow environment: Xcode ${required_xcode_version} (${required_xcode_build}) or a newer Apple production release explicitly allowed for App Store submission."
    echo "Manual fix: App Store Connect > App > Xcode Cloud > Workflows > Edit Workflow > Environment > Xcode Version > choose Xcode ${required_xcode_version} or newer production release. Do not choose Latest Beta."
    exit 20
    ;;
esac

if [ "${xcode_version}" != "${required_xcode_version}" ] || [ "${xcode_build}" != "${required_xcode_build}" ]; then
  echo "ERROR: Unexpected Xcode version for this release workflow."
  echo "Detected Xcode: ${xcode_version} (${xcode_build})"
  echo "Expected Xcode: ${required_xcode_version} (${required_xcode_build})"
  echo "Manual fix: App Store Connect > App > Xcode Cloud > Workflows > Edit Workflow > Environment > Xcode Version > choose Xcode ${required_xcode_version}. Do not choose Latest Beta."
  exit 21
fi

version_ge() {
  left="$1"
  right="$2"
  IFS=. read -r left_major left_minor left_patch <<EOF
${left}
EOF
  IFS=. read -r right_major right_minor right_patch <<EOF
${right}
EOF
  left_patch="${left_patch:-0}"
  right_patch="${right_patch:-0}"

  [ "${left_major}" -gt "${right_major}" ] && return 0
  [ "${left_major}" -lt "${right_major}" ] && return 1
  [ "${left_minor}" -gt "${right_minor}" ] && return 0
  [ "${left_minor}" -lt "${right_minor}" ] && return 1
  [ "${left_patch}" -ge "${right_patch}" ]
}

if ! version_ge "${iphoneos_sdk_version}" "${required_min_iphoneos_sdk}"; then
  echo "ERROR: iPhoneOS SDK is too old for the current App Store submission preflight."
  echo "Detected SDK: ${iphoneos_sdk_version}"
  echo "Required minimum SDK: ${required_min_iphoneos_sdk}"
  echo "Manual fix: update the Xcode Cloud workflow to Xcode ${required_xcode_version} or a newer production Xcode allowed by Apple."
  exit 22
fi

echo "Xcode Cloud preflight passed."
