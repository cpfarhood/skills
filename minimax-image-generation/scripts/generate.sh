#!/usr/bin/env bash
# generate.sh — Generate images via MiniMax API
set -euo pipefail

die() {
  echo "ERROR: $1" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Options:
  -p, --prompt <text>        Image description (required)
  -a, --aspect-ratio <ratio> Aspect ratio: 16:9 (default), 1:1, 9:16, 4:3, 3:4
  -n, --num-images <n>      Number of images (1-4, default 1)
  -o, --output <filename>    Output filename (default: output-{index}.jpeg)
  -k, --api-key <key>       MiniMax API key (or set MINIMAX_API_KEY env var)
  -u, --base-url <url>       API base URL (default: https://api.minimax.io)
  -h, --help                Show this help

Examples:
  $(basename "$0") -p "a sunset over the ocean, cinematic"
  $(basename "$0") -p "a cat" -a 1:1 -n 2 -o mycat.jpeg
EOF
  exit 0
}

# Parse arguments
PROMPT=""
ASPECT_RATIO="16:9"
NUM_IMAGES=1
OUTPUT=""
API_KEY="${MINIMAX_API_KEY:-}"
BASE_URL="${MINIMAX_API_BASE_URL:-https://api.minimax.io}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--prompt) PROMPT="$2"; shift 2 ;;
    -a|--aspect-ratio) ASPECT_RATIO="$2"; shift 2 ;;
    -n|--num-images) NUM_IMAGES="$2"; shift 2 ;;
    -o|--output) OUTPUT="$2"; shift 2 ;;
    -k|--api-key) API_KEY="$2"; shift 2 ;;
    -u|--base-url) BASE_URL="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) die "Unknown option: $1" ;;
  esac
done

# Validate required inputs
if [ -z "$PROMPT" ]; then
  die "Prompt is required. Use -p 'description'"
fi

if [ -z "$API_KEY" ]; then
  die "MINIMAX_API_KEY is not set. Pass -k or export MINIMAX_API_KEY"
fi

# Validate aspect ratio
case "$ASPECT_RATIO" in
  16:9|1:1|9:16|4:3|3:4) ;;
  *) die "Invalid aspect ratio: $ASPECT_RATIO. Use 16:9, 1:1, 9:16, 4:3, or 3:4" ;;
esac

# Validate num_images
if ! [[ "$NUM_IMAGES" =~ ^[1-4]$ ]]; then
  die "num-images must be between 1 and 4"
fi

# Make the API call
URL="${BASE_URL}/v1/image_generation"

echo "🎨 MiniMax Image Generation"
echo "├─ Prompt: $PROMPT"
echo "├─ Aspect ratio: $ASPECT_RATIO"
echo "├─ Num images: $NUM_IMAGES"
echo "└─ Model: image-01"
echo ""

response=$(curl -s -X POST "${URL}" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n \
    --arg prompt "$PROMPT" \
    --arg ratio "$ASPECT_RATIO" \
    --argjson num "$NUM_IMAGES" \
    '{
      model: "image-01",
      prompt: $prompt,
      aspect_ratio: $ratio,
      num_images: $num,
      response_format: "base64"
    }')")

# Check for HTTP errors
if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
  error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
  die "API error: $error_msg"
fi

# Decode and save images
images=$(echo "$response" | jq -r '.data.image_base64[]')

idx=0
for image_b64 in $images; do
  if [ -n "$OUTPUT" ]; then
    if [ "$NUM_IMAGES" -gt 1 ]; then
      filename="${OUTPUT%.*}-${idx}.${OUTPUT##*.}"
    else
      filename="$OUTPUT"
    fi
  else
    filename="output-${idx}.jpeg"
  fi

  echo "$image_b64" | base64 -d > "$filename"
  echo "Saved: $filename"
  idx=$((idx + 1))
done

echo ""
echo "Done."
