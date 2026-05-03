#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Validate required env vars ---
[[ -z "${GITHUB_APP_ID:-}" ]]              && die "GITHUB_APP_ID is not set"
[[ -z "${GITHUB_APP_INSTALLATION_ID:-}" ]] && die "GITHUB_APP_INSTALLATION_ID is not set"

# Resolve PEM key: prefer GITHUB_APP_PEM (inline data), fall back to GITHUB_APP_PEM_FILE
_CLEANUP_PEM_FILE=""
if [[ -n "${GITHUB_APP_PEM:-}" ]]; then
  _TMP_PEM=$(mktemp)
  _CLEANUP_PEM_FILE="$_TMP_PEM"
  printf '%s' "$GITHUB_APP_PEM" > "$_TMP_PEM"
  chmod 600 "$_TMP_PEM"
  GITHUB_APP_PEM_FILE="$_TMP_PEM"
elif [[ -n "${GITHUB_APP_PEM_FILE:-}" ]]; then
  [[ ! -f "$GITHUB_APP_PEM_FILE" ]] && die "PEM file not found: $GITHUB_APP_PEM_FILE"
else
  die "Either GITHUB_APP_PEM (inline PEM data) or GITHUB_APP_PEM_FILE (path to PEM file) must be set"
fi

cleanup() { [[ -n "$_CLEANUP_PEM_FILE" ]] && rm -f "$_CLEANUP_PEM_FILE"; }
trap cleanup EXIT

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

# --- Resolve token file location ---
# Prefer GH_CONFIG_DIR (so the token lives alongside the per-agent gh config),
# fall back to AGENT_HOME, fail loudly if neither is set rather than silently
# writing to /tmp and leaking the token.
if [[ -n "${GH_CONFIG_DIR:-}" ]]; then
  GH_TOKEN_DIR="$GH_CONFIG_DIR"
elif [[ -n "${AGENT_HOME:-}" ]]; then
  GH_TOKEN_DIR="$AGENT_HOME"
else
  die "Neither GH_CONFIG_DIR nor AGENT_HOME is set — refusing to write the token to a default location"
fi

mkdir -p "$GH_TOKEN_DIR"
GH_TOKEN_FILE="$GH_TOKEN_DIR/.gh-token"

printf '%s' "$TOKEN" > "$GH_TOKEN_FILE"
chmod 600 "$GH_TOKEN_FILE"

# --- Authenticate gh CLI ---
gh auth login --with-token < "$GH_TOKEN_FILE"

echo "Authenticated. Token written to $GH_TOKEN_FILE (expires in 1 hour)."
