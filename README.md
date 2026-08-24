# LLM Dev Guides

**Public, opinionated agent guides** for multi-tool coding (Claude Code, Codex, Grok Build,
and similar). Distilled from real projects so agents follow one mental model instead of
generic “best practice.”

This is **one author’s engineering judgment**, not an industry standard. Fork, adapt, or
ignore pieces. In *your* repos, **local code and your rules still win** over these files
when they conflict (see protocol).

## What’s in here

| Piece | Purpose |
|---|---|
| **`guides/`** | Protocol, orchestration, style, architecture, stack, data, contracts, observability, testing, security, release, ADRs |
| **`adapters/`** | Generated consumer `AGENTS.md` (shared) + Claude `@AGENTS.md` wrapper; hooks stay hand-authored |
| **`docs/USING_IN_EXISTING_REPOS.md`** | How to attach this suite to a brownfield app |

This repo’s own maps: root `AGENTS.md` (canonical), `CLAUDE.md` (`@AGENTS.md` + Claude mechanics).

## Guides

| Guide | File |
|---|---|
| Protocol | `guides/protocol/RULES.md` (every-task core) |
| Orchestration | `guides/orchestration/RULES.md` (git flow, parallel agents, subagents — load when orchestrating) |
| Code style | `guides/code-style/RULES.md` + `REFERENCE.md` |
| Architecture | `guides/architecture/RULES.md` |
| Stack | `guides/stack/RULES.md` |
| Data | `guides/data/RULES.md` |
| Contracts | `guides/contracts/RULES.md` |
| Observability | `guides/observability/RULES.md` |
| Testing | `guides/testing/RULES.md` |
| Security | `guides/security/RULES.md` |
| Release | `guides/release/RULES.md` |
| Decisions | `guides/decisions/` |
| Adapters | `adapters/{claude,codex,grok}/` |

## How to use

### In another / existing codebase

→ **[`docs/USING_IN_EXISTING_REPOS.md`](./docs/USING_IN_EXISTING_REPOS.md)**  
(submodule / sibling path / vendor copy, install `AGENTS.md`, brownfield rules, checklist)

Adapter details: [`adapters/README.md`](./adapters/README.md)

### Which guide for which task

| Need | Open |
|---|---|
| How any agent should work (start, ask vs decide, done bar) | `guides/protocol/RULES.md` |
| Git flow, parallel agents, subagent briefs, orchestration | `guides/orchestration/RULES.md` |
| Code shape / smells | `guides/code-style/RULES.md` |
| Greenfield layout / engines | `guides/architecture/RULES.md` |
| Language / framework / storage | `guides/stack/RULES.md` |
| Schema / migrations / money / time | `guides/data/RULES.md` |
| HTTP / events / DTOs / internal transport | `guides/contracts/RULES.md` |
| Logs / metrics / traces / DB health / runtime data health and lineage | `guides/observability/RULES.md` |
| Testing / TDD / factories | `guides/testing/RULES.md` |
| Auth / PII / secrets / IDOR | `guides/security/RULES.md` |
| Expand/contract, flags, deploy | `guides/release/RULES.md` |
| ADRs | `guides/decisions/RULES.md` |
| Adopt in an existing app | `docs/USING_IN_EXISTING_REPOS.md` |

**Instruction authority:** org/platform policy > current-task human > project/path instructions > adopted suite > user-global > third-party skills (except vendor API how-to) > model taste.

**Implementation convention:** approved task design > nearest file > package > repository > suite default.

**Bootstrap:** thin adapter → protocol → only the guides the task needs → `docs/agent/STATUS.md`
if present.

**Orchestration:** root asks the human; subagents escalate to parent. Write children
need a full brief (paths, `GUIDES_ROOT`, protocol). See `guides/orchestration/RULES.md` for the
orchestrator checklist and brief/result templates.

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
