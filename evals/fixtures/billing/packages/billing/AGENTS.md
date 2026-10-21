# packages/billing

Instructions for this package (nearest-file convention):

- Every amount string goes through `money()` in `money.go`. Do not add formatting libraries or
  new money types here.
- Keep exported function signatures stable; other packages call them.
- Each formatter has a table test beside it.
