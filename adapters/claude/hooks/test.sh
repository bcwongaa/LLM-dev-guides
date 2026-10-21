#!/usr/bin/env bash
# Behavior tests for the hooks: feed each one the JSON Claude Code sends and check the exit code.
# Run by scripts/check-sync.sh.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
mkdir -p "$repo/docs/agent"
git -C "$repo" init -q -b main
git -C "$repo" -c user.name=t -c user.email=t@example.com commit -q --allow-empty -m init

fails=0
check() {
  local want="$1" label="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  [ "$got" -eq "$want" ] || { echo "FAIL: hooks: $label (exit $got, want $want)" >&2; fails=1; }
}

guard() { # guard <file_path> [allow]
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":"x"}}' "$1" \
    | env CLAUDE_PROJECT_DIR="$repo" GUIDES_ALLOW_BASE_EDITS="${2:-0}" bash "$here/pre-edit-branch-guard.sh"
}
check 2 "guard blocks an in-repo edit on main" guard "$repo/src/a.txt"
check 0 "guard allows an edit outside any git repo" guard "$tmp/scratch/note.md"
check 0 "guard allows base edits when GUIDES_ALLOW_BASE_EDITS=1" guard "$repo/src/a.txt" 1
git -C "$repo" checkout -q -b feat/x
check 0 "guard allows an in-repo edit on a feature branch" guard "$repo/src/a.txt"
git -C "$repo" checkout -q main

gate() { # gate <test-cmd> [baseline]
  printf '{"session_id":"s1","stop_hook_active":false}' \
    | (cd / && env CLAUDE_PROJECT_DIR="$repo" GUIDES_TEST_CMD="$1" bash "$here/stop-test-gate.sh" ${2:-})
}
gate_active() {
  printf '{"session_id":"s1","stop_hook_active":true}' \
    | env CLAUDE_PROJECT_DIR="$repo" GUIDES_TEST_CMD=false bash "$here/stop-test-gate.sh"
}
check 0 "gate is a no-op when GUIDES_TEST_CMD is unset" gate ""
check 0 "gate is a no-op while GUIDES_TEST_CMD is the {{TEST_CMD}} placeholder" gate "{{TEST_CMD}}"
check 0 "gate lets the stop through once it already blocked" gate_active
check 2 "red tests with no recorded baseline block" gate false
gate false baseline >/dev/null 2>&1
check 0 "red tests do not block when the baseline was already red" gate false
gate true baseline >/dev/null 2>&1
check 2 "red tests block when the baseline was green" gate false
counter="$tmp/runs"
green="echo run >> '$counter'"
gate "$green" >/dev/null 2>&1
rm -f "$counter"
check 0 "gate passes on an unchanged tree after a green run" gate "$green"
[ ! -e "$counter" ] || { echo "FAIL: hooks: gate re-ran tests on an unchanged tree" >&2; fails=1; }

echo "# STATUS" > "$repo/docs/agent/STATUS.md"
status_out="$(cd / && CLAUDE_PROJECT_DIR="$repo" bash "$here/session-start-status.sh" </dev/null)"
case "$status_out" in
  *"# STATUS"*) ;;
  *) echo "FAIL: hooks: session-start-status.sh did not inject STATUS when run outside the project dir" >&2; fails=1 ;;
esac

[ "$fails" -eq 0 ] && echo "hooks test: OK"
exit "$fails"
