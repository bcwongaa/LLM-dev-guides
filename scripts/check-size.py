#!/usr/bin/env python3
"""Size gate for every text file in the repo. Policy and rationale: docs/MAINTAINING_GUIDES.md.

Per file and per metric (bytes, lines):
  over the hard cap                          -> FAIL: repo-wide refactor signal, ask the author
  over the soft cap and over mean + 1.5 SD   -> FAIL: split by topic, or ask the author
  over the soft cap only                     -> note: tolerated outlier

Mean and SD come from scripts/size-baseline.tsv, recalculated only when a release is cut
(--rebaseline TAG). Live stats would drop the bar every time a big file is split.

Never compress wording to get under a number. That is the failure this design exists to stop.
"""
from __future__ import annotations

import argparse
import statistics
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASELINE = ROOT / "scripts" / "size-baseline.tsv"
OUTLIER_SD = 1.5

KB = 1024
# kind: (soft bytes, soft lines, hard bytes, hard lines)
# The byte hard caps sit at Codex's single-read window (10,000 tokens of shell output, about 40 KB).
# The 1,600-line hard cap is the author's brake on drift, well above today's largest file; it is
# not a read window (Grok's read tool returns 1,000 lines per call).
HARD_LINES = 1600
CAPS = {
    "rules": (8 * KB, 500, 16 * KB, HARD_LINES),
    "reference": (20 * KB, 500, 40 * KB, HARD_LINES),
    "docs": (20 * KB, 500, 40 * KB, HARD_LINES),
    "code": (20 * KB, 500, 40 * KB, HARD_LINES),
}
# Limits the tools enforce, not ours: Codex reads at most 32 KiB across the AGENTS.md chain;
# the Agent Skills spec caps a skill description at 1,024 characters.
AGENTS_CHAIN_MAX_BYTES = 32 * KB
SKILL_DESCRIPTION_MAX_CHARS = 1024


def kind_of(rel: str) -> str:
    path = Path(rel)
    if path.parts[0] == "guides" and path.name.startswith("RULES"):
        return "rules"
    if path.parts[0] == "guides" and path.name.startswith("REFERENCE"):
        return "reference"
    return "docs" if path.suffix == ".md" else "code"


def git(*args: str) -> bytes:
    return subprocess.run(["git", *args], cwd=ROOT, capture_output=True, check=True).stdout


def measured_files(ref: str | None = None) -> list[tuple[str, str, int, int]]:
    """(path, kind, bytes, lines) for text files at `ref`, or in the working tree when ref is None
    (tracked plus untracked-but-not-ignored)."""
    if ref:
        listing = git("ls-tree", "-r", "--name-only", ref).decode().splitlines()
    else:
        listing = git("ls-files", "--cached", "--others", "--exclude-standard").decode().splitlines()
    out = []
    for rel in sorted(set(listing)):
        if rel.startswith("temp/"):
            continue
        if ref:
            data = git("show", f"{ref}:{rel}")
        elif (ROOT / rel).is_file():
            data = (ROOT / rel).read_bytes()
        else:
            continue
        if b"\0" in data:
            continue
        out.append((rel, kind_of(rel), len(data), len(data.decode("utf-8", "replace").splitlines())))
    return out


def load_baseline() -> dict[str, tuple[str, float, float, float, float]]:
    rows = {}
    for line in BASELINE.read_text().splitlines():
        if not line.strip() or line.startswith("#"):
            continue
        release, kind, _n, mean_b, sd_b, mean_l, sd_l = line.split("\t")
        rows[kind] = (release, float(mean_b), float(sd_b), float(mean_l), float(sd_l))
    return rows


def rebaseline(release: str) -> int:
    files = measured_files(release)
    lines = [
        "# Per-kind size stats for the outlier bar (mean + 1.5 SD). Recalculated only when a",
        "# release is cut, so splitting a big file does not drop the bar for every other file.",
        "# Regenerate at release time: python3 scripts/check-size.py --rebaseline <tag>",
        "# release\tkind\tn\tmean_bytes\tsd_bytes\tmean_lines\tsd_lines",
    ]
    for kind in CAPS:
        sizes = [(b, n) for _rel, k, b, n in files if k == kind]
        if len(sizes) < 2:
            print(f"FAIL: kind {kind!r} has {len(sizes)} files; cannot compute a baseline", file=sys.stderr)
            return 1
        b_vals = [b for b, _ in sizes]
        l_vals = [n for _, n in sizes]
        lines.append(
            f"{release}\t{kind}\t{len(sizes)}\t{statistics.mean(b_vals):.0f}\t{statistics.stdev(b_vals):.0f}"
            f"\t{statistics.mean(l_vals):.0f}\t{statistics.stdev(l_vals):.0f}"
        )
    BASELINE.write_text("\n".join(lines) + "\n")
    print(f"check-size --rebaseline: wrote {BASELINE.relative_to(ROOT)} for {release}")
    return 0


def tool_limit_failures() -> list[str]:
    failures = []
    for agents in [ROOT / "AGENTS.md", *sorted((ROOT / "adapters").glob("*/AGENTS.md"))]:
        size = len(agents.read_bytes())
        if size > AGENTS_CHAIN_MAX_BYTES:
            failures.append(
                f"{agents.relative_to(ROOT)}: {size} B; Codex reads at most {AGENTS_CHAIN_MAX_BYTES} B "
                "across the whole AGENTS.md chain and silently truncates the rest"
            )
    for skill in sorted((ROOT / "adapters" / "skills").glob("*/SKILL.md")):
        for line in skill.read_text().splitlines():
            if line.startswith("description:"):
                desc = line.split(":", 1)[1].strip().strip('"')
                if len(desc) > SKILL_DESCRIPTION_MAX_CHARS:
                    failures.append(
                        f"{skill.relative_to(ROOT)}: description is {len(desc)} chars; "
                        f"the Agent Skills spec allows {SKILL_DESCRIPTION_MAX_CHARS}"
                    )
    return failures


def check() -> int:
    baseline = load_baseline()
    failures = tool_limit_failures()
    notes = []
    for rel, kind, nbytes, nlines in measured_files():
        soft_b, soft_l, hard_b, hard_l = CAPS[kind]
        if kind not in baseline:
            failures.append(f"{rel}: no baseline row for kind {kind!r}; run --rebaseline at the next release")
            continue
        release, mean_b, sd_b, mean_l, sd_l = baseline[kind]
        for metric, value, soft, hard, mean, sd in (
            ("bytes", nbytes, soft_b, hard_b, mean_b, sd_b),
            ("lines", nlines, soft_l, hard_l, mean_l, sd_l),
        ):
            bar = mean + OUTLIER_SD * sd
            if value > hard:
                failures.append(
                    f"{rel}: {value} {metric}, over the hard cap of {hard}. This is a repo-wide "
                    "refactor signal: stop and ask the author."
                )
            elif value > soft and value > bar:
                failures.append(
                    f"{rel}: {value} {metric}, over the {kind} soft cap ({soft}) and over the outlier "
                    f"bar ({bar:.0f} = mean + {OUTLIER_SD} SD at {release}). Split it by topic, or ask "
                    "the author. Do not compress wording to get under the bar."
                )
            elif value > soft:
                notes.append(f"{rel}: {value} {metric}, over the {kind} soft cap ({soft}); tolerated outlier")
    for note in notes:
        print(f"note: {note}", flush=True)
    for failure in failures:
        print(f"FAIL: {failure}", file=sys.stderr)
    if failures:
        print("check-size: FAILED (policy: docs/MAINTAINING_GUIDES.md)", file=sys.stderr)
        return 1
    print(f"check-size: OK ({len(notes)} tolerated outliers)")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--rebaseline", metavar="RELEASE_TAG", help="recalculate per-kind stats from the files at this git tag; run only when cutting a release")
    args = parser.parse_args()
    return rebaseline(args.rebaseline) if args.rebaseline else check()


if __name__ == "__main__":
    sys.exit(main())
