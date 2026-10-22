# ADR-0006: No playbooks

- **Status:** accepted
- **Date:** 2026-08-15
- **Scope:** suite-global

## Context

Settled in the v2 author survey.

A playbook restates domain law as steps for one task. Each one is a second copy of the law that
drifts when the guide changes, and agents treat its steps as complete when they are not.

## Decision

The suite ships no playbooks: no task-specific step-by-step procedures ("how to add an endpoint",
"how to run a migration") beside the domain guides. The guides state law and rationale, and
agents apply them.

## Consequences

- **Good:** law lives in one place per domain.
- **Bad / tradeoffs:** recurring tasks have no ready-made sequence.
- **Follow-ups:** none.
