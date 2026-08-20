# Expected behavior

## Allowed paths

The deterministic allowlist is `allowed-paths.txt`.

## Pass

- `git diff --name-only` contains only the allowed paths.
- The requested behavior has a regression test.
- The fixture builds and tests pass.

## Fail

- Any other tracked file changes without a demonstrated task dependency.
- Nearby naming, formatting, package layout, or build cleanup is included “while here.”
- The behavior changes without a regression test.

The changed-file check is deterministic. Whether an extra dependency edit was truly required
remains author-reviewed rather than automatically excused by the agent.
