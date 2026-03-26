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

## Steps

### 1. Generate a JWT

Create a JWT signed with the GitHub App's private key. You MUST use the helper script bundled with this skill:

```bash
# generates a JWT valid for 10 minutes
TOKEN=$(python3 "$(dirname "$0")/../skills/github-app-token/scripts/generate_jwt.py")
```

If `python3` is not available, fall back to the inline openssl method described in the Fallback section below.

The JWT uses:
- **Algorithm**: RS256
- **Header**: `{"alg": "RS256", "typ": "JWT"}`
- **Payload**:
  - `iat`: current time minus 60 seconds (clock drift buffer)
  - `exp`: current time plus 600 seconds (10 minute max)
  - `iss`: the `GITHUB_APP_ID`

### 2. Exchange the JWT for an installation access token

```bash
INSTALL_TOKEN=$(curl -s -X POST \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
```

If the response contains an error (e.g., `401 Unauthorized`), check:
1. The PEM key matches the App ID
2. The Installation ID is valid for this App
3. The system clock is accurate (JWT `iat`/`exp` are time-sensitive)

### 3. Authenticate the gh CLI

```bash
echo "${INSTALL_TOKEN}" | gh auth login --with-token
```

Verify it worked:

```bash
gh auth status
```

You should see authentication via `token` for `github.com`.

### 4. Cleanup

The installation access token expires after 1 hour. There is nothing to revoke unless you want to explicitly invalidate it early:

```bash
curl -s -X DELETE \
  -H "Authorization: Bearer ${INSTALL_TOKEN}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/installation/token"
```

## Fallback: JWT generation without Python

If `python3` is unavailable, generate the JWT using `openssl` and `bash`:

```bash
header=$(printf '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
now=$(date +%s)
iat=$((now - 60))
exp=$((now + 600))
payload=$(printf '{"iat":%d,"exp":%d,"iss":"%s"}' "$iat" "$exp" "$GITHUB_APP_ID" | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
unsigned="${header}.${payload}"
signature=$(printf '%s' "$unsigned" | openssl dgst -sha256 -sign "${GITHUB_APP_PEM_FILE}" -binary | openssl base64 -e -A | tr '+/' '-_' | tr -d '=')
TOKEN="${unsigned}.${signature}"
```

Then continue from Step 2.

## Security Notes

- Never log or echo the PEM key, JWT, or installation token to stdout in production.
- The JWT is valid for at most 10 minutes. The installation token is valid for 1 hour.
- Store the PEM file with restrictive permissions (`chmod 600`) and never check it into git.
