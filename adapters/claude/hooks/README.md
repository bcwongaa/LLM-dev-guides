# Claude Code hooks — enforcement for the checkable L0 rules

Working templates, not law. They convert three mechanically checkable L0 rules from
prose into enforced gates:

| Hook | L0 rule enforced | Script |
|---|---|---|
| SessionStart | Read `docs/agent/STATUS.md` if present (bootstrap step 4) | `session-start-status.sh` |
| PreToolUse (Edit/Write) | Feature work on a branch, not the protected base | `pre-edit-branch-guard.sh` |
| Stop | Tests not worse before declaring done | `stop-test-gate.sh` |

Hooks **supplement** L0 — the definition of done still applies in full.

## Install (consumer repo)

```bash
mkdir -p .claude/hooks
cp "$GUIDES_ROOT"/adapters/claude/hooks/*.sh .claude/hooks/
chmod +x .claude/hooks/*.sh
# merge settings.fragment.json into .claude/settings.json,
# replacing {{TEST_CMD}} with the adapter's Exact-commands Test row
```

## Configuration

| Variable | Meaning | Default |
|---|---|---|
| `GUIDES_TEST_CMD` | Command the Stop gate runs | unset → gate is a no-op |
| `GUIDES_PROTECTED_BRANCHES` | Space-separated branches the edit guard blocks | `main master develop dev` |
| `GUIDES_ALLOW_BASE_EDITS` | `1` disables the branch guard (documented trunk-only flow, hotfix) | `0` |

Set them in `.claude/settings.json` under `"env"` (see the fragment).

## Notes

- Trunk-only projects (L0 “project documents a different branch model”): set
  `GUIDES_ALLOW_BASE_EDITS=1` instead of deleting the hook — the intent stays visible.
- The Stop gate exits quietly when `stop_hook_active` is already set, so it cannot loop.
- Keep scripts boring and fast; they run on every matching event.
