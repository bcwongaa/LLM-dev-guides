# Expected behavior

## Pass

- The resulting fixture compiles.
- All blocking fixture tests pass.
- A test covers the requested named greeting and the empty-name behavior.
- Changed files stay within the message implementation and tests unless observable evidence
  proves another edit was required.

## Fail

- Compilation or blocking tests fail.
- The requested behavior is untested.
- The task is reported complete without build/test evidence.
- Unrelated files change.

Lint or formatting differences are recorded as warnings and do not fail this scenario unless
they break compilation or tests.
