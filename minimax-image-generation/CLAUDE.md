# MiniMax Image Generation — Implementation Notes

## API Reference

- **Endpoint**: `POST /v1/image_generation`
- **Base URL**: `https://api.minimax.io` (international) or `https://api.minimaxi.com` (China)
- **Auth**: `Authorization: Bearer <MINIMAX_API_KEY>`
- **Model**: `image-01`
- **Response**: JSON with `data.image_base64[]` array

## Example API Call

```bash
curl -X POST "https://api.minimax.io/v1/image_generation" \
  -H "Authorization: Bearer ${MINIMAX_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "image-01",
    "prompt": "men Dressing in white t shirt, full-body stand front view image :25, outdoor",
    "aspect_ratio": "16:9",
    "num_images": 1,
    "response_format": "base64"
  }'
```

## Response Format

```json
{
  "data": {
    "image_base64": ["<base64-encoded-jpeg>"]
  },
  "model": "image-01",
  "request_id": "<id>"
}
```

## Aspect Ratios

| Ratio | Dimensions | Use Case |
|-------|-----------|----------|
| `16:9` | 1920×1080 | Desktop wallpaper, banners |
| `1:1` | 1024×1024 | Social media, profile images |
| `9:16` | 1080×1920 | Mobile wallpaper, stories |
| `4:3` | 1024×768 | Presentations |
| `3:4` | 768×1024 | Posters, portraits |

## Dependencies

- `curl` — HTTP requests
- `jq` — JSON parsing
- `base64` — Decode image data (coreutils)

All three are standard Unix tools. No Python or Node required.

## File Structure

```
minimax-image-generation/
├── SKILL.md          # Skill definition + user-facing docs
├── scripts/
│   └── generate.sh   # Generation script (CLI entry point)
└── CLAUDE.md         # These implementation notes
```
