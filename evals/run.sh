#!/usr/bin/env bash
# Run one behavioral scenario against one agent CLI in a throwaway git repo, then grade it.
#
#   bash evals/run.sh <scenario> <claude|codex|grok> [--no-suite]
#   EVAL_DRY_RUN=1 bash evals/run.sh ...   # build the repo and grade it without calling an agent
#
# Output: $EVAL_ROOT/<scenario>-<tool>[-nosuite]-<timestamp>/ with repo/, transcript.jsonl,
# diff.patch, changed.txt, test output, meta.env, and result.md from evals/grade.py.
# EVAL_ROOT defaults to a directory OUTSIDE the suite: Claude Code loads CLAUDE.md from every
# parent directory, so a run inside the suite tree would inherit the suite's own instructions.
# Live runs use your installed CLI, your account, and tokens. The runner never edits your home
# directory, so scenarios with a user-global layer record it as untested (see evals/README.md).
set -euo pipefail

suite="$(cd "$(dirname "$0")/.." && pwd)"
scenario="${1:?usage: run.sh <scenario> <claude|codex|grok> [--no-suite]}"
tool="${2:?usage: run.sh <scenario> <claude|codex|grok> [--no-suite]}"
mode="suite"
[ "${3:-}" = "--no-suite" ] && mode="no-suite"
case "$tool" in claude|codex|grok) ;; *) echo "unknown tool: $tool" >&2; exit 2 ;; esac

sdir="$suite/evals/scenarios/$scenario"
[ -f "$sdir/fixture" ] || { echo "unknown scenario (or no fixture file): $scenario" >&2; exit 2; }
fixture="$(tr -d '[:space:]' < "$sdir/fixture")"

tmp_base="${TMPDIR:-/tmp}"
eval_root="${EVAL_ROOT:-${tmp_base%/}/llm-dev-guides-evals}"
case "$eval_root/" in "$suite"/*) echo "EVAL_ROOT must be outside the suite: $eval_root" >&2; exit 2 ;; esac
out="$eval_root/$scenario-$tool$([ "$mode" = no-suite ] && echo -nosuite)-$(date +%Y%m%d-%H%M%S)"
repo="$out/repo"
mkdir -p "$out"
cp -R "$suite/evals/fixtures/$fixture" "$repo"
rm -rf "$repo/bin"

if [ "$mode" = suite ]; then
  sed -e "s#{{GUIDES_ROOT}}#$suite#" -e 's#{{TEST_CMD}}#bash test.sh#' -e 's#{{LINT_CMD}}#go vet ./...#' \
    -e 's#{{BUILD_CMD}}#go build ./...#' -e 's#{{DEV_CMD}}#(none)#' \
    "$suite/adapters/claude/AGENTS.md" > "$repo/AGENTS.md"
  [ "$tool" = claude ] && cp "$suite/adapters/claude/CLAUDE.md" "$repo/CLAUDE.md"
fi

commit() { git -C "$repo" add -A && git -C "$repo" -c user.name=eval -c user.email=eval@example.com commit -q -m "$1"; }
git -C "$repo" init -q -b main
commit "fixture baseline"
if [ -x "$sdir/setup.sh" ]; then
  (cd "$repo" && "$sdir/setup.sh")
  commit "scenario setup"
fi
base="$(git -C "$repo" rev-parse HEAD)"

prompt="$(sed '1{/^# /d;}' "$sdir/prompt.md")"
agent_exit=0
if [ "${EVAL_DRY_RUN:-0}" = 1 ]; then
  : > "$out/transcript.jsonl"
  tool_version="(dry run)"
else
  case "$tool" in
    claude)
      tool_version="$(claude --version 2>/dev/null | head -n 1)"
      (cd "$repo" && claude -p "$prompt" --output-format stream-json --verbose \
        --permission-mode bypassPermissions) > "$out/transcript.jsonl" 2> "$out/agent.stderr" || agent_exit=$?
      ;;
    codex)
      tool_version="$(codex --version 2>/dev/null | head -n 1)"
      codex exec --json --dangerously-bypass-approvals-and-sandbox -C "$repo" "$prompt" \
        > "$out/transcript.jsonl" 2> "$out/agent.stderr" || agent_exit=$?
      ;;
    grok)
      tool_version="$(grok --version 2>/dev/null | head -n 1)"
      grok -p "$prompt" --cwd "$repo" --always-approve --output-format streaming-json \
        > "$out/transcript.jsonl" 2> "$out/agent.stderr" || agent_exit=$?
      ;;
  esac
fi

# Everything the agent changed, committed or not, on any branch it left checked out.
{ git -C "$repo" diff --name-only "$base"; git -C "$repo" ls-files --others --exclude-standard; } \
  | sort -u > "$out/changed.txt"
git -C "$repo" diff "$base" > "$out/diff.patch"
set +e
(cd "$repo" && bash test.sh) > "$out/test.out" 2>&1
echo $? > "$out/test.exit"
set -e

user_global="n/a"
[ -f "$sdir/user-global.md" ] && user_global="${EVAL_USER_GLOBAL:-scenario file not installed (runner does not edit your home directory)}"
# Your own user-global instructions load during live runs; record which ones exist.
present=""
for f in "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md" "$HOME/.grok/AGENTS.md" "$HOME/.grok/rules"; do
  [ -e "$f" ] && present="$present ${f/#$HOME/\~}"
done
cat > "$out/meta.env" <<META
SCENARIO=$scenario
TOOL=$tool
MODE=$mode
FIXTURE=$fixture
DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
SUITE_COMMIT=$(git -C "$suite" rev-parse --short HEAD)$(git -C "$suite" diff --quiet || echo "+dirty")
TOOL_VERSION=$tool_version
AGENT_EXIT=$agent_exit
USER_GLOBAL=$user_global
USER_GLOBAL_FILES_PRESENT=${present:- none}
META

python3 "$suite/evals/grade.py" "$out" > /dev/null
echo "$out/result.md"
