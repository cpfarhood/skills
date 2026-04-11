# MiniMax Image Generation Skill

Claude Code skill for generating images via the MiniMax API.
Wraps the MiniMax `/v1/image_generation` endpoint as a `/minimax-image-generation` slash command.

## Structure
- `SKILL.md` — skill definition (deployed to ~/.claude/skills/minimax-image-generation/)
- `scripts/generate.sh` — image generation script
- `CLAUDE.md` — implementation notes

## Commands
```bash
bash scripts/generate.sh [options]
```

## Rules
- The generated image is written to disk as `output-0.jpeg` (and `output-1.jpeg`, etc. for multiple images)
- Set `MINIMAX_API_KEY` env var before use
- After edits: run `bash scripts/sync.sh` to deploy (if provided)

---
name: minimax-image-generation
version: "1.0.0"
description: "Generate images from MiniMax's image-01 model. Triggered by phrases like 'generate image', 'create picture', 'minimax image', 'text to image'."
argument-hint: '"a sunset over the ocean, cinematic" [--aspect-ratio=16:9] [--num-images=1] [--output=output.jpeg]'
allowed-tools: Bash, Read, Write
user-invocable: true
metadata:
  openclaw:
    emoji: "🎨"
    category: "media"
    requires:
      env:
        - MINIMAX_API_KEY
      optionalEnv:
        - MINIMAX_API_BASE_URL
    bins:
      - curl
      - jq
    primaryEnv: MINIMAX_API_KEY
    files:
      - "scripts/*"
    tags:
      - image
      - image-generation
      - generative-ai
      - minimax
      - text-to-image
      - AI
---

# MiniMax Image Generation

> Generate images using MiniMax's `image-01` model via the `/v1/image_generation` API.

## Quick Start

```bash
# Set your API key
export MINIMAX_API_KEY="your-minimax-api-key"

# Generate an image
/minimax-image-generation "a cat wearing a spacesuit, cinematic photography"

# With options
/minimax-image-generation "a sunset over the ocean" --aspect-ratio=16:9 --num-images=1 --output=sunset.jpeg
```

---

## Parse User Intent

Extract from the user's input:

1. **PROMPT**: The image description (required)
2. **ASPECT_RATIO**: `16:9` (default), `1:1`, `9:16`, `4:3`, `3:4`
3. **NUM_IMAGES**: Number of images to generate (1–4, default 1)
4. **OUTPUT**: Output filename (default `output-{index}.jpeg`)

---

## Step 1: Verify Credentials

```bash
if [ -z "${MINIMAX_API_KEY:-}" ]; then
  echo "ERROR: MINIMAX_API_KEY is not set."
  echo "Set it with: export MINIMAX_API_KEY='your-api-key'"
  exit 1
fi

API_BASE_URL="${MINIMAX_API_BASE_URL:-https://api.minimax.io}"
echo "Using API base: $API_BASE_URL"
```

---

## Step 2: Call the MiniMax Image Generation API

```bash
PROMPT="a serene mountain landscape at dawn, cinematic, photorealistic"
ASPECT_RATIO="${ASPECT_RATIO:-16:9}"
NUM_IMAGES="${NUM_IMAGES:-1}"
OUTPUT="${OUTPUT:-}"

URL="${API_BASE_URL}/v1/image_generation"

response=$(curl -s -X POST "${URL}" \
  -H "Authorization: Bearer ${MINIMAX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"image-01\",
    \"prompt\": \"${PROMPT}\",
    \"aspect_ratio\": \"${ASPECT_RATIO}\",
    \"num_images\": ${NUM_IMAGES},
    \"response_format\": \"base64\"
  }")

# Check for errors
if echo "$response" | jq -e '.error' >/dev/null 2>&1; then
  error_msg=$(echo "$response" | jq -r '.error.message // "Unknown error"')
  echo "ERROR: $error_msg"
  exit 1
fi
```

---

## Step 3: Decode and Save Images

```bash
images=$(echo "$response" | jq -r '.data.image_base64[]')

idx=0
for image_b64 in $images; do
  if [ -n "${OUTPUT}" ]; then
    # Single output filename (use index if multiple images)
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
```

---

## Aspect Ratio Guide

| Ratio | Use Case |
|-------|----------|
| `16:9` | Widescreen (default) — desktop wallpaper, banners |
| `1:1` | Square — social media posts, profile images |
| `9:16` | Portrait — mobile wallpapers, stories |
| `4:3` | Standard — presentations, blog images |
| `3:4` | Portrait standard — posters, portraits |

---

## Configuration Reference

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MINIMAX_API_KEY` | Yes | Your MiniMax API key |
| `MINIMAX_API_BASE_URL` | No | API base URL (default: `https://api.minimax.io`) |

### API Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `model` | string | `image-01` | Model to use |
| `prompt` | string | required | Image description |
| `aspect_ratio` | string | `16:9` | Image aspect ratio |
| `num_images` | integer | `1` | Number of images (1–4) |
| `response_format` | string | `base64` | Output format |

---

## Example Output

```
🎨 MiniMax Image Generation
├─ Prompt: "a cat wearing a spacesuit, cinematic photography"
├─ Aspect ratio: 16:9
├─ Model: image-01
└─ Generating...

Saved: output-0.jpeg
Done.
```
