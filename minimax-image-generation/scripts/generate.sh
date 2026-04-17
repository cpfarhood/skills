#!/usr/bin/env bash
# generate.sh — Generate images via MiniMax /v1/image_generation.
# Usage: bash scripts/generate.sh "<prompt>" [--aspect-ratio=16:9] [--count=1] [--output=output]
set -euo pipefail

die() { echo "ERROR: $*" >&2; exit 1; }

# --- Dependencies ---
for cmd in curl jq base64; do
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
done

# --- Credentials ---
[[ -z "${MINIMAX_API_KEY:-}" ]] && die "MINIMAX_API_KEY is not set"
API_BASE_URL="${MINIMAX_API_BASE_URL:-https://api.minimax.io}"

# --- Parse args ---
PROMPT=""
ASPECT_RATIO="16:9"
COUNT=1
OUTPUT_PREFIX="output"

for arg in "$@"; do
  case "$arg" in
    --aspect-ratio=*) ASPECT_RATIO="${arg#*=}" ;;
    --count=*)        COUNT="${arg#*=}" ;;
    --output=*)       OUTPUT_PREFIX="${arg#*=}" ;;
    --*)              die "Unknown flag: $arg" ;;
    *)                if [[ -z "$PROMPT" ]]; then PROMPT="$arg"; else die "Unexpected positional argument: $arg"; fi ;;
  esac
done

[[ -z "$PROMPT" ]] && die "Usage: bash scripts/generate.sh \"<prompt>\" [--aspect-ratio=16:9] [--count=1] [--output=output]"

case "$ASPECT_RATIO" in
  16:9|1:1|9:16|4:3|3:4) ;;
  *) die "Unsupported aspect ratio: $ASPECT_RATIO (valid: 16:9, 1:1, 9:16, 4:3, 3:4)" ;;
esac

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || (( COUNT < 1 )); then
  die "Invalid --count: $COUNT (must be a positive integer)"
fi

echo "🎨 MiniMax Image Generation" >&2
echo "├─ Prompt: \"$PROMPT\"" >&2
echo "├─ Aspect ratio: $ASPECT_RATIO" >&2
echo "├─ Count: $COUNT" >&2
echo "└─ Model: image-01" >&2
echo "" >&2

# --- Build JSON payload safely (jq handles escaping) ---
PAYLOAD=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg ratio "$ASPECT_RATIO" \
  --argjson n "$COUNT" \
  '{model:"image-01", prompt:$prompt, aspect_ratio:$ratio, num_images:$n, response_format:"base64"}')

# --- Call API ---
RESPONSE=$(curl -sS -X POST "${API_BASE_URL}/v1/image_generation" \
  -H "Authorization: Bearer ${MINIMAX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD") || die "MiniMax API request failed"

# --- Check for API error ---
ERR=$(echo "$RESPONSE" | jq -r '.base_resp.status_msg // empty')
CODE=$(echo "$RESPONSE" | jq -r '.base_resp.status_code // 0')
if [[ "$CODE" != "0" && -n "$ERR" ]]; then
  die "MiniMax API error (code=$CODE): $ERR"
fi

# --- Decode and save ---
COUNT_SAVED=0
while IFS= read -r image_b64; do
  [[ -z "$image_b64" ]] && continue
  OUT="${OUTPUT_PREFIX}-${COUNT_SAVED}.jpeg"
  echo "$image_b64" | base64 -d > "$OUT" || die "Failed to decode image $COUNT_SAVED"
  echo "Saved: $OUT" >&2
  COUNT_SAVED=$((COUNT_SAVED + 1))
done < <(echo "$RESPONSE" | jq -r '.data.image_base64[]?')

(( COUNT_SAVED == 0 )) && die "No images returned: $RESPONSE"

echo "Done." >&2
