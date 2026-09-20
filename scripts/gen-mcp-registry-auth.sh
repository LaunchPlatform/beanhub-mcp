#!/usr/bin/env bash
# Generate an Ed25519 key and the MCP Registry domain-proof string.
# Encrypts MCP_PRIVATE_KEY into secrets.sops.yaml (PGP) when sops is
# available; otherwise writes key.pem (private, gitignored).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

FORCE=0
if [[ "${1:-}" == "--force" ]]; then
  FORCE=1
fi

use_sops=0
if command -v sops >/dev/null 2>&1; then
  use_sops=1
fi

if [[ "${use_sops}" -eq 1 ]]; then
  if [[ -e "${MCP_SOPS_FILE}" && "${FORCE}" -ne 1 ]]; then
    echo "${MCP_SOPS_FILE} already exists. Pass --force to overwrite." >&2
    exit 1
  fi
else
  PEM="${MCP_PRIVATE_KEY_FILE:-${ROOT}/key.pem}"
  if [[ -e "${PEM}" && "${FORCE}" -ne 1 ]]; then
    echo "${PEM} already exists. Pass --force to overwrite." >&2
    exit 1
  fi
fi

PEM="$(mktemp)"
cleanup() {
  rm -f "${PEM}" "${PLAINTEXT:-}"
}
trap cleanup EXIT
chmod 600 "${PEM}"
openssl genpkey -algorithm Ed25519 -out "${PEM}"

PUBLIC_KEY="$(openssl pkey -in "${PEM}" -pubout -outform DER | tail -c 32 | base64)"
PROOF="v=MCPv1; k=ed25519; p=${PUBLIC_KEY}"
printf '%s\n' "${PROOF}" >"${ROOT}/mcp-registry-auth"

if [[ "${use_sops}" -eq 1 ]]; then
  PRIVATE_KEY="$(hex_private_key_from_pem "${PEM}")"
  PLAINTEXT="$(mktemp)"
  chmod 600 "${PLAINTEXT}"
  printf 'MCP_PRIVATE_KEY: %s\n' "${PRIVATE_KEY}" >"${PLAINTEXT}"
  unset PRIVATE_KEY
  sops --encrypt \
    --filename-override "${MCP_SOPS_FILE}" \
    --input-type yaml \
    --output-type yaml \
    --output "${MCP_SOPS_FILE}" \
    "${PLAINTEXT}"
  KEY_LOCATION="${MCP_SOPS_FILE} (PGP-encrypted; commit this file)"
else
  DEST_PEM="${MCP_PRIVATE_KEY_FILE:-${ROOT}/key.pem}"
  cp "${PEM}" "${DEST_PEM}"
  chmod 600 "${DEST_PEM}"
  KEY_LOCATION="${DEST_PEM} (keep this private; do not commit it)"
fi

cat <<EOF
Wrote ${KEY_LOCATION}.
Wrote ${ROOT}/mcp-registry-auth (public proof; still gitignored).

HTTP: host the proof as plain text at
  https://${MCP_DOMAIN}/.well-known/mcp-registry-auth

DNS: TXT on the apex ${MCP_DOMAIN} (not a _mcp-auth selector):
  ${MCP_DOMAIN}. IN TXT "${PROOF}"

Then:
  mcp-validate
  mcp-publish
EOF
