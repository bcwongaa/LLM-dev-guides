package main

import (
	"fmt"
	"os"

	"example.com/scopeguard/internal/message"
)

func main() {
	name := ""
	if len(os.Args) > 1 {
		name = os.Args[1]
	}

	fmt.Println(message.Greeting(name))
}
