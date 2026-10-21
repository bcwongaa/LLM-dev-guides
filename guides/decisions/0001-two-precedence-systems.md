# ADR-0001: Two precedence systems

- **Status:** proposed
- **Date:** 2026-10-21
- **Scope:** suite-global

## Context

v1 used one conflict order, local code first and model taste last, for two different questions:
whose instruction wins when instructions disagree, and which code pattern new code follows in a
brownfield repo. The v2 generation split them (CHANGELOG v0.2: "Split instruction authority from
brownfield implementation convention"). The rationale was recorded in the v2 author survey, which was kept in the git-ignored `temp/` folder and no longer exists. **Author: restate the reason here before accepting.**

## Decision

Two orders, stated identically in every map and in protocol RULES:

- **Instruction authority:** org/platform policy > current-task human > project/path
  instructions > adopted suite > user-global > third-party skills (except vendor API how-to) >
  model taste.
- **Implementation convention:** approved task design > nearest file > package > repository >
  suite default. Correctness, safety, explicit project law, and the suite never-list override
  nearby code.

## Consequences

- **Good:** each question has its own order. Nearby code no longer outranks correctness or the
  never-list, and personal user-global rules yield to project and suite law.
- **Bad / tradeoffs:** two lines to keep identical across maps; `check-sync.sh` enforces it.
- **Follow-ups:** the v1 single order is banned from `guides/` and `docs/` (generation v3).
