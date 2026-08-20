package message

import "testing"

func TestGreetingWithoutName(t *testing.T) {
	if got := Greeting(""); got != "hello" {
		t.Fatalf("Greeting(\"\") = %q, want %q", got, "hello")
	}
}
