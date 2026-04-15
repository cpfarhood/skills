#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Validate required env vars ---
[[ -z "${GITHUB_APP_ID:-}" ]]              && die "GITHUB_APP_ID is not set"
[[ -z "${GITHUB_APP_INSTALLATION_ID:-}" ]] && die "GITHUB_APP_INSTALLATION_ID is not set"
[[ -z "${GITHUB_APP_PEM_FILE:-}" ]]        && die "GITHUB_APP_PEM_FILE is not set"
[[ ! -f "$GITHUB_APP_PEM_FILE" ]]          && die "PEM file not found: $GITHUB_APP_PEM_FILE"

for cmd in openssl curl jq gh; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

# --- Build JWT (valid 10 minutes) ---
b64url() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

NOW=$(date +%s)
HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | b64url)
PAYLOAD=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "$NOW" "$((NOW + 600))" "$GITHUB_APP_ID" | b64url)
SIGNED="${HEADER}.${PAYLOAD}"
SIG=$(printf '%s' "$SIGNED" | openssl dgst -binary -sha256 -sign "$GITHUB_APP_PEM_FILE" | b64url)
JWT="${SIGNED}.${SIG}"

# --- Exchange JWT for installation access token ---
RESPONSE=$(curl -sf -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens") \
  || die "GitHub API request failed — check App ID, Installation ID, and PEM key"

TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')
[[ -z "$TOKEN" ]] && die "No token in GitHub response: $RESPONSE"

# --- Write token to file ---
GH_TOKEN_FILE="${AGENT_HOME:+${AGENT_HOME}/.gh-token}"
GH_TOKEN_FILE="${GH_TOKEN_FILE:-$(mktemp)}"

printf '%s' "$TOKEN" > "$GH_TOKEN_FILE"
chmod 600 "$GH_TOKEN_FILE"

# --- Authenticate gh CLI with per-agent config isolation ---
# Each agent gets its own GH_CONFIG_DIR so tokens never bleed across agents.
export GH_CONFIG_DIR="${AGENT_HOME:+${AGENT_HOME}/.config/gh}"
GH_CONFIG_DIR="${GH_CONFIG_DIR:-$(mktemp -d)}"
mkdir -p "$GH_CONFIG_DIR"

gh auth login --with-token < "$GH_TOKEN_FILE"

echo "Authenticated. Token written to $GH_TOKEN_FILE (expires in 1 hour). GH_CONFIG_DIR=$GH_CONFIG_DIR"
