#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
PROJECT_FILE="${PROJECT_FILE_OVERRIDE:-${REPOSITORY_ROOT}/ios/BatalAlDroob/BatalAlDroob.xcodeproj/project.pbxproj}"

if [ -z "${CI_BUILD_NUMBER:-}" ]; then
  echo "error: CI_BUILD_NUMBER is required to synchronize CURRENT_PROJECT_VERSION before Xcode Cloud builds." >&2
  exit 1
fi

if ! echo "${CI_BUILD_NUMBER}" | grep -Eq '^[0-9]+$'; then
  echo "error: CI_BUILD_NUMBER must be numeric. Found: ${CI_BUILD_NUMBER}" >&2
  exit 1
fi

if [ ! -f "${PROJECT_FILE}" ]; then
  echo "error: Expected Batal Al-Droob project file is missing: ${PROJECT_FILE}" >&2
  exit 1
fi

echo "Synchronizing Batal Al-Droob CURRENT_PROJECT_VERSION to Xcode Cloud build ${CI_BUILD_NUMBER}."
perl -0pi -e "s/CURRENT_PROJECT_VERSION = \\d+;/CURRENT_PROJECT_VERSION = ${CI_BUILD_NUMBER};/g" "${PROJECT_FILE}"
grep -E 'CURRENT_PROJECT_VERSION = ' "${PROJECT_FILE}" | sort -u
