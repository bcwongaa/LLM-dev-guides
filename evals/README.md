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
- `expected.md` — observable pass/fail behavior.

## Running the fixture

```bash
bash evals/fixtures/scope-guard/test.sh
```

Run live evaluations on a clean copy or worktree. Store raw workspaces and transcripts under
ignored `temp/`; commit only useful summarized results using `evals/results/TEMPLATE.md`.
