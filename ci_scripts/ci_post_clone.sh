#!/bin/bash
set -euo pipefail

echo "== Xcode Cloud environment guard =="
echo "Commit: $(git rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Branch: ${CI_BRANCH:-unknown}"
echo "Workflow: ${CI_WORKFLOW:-unknown}"
echo "CI_XCODE_PROJECT: ${CI_XCODE_PROJECT:-unset}"
echo "CI_XCODE_WORKSPACE: ${CI_XCODE_WORKSPACE:-unset}"
echo "CI_PRODUCT: ${CI_PRODUCT:-unset}"
echo "CI_BUNDLE_ID: ${CI_BUNDLE_ID:-unset}"
echo "CI_PROJECT_FILE_PATH: ${CI_PROJECT_FILE_PATH:-unset}"
echo "CI_COMMIT: ${CI_COMMIT:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
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
MIN_IPHONEOS_SDK_MAJOR="${MIN_IPHONEOS_SDK_MAJOR:-26}"
MIN_IPHONEOS_SDK_MINOR="${MIN_IPHONEOS_SDK_MINOR:-5}"
BATAL_EXPECTED_MARKETING_VERSION="${BATAL_EXPECTED_MARKETING_VERSION:-2.1}"
BATAL_MIN_PROJECT_BUILD="${BATAL_MIN_PROJECT_BUILD:-137}"
BATAL_BUNDLE_ID="com.batalaldroob.parts"
BATAL_PROJECT_FILE="ios/BatalAlDroob/BatalAlDroob.xcodeproj/project.pbxproj"
DARB_EXPECTED_MARKETING_VERSION="${DARB_EXPECTED_MARKETING_VERSION:-1.9.2}"
DARB_MIN_PROJECT_BUILD="${DARB_MIN_PROJECT_BUILD:-95}"
DARB_BUNDLE_ID="com.codex.DesertTrail"
DARB_PROJECT_FILE="DesertTrail/DesertTrail.xcodeproj/project.pbxproj"
WESH_BUNDLE_ID="com.shary17454.esal"
WESH_GUARD_SCRIPT="StudyVaultApp/ci_scripts/ci_post_clone.sh"

IS_BATAL_BUILD="false"
if [ "${BATAL_RELEASE_GUARD:-0}" = "1" ] || [ "${CI_BUNDLE_ID:-}" = "${BATAL_BUNDLE_ID}" ] || [ "${CI_PRODUCT:-}" = "BatalAlDroob" ]; then
  IS_BATAL_BUILD="true"
elif [ -n "${CI_PROJECT_FILE_PATH:-}" ] && echo "${CI_PROJECT_FILE_PATH}" | grep -Eq '(^|/)BatalAlDroob\.xcodeproj$'; then
  IS_BATAL_BUILD="true"
elif [ -n "${CI_XCODE_PROJECT:-}" ] && echo "${CI_XCODE_PROJECT}" | grep -Eq '(^|/)BatalAlDroob(\.xcodeproj)?$'; then
  IS_BATAL_BUILD="true"
fi

IS_DARB_BUILD="false"
if [ "${DARB_RELEASE_GUARD:-0}" = "1" ] || [ "${CI_BUNDLE_ID:-}" = "${DARB_BUNDLE_ID}" ] || [ "${CI_PRODUCT:-}" = "DesertTrail" ]; then
  IS_DARB_BUILD="true"
elif [ -n "${CI_PROJECT_FILE_PATH:-}" ] && echo "${CI_PROJECT_FILE_PATH}" | grep -Eq '(^|/)DesertTrail\.xcodeproj$'; then
  IS_DARB_BUILD="true"
elif [ -n "${CI_XCODE_PROJECT:-}" ] && echo "${CI_XCODE_PROJECT}" | grep -Eq '(^|/)DesertTrail(\.xcodeproj)?$'; then
  IS_DARB_BUILD="true"
fi

IS_WESH_BUILD="false"
if [ "${WESH_RELEASE_GUARD:-0}" = "1" ] || [ "${CI_BUNDLE_ID:-}" = "${WESH_BUNDLE_ID}" ] || [ "${CI_PRODUCT:-}" = "StudyVault" ]; then
  IS_WESH_BUILD="true"
elif [ -n "${CI_PROJECT_FILE_PATH:-}" ] && echo "${CI_PROJECT_FILE_PATH}" | grep -Eq '(^|/)StudyVault\.xcodeproj$'; then
  IS_WESH_BUILD="true"
elif [ -n "${CI_XCODE_PROJECT:-}" ] && echo "${CI_XCODE_PROJECT}" | grep -Eq '(^|/)StudyVault(\.xcodeproj)?$'; then
  IS_WESH_BUILD="true"
fi

if [ "${IS_WESH_BUILD}" = "true" ]; then
  if [ ! -x "${WESH_GUARD_SCRIPT}" ]; then
    echo "error: Wesh Alray release guard is missing or not executable: ${WESH_GUARD_SCRIPT}" >&2
    exit 1
  fi
  exec "${WESH_GUARD_SCRIPT}"
fi

if [ "${IS_BATAL_BUILD}" != "true" ] && [ "${IS_DARB_BUILD}" != "true" ]; then
  echo "Skipping iOS release guard for bundle ${CI_BUNDLE_ID:-unset} and product ${CI_PRODUCT:-unset}."
  exit 0
fi

if [ "${IS_DARB_BUILD}" = "true" ]; then
  PROJECT_FILE="${DARB_PROJECT_FILE}"
  EXPECTED_MARKETING_VERSION="${DARB_EXPECTED_MARKETING_VERSION}"
  MIN_PROJECT_BUILD="${DARB_MIN_PROJECT_BUILD}"
  APP_LABEL="الدروب"
else
  PROJECT_FILE="${BATAL_PROJECT_FILE}"
  EXPECTED_MARKETING_VERSION="${BATAL_EXPECTED_MARKETING_VERSION}"
  MIN_PROJECT_BUILD="${BATAL_MIN_PROJECT_BUILD}"
  APP_LABEL="Batal Al-Droob"
fi

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
SDK_MINOR="$(echo "${SDK_VERSION}" | awk -F. '{print $2 + 0}')"
if [ -z "${SDK_MAJOR}" ] || [ "${SDK_MAJOR}" -lt "${MIN_IPHONEOS_SDK_MAJOR}" ]; then
  echo "error: iPhoneOS SDK ${SDK_VERSION} is below required major ${MIN_IPHONEOS_SDK_MAJOR}." >&2
  exit 1
fi
if [ "${SDK_MAJOR}" = "${MIN_IPHONEOS_SDK_MAJOR}" ] && [ "${SDK_MINOR}" -lt "${MIN_IPHONEOS_SDK_MINOR}" ]; then
  echo "error: iPhoneOS SDK ${SDK_VERSION} is below required ${MIN_IPHONEOS_SDK_MAJOR}.${MIN_IPHONEOS_SDK_MINOR}." >&2
  exit 1
fi

if [ -n "${SDKROOT:-}" ] && echo "${SDKROOT}" | grep -Eiq 'beta|iPhoneOS(1[0-9]|2[0-5])\.'; then
  echo "error: SDKROOT appears pinned to an unsupported or beta SDK: ${SDKROOT}" >&2
  exit 1
fi

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
PROJECT_BUILD_VALUE="${BUILD_VALUES% }"
if ! echo "${PROJECT_BUILD_VALUE}" | grep -Eq '^[0-9]+$'; then
  echo "error: CURRENT_PROJECT_VERSION must be a numeric build number. Found: ${PROJECT_BUILD_VALUE}" >&2
  exit 1
fi
if [ "${PROJECT_BUILD_VALUE}" -lt "${MIN_PROJECT_BUILD}" ]; then
  echo "error: CURRENT_PROJECT_VERSION must be ${MIN_PROJECT_BUILD} or higher before Xcode Cloud archive. Found: ${PROJECT_BUILD_VALUE}" >&2
  echo "Set Xcode Cloud Next Build Number to ${MIN_PROJECT_BUILD} or higher and keep project values synchronized." >&2
  exit 1
fi

if [ -n "${CI_BUILD_NUMBER:-}" ]; then
  if ! echo "${CI_BUILD_NUMBER}" | grep -Eq '^[0-9]+$'; then
    echo "error: Xcode Cloud CI_BUILD_NUMBER must be numeric. Found: ${CI_BUILD_NUMBER}" >&2
    exit 1
  fi
  if [ "${CI_BUILD_NUMBER}" -lt "${MIN_PROJECT_BUILD}" ]; then
    echo "error: Xcode Cloud Next Build Number must be ${MIN_PROJECT_BUILD} or higher. Found: ${CI_BUILD_NUMBER}" >&2
    echo "Manual step: App Store Connect > ${APP_LABEL} > Xcode Cloud > Workflow > Edit > Next Build Number." >&2
    exit 1
  fi
fi

echo "Xcode Cloud release guard passed."
