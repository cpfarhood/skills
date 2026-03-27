---
name: github-app-token
description: Generate a GitHub installation access token from a GitHub App PEM key, App ID, and Installation ID, then authenticate the gh CLI with it.
---

# GitHub App Token Skill

Generate a short-lived GitHub installation access token from a GitHub App's credentials and use it to authenticate the `gh` CLI.

## Prerequisites

The following environment variables MUST be set before invoking this skill:

| Variable | Description |
|---|---|
| `GITHUB_APP_ID` | The numeric App ID from the GitHub App settings page |
| `GITHUB_APP_INSTALLATION_ID` | The numeric Installation ID for the target org/user |
| `GITHUB_APP_PEM_FILE` | Absolute path to the GitHub App's PEM private key file |

If any variable is missing, stop and tell the user which ones are required.

Requires `openssl`, `curl`, and `jq` (standard on modern environments).

## Steps

### 1. Generate a Token

The simplest approach is to use `--raw` mode, which prints only the token value. This works reliably in a single shell invocation:

```bash
GH_TOKEN=$(./github-app-token/scripts/generate_token.sh --raw) && export GH_TOKEN
```

You can then use `GH_TOKEN` in subsequent commands within the same shell invocation:

```bash
GH_TOKEN=$(./github-app-token/scripts/generate_token.sh --raw) && export GH_TOKEN && gh api user
```

### 2. Authenticate the gh CLI

With `GH_TOKEN` set (in the same shell), the `gh` CLI operates securely and without needing a separate authentication login for most API operations. Note that `gh auth status` may not reflect the token since it checks local config, but `gh` will respect the `GH_TOKEN` environment variable.

To both generate the token and authenticate `gh` in one go:

```bash
GH_TOKEN=$(./github-app-token/scripts/generate_token.sh --raw) && export GH_TOKEN && echo "${GH_TOKEN}" | gh auth login --with-token && gh auth status
```

### 3. Cleanup

The installation access token expires after 1 hour. There is nothing to revoke unless you want to explicitly invalidate it early:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer ${GH_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/installation/token"
```

## Advanced: `eval` Mode (Legacy)

Without the `--raw` flag, the script outputs `export GH_TOKEN="..."` meant to be `eval`'d. This is the original behavior, preserved for backward compatibility:

```bash
eval "$(./github-app-token/scripts/generate_token.sh)" && gh api user
```

> [!NOTE]
> For CI/CD environments (like GitHub Actions), use `--raw` to extract the token cleanly:
> `echo "GH_TOKEN=$(./github-app-token/scripts/generate_token.sh --raw)" >> $GITHUB_ENV`

## Security Notes

- Never log or echo the PEM key or installation token to stdout in production.
- The installation token represents your GitHub App and is strictly valid for 1 hour from generation.
- Store the PEM file with restrictive permissions (`chmod 600`) and never check it into git.
