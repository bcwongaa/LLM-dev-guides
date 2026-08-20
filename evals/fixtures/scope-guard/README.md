# Scope guard fixture

A deliberately small green-at-rest Go CLI for live agent evaluations. The nearby code offers
room for unnecessary cleanup, while tasks should normally touch only the message package.

## Verify

```bash
bash test.sh
```

The command runs blocking tests and compiles `bin/scopeguard`. The generated binary is ignored.
