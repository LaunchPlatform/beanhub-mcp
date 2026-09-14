{ pkgs, config, ... }:

{
  packages = [
    pkgs.curl
    pkgs.git
    pkgs.jq
    pkgs.openssl
    pkgs.python3
  ];

  env.MCP_DOMAIN = "beanhub.io";
  env.MCP_AUTH_METHOD = "http";
  env.MCP_PUBLISHER_VERSION = "1.8.1";

  scripts.mcp-validate.exec = ''
    exec "${config.devenv.root}/scripts/validate-mcp.sh"
  '';

  scripts.mcp-publish.exec = ''
    exec "${config.devenv.root}/scripts/publish-mcp.sh" "$@"
  '';

  scripts.mcp-gen-auth.exec = ''
    exec "${config.devenv.root}/scripts/gen-mcp-registry-auth.sh" "$@"
  '';

  enterShell = ''
    echo "beanhub-mcp devenv"
    echo "  commands  mcp-validate | mcp-publish | mcp-gen-auth"
    echo "  docs      README.md"
    echo "  openssl   $(openssl version)"
  '';

  enterTest = ''
    "${config.devenv.root}/scripts/validate-mcp.sh" --offline
  '';
}
