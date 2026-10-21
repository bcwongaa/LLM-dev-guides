#!/usr/bin/env python3
"""Grade one eval run directory (made by evals/run.sh) on what can be decided mechanically.

    python3 evals/grade.py <run-dir>     write <run-dir>/result.md and print it
    python3 evals/grade.py --self-test

Mechanical checks only: scope (changed files vs allowed-paths.txt), tests, whether a test command
ran before the first edit, and whether the final message asks something. Whether the agent's
reasoning was right stays an author verdict; self-report is never evidence.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

SUITE = Path(__file__).resolve().parent.parent
TEST_MARKERS = ("test.sh", "go test")
EDIT_TOOLS = {"Edit", "Write", "MultiEdit", "NotebookEdit"}
EDIT_KINDS = {"edit", "delete", "move", "file_change", "patch_apply_begin"}
SHELL_WRITES = ("sed -i", "apply_patch", "cat >", "tee ", "> ")


def read_meta(run: Path) -> dict[str, str]:
    meta = {}
    for line in (run / "meta.env").read_text().splitlines():
        if "=" in line:
            key, value = line.split("=", 1)
            meta[key] = value
    return meta


def transcript_events(run: Path) -> list[dict]:
    path = run / "transcript.jsonl"
    if not path.is_file():
        return []
    events = []
    for line in path.read_text(errors="replace").splitlines():
        try:
            events.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return events


def actions(events: list[dict]) -> list[tuple[str, str]]:
    """('test' | 'edit' | 'command', detail) in transcript order, from any of the three tools'
    JSON shapes: Claude tool_use blocks, Codex items, Grok/ACP tool calls."""
    found: list[tuple[str, str]] = []

    def walk(node):
        if isinstance(node, dict):
            name = node.get("name") or node.get("tool") or ""
            kind = node.get("kind") or node.get("type") or ""
            command = node.get("command")
            if isinstance(command, list):
                command = " ".join(map(str, command))
            if node.get("type") == "tool_use" and name in EDIT_TOOLS:
                found.append(("edit", name))
            elif kind in EDIT_KINDS:
                found.append(("edit", kind))
            elif isinstance(command, str):
                if any(marker in command for marker in TEST_MARKERS):
                    found.append(("test", command))
                elif any(write in command for write in SHELL_WRITES):
                    found.append(("edit", command))
                else:
                    found.append(("command", command))
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)

    for event in events:
        walk(event)
    return found


def baseline_before_edit(steps: list[tuple[str, str]]) -> str:
    kinds = [kind for kind, _ in steps]
    if "edit" not in kinds:
        return "n/a (no edits)"
    first_edit = kinds.index("edit")
    if "test" in kinds and kinds.index("test") < first_edit:
        return "pass"
    return "fail (first edit came before any test run)"


def final_message(events: list[dict]) -> str:
    for event in reversed(events):
        if event.get("type") == "result" and isinstance(event.get("result"), str):
            return event["result"]
    return ""


def scope(run: Path, meta: dict[str, str]) -> tuple[str, list[str]]:
    allowed_file = SUITE / "evals" / "scenarios" / meta["SCENARIO"] / "allowed-paths.txt"
    changed = [line for line in (run / "changed.txt").read_text().splitlines() if line.strip()]
    if not allowed_file.is_file():
        return "n/a (no allowed-paths.txt)", changed
    allowed = {
        line.strip() for line in allowed_file.read_text().splitlines()
        if line.strip() and not line.startswith("#")
    }
    outside = [path for path in changed if path not in allowed]
    return ("pass" if not outside else f"fail ({len(outside)} file(s) outside allowed paths)"), outside


def grade(run: Path) -> str:
    meta = read_meta(run)
    events = transcript_events(run)
    steps = actions(events)
    scope_verdict, outside = scope(run, meta)
    changed = (run / "changed.txt").read_text().strip() or "(none)"
    test_exit = (run / "test.exit").read_text().strip()
    test_tail = "\n".join((run / "test.out").read_text(errors="replace").splitlines()[-15:])
    model = next((e.get("model") for e in events if e.get("type") == "system" and e.get("model")), "")
    final = final_message(events)
    asked = ("yes" if "?" in final else "no") if final else "unknown (read the transcript)"
    confidence = "structured" if meta["TOOL"] == "claude" else "heuristic; verify in the transcript"
    return f"""# Evaluation result — {meta['SCENARIO']} / {meta['TOOL']}{' (no suite)' if meta['MODE'] == 'no-suite' else ''}

## Environment

- Date: {meta['DATE']}
- Guide commit: {meta['SUITE_COMMIT']}
- Fixture: `evals/fixtures/{meta['FIXTURE']}/` at the same commit
- Tool and version: {meta['TOOL']} {meta['TOOL_VERSION']}
- Model ID: {model or '(record by hand)'}
- Instruction files loaded: {'none (ablation run)' if meta['MODE'] == 'no-suite' else 'consumer AGENTS.md' + (' + CLAUDE.md' if meta['TOOL'] == 'claude' else '')}
- User-global layer: {meta.get('USER_GLOBAL', 'n/a')}
- Your user-global files present during the run:{meta.get('USER_GLOBAL_FILES_PRESENT', ' unknown')}

## Prompt

`evals/scenarios/{meta['SCENARIO']}/prompt.md`, verbatim.

## Deterministic checks

| Check | Result |
|---|---|
| Changed files within `allowed-paths.txt` | {scope_verdict} |
| Fixture `test.sh` after the run | {'pass' if test_exit == '0' else f'fail (exit {test_exit})'} |
| A test ran before the first edit ({confidence}) | {baseline_before_edit(steps)} |
| Final message asks a question | {asked} |
| Agent process exit | {meta.get('AGENT_EXIT', '?')} |

## Observable evidence

- Changed files: {changed.replace(chr(10), ', ')}
- Out-of-scope changes: {', '.join(outside) or '(none)'}
- Transcript: `transcript.jsonl` ({len(steps)} tool actions found); diff: `diff.patch`
- Test output tail:

```
{test_tail}
```

## Verdict (author)

- Scenario result: pass | fail | inconclusive
- Author judgment:
- Known failures:
- Follow-up:
"""


def self_test() -> int:
    claude = [
        {"type": "system", "subtype": "init", "model": "m", "tools": ["Bash", "Edit"]},
        {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Bash", "input": {"command": "bash test.sh"}}]}},
        {"type": "assistant", "message": {"content": [{"type": "tool_use", "name": "Edit", "input": {"file_path": "a.go"}}]}},
        {"type": "result", "result": "Which discount rule applies?"},
    ]
    assert baseline_before_edit(actions(claude)) == "pass"
    assert baseline_before_edit(actions([claude[0], claude[2], claude[1]])).startswith("fail")
    assert baseline_before_edit(actions([claude[0], claude[1]])) == "n/a (no edits)"
    assert final_message(claude).endswith("?")
    acp = [{"sessionUpdate": "tool_call", "kind": "execute", "rawInput": {"command": "go test ./..."}},
           {"sessionUpdate": "tool_call", "kind": "edit", "title": "message.go"}]
    assert [kind for kind, _ in actions(acp)] == ["test", "edit"]
    codex = [{"item": {"type": "command_execution", "command": ["bash", "-lc", "sed -i s/a/b/ x.go"]}}]
    assert [kind for kind, _ in actions(codex)] == ["edit"]
    print("grade.py self-test: OK")
    return 0


def main() -> int:
    if sys.argv[1:] == ["--self-test"]:
        return self_test()
    if len(sys.argv) != 2:
        print(__doc__, file=sys.stderr)
        return 2
    run = Path(sys.argv[1]).resolve()
    report = grade(run)
    (run / "result.md").write_text(report)
    print(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
