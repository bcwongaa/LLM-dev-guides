# LLM Dev Guides

**Public, opinionated agent guides** for multi-tool coding (Claude Code, Codex, Grok Build,
and similar). Distilled from real projects so agents follow one mental model instead of
generic “best practice.”

This is **one author’s engineering judgment**, not an industry standard. Fork, adapt, or
ignore pieces. In *your* repos, **local code and your rules still win** over these files
when they conflict (see L0).

## What’s in here

| Piece | Purpose |
|---|---|
| **L0–L9** | Protocol, style, bootstrap, stack, data, API, observability, testing, security, release |
| **L10** | Short ADR process + template for standing decisions |
| **`adapters/`** | Thin `CLAUDE.md` / `AGENTS.md` templates that point at the guides |
| **`USING_IN_EXISTING_REPOS.md`** | How to attach this suite to a brownfield app |

This repo’s own maps: root `CLAUDE.md`, `AGENTS.md` (for working *on* the suite).

## Layers (all v1)

| Layer | File |
|---|---|
| L0 | `L0_AGENT_PROTOCOL.md` |
| L1 | `L1_CODING_STYLE.md` |
| L2 | `L2_PROJECT_BOOTSTRAP.md` |
| L3 | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| L4 | `L4_DATA_MODEL.md` |
| L5 | `L5_API_AND_CONTRACTS.md` |
| L6 | `L6_OBSERVABILITY.md` |
| L7 | `L7_TESTING.md` |
| L8 | `L8_SECURITY_AND_SECRETS.md` |
| L9 | `L9_CHANGE_AND_RELEASE.md` |
| L10 | `L10_DECISIONS/` |
| Adapters | `adapters/{claude,codex,grok}/` |

## How to use

### In another / existing codebase

→ **[`USING_IN_EXISTING_REPOS.md`](./USING_IN_EXISTING_REPOS.md)**  
(submodule / sibling path / vendor copy, install adapters, brownfield rules, checklist)

Adapter details: [`adapters/README.md`](./adapters/README.md)

### Which guide for which task

| Need | Open |
|---|---|
| How any agent should work (incl. git flow + parallel agents) | `L0_AGENT_PROTOCOL.md` |
| Code shape / smells | `L1_CODING_STYLE.md` |
| Greenfield layout / engines | `L2_PROJECT_BOOTSTRAP.md` |
| Language / framework / storage | `L3_LANGUAGE_AND_FRAMEWORK.md` |
| Schema / migrations / money / time | `L4_DATA_MODEL.md` |
| HTTP / events / DTOs / internal transport | `L5_API_AND_CONTRACTS.md` |
| Logs / metrics / traces / DB health | `L6_OBSERVABILITY.md` |
| Testing / TDD / factories | `L7_TESTING.md` |
| Auth / PII / secrets / IDOR | `L8_SECURITY_AND_SECRETS.md` |
| Expand/contract, flags, deploy | `L9_CHANGE_AND_RELEASE.md` |
| ADRs | `L10_DECISIONS/README.md` |
| Adopt in an existing app | `USING_IN_EXISTING_REPOS.md` |

**Conflict order:** local code > these guides > third-party skills (except pure vendor API
how-to) > model taste.

**Bootstrap:** thin adapter → L0 → only the L\* files the task needs → `docs/agent/STATUS.md`
if present.

**Orchestration:** root asks the human; subagents escalate to parent (L0). Write children
need a full brief (paths, `GUIDES_ROOT`, L0). See L0 orchestrator checklist and
brief/result templates.

## Public repo notes

- **No secrets belong here** — only placeholders (e.g. in security examples). Don’t open PRs
  with real keys or private prod details.
- Guides say “ask the author” for hard choices: in a fork or your company, that means
  **your** owner / team, not a bot filing issues on this GitHub repo.
- Issues/PRs that improve clarity are welcome; wholesale rewrites to generic best-practice
  are out of scope for *this* project’s purpose.

## License

[MIT](./LICENSE) — free to use, copy, modify, and distribute with attribution notice
retained.
