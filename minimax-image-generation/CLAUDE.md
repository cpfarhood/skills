# MiniMax Image Generation — Implementation Notes

User-facing docs (aspect ratios, usage, env vars) live in `SKILL.md`. This file is for maintenance notes only.

## API Reference

- **Endpoint**: `POST /v1/image_generation`
- **Base URL**: `https://api.minimax.io` (international) or `https://api.minimaxi.com` (China)
- **Auth**: `Authorization: Bearer <MINIMAX_API_KEY>`
- **Model**: `image-01`
- **Response**: JSON with `data.image_base64[]` array; errors surface in `base_resp.status_code` / `base_resp.status_msg`.

## Response Format

```json
{
  "data": { "image_base64": ["<base64-encoded-jpeg>"] },
  "model": "image-01",
  "request_id": "<id>",
  "base_resp": { "status_code": 0, "status_msg": "success" }
}
```

## File Structure

```
minimax-image-generation/
├── SKILL.md              # Skill definition + user-facing docs
├── CLAUDE.md             # These implementation notes
└── scripts/
    └── generate.sh       # Generate images (invoke via `bash scripts/generate.sh …`)
```
