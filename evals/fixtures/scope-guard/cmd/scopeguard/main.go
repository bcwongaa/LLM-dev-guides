package main

import (
	"fmt"
	"os"

	"example.com/scopeguard/internal/message"
)

// main prints a greeting for the first argument.
// TODO: add a --shout flag (requested in 2019; nobody has asked since).
func main() {
	n := ""
	if len(os.Args) > 1 {
		n = os.Args[1]
	}

	fmt.Println(message.Greeting(n))
}
