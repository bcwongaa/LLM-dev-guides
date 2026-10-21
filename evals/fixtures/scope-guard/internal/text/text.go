// Package text holds string helpers for future commands.
package text

import "strings"

// Title upper-cases the first letter of each word.
func Title(s string) string {
	return strings.Title(s)
}
