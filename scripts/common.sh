#!/usr/bin/env bash
# Shared helpers for MCP Registry publisher scripts.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT}"

MCP_PUBLISHER_VERSION="${MCP_PUBLISHER_VERSION:-1.8.1}"
MCP_DOMAIN="${MCP_DOMAIN:-beanhub.io}"
MCP_AUTH_METHOD="${MCP_AUTH_METHOD:-http}"
MCP_ALGORITHM="${MCP_ALGORITHM:-ed25519}"
MCP_SOPS_FILE="${MCP_SOPS_FILE:-${ROOT}/secrets.sops.yaml}"
TOOLS_DIR="${ROOT}/.tools"
PUBLISHER_BIN="${TOOLS_DIR}/mcp-publisher"

# Pinned SHA-256 digests for mcp-publisher v1.8.1 release tarballs.
publisher_sha256() {
  case "$1" in
    mcp-publisher_darwin_amd64.tar.gz)
      echo "88126981225e7714fcc6b7a10cdba4a80ae5901e9740a8c06d0d5195c8bc294c"
      ;;
    mcp-publisher_darwin_arm64.tar.gz)
      echo "e45e520892460732a4bdf37255576415d4a53ec171f8b913faf15bb1aef7cb77"
      ;;
    mcp-publisher_linux_amd64.tar.gz)
      echo "a06c9096dcb9727c13555b6be26c7effa707b01f06a4c561ba7a3635443cf2cc"
      ;;
    mcp-publisher_linux_arm64.tar.gz)
      echo "8dd75a6cf6845688b5d4e46df58d3ca26d5c8d233bb0626606e1db82c5e883e4"
      ;;
    mcp-publisher_windows_amd64.tar.gz)
      echo "399ad0d6e00a50812b563a71d8bfbff5160c085e6b13aac6ec083d98d5ff7c45"
      ;;
    mcp-publisher_windows_arm64.tar.gz)
      echo "2e3a3435e27afcaa35bec9cb573bab99db9e980d7fb49f90f32a59d03d4a3fa3"
      ;;
    *)
      echo "unknown archive: $1" >&2
      return 1
      ;;
  esac
}

publisher_archive_name() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"
  case "${arch}" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *)
      echo "unsupported architecture: ${arch}" >&2
      return 1
      ;;
  esac
  echo "mcp-publisher_${os}_${arch}.tar.gz"
}

file_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

ensure_publisher() {
  mkdir -p "${TOOLS_DIR}"
  if [[ -x "${PUBLISHER_BIN}" ]]; then
    return 0
  fi
  if [[ "${MCP_PUBLISHER_VERSION}" != "1.8.1" ]]; then
    echo "This repo pins mcp-publisher 1.8.1 checksums. Bump scripts/common.sh when changing MCP_PUBLISHER_VERSION." >&2
    exit 1
  fi
  local archive expected url tmp
  archive="$(publisher_archive_name)"
  expected="$(publisher_sha256 "${archive}")"
  url="https://github.com/modelcontextprotocol/registry/releases/download/v${MCP_PUBLISHER_VERSION}/${archive}"
  tmp="$(mktemp)"
  echo "Downloading ${url}" >&2
  curl -fsSL "${url}" -o "${tmp}"
  local actual
  actual="$(file_sha256 "${tmp}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "SHA-256 mismatch for ${archive}: expected ${expected}, got ${actual}" >&2
    rm -f "${tmp}"
    exit 1
  fi
  tar -xzf "${tmp}" -C "${TOOLS_DIR}" mcp-publisher
  rm -f "${tmp}"
  chmod +x "${PUBLISHER_BIN}"
}

hex_private_key_from_pem() {
  local pem="$1"
  openssl pkey -in "${pem}" -noout -text | grep -A3 "priv:" | tail -n +2 | tr -d ' :\n'
}

decrypt_sops_private_key() {
  local file="$1"
  if ! command -v sops >/dev/null 2>&1; then
    echo "sops is required to decrypt ${file} (enter the devenv shell)." >&2
    exit 1
  fi
  local key
  key="$(sops -d --input-type yaml --output-type json "${file}" | jq -r '.MCP_PRIVATE_KEY // empty')"
  if [[ -z "${key}" || "${key}" == "null" ]]; then
    echo "${file} has no MCP_PRIVATE_KEY." >&2
    exit 1
  fi
  printf '%s' "${key}"
}

resolve_private_key() {
  if [[ -n "${MCP_PRIVATE_KEY:-}" ]]; then
    printf '%s' "${MCP_PRIVATE_KEY}"
    return 0
  fi
  if [[ -n "${MCP_PRIVATE_KEY_FILE:-}" ]]; then
    hex_private_key_from_pem "${MCP_PRIVATE_KEY_FILE}"
    return 0
  fi
  if [[ -f "${MCP_SOPS_FILE}" ]]; then
    decrypt_sops_private_key "${MCP_SOPS_FILE}"
    return 0
  fi
  local pem="${ROOT}/key.pem"
  if [[ -f "${pem}" ]]; then
    hex_private_key_from_pem "${pem}"
    return 0
  fi
  echo "Set MCP_PRIVATE_KEY, encrypt MCP_PRIVATE_KEY in ${MCP_SOPS_FILE}, or provide MCP_PRIVATE_KEY_FILE / key.pem." >&2
  exit 1
}

validate_json_files() {
  python3 - <<'PY'
import json
from pathlib import Path

root = Path(".")
files = [
    "server.json",
    "mcp.json",
    ".mcp.json",
    "plugin.json",
    "gemini-extension.json",
    ".cursor-plugin/plugin.json",
    ".claude-plugin/plugin.json",
    ".claude-plugin/marketplace.json",
]
for rel in files:
    path = root / rel
    data = json.loads(path.read_text())
    print(f"ok json {rel}")

server = json.loads((root / "server.json").read_text())
errors = []
if server.get("name") != "io.beanhub/mcp":
    errors.append(f"server.json name must be io.beanhub/mcp, got {server.get('name')!r}")
desc = server.get("description") or ""
if not (1 <= len(desc) <= 100):
    errors.append(f"server.json description length {len(desc)} is outside 1-100")
remotes = server.get("remotes") or []
if not remotes:
    errors.append("server.json remotes is empty")
else:
    remote = remotes[0]
    if remote.get("type") != "streamable-http":
        errors.append(f"remote type must be streamable-http, got {remote.get('type')!r}")
    if remote.get("url") != "https://api.beanhub.io/mcp":
        errors.append(f"remote url must be https://api.beanhub.io/mcp, got {remote.get('url')!r}")
    if "headers" in remote:
        errors.append("do not put OAuth headers on remotes; clients use DCR")
repo = server.get("repository") or {}
if repo.get("source") != "github":
    errors.append("repository.source must be github")
if repo.get("url") != "https://github.com/LaunchPlatform/beanhub-mcp":
    errors.append("repository.url must be https://github.com/LaunchPlatform/beanhub-mcp")
if errors:
    raise SystemExit("\n".join(errors))
print("ok server.json fields")
PY
}
