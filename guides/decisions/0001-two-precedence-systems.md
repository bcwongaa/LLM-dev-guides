# ADR-0001: Two precedence systems

- **Status:** accepted
- **Date:** 2026-08-15
- **Scope:** suite-global

## Context

v1 used one conflict order, local code first and model taste last, for two different questions:
whose instruction wins when instructions disagree, and which code pattern new code follows in a
brownfield repo. The v2 generation split them (CHANGELOG v0.2: "Split instruction authority from
brownfield implementation convention").

The single v1 order answered two questions with one ranking. "Local code first" is right for how
new code looks, but it also put an existing file above the suite on correctness and safety, so a
file that swallows errors could justify swallowing more. And it had no place for org policy or
for what the human asked in this task.

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
