# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Claude Code skills repository**. Skills are reusable tools that extend Claude Code's capabilities. Each skill lives in its own top-level directory.

## Skill Structure

Each skill follows this convention:
- **`<skill-name>/SKILL.md`** — Required. Contains YAML frontmatter (`name`, `description`) and usage documentation. This is the entry point Claude Code reads when invoking the skill.
- **`<skill-name>/scripts/`** — Implementation scripts (bash). Scripts use `set -euo pipefail` and the `die()` pattern for error handling.

## Current Skills

- **`github-app-token`** — Generates short-lived GitHub App installation access tokens. Requires `GITHUB_APP_ID`, `GITHUB_APP_INSTALLATION_ID`, and `GITHUB_APP_PEM_FILE` env vars. Use `--raw` flag to get the token value directly (recommended for agents), or omit for legacy `eval`-based `export GH_TOKEN=...` output.

## Key Patterns

- Scripts are pure bash with no external dependencies beyond standard Unix tools (`openssl`, `curl`, `jq`).
- The `--raw` output pattern (preferred): scripts with `--raw` print only the value to stdout for easy `$(...)` capture. The legacy `eval` pattern (no flag) prints shell commands like `export VAR="value"` for backward compatibility.
- The `die()` function prints errors to stderr and exits non-zero.

## No Build/Test/Lint System

There is no centralized build, test, or lint tooling. Each skill is self-contained.
