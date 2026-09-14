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

## Publish this to GitHub

Cursor, Claude Code, Gemini CLI, and the official registry `repository.source` field expect a public GitHub repo. Create `LaunchPlatform/beanhub-mcp` as a public repository, then:

```bash
git clone https://amendable.io/r/fangpenlin/beanhub-mcp.git
cd beanhub-mcp
git remote add github https://github.com/LaunchPlatform/beanhub-mcp.git
git push -u github master
```

Amendable Git HTTPS uses your Amendable username and an access token as the password. After the GitHub repo exists, add a `repository` object to `server.json`:

```json
"repository": {
  "url": "https://github.com/LaunchPlatform/beanhub-mcp",
  "source": "github"
}
```

Set the same GitHub URL on `.cursor-plugin/plugin.json` and `plugin.json` (`repository`). For Gemini CLI gallery, add the GitHub topic `gemini-cli-extension`.

Official registry namespace `io.beanhub/mcp` needs DNS or HTTP verification on [beanhub.io](https://beanhub.io). See [Publishing remote servers](https://modelcontextprotocol.io/registry/remote-servers).

## Links

- App: [https://app.beanhub.io](https://app.beanhub.io)
- Docs: [https://docs.beanhub.io/guides/mcp/](https://docs.beanhub.io/guides/mcp/)
- Privacy: [https://beanhub.io/privacy-policy](https://beanhub.io/privacy-policy)
- Terms: [https://beanhub.io/terms-of-service](https://beanhub.io/terms-of-service)
- Support: support@beanhub.io
