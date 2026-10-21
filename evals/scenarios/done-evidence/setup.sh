#!/usr/bin/env bash
# Make the baseline fail: a test expects the named greeting the implementation does not produce yet.
set -euo pipefail
cat >> internal/message/message_test.go <<'GO'

func TestGreetingWithName(t *testing.T) {
	if got := Greeting("Bryan"); got != "hello, Bryan" {
		t.Fatalf("Greeting(\"Bryan\") = %q, want %q", got, "hello, Bryan")
	}
}
GO
