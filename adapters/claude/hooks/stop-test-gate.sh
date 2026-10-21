#!/usr/bin/env bash
# Run the project's test command before the agent declares itself done, and block only when the
# tests are worse than at session start. Protocol's bar is "not worse than the recorded baseline",
# not "green": a repo whose tests already failed when the session began is not blocked by them.
#
#   stop-test-gate.sh baseline   SessionStart (matcher "startup"): record this session's baseline
#   stop-test-gate.sh            Stop: run the tests and compare against that baseline
#
# Configure the command via GUIDES_TEST_CMD (e.g. in .claude/settings.json "env"). Unset, or still
# the {{TEST_CMD}} placeholder → no-op (matches protocol "no test command exists" exception).
# "Worse" is judged by exit status only; failure counts are runner-specific and out of scope here.
set -uo pipefail
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

input="$(cat 2>/dev/null || true)"
cmd="${GUIDES_TEST_CMD:-}"
case "$cmd" in
  "") exit 0 ;;
  *"{{"*)
    echo "stop-test-gate.sh: GUIDES_TEST_CMD is still the {{TEST_CMD}} placeholder; the gate is off until it is filled in." >&2
    exit 0 ;;
esac

git_dir="$(git rev-parse --absolute-git-dir 2>/dev/null || true)"
session="$(printf '%s' "$input" | sed -nE 's/.*"session_id"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -n 1)"

run_tests() {
  out="$(bash -c "$cmd" 2>&1)"
  status=$?
}

if [ "${1:-}" = "baseline" ]; then
  [ -n "$git_dir" ] || exit 0
  run_tests
  printf '%s\t%s\n' "$session" "$status" > "$git_dir/guides-baseline"
  if [ "$status" -ne 0 ]; then
    echo "Test baseline at session start: FAILING (exit $status, command: $cmd). Record this as the baseline; the stop gate will not block on failures that predate this session."
  fi
  exit 0
fi

# Prevent infinite stop loops: if we already blocked once, let the turn end.
if printf '%s' "$input" | grep -q '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi

# Skip the run when nothing changed since the last green run (Q&A turns, repeated stops).
state="$({ printf '%s\n' "$cmd"; git rev-parse HEAD; git status --porcelain=v1 -uall; git diff HEAD; } 2>/dev/null | cksum)"
if [ -n "$git_dir" ] && [ "$(cat "$git_dir/guides-last-green" 2>/dev/null)" = "$state" ]; then
  exit 0
fi

run_tests
if [ "$status" -eq 0 ]; then
  [ -n "$git_dir" ] && printf '%s' "$state" > "$git_dir/guides-last-green"
  exit 0
fi

baseline=""
[ -n "$git_dir" ] && baseline="$(awk -F'\t' -v s="$session" '$1 == s { print $2 }' "$git_dir/guides-baseline" 2>/dev/null)"
if [ -n "$baseline" ] && [ "$baseline" -ne 0 ]; then
  echo "stop-test-gate.sh: tests fail (exit $status), but they already failed at session start (exit $baseline). Not blocking; report failures against the baseline in the summary." >&2
  exit 0
fi

echo "Blocked by stop-test-gate.sh: test command failed (exit $status): $cmd" >&2
echo "Protocol definition of done: tests must not be worse than the recorded baseline${baseline:+ (green at session start)}." >&2
echo "--- last 40 lines ---" >&2
printf '%s\n' "$out" | tail -n 40 >&2
echo "Fix the failures (or explain why they predate this change vs the baseline) before finishing." >&2
exit 2
