#!/usr/bin/env bash
# Publish server.json to the official MCP Registry (io.beanhub/mcp).
# Requires domain proof on beanhub.io (HTTP well-known or DNS TXT) and
# MCP_PRIVATE_KEY, secrets.sops.yaml, or key.pem.
#
# Env:
#   MCP_PRIVATE_KEY        Ed25519 private key as 64 hex chars
#   MCP_SOPS_FILE          SOPS YAML with MCP_PRIVATE_KEY (default ./secrets.sops.yaml)
#   MCP_PRIVATE_KEY_FILE   PEM path (overrides SOPS; default ./key.pem if no SOPS file)
#   MCP_AUTH_METHOD        http (default) or dns
#   MCP_DOMAIN             beanhub.io
#   MCP_SERVER_VERSION     if set, publish that version without editing the repo copy
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

case "${MCP_AUTH_METHOD}" in
  http | dns) ;;
  *)
    echo "MCP_AUTH_METHOD must be http or dns, got ${MCP_AUTH_METHOD}" >&2
    exit 1
    ;;
esac

validate_json_files
ensure_publisher
"${PUBLISHER_BIN}" validate "${ROOT}/server.json"

SERVER_JSON="${ROOT}/server.json"
if [[ -n "${MCP_SERVER_VERSION:-}" ]]; then
  tmp="$(mktemp)"
  jq --arg v "${MCP_SERVER_VERSION}" '.version = $v' "${ROOT}/server.json" >"${tmp}"
  SERVER_JSON="${tmp}"
  echo "publishing version ${MCP_SERVER_VERSION}" >&2
fi

PRIVATE_KEY="$(resolve_private_key)"
login_args=("${MCP_AUTH_METHOD}" --domain "${MCP_DOMAIN}" --private-key "${PRIVATE_KEY}")
if [[ "${MCP_ALGORITHM}" != "ed25519" ]]; then
  login_args+=(--algorithm "${MCP_ALGORITHM}")
fi
"${PUBLISHER_BIN}" login "${login_args[@]}"
unset PRIVATE_KEY
unset MCP_PRIVATE_KEY

"${PUBLISHER_BIN}" publish "${SERVER_JSON}"
if [[ "${SERVER_JSON}" != "${ROOT}/server.json" ]]; then
  rm -f "${SERVER_JSON}"
fi
echo "published io.beanhub/mcp"
