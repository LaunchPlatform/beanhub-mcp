# BeanHub MCP

Listing files for BeanHub's hosted [MCP](https://modelcontextprotocol.io) server. This repository is not the server source. The live endpoint is [https://api.beanhub.io/mcp](https://api.beanhub.io/mcp).

BeanHub is a hosted [Beancount](https://beancount.github.io/docs/) book on [Git](https://git-scm.com/). An AI app signs in with OAuth, then can list accounts, search transactions, check balances, and update the ledger if you allow it. The app does not use a CLI access token. New connections start read-only.

Enable MCP on your account before you connect: [https://app.beanhub.io/mcp/](https://app.beanhub.io/mcp/). Full steps: [Connect an AI app with MCP](https://docs.beanhub.io/guides/mcp/).

## Files

Each client looks for its own filename. They all point at the same URL.

| File | Used by |
| --- | --- |
| `server.json` | Official MCP Registry (`io.beanhub/mcp`) |
| `mcp.json` | Cursor plugins and Agent Plugins |
| `.mcp.json` | Claude Code plugins |
| `plugin.json` | Agent Plugins |
| `.cursor-plugin/plugin.json` | Cursor Marketplace |
| `.claude-plugin/plugin.json` | Claude Code plugins |
| `.claude-plugin/marketplace.json` | Claude Code marketplace catalog |
| `gemini-extension.json` | Gemini CLI gallery |

Do not paste [https://app.beanhub.io/mcp/](https://app.beanhub.io/mcp/) into an AI app. That page is MCP settings, not the server.

## Auth

The server uses OAuth 2.0 with dynamic client registration and `token_endpoint_auth_method=none`. Do not add a Bearer access token or a static client secret.

## What the app can do

Read tools: `list_books`, `list_accounts`, `search_transactions`, `get_balances`, `list_entries`, `get_entry`, `list_files`, `get_file`, `list_forms`, `list_commits`.

Write tools (only if you turn on updates): `create_entries`, `update_entry`, `delete_entry`, `rename_account`, `submit_form`, `update_files`.

The app cannot mint access tokens, change billing, connect a bank, dump Connect or Inbox data, make a book public, or delete a book.

## Public source

The public copy is [https://github.com/LaunchPlatform/beanhub-mcp](https://github.com/LaunchPlatform/beanhub-mcp). Cursor, Claude Code, Gemini CLI, and the official registry `repository.source` field use that GitHub repo.

To pull Amendable updates and push GitHub:

```bash
cd beanhub-mcp
git fetch origin
git merge origin/master
git push github master
```

For Gemini CLI gallery, add the GitHub topic `gemini-cli-extension`.

## Official MCP Registry

This repo publishes **metadata only** for the hosted server `https://api.beanhub.io/mcp`. The registry name is `io.beanhub/mcp`. That namespace needs HTTP or DNS proof on [beanhub.io](https://beanhub.io), not GitHub OIDC. Docs: [remote servers](https://modelcontextprotocol.io/registry/remote-servers), [authentication](https://modelcontextprotocol.io/registry/authentication), [GitHub Actions](https://modelcontextprotocol.io/registry/github-actions).

Do not run `mcp-publisher init`. It would overwrite `server.json`.

### devenv

```bash
direnv allow   # or: devenv shell
mcp-validate
mcp-gen-auth   # encrypts MCP_PRIVATE_KEY into secrets.sops.yaml + gitignored mcp-registry-auth
```

The publisher key is stored in `secrets.sops.yaml`, encrypted with SOPS using PGP fingerprint `A57616E62A499B512EDA662E0FC8D7008588874B`. Edit later with `sops secrets.sops.yaml`. Commit the encrypted file; do not commit `key.pem`.

The public proof is served from the Hugo site as `static/.well-known/mcp-registry-auth`. Deploy [beanhub.io](https://github.com/LaunchPlatform/beanhub.io) so `https://beanhub.io/.well-known/mcp-registry-auth` returns that one line. DNS alternative: TXT on the apex `beanhub.io`. Then:

```bash
mcp-publish
```

`mcp-publish` reads `MCP_PRIVATE_KEY` (64 hex chars), decrypts `./secrets.sops.yaml`, or falls back to `./key.pem`. Default auth method is HTTP. For DNS: `MCP_AUTH_METHOD=dns mcp-publish`.

Without devenv:

```bash
./scripts/validate-mcp.sh
./scripts/gen-mcp-registry-auth.sh
./scripts/publish-mcp.sh
```

### GitHub Actions

`CI` runs `./scripts/validate-mcp.sh` on pulls and pushes to `master`.

`Publish to MCP Registry` runs on `v*` tags and on `workflow_dispatch`. Create a GitHub Environment named `mcp-registry-publish`, store `MCP_PRIVATE_KEY` as an **environment** secret (not a repo secret), and restrict the environment to `master` and tags. Then:

```bash
git tag v1.0.0
git push github v1.0.0
```

A tag `v1.0.0` publishes version `1.0.0` (the committed `server.json` is not rewritten). Versions are immutable. Bump the tag for later metadata-only updates.

Confirm:

```bash
curl -sS "https://registry.modelcontextprotocol.io/v0.1/servers?search=io.beanhub/mcp"
```

## Links

- App: [https://app.beanhub.io](https://app.beanhub.io)
- Docs: [https://docs.beanhub.io/guides/mcp/](https://docs.beanhub.io/guides/mcp/)
- Privacy: [https://beanhub.io/privacy-policy](https://beanhub.io/privacy-policy)
- Terms: [https://beanhub.io/terms-of-service](https://beanhub.io/terms-of-service)
- Support: support@beanhub.io
