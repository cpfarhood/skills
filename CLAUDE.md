# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Claude Code skills repository**. Skills are reusable tools that extend Claude Code's capabilities. Each skill lives in its own top-level directory.

## Skill Structure

Each skill follows this convention:
- **`<skill-name>/SKILL.md`** — Required. Contains YAML frontmatter (`name`, `description`) and usage documentation. This is the entry point Claude Code reads when invoking the skill.
- **`<skill-name>/scripts/`** — Implementation scripts (bash). Scripts use `set -euo pipefail` and the `die()` pattern for error handling.

## Current Skills

- **`playwright-ephemeral`** — Provisions ephemeral Playwright MCP browser sessions as Kubernetes Jobs for E2E testing. Creates a Job + Service pair in a dedicated namespace, waits for readiness, and returns the MCP endpoint URL. Requires `kubectl` and appropriate RBAC.

## Key Patterns

- Scripts are pure bash with no external dependencies beyond standard Unix tools (`openssl`, `curl`, `jq`, `kubectl`).
- The `die()` function prints errors to stderr and exits non-zero.

## No Build/Test/Lint System

There is no centralized build, test, or lint tooling. Each skill is self-contained.
