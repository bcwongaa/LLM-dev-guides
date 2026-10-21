# Claude Code hooks — enforcement for the checkable protocol rules

Working templates, not law. They convert three mechanically checkable protocol rules from
prose into enforced gates:

| Hook | Protocol rule enforced | Script |
|---|---|---|
| SessionStart | Read `docs/agent/STATUS.md` if present (bootstrap step 4) | `session-start-status.sh` |
| SessionStart (`startup`) | Record the test baseline (bootstrap step 5) | `stop-test-gate.sh baseline` |
| PreToolUse (Edit/Write) | Feature work on a branch, not the protected base | `pre-edit-branch-guard.sh` |
| Stop | Tests not worse than that baseline before declaring done | `stop-test-gate.sh` |

Hooks **supplement** protocol — the definition of done still applies in full.

## Install (consumer repo)

```bash
mkdir -p .claude/hooks
cp "$GUIDES_ROOT"/adapters/claude/hooks/{session-start-status,pre-edit-branch-guard,stop-test-gate}.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
# merge settings.fragment.json into .claude/settings.json,
# replacing {{TEST_CMD}} with the adapter's Exact-commands Test row
```

## Configuration

| Variable | Meaning | Default |
|---|---|---|
| `GUIDES_TEST_CMD` | Command the baseline and Stop gate run | unset or `{{TEST_CMD}}` → gate is a no-op |
| `GUIDES_PROTECTED_BRANCHES` | Space-separated branches the edit guard blocks | `main master develop dev` |
| `GUIDES_ALLOW_BASE_EDITS` | `1` disables the branch guard (documented trunk-only flow, hotfix) | `0` |

Set them in `.claude/settings.json` under `"env"` (see the fragment).

## Notes

- Trunk-only projects (protocol “project documents a different branch model”): set
  `GUIDES_ALLOW_BASE_EDITS=1` instead of deleting the hook — the intent stays visible.
- The Stop gate blocks only when tests are red **and** were green at session start. Failures
  that predate the session are reported, not blocked; protocol still requires "not worse".
  "Worse" is judged by exit status; failure counts are runner-specific and out of scope.
- The Stop gate skips the test run when nothing changed since its last green run, so Q&A
  turns cost nothing. It exits quietly when `stop_hook_active` is set, so it cannot loop.
- The branch guard checks the branch of the worktree holding the edited file. Edits outside
  any repo (scratch files, memory, plans) are allowed. Edits made through Bash are not seen.
- Claude Code caps SessionStart output at 10,000 characters; a longer STATUS is replaced by a
  short preview. Keep STATUS short (protocol already bans essays there).
- Command hooks time out after 600 s by default, and a timeout lets the stop through. For a
  slower suite, set `"timeout"` on the Stop hook (and `"onFailure": "block"` on Claude Code
  v2.1.295+) rather than letting the gate silently pass.
- Keep scripts boring and fast; they run on every matching event. `test.sh` exercises them.
