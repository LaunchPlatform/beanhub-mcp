#!/usr/bin/env bash
# Validate listing JSON and official-registry server.json.
# Usage: scripts/validate-mcp.sh [--offline]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

OFFLINE=0
if [[ "${1:-}" == "--offline" ]]; then
  OFFLINE=1
fi

validate_json_files

if [[ "${OFFLINE}" -eq 1 ]]; then
  echo "offline: skipped mcp-publisher validate"
  exit 0
fi

ensure_publisher
"${PUBLISHER_BIN}" validate "${ROOT}/server.json"
echo "ok mcp-publisher validate"
