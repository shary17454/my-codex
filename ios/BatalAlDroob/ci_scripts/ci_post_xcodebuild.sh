#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPOSITORY_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"

export BATAL_ARCHIVE_GUARD=1
exec "${REPOSITORY_ROOT}/ci_scripts/ci_post_xcodebuild.sh"
