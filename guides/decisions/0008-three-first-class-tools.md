# ADR-0008: Claude Code, Codex, and Grok Build are first-class tools

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

The author works across all three tools, and every one of them must load the same law.

## Decision

All three are first-class: they read the same `AGENTS.md` and guides, they are evaluated
(`evals/run.sh`), and the pointer-skills ship for all three in the Agent Skills format. Tool
mechanics may differ: the hooks in `adapters/claude/hooks/` are Claude-native, while the git
pre-commit guard holds for every tool.

## Consequences

- **Good:** a task can move between tools without changing the rules.
- **Bad / tradeoffs:** every tool-facing change needs checking against three tools' docs.
- **Follow-ups:** live evaluation results per tool, before the `v2`/`v3` tag.
