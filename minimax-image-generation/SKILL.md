---
name: minimax-image-generation
version: "1.0.0"
description: "Generate images from MiniMax's image-01 model. Triggered by phrases like 'generate image', 'create picture', 'minimax image', 'text to image'."
argument-hint: '"a sunset over the ocean, cinematic" [--aspect-ratio=16:9]'
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
      - base64
    primaryEnv: MINIMAX_API_KEY
    tags:
      - image
      - image-generation
      - generative-ai
      - minimax
      - text-to-image
---

# MiniMax Image Generation

> Generate images using MiniMax's `image-01` model via the `/v1/image_generation` API.

## Quick Start

```bash
export MINIMAX_API_KEY="your-minimax-api-key"
bash minimax-image-generation/scripts/generate.sh "a cat wearing a spacesuit, cinematic photography"
```

Always invoke the script via `bash scripts/generate.sh …` (or `bash minimax-image-generation/scripts/generate.sh …` when running from the repo root). Do **not** rely on the executable bit — invoking through `bash` is the supported entry point, and works even when the file permissions were not preserved during deployment.

## Parse User Intent

Extract from the user's input:

1. **PROMPT**: The image description (required, positional argument)
2. **ASPECT_RATIO**: `16:9` (default), `1:1`, `9:16`, `4:3`, `3:4` — via `--aspect-ratio=<ratio>`
3. **COUNT**: number of images to generate (default `1`) — via `--count=<N>`
4. **OUTPUT_PREFIX**: filename stem (default `output`) — via `--output=<stem>`

## Script Usage

```bash
bash minimax-image-generation/scripts/generate.sh \
  "a sunset over the ocean, cinematic" \
  --aspect-ratio=16:9 \
  --count=1 \
  --output=sunset
```

The script writes `<output>-0.jpeg`, `<output>-1.jpeg`, … to the current working directory. On failure it exits non-zero with a descriptive error.

## Aspect Ratio Guide

| Ratio | Use Case |
|-------|----------|
| `16:9` | Widescreen (default) — desktop wallpaper, banners |
| `1:1` | Square — social media posts, profile images |
| `9:16` | Portrait — mobile wallpapers, stories |
| `4:3` | Standard — presentations, blog images |
| `3:4` | Portrait standard — posters, portraits |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `MINIMAX_API_KEY` | Yes | Your MiniMax API key |
| `MINIMAX_API_BASE_URL` | No | API base URL (default: `https://api.minimax.io`) |

## Example Output

```
🎨 MiniMax Image Generation
├─ Prompt: "a cat wearing a spacesuit, cinematic photography"
├─ Aspect ratio: 16:9
└─ Model: image-01

Saved: output-0.jpeg
Done.
```
