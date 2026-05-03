---
name: github-app-token
description: Generate a GitHub installation access token from a GitHub App PEM key, App ID, and Installation ID, write it to a per-agent file, then authenticate the gh CLI with it.
---

# GitHub App Token Skill

Generate a short-lived GitHub App installation token and authenticate `gh`.

## Required Environment Variables

| Variable | Description |
|---|---|
| `GITHUB_APP_ID` | Numeric App ID from GitHub App settings |
| `GITHUB_APP_INSTALLATION_ID` | Numeric Installation ID for the target org/user |
| `GITHUB_APP_PEM_FILE` | Absolute path to the App's PEM private key file *(one of `GITHUB_APP_PEM` or `GITHUB_APP_PEM_FILE` required)* |
| `GITHUB_APP_PEM` | Raw PEM private key content as an env var *(one of `GITHUB_APP_PEM` or `GITHUB_APP_PEM_FILE` required)* |

`GITHUB_APP_PEM` takes precedence over `GITHUB_APP_PEM_FILE` when both are set. Using `GITHUB_APP_PEM` avoids the need to write the key to disk ahead of time — it is written to a temp file with `chmod 600` and deleted after token generation.

## Usage

```bash
bash github-app-token/scripts/generate-token.sh
```

The script validates env vars, generates a JWT, exchanges it for an installation token, writes the token to `.gh-token` inside `$GH_CONFIG_DIR` (preferred) or `$AGENT_HOME` (fallback), and runs `gh auth login`. If neither `GH_CONFIG_DIR` nor `AGENT_HOME` is set the script exits non-zero rather than silently writing the token to a default location. On success it prints a confirmation line. On failure it exits non-zero with a descriptive error.

Requires `openssl`, `curl`, `jq`, and `gh`.
