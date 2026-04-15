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
| `GITHUB_APP_PEM_FILE` | Absolute path to the App's PEM private key file |

## Usage

```bash
bash github-app-token/scripts/generate-token.sh
```

The script validates env vars, generates a JWT, exchanges it for an installation token, writes the token to `$AGENT_HOME/.gh-token`, and runs `gh auth login`. On success it prints a confirmation line. On failure it exits non-zero with a descriptive error.

The script sets and exports `GH_CONFIG_DIR=$AGENT_HOME/.config/gh` so each agent's `gh` state is isolated from every other agent on the same host. After sourcing or calling the script, subsequent `gh` commands in the same shell session will automatically use that isolated config. If you spawn a subprocess, export `GH_CONFIG_DIR` before calling `gh`.

Requires `openssl`, `curl`, `jq`, and `gh`.
