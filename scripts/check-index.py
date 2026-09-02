#!/usr/bin/env python3
"""Verify every line range a SKILL.md claims actually points at the section it names.

Deliberately independent of scripts/gen-adapters.py: it re-derives headings from the
guides with its own parser and validates the SKILL.md files *as shipped*. Sharing the
generator's code would only prove the generator agrees with itself. This catches a
generator bug, a hand-edited skill, and a guide edited without regeneration.

Exit 0 = every claimed range is real. Exit 1 = at least one claim is false.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "adapters" / "claude" / "skills"

CLAIM_RE = re.compile(r"^(\d+)-(\d+)\s+(\S.*?)\s*$")
LAW_RE = re.compile(r"^Law: `GUIDES_ROOT/(\S+?)`")
TAG_RE = re.compile(r"\s*`\[[a-z-]+\]`\s*$")

failures: list[str] = []


def err(msg: str) -> None:
    failures.append(msg)
    print(f"FAIL: {msg}", file=sys.stderr)


def headings_of(guide: Path) -> list[tuple[int, str]]:
    """Independent heading parse: `## ` at top level, ignoring fenced code blocks."""
    out: list[tuple[int, str]] = []
    fenced = False
    for n, line in enumerate(guide.read_text().splitlines(), start=1):
        stripped = line.lstrip()
        if stripped.startswith("```") or stripped.startswith("~~~"):
            fenced = not fenced
            continue
        if fenced:
            continue
        if line.startswith("## "):
            out.append((n, TAG_RE.sub("", line[3:].strip())))
    return out


def check_skill(skill_md: Path) -> None:
    rel = skill_md.relative_to(ROOT)
    text = skill_md.read_text()
    lines = text.splitlines()

    law = next((m.group(1) for line in lines if (m := LAW_RE.match(line))), None)
    if not law:
        err(f"{rel}: no `Law: GUIDES_ROOT/<guide>` line; cannot verify its claims")
        return

    guide = ROOT / law
    if not guide.is_file():
        err(f"{rel}: claims guide {law}, which does not exist")
        return

    guide_lines = guide.read_text().splitlines()
    eof = len(guide_lines)
    actual = headings_of(guide)
    claims = [
        (int(m.group(1)), int(m.group(2)), m.group(3))
        for line in lines
        if (m := CLAIM_RE.match(line))
    ]

    if not claims:
        err(f"{rel}: declares {law} but claims no ranges")
        return

    if len(claims) != len(actual):
        err(f"{rel}: claims {len(claims)} sections, {law} has {len(actual)}")

    for i, (start, end, title) in enumerate(claims):
        where = f"{rel} [{start}-{end} {title!r}]"

        if not 1 <= start <= eof:
            err(f"{where}: start line {start} outside {law} (1-{eof})")
            continue
        if end < start:
            err(f"{where}: end {end} precedes start {start}")
            continue
        if end > eof:
            err(f"{where}: end line {end} past EOF of {law} ({eof})")
            continue

        # The claimed start must BE the heading it names.
        real = guide_lines[start - 1]
        if not real.startswith("## "):
            err(f"{where}: {law}:{start} is not a heading, it is {real.strip()[:50]!r}")
            continue
        real_title = TAG_RE.sub("", real[3:].strip())
        if real_title != title:
            err(f"{where}: {law}:{start} is {real_title!r}, not the claimed title")

        # The range must stop exactly where the next section starts (or at EOF).
        expected_end = actual[i + 1][0] - 1 if i + 1 < len(actual) else eof
        if i < len(actual) and start == actual[i][0] and end != expected_end:
            err(f"{where}: range should end at {expected_end}, not {end}")

        # A range must never swallow a following heading.
        for hl, ht in actual:
            if start < hl <= end:
                err(f"{where}: range swallows section {ht!r} at {law}:{hl}")
                break

    # Every real section must be reachable from the index.
    claimed_starts = {c[0] for c in claims}
    for hl, ht in actual:
        if hl not in claimed_starts:
            err(f"{rel}: {law} section {ht!r} at line {hl} is missing from the index")


def check_index_tsv(tsv: Path) -> int:
    """Verify guides/<domain>/INDEX.tsv against the guide files it indexes."""
    rel = tsv.relative_to(ROOT)
    domain = tsv.parent
    rows = 0
    seen: dict[str, set[int]] = {}
    for lineno, line in enumerate(tsv.read_text().splitlines(), start=1):
        if line.startswith("#") or line.startswith("file\t") or not line.strip():
            continue
        parts = line.split("\t")
        if len(parts) != 6:
            err(f"{rel}:{lineno}: expected 6 tab-separated fields, got {len(parts)}")
            continue
        fname, start_s, end_s, bytes_s, tag, title = parts
        rows += 1
        target = domain / fname
        if not target.is_file():
            err(f"{rel}:{lineno}: indexes {fname}, which does not exist")
            continue
        lines = target.read_text().splitlines()
        try:
            start, end, claimed_bytes = int(start_s), int(end_s), int(bytes_s)
        except ValueError:
            err(f"{rel}:{lineno}: non-numeric start/end/bytes")
            continue
        if not 1 <= start <= len(lines) or end > len(lines) or end < start:
            err(f"{rel}:{lineno}: range {start}-{end} invalid for {fname} (1-{len(lines)})")
            continue
        real = lines[start - 1]
        if not real.startswith("## "):
            err(f"{rel}:{lineno}: {fname}:{start} is not a heading, it is {real.strip()[:40]!r}")
            continue
        raw = real[3:].strip()
        real_title = TAG_RE.sub("", raw)
        if real_title != title:
            err(f"{rel}:{lineno}: {fname}:{start} is {real_title!r}, not {title!r}")
        tag_m = TAG_RE.search(raw)
        real_tag = tag_m.group(0).strip().strip("`[]") if tag_m else ""
        if real_tag != tag:
            err(f"{rel}:{lineno}: tag is {real_tag!r} in the guide, indexed as {tag!r}")
        actual_bytes = len("\n".join(lines[start - 1 : end]))
        if actual_bytes != claimed_bytes:
            err(f"{rel}:{lineno}: claims {claimed_bytes}B, section is {actual_bytes}B")
        seen.setdefault(fname, set()).add(start)

    # No section may be missing from the index. Use the fence-aware parser: a `## `
    # inside a ```markdown block is a template example, not a section.
    for fname, starts in seen.items():
        for n, title in headings_of(domain / fname):
            if n not in starts:
                err(f"{rel}: {fname} section {title!r} at line {n} is missing from the index")
    return rows


def main() -> int:
    skills = sorted(SKILLS.glob("*/SKILL.md"))
    if not skills:
        err(f"no SKILL.md found under {SKILLS.relative_to(ROOT)}")
        return 1
    for s in skills:
        check_skill(s)
    tsvs = sorted((ROOT / "guides").glob("*/INDEX.tsv"))
    if not tsvs:
        err("no guides/*/INDEX.tsv found")
    index_rows = sum(check_index_tsv(t) for t in tsvs)
    total = sum(
        1
        for s in skills
        for line in s.read_text().splitlines()
        if CLAIM_RE.match(line)
    )
    if failures:
        print(
            "\nA line range no longer matches the section it names. If you edited a guide,\n"
            "the index is simply stale — regenerate it:\n"
            "    python3 scripts/gen-adapters.py --write\n"
            "If it is already regenerated, the claim is genuinely wrong; see\n"
            "docs/MAINTAINING_GUIDES.md before hand-editing anything.",
            file=sys.stderr,
        )
        print(f"check-index: FAILED ({len(failures)} false claims)", file=sys.stderr)
        return 1
    print(
        f"check-index: OK ({total} skill ranges across {len(skills)} skills, "
        f"{index_rows} index rows across {len(tsvs)} guides)"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
