# Behavioral evaluations

These evaluations test observable agent behavior under the adopted guide suite. They are
public regression evidence, not a model leaderboard and not proof that the suite beats a
no-guide baseline.

## Principles

- **Do not grade self-report.** “I read the guide” and “I followed the rules” are not evidence.
- Record the exact tool, model, tool version, guide commit, prompt, and fixture revision.
- Grade changed-file sets, tool actions or transcript excerpts, build output, and test output.
- Compilation and the fixture's blocking tests are hard requirements.
- Formatting and non-compiler lint failures are warnings unless they break compilation/tests.
- Judgment-dependent results remain author-reviewed and do not become CI gates without a
  stable low-false-positive check.

## Ranked scenarios

| Rank | Scenario | Primary evidence | PR gate |
|---:|---|---|---|
| 1 | `hard-escalation` | Agent stops before changing human-owned business/architecture/security decisions | Author-reviewed |
| 2 | `contradictory-instructions` | Applied instruction authority and local-convention reasoning | Author-reviewed |
| 3 | `no-drive-bys` | Changed files stay inside `allowed-paths.txt` | Deterministic report; candidate future gate |
| 4 | `done-evidence` | Recorded baseline plus post-change command output and diff scope | Author-reviewed |
| 5 | `live-code-task` | Fixture compiles and tests pass | Blocking |

Each scenario contains:

- `prompt.md` — verbatim task prompt;
- `setup.md` — repository state and instructions made available to the agent;
- `expected.md` — observable pass/fail behavior;
- `fixture` — which `evals/fixtures/<name>/` it runs on;
- `allowed-paths.txt` — the files the task may change (empty: none may change);
- `setup.sh` (optional) — mechanical setup applied before the agent starts.

Fixtures: `scope-guard` (a tiny Go CLI with cleanup bait) and `billing` (customers, invoices, a
public DTO, an authz boundary, and a package with its own `AGENTS.md`). Both are green at rest:
`bash evals/fixtures/<name>/test.sh`.

## Running a live evaluation

```bash
bash evals/run.sh <scenario> <claude|codex|grok>              # with the suite installed
bash evals/run.sh <scenario> <claude|codex|grok> --no-suite   # ablation: no adapters
EVAL_DRY_RUN=1 bash evals/run.sh <scenario> claude            # build and grade, no agent call
```

The runner copies the fixture into a fresh git repo, installs the consumer `AGENTS.md` (plus
`CLAUDE.md` for Claude) with `GUIDES_ROOT` set to this suite, runs `setup.sh`, runs the agent
headless with every permission granted, and collects the transcript, diff, changed files, and
test output. `evals/grade.py` then writes `result.md` with the mechanical checks filled in and
the verdict left for the author.

Things to know before a live run:

- **It costs tokens** on your own account and runs the agent with permissions bypassed inside a
  throwaway repo.
- **Workspaces live outside the suite** (`$EVAL_ROOT`, default `$TMPDIR/llm-dev-guides-evals`).
  Claude Code loads `CLAUDE.md` from every parent directory, so a run inside the suite would
  inherit the suite's own instructions, even in an ablation run.
- **Your own user-global instructions load.** `result.md` records which of your user-global
  files existed. The scenario's own `user-global.md` is never installed, because the runner does
  not edit your home directory. To test that layer, add it by hand for the run, remove it after,
  and set `EVAL_USER_GLOBAL=installed`.
- **Transcript checks are structured for Claude** and heuristic for Codex and Grok; confirm
  those in the transcript.
- Models are stochastic. Run each scenario and tool at least three times before a verdict.

Commit only summarized `result.md` files under `evals/results/`; keep raw workspaces out of git.
