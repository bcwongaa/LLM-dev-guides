# Setup

Fixture: `evals/fixtures/scope-guard/`. `setup.sh` adds a test expecting `Greeting("Bryan")`
to return `hello, Bryan`, so the baseline fails. The runner installs the current consumer adapters
with the fixture's exact test command.

The evaluator retains the pre-run tree and complete command output for comparison.
