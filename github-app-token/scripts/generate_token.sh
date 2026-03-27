#!/usr/bin/env bash
# Generate a GitHub App Installation Access Token and authenticate the gh CLI
#
# Required environment variables:
#   GITHUB_APP_ID              - The GitHub App's numeric ID
#   GITHUB_APP_INSTALLATION_ID - The numeric Installation ID for the target org/user
#   GITHUB_APP_PEM_FILE        - Path to the PEM-encoded private key file

set -euo pipefail

# Parse flags
RAW_MODE=false
for arg in "$@"; do
  case "$arg" in
    --raw) RAW_MODE=true ;;
    *) echo "error: unknown flag: $arg" >&2; exit 1 ;;
  esac
done

die() {
  echo "error: $1" >&2
  exit 1
}

if [[ -z "${GITHUB_APP_ID:-}" ]]; then
  die "GITHUB_APP_ID is not set"
fi

if [[ -z "${GITHUB_APP_INSTALLATION_ID:-}" ]]; then
  die "GITHUB_APP_INSTALLATION_ID is not set"
fi

if [[ -z "${GITHUB_APP_PEM_FILE:-}" ]]; then
  die "GITHUB_APP_PEM_FILE is not set"
fi

if [[ ! -f "${GITHUB_APP_PEM_FILE}" ]]; then
  die "PEM file not found: ${GITHUB_APP_PEM_FILE}"
fi

# Function to base64 encode with URL-safe characters
b64enc() { openssl enc -base64 -A | tr '+/' '-_' | tr -d '='; }

NOW=$(date +%s)
# JWT valid for 10 minutes (GitHub limit)
IAT=$NOW
EXP=$((NOW + 10 * 60))

# Create the JWT header and payload (requires jq for compact formatting just to be safe)
HEADER=$(printf '{"alg":"RS256","typ":"JWT"}' | jq -r -c .)
PAYLOAD=$(printf '{"iat":%s,"exp":%s,"iss":"%s"}' "${IAT}" "${EXP}" "${GITHUB_APP_ID}" | jq -r -c .)

SIGNED_CONTENT=$(printf '%s' "${HEADER}" | b64enc).$(printf '%s' "${PAYLOAD}" | b64enc)

# Sign the content with the private key
SIG=$(printf '%s' "${SIGNED_CONTENT}" | openssl dgst -binary -sha256 -sign "${GITHUB_APP_PEM_FILE}" | b64enc)

JWT=$(printf '%s.%s' "${SIGNED_CONTENT}" "${SIG}")

# Exchange JWT for an installation access token
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer ${JWT}" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/app/installations/${GITHUB_APP_INSTALLATION_ID}/access_tokens")

INSTALL_TOKEN=$(printf '%s' "${RESPONSE}" | jq -r '.token // empty')

if [[ -z "${INSTALL_TOKEN}" ]]; then
  die "failed to generate installation token. Response: ${RESPONSE}"
fi

# Output the token
if [[ "$RAW_MODE" == true ]]; then
  printf '%s' "${INSTALL_TOKEN}"
else
  echo "export GH_TOKEN=\"${INSTALL_TOKEN}\""
fi
