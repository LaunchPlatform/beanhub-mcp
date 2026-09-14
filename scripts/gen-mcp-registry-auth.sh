#!/usr/bin/env bash
# Generate an Ed25519 key and the MCP Registry domain-proof string.
# Writes key.pem (private, gitignored) and prints the public proof.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

PEM="${MCP_PRIVATE_KEY_FILE:-${ROOT}/key.pem}"
if [[ -e "${PEM}" && "${1:-}" != "--force" ]]; then
  echo "${PEM} already exists. Pass --force to overwrite." >&2
  exit 1
fi

openssl genpkey -algorithm Ed25519 -out "${PEM}"
chmod 600 "${PEM}"

PUBLIC_KEY="$(openssl pkey -in "${PEM}" -pubout -outform DER | tail -c 32 | base64)"
PROOF="v=MCPv1; k=ed25519; p=${PUBLIC_KEY}"
printf '%s\n' "${PROOF}" >"${ROOT}/mcp-registry-auth"

cat <<EOF
Wrote ${PEM} (keep this private; do not commit it).
Wrote ${ROOT}/mcp-registry-auth (public proof; still gitignored).

HTTP: host the proof as plain text at
  https://${MCP_DOMAIN}/.well-known/mcp-registry-auth

DNS: TXT on the apex ${MCP_DOMAIN} (not a _mcp-auth selector):
  ${MCP_DOMAIN}. IN TXT "${PROOF}"

Then:
  mcp-validate
  mcp-publish
EOF
