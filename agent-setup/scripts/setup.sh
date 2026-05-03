#!/usr/bin/env bash
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

[[ -z "${AGENT_HOME:-}" ]] && die "AGENT_HOME is not set"

# Derive GH_CONFIG_DIR — gh stores config at ~/.config/gh by default,
# so we mirror that structure under AGENT_HOME
export GH_CONFIG_DIR="$AGENT_HOME/.github"

mkdir -p "$AGENT_HOME"
_ENV_FILE="$AGENT_HOME/.env"

# If .env exists, source it first so we preserve existing variables
if [[ -f "$_ENV_FILE" ]]; then
  set -a
  source "$_ENV_FILE"
  set +a
fi

# Update or add GH_CONFIG_DIR export
if grep -q '^export GH_CONFIG_DIR=' "$_ENV_FILE" 2>/dev/null; then
  # Replace existing value in place
  sed -i.bak "s|^export GH_CONFIG_DIR=.*|export GH_CONFIG_DIR=\"$GH_CONFIG_DIR\"|" "$_ENV_FILE"
  rm -f "$_ENV_FILE.bak"
else
  # Append new export
  printf 'export GH_CONFIG_DIR="%s"\n' "$GH_CONFIG_DIR" >> "$_ENV_FILE"
fi

echo "GH_CONFIG_DIR set to $GH_CONFIG_DIR"
