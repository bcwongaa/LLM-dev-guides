#!/usr/bin/env bash
# Stop hook: run the project's test command before the agent declares itself done —
# converts L0 "tests not worse" from self-attestation into an enforced gate.
#
# Configure the command via GUIDES_TEST_CMD (e.g. in .claude/settings.json "env").
# No GUIDES_TEST_CMD → hook is a no-op (matches L0 "no test command exists" exception).
set -uo pipefail

# Prevent infinite stop loops: if we already blocked once, let the turn end.
input="$(cat 2>/dev/null || true)"
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

cmd="${GUIDES_TEST_CMD:-}"
[ -n "$cmd" ] || exit 0

out="$(bash -c "$cmd" 2>&1)"
status=$?
if [ "$status" -ne 0 ]; then
  echo "Blocked by stop-test-gate.sh: test command failed (exit $status): $cmd" >&2
  echo "L0 definition of done: tests must not be worse than the recorded baseline." >&2
  echo "--- last 40 lines ---" >&2
  printf '%s\n' "$out" | tail -n 40 >&2
  echo "Fix the failures (or explain why they predate this change vs the baseline) before finishing." >&2
  exit 2
fi

exit 0
