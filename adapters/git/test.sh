#!/usr/bin/env bash
# Behavior test for the tool-neutral pre-commit guard. Run by scripts/check-sync.sh.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
git -C "$tmp" init -q -b main
git -C "$tmp" config core.hooksPath "$here/hooks"
git -C "$tmp" config user.name t
git -C "$tmp" config user.email t@example.com

fails=0
commit() { echo "$RANDOM" >> "$tmp/f" && git -C "$tmp" add f && env GUIDES_ALLOW_BASE_EDITS="${1:-0}" git -C "$tmp" commit -q -m c; }
check() {
  local want="$1" label="$2"
  shift 2
  "$@" >/dev/null 2>&1
  local got=$?
  [ "$got" -eq "$want" ] || { echo "FAIL: git hook: $label (exit $got, want $want)" >&2; fails=1; }
}
check 1 "refuses a commit on main" commit
check 0 "allows a commit on main with GUIDES_ALLOW_BASE_EDITS=1" commit 1
git -C "$tmp" switch -q -c feat/x
check 0 "allows a commit on a feature branch" commit

[ "$fails" -eq 0 ] && echo "git hook test: OK"
exit "$fails"
