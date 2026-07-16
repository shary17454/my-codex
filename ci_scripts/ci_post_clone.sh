#!/bin/bash
set -euo pipefail

echo "== Xcode Cloud environment guard =="
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Branch: ${CI_BRANCH:-unknown}"
echo "Workflow: ${CI_WORKFLOW:-unknown}"
echo "CI_XCODE_PROJECT: ${CI_XCODE_PROJECT:-unset}"
echo "CI_XCODE_WORKSPACE: ${CI_XCODE_WORKSPACE:-unset}"
echo "CI_PRODUCT: ${CI_PRODUCT:-unset}"
echo "CI_BUILD_NUMBER: ${CI_BUILD_NUMBER:-unset}"

echo "== Toolchain =="
xcodebuild -version
xcode-select -p
SDK_VERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
echo "iPhoneOS SDK version: ${SDK_VERSION}"
echo "iPhoneOS SDK path: ${SDK_PATH}"
echo "SDKROOT: ${SDKROOT:-unset}"

XCODE_VERSION="$(xcodebuild -version | awk '/^Xcode / {print $2}')"
XCODE_BUILD="$(xcodebuild -version | awk '/^Build version/ {print $3}')"
XCODE_FULL="$(xcodebuild -version)"

EXPECTED_XCODE_VERSION="${EXPECTED_XCODE_VERSION:-26.6}"
EXPECTED_XCODE_BUILD="${EXPECTED_XCODE_BUILD:-17F113}"
EXPECTED_MARKETING_VERSION="${EXPECTED_MARKETING_VERSION:-1.1.0}"
EXPECTED_PROJECT_BUILD="${EXPECTED_PROJECT_BUILD:-96}"
MIN_IPHONEOS_SDK_MAJOR="${MIN_IPHONEOS_SDK_MAJOR:-26}"
BATAL_PROJECT_FILE="ios/BatalAlDroob/BatalAlDroob.xcodeproj/project.pbxproj"

if echo "${XCODE_FULL}" | grep -Eiq 'beta'; then
  echo "error: Xcode Cloud is using a beta Xcode. App Store submission must use a production Xcode." >&2
  echo "Detected: ${XCODE_FULL}" >&2
  echo "Set App Store Connect > Xcode Cloud > Workflows > Edit Workflow > Environment > Xcode Version to Xcode ${EXPECTED_XCODE_VERSION} (${EXPECTED_XCODE_BUILD}) or newer production version. Do not choose Latest Beta." >&2
  exit 1
fi

if [ "${XCODE_VERSION}" != "${EXPECTED_XCODE_VERSION}" ] || [ "${XCODE_BUILD}" != "${EXPECTED_XCODE_BUILD}" ]; then
  echo "error: Unsupported Xcode for this release guard." >&2
  echo "Detected: Xcode ${XCODE_VERSION} (${XCODE_BUILD})" >&2
  echo "Expected: Xcode ${EXPECTED_XCODE_VERSION} (${EXPECTED_XCODE_BUILD})" >&2
  echo "If Apple has released a newer production Xcode, update EXPECTED_XCODE_VERSION/EXPECTED_XCODE_BUILD deliberately after verifying App Store acceptance." >&2
  echo "Manual step: App Store Connect > this app > Xcode Cloud > Workflows > Edit Workflow > Environment > Xcode Version." >&2
  exit 1
fi

SDK_MAJOR="${SDK_VERSION%%.*}"
if [ -z "${SDK_MAJOR}" ] || [ "${SDK_MAJOR}" -lt "${MIN_IPHONEOS_SDK_MAJOR}" ]; then
  echo "error: iPhoneOS SDK ${SDK_VERSION} is below required major ${MIN_IPHONEOS_SDK_MAJOR}." >&2
  exit 1
fi

if [ -n "${SDKROOT:-}" ] && echo "${SDKROOT}" | grep -Eiq 'beta|iPhoneOS(1[0-9]|2[0-5])\.'; then
  echo "error: SDKROOT appears pinned to an unsupported or beta SDK: ${SDKROOT}" >&2
  exit 1
fi

if [ -n "${CI_PRODUCT:-}" ] && [ "${CI_PRODUCT}" != "BatalAlDroob" ]; then
  echo "Skipping Batal Al-Droob version guard for CI_PRODUCT=${CI_PRODUCT}."
  echo "Xcode toolchain guard passed."
  exit 0
fi

PROJECT_FILE="${BATAL_PROJECT_FILE}"
if [ ! -f "${PROJECT_FILE}" ]; then
  echo "error: Expected project file is missing: ${PROJECT_FILE}" >&2
  exit 1
fi

MARKETING_VALUES="$(grep -E 'MARKETING_VERSION = ' "${PROJECT_FILE}" | sed -E 's/.*MARKETING_VERSION = ([^;]+);.*/\1/' | sort -u | tr '\n' ' ')"
BUILD_VALUES="$(grep -E 'CURRENT_PROJECT_VERSION = ' "${PROJECT_FILE}" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([^;]+);.*/\1/' | sort -u | tr '\n' ' ')"
echo "Project MARKETING_VERSION values: ${MARKETING_VALUES}"
echo "Project CURRENT_PROJECT_VERSION values: ${BUILD_VALUES}"

MARKETING_COUNT="$(grep -E 'MARKETING_VERSION = ' "${PROJECT_FILE}" | sed -E 's/.*MARKETING_VERSION = ([^;]+);.*/\1/' | sort -u | wc -l | tr -d ' ')"
BUILD_COUNT="$(grep -E 'CURRENT_PROJECT_VERSION = ' "${PROJECT_FILE}" | sed -E 's/.*CURRENT_PROJECT_VERSION = ([^;]+);.*/\1/' | sort -u | wc -l | tr -d ' ')"
if [ "${MARKETING_COUNT}" != "1" ]; then
  echo "error: Multiple MARKETING_VERSION values found. Unify all targets before archiving." >&2
  exit 1
fi
if [ "${BUILD_COUNT}" != "1" ]; then
  echo "error: Multiple CURRENT_PROJECT_VERSION values found. Unify all targets before archiving." >&2
  exit 1
fi
if [ "${MARKETING_VALUES% }" != "${EXPECTED_MARKETING_VERSION}" ]; then
  echo "error: MARKETING_VERSION must be ${EXPECTED_MARKETING_VERSION} for this release train. Found: ${MARKETING_VALUES}" >&2
  exit 1
fi
if [ "${BUILD_VALUES% }" != "${EXPECTED_PROJECT_BUILD}" ]; then
  echo "error: CURRENT_PROJECT_VERSION must be ${EXPECTED_PROJECT_BUILD} before Xcode Cloud archive. Found: ${BUILD_VALUES}" >&2
  echo "If Xcode Cloud uses Next Build Number, set it to ${EXPECTED_PROJECT_BUILD} or higher and keep project values synchronized." >&2
  exit 1
fi

echo "Xcode Cloud release guard passed."
