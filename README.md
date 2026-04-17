# Skills

A collection of Claude Code skills — reusable tools that extend Claude Code's capabilities. Each skill lives in its own top-level directory and ships a `SKILL.md` (the entry point Claude Code reads when invoking the skill) plus any supporting scripts or references.

## Available skills

| Skill | What it does |
|---|---|
| [`github-app-token`](./github-app-token) | Generate a short-lived GitHub App installation access token and authenticate the `gh` CLI with it. |
| [`minimax-image-generation`](./minimax-image-generation) | Generate images from MiniMax's `image-01` model via the `/v1/image_generation` endpoint. |

## Skill layout

```
<skill-name>/
├── SKILL.md              # Required. YAML frontmatter (name, description) + usage docs.
├── CLAUDE.md             # Optional. Maintainer / implementation notes.
└── scripts/              # Optional. Bash or other implementation scripts.
```

Scripts use `set -euo pipefail` and a shared `die()` pattern for error handling. Scripts are invoked via `bash scripts/<name>.sh` (not `./scripts/<name>.sh`) so that they work even when the executable bit did not survive deployment.

## No build / test / lint tooling

There is no centralized build, test, or lint system. Each skill is self-contained and pulls in only standard Unix tools as declared in its `SKILL.md`.

## Contributing

- New skills get a new top-level directory with at minimum a `SKILL.md` that starts with YAML frontmatter on line 1.
- Keep `SKILL.md` focused on decision flow + user-facing usage. Move implementation details, API references, and rarely-needed tables into `CLAUDE.md` or a `references/` subdirectory to keep per-invocation token cost low.
- Add a row to the table above.
